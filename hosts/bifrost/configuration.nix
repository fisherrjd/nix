{ config, flake, pkgs, machine-name, lib, modulesPath, ... }:
let
  hostname = "bifrost";
  username = "jade";
  common = import ../common.nix { inherit config flake machine-name pkgs username; };
  modulesDir = ../../modules/home_configurations;

in
{
  imports =
    lib.optional (builtins.pathExists ./do-userdata.nix) ./do-userdata.nix
    ++ [
      (modulesPath + "/virtualisation/digital-ocean-config.nix")
      (modulesDir + "/starship.nix")
      # (modulesDir + "/git.nix")

    ];

  #defining nix tings
  inherit (common) nix;

  age = {
    identityPaths = [ "/home/jade/.ssh/id_ed25519" ];
    secrets = {
      caddy = {
        file = ../../secrets/caddy.age;
        owner = "root";
        group = "root";
        mode = "600";
      };
    };
  };

  #define hostname env variable
  environment.variables = {
    NIX_HOST = hostname;
  };
  networking = {
    hostName = hostname;
    firewall.enable = true;
    firewall.allowedTCPPorts = [ 80 443 ];
  };

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  users.users.jade = {
    isNormalUser = true;
    description = "Jade Fisher";
    extraGroups = [ "networkmanager" "wheel" ];
    openssh.authorizedKeys.keys = with common.pubkeys; [
      atlantis
      neverland
      airbook
      eldo
    ];
    packages = with pkgs; [ ];
  };

  security.sudo.wheelNeedsPassword = false;
  environment.systemPackages = with pkgs; [
    git
    vim
  ];
  services = {
    tailscale.enable = true;
    caddy =
      let
        # Google accounts allowed past `authorize with friends_only` pages.
        # Adding a friend = one line here (their Google login email).
        admins = [
          "fisherrjd@gmail.com"
          "hannahlwolfinbarger@gmail.com"
        ];
        friends = [
          # "friend@gmail.com"
        ];
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
        virtualHosts = {
          # Google-auth login portal (caddy-security)
          "auth.jade.rip".extraConfig = ''
            authenticate with auth_portal
          '';
        # Push Notifications
        "ntfy.jade.rip".extraConfig = ''
          reverse_proxy * {
            to eldo:8081
          }
        '';
        "chat.jade.rip".extraConfig = ''
          reverse_proxy * {
            to eldo:3001
          }
        '';
        "llama.jade.rip".extraConfig = ''
          reverse_proxy * {
            to airbook:6969
          }
        '';
        "n8n.jade.rip".extraConfig = ''
          reverse_proxy * {
            to eldo:5678
          }
        '';
        "litellm.jade.rip".extraConfig = ''
          reverse_proxy * {
            to eldo:4000
          }
        '';
        "nix.jade.rip".extraConfig = ''
          redir https://github.com/fisherrjd/nix permanent
        '';
        "resume.jade.rip".extraConfig = ''
          redir https://github.com/fisherrjd/resume/blob/main/resume.pdf permanent
        '';
        "chores.jade.rip".extraConfig = ''
          authorize with friends_only
          reverse_proxy * {
            to eldo:3030
          }
        '';
        "atlas.jade.rip".extraConfig = ''
          authorize with friends_only
          reverse_proxy * {
            to eldo:3040
          }
        '';
        "ge.jade.rip".extraConfig = ''
          reverse_proxy * {
            to eldo:30420
          }
        '';
      };
    };
  };

  system.stateVersion = "24.05";
  programs.command-not-found.enable = false;


}
