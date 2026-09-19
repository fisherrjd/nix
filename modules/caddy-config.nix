# modules/caddy-config.nix
#
# bifrost's public edge: Caddy terminates TLS for *.jade.rip and proxies to
# tailnet hosts. Google login is caddy-security's `friends_only` policy.
#
#   Add a site    -> one line in `sites`
#   Add a friend  -> one line in `friends`
#
# The `caddy` age secret (Google client id/secret, JWT key) is declared by the
# host that imports this, since identityPaths are host-specific.
{ config, lib, pkgs, ... }:
let
  # Google accounts allowed past `authorize with friends_only` pages.
  # Adding a friend = one line here (their Google login email).
  admins = [
    "fisherrjd@gmail.com"
    "hlwolfinbarger@gmail.com"
  ];
  friends = [
    # "friend@gmail.com"
  ];

  # ---- site builders -------------------------------------------------------

  # Public reverse proxy.
  proxy = to: ''
    reverse_proxy * {
      to ${to}
    }
  '';

  # Reverse proxy behind Google login.
  private = to: "authorize with friends_only\n" + proxy to;

  # Behind Google login, except an exact list of paths that authenticate
  # themselves. `route` keeps the two handlers in written order, so the open
  # paths are matched first and everything else falls through to `authorize`.
  privateExcept = { to, method, paths }: ''
    @open {
      method ${method}
      path ${lib.concatStringsSep " " paths}
    }
    route {
      handle @open {
        reverse_proxy ${to}
      }
      handle {
        authorize with friends_only
        reverse_proxy ${to}
      }
    }
  '';

  # Paths the Atlas worker daemon calls. Each carries its own bearer token, and
  # a daemon cannot complete a browser login, so they skip Google. Everything
  # else on the host stays behind it -- including enroll/revoke/reset, which
  # live under the same /workers/ prefix. That is why this is an exact list and
  # must never become a /api/v1/workers/* wildcard.
  #
  # They cannot simply pass through `authorize` either: friends_only sets
  # `validate bearer header`, so a worker's bearer would be parsed as a login
  # JWT and refused.
  atlasWorkerPaths = map (p: "/api/v1/workers/${p}") [
    "refresh"
    "events"
    "claim"
    "renew"
    "fetch-credential"
    "complete"
    "unlaunchable"
    "control/poll"
    "control/receipt"
    "control/confirm"
  ];

  # ---- sites ---------------------------------------------------------------

  sites = {
    # Google-auth login portal (caddy-security)
    "auth.jade.rip" = ''
      authenticate with auth_portal
    '';

    "ntfy.jade.rip" = proxy "eldo:8081"; # push notifications
    "chat.jade.rip" = proxy "eldo:3001";
    "llama.jade.rip" = proxy "airbook:6969";
    "n8n.jade.rip" = proxy "eldo:5678";
    "litellm.jade.rip" = proxy "eldo:4000";
    "ge.jade.rip" = proxy "eldo:30420";
    "7out.jade.rip" = proxy "eldo:30711";

    "chores.jade.rip" = private "eldo:3030";
    "grafana.jade.rip" = private "eldo:3000";
    "atlas.jade.rip" = privateExcept {
      to = "eldo:3040";
      method = "POST";
      paths = atlasWorkerPaths;
    };

    "nix.jade.rip" = ''
      redir https://github.com/fisherrjd/nix permanent
    '';
    "resume.jade.rip" = ''
      redir https://github.com/fisherrjd/resume/blob/main/resume.pdf permanent
    '';
    # Static docs, served straight from the store. No reverse_proxy and no service to
    # keep alive: deploying a docs change is just a rebuild of this host.
    "wisp.jade.rip" = ''
      root * ${pkgs.wisp-docs}
      file_server
    '';
  };

  # ---- auth ----------------------------------------------------------------

  transformUser = roles: email: ''
    transform user {
      match realm google
      match email ${email}
      action add role ${roles}
    }
  '';
  userTransforms = lib.concatStringsSep "\n" (
    map (transformUser "authp/admin friends") admins
    ++ map (transformUser "friends") friends
  );
in
{
  services.caddy = {
    enable = true;
    package = pkgs.jacobi.zaddy;
    environmentFile = config.age.secrets.caddy.path;
    globalConfig = ''
      order authenticate before respond
      order authorize before basic_auth

      security {
        oauth identity provider google {
          realm google
          driver google
          client_id {env.GOOGLE_CLIENT_ID}.apps.googleusercontent.com
          client_secret {env.GOOGLE_CLIENT_SECRET}
          scopes openid email profile
        }

        authentication portal auth_portal {
          crypto default token lifetime 3600
          crypto key sign-verify {env.JWT_SHARED_KEY}
          enable identity provider google
          cookie domain jade.rip
          trust login redirect uri domain suffix jade.rip path prefix /

          transform user {
            match realm google
            action add role authp/user
          }

          ${userTransforms}
        }

        authorization policy friends_only {
          set auth url https://auth.jade.rip/oauth2/google
          crypto key verify {env.JWT_SHARED_KEY}
          allow roles friends
          validate bearer header
          inject headers with claims
        }
      }
    '';
    virtualHosts = lib.mapAttrs (_: extraConfig: { inherit extraConfig; }) sites;
  };
}
