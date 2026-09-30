# modules/buzz-selfhost.nix
#
# Self-hosted Buzz community (github.com/block/buzz) as launchd user agents:
# Postgres, Redis, versitygw (S3 for media) and buzz-relay, all bound to 127.0.0.1 and all state
# under one dataDir. Ports are offset from the repo's `just dev` stack
# (3000/5432/6379/9000) so both can run at once.
#
# Secrets (relay signing key, service passwords) are generated on first start
# into dataDir/secrets.env, never the nix store. Back that file up: losing the
# relay key changes the relay's identity.
#
# Join from every client (desktop, phone, agents) with exactly `publicUrl`.
# The relay maps one host to its community, so every client must use the same
# spelling. For a loopback-only relay that must be 127.0.0.1, not localhost:
# the desktop app folds loopback spellings to 127.0.0.1 in the URL it hands
# managed agents (buzz-core normalize_relay_url), so `localhost` 404s agents.
#
# tailscaleServe publishes the relay to the tailnet only (not Funnel) with a
# real TLS cert; the relay itself stays bound to 127.0.0.1. `tailscale serve`
# forwards the original Host header, which is what the relay resolves.
{ config, lib, pkgs, ... }:
let
  cfg = config.services.buzz-selfhost;
  dir = cfg.dataDir;
  logDir = "${dir}/logs";
  secrets = "${dir}/secrets.env";

  # Idempotent and race-safe: all four agents start at login and call this.
  # The first `ln` wins; losers discard their candidate and use the winner's.
  ensureSecrets = pkgs.writeShellScript "buzz-selfhost-secrets" ''
    set -eu
    umask 077
    mkdir -p ${lib.escapeShellArg dir} ${lib.escapeShellArg logDir}
    if [ ! -e ${lib.escapeShellArg secrets} ]; then
      tmp=$(mktemp ${lib.escapeShellArg dir}/.secrets.XXXXXX)
      rand() { ${pkgs.openssl}/bin/openssl rand -hex "$1"; }
      {
        echo "BUZZ_RELAY_PRIVATE_KEY=$(rand 32)"
        echo "PG_PASSWORD=$(rand 24)"
        echo "REDIS_PASSWORD=$(rand 24)"
        echo "S3_SECRET=$(rand 24)"
      } > "$tmp"
      ln "$tmp" ${lib.escapeShellArg secrets} 2>/dev/null || true
      rm -f "$tmp"
    fi
    set -a
    . ${lib.escapeShellArg secrets}
    set +a
  '';

  mkAgent = name: script: {
    path = [ pkgs.coreutils ];
    inherit script;
    serviceConfig = {
      Label = "jade.buzz-selfhost.${name}";
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 10;
      StandardOutPath = "${logDir}/${name}.log";
      StandardErrorPath = "${logDir}/${name}.log";
    };
  };

  pg = cfg.postgresPackage;
  pgData = "${dir}/postgres";
in
{
  options.services.buzz-selfhost = {
    enable = lib.mkEnableOption "self-hosted Buzz relay and its backing services";
    package = lib.mkOption { type = lib.types.package; default = pkgs.buzz-relay; };
    postgresPackage = lib.mkOption { type = lib.types.package; default = pkgs.postgresql_17; };
    dataDir = lib.mkOption { type = lib.types.str; };
    relayPort = lib.mkOption { type = lib.types.port; default = 3030; };
    publicUrl = lib.mkOption {
      type = lib.types.str;
      default = "ws://127.0.0.1:${toString cfg.relayPort}";
      description = "The one URL every client uses; its host is the community's host.";
    };
    tailscaleServe = lib.mkEnableOption "publishing the relay on the tailnet via `tailscale serve` on :443";
    tailscaleBin = lib.mkOption { type = lib.types.str; default = "/usr/local/bin/tailscale"; };
    postgresPort = lib.mkOption { type = lib.types.port; default = 5442; };
    redisPort = lib.mkOption { type = lib.types.port; default = 6389; };
    s3Port = lib.mkOption { type = lib.types.port; default = 9010; };
    # The relay always binds these on 0.0.0.0; offset them to avoid clashes.
    healthPort = lib.mkOption { type = lib.types.port; default = 8090; };
    metricsPort = lib.mkOption { type = lib.types.port; default = 9112; };
  };

  config = lib.mkIf cfg.enable {
    launchd.user.agents = {
      # Oneshot; serve config persists in tailscaled, re-applying is idempotent.
      # Retries until it succeeds, since tailscaled may not be up yet at login.
      buzz-tailscale-serve = lib.mkIf cfg.tailscaleServe {
        script = "exec ${cfg.tailscaleBin} serve --bg --https=443 http://127.0.0.1:${toString cfg.relayPort}";
        serviceConfig = {
          Label = "jade.buzz-selfhost.tailscale-serve";
          RunAtLoad = true;
          KeepAlive = { SuccessfulExit = false; };
          ThrottleInterval = 30;
          StandardOutPath = "${logDir}/tailscale-serve.log";
          StandardErrorPath = "${logDir}/tailscale-serve.log";
        };
      };

      buzz-postgres = mkAgent "postgres" ''
        . ${ensureSecrets}
        if [ ! -e ${lib.escapeShellArg pgData}/PG_VERSION ]; then
          pwfile=$(mktemp)
          printf '%s' "$PG_PASSWORD" > "$pwfile"
          ${pg}/bin/initdb -D ${lib.escapeShellArg pgData} -U buzz \
            --auth=scram-sha-256 --pwfile="$pwfile" --encoding=UTF8
          rm -f "$pwfile"
        fi
        exec ${pg}/bin/postgres -D ${lib.escapeShellArg pgData} \
          -c listen_addresses=127.0.0.1 -c port=${toString cfg.postgresPort} \
          -c unix_socket_directories=
      '';

      buzz-redis = mkAgent "redis" ''
        . ${ensureSecrets}
        mkdir -p ${lib.escapeShellArg dir}/redis
        cd ${lib.escapeShellArg dir}/redis
        # Password via stdin config so it stays out of `ps`.
        printf 'requirepass %s\n' "$REDIS_PASSWORD" | exec ${pkgs.redis}/bin/redis-server - \
          --bind 127.0.0.1 --port ${toString cfg.redisPort} --dir ${lib.escapeShellArg dir}/redis \
          --appendonly yes
      '';

      # versitygw, not MinIO: nixpkgs marks MinIO insecure (abandoned upstream).
      # Each top-level folder is a bucket, so the relay's bucket is a mkdir.
      buzz-s3 = mkAgent "s3" ''
        . ${ensureSecrets}
        mkdir -p ${lib.escapeShellArg dir}/s3/buzz-media
        export ROOT_ACCESS_KEY=buzz ROOT_SECRET_KEY="$S3_SECRET"
        exec ${pkgs.versitygw}/bin/versitygw --port 127.0.0.1:${toString cfg.s3Port} \
          posix ${lib.escapeShellArg dir}/s3
      '';

      buzz-relay = lib.recursiveUpdate (mkAgent "relay" ''
        . ${ensureSecrets}
        export PGPASSWORD="$PG_PASSWORD"
        pgargs="-h 127.0.0.1 -p ${toString cfg.postgresPort} -U buzz"
        until ${pg}/bin/pg_isready $pgargs -d postgres -q; do sleep 1; done
        ${pg}/bin/psql $pgargs -d postgres -tAc "select 1 from pg_database where datname='buzz'" | grep -q 1 \
          || ${pg}/bin/createdb $pgargs buzz
        until REDISCLI_AUTH="$REDIS_PASSWORD" ${pkgs.redis}/bin/redis-cli -p ${toString cfg.redisPort} ping >/dev/null 2>&1; do sleep 1; done
        until ${pkgs.curl}/bin/curl -s -o /dev/null http://127.0.0.1:${toString cfg.s3Port}/; do sleep 1; done

        export DATABASE_URL="postgres://buzz:$PG_PASSWORD@127.0.0.1:${toString cfg.postgresPort}/buzz"
        export REDIS_URL="redis://:$REDIS_PASSWORD@127.0.0.1:${toString cfg.redisPort}"
        export BUZZ_S3_SECRET_KEY="$S3_SECRET"
        unset PG_PASSWORD PGPASSWORD REDIS_PASSWORD S3_SECRET
        exec ${lib.getExe cfg.package}
      '') {
        path = [ pkgs.coreutils pkgs.gnugrep pkgs.git ];
        environment = {
          RELAY_URL = cfg.publicUrl;
          BUZZ_BIND_ADDR = "127.0.0.1:${toString cfg.relayPort}";
          BUZZ_HEALTH_PORT = toString cfg.healthPort;
          BUZZ_METRICS_PORT = toString cfg.metricsPort;
          BUZZ_AUTO_MIGRATE = "true";
          BUZZ_MEDIA_BASE_URL = "${builtins.replaceStrings [ "wss://" "ws://" ] [ "https://" "http://" ] cfg.publicUrl}/media";
          BUZZ_S3_ENDPOINT = "http://127.0.0.1:${toString cfg.s3Port}";
          BUZZ_S3_ACCESS_KEY = "buzz";
          BUZZ_S3_BUCKET = "buzz-media";
          BUZZ_S3_REGION = "us-east-1";
          BUZZ_S3_ADDRESSING_STYLE = "path";
          BUZZ_GIT_REPO_PATH = "${dir}/git";
          RUST_LOG = "buzz_relay=info";
        };
      };
    };
  };
}
