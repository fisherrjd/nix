# modules/monitoring.nix
{ config, lib, ... }:
let
  cfg = config.services.monitoring;

in
{
  options.services.monitoring = {
    enable = lib.mkOption { type = lib.types.bool; default = false; };
    port = lib.mkOption { type = lib.types.port; default = 3000; };
    domain = lib.mkOption { type = lib.types.str; default = "grafana.jade.rip"; };
    # string, not path — must stay a runtime path (/run/agenix/...), never copied to store
    secretKeyFile = lib.mkOption { type = lib.types.str; };
  };

  config = lib.mkIf cfg.enable {
    services = {
      grafana = {
        enable = true;
        settings = {
          server = {
            http_addr = "0.0.0.0"; # reachable over tailnet at http://eldo:<port>
            http_port = cfg.port;
            # public URL (bifrost Caddy proxies here) — keeps redirects/links correct
            inherit (cfg) domain;
            root_url = "https://${cfg.domain}/";
          };
          # required since NixOS 26.05 (no built-in default anymore); agenix
          # secret so no key material lives in this public repo
          security.secret_key = "$__file{${cfg.secretKeyFile}}";
        };
        provision.datasources.settings.datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            url = "http://127.0.0.1:9090";
            isDefault = true;
          }
        ];
      };
      prometheus = {
        enable = true;
        listenAddress = "127.0.0.1"; # only Grafana on this box needs it
        scrapeConfigs = [
          {
            job_name = "node";
            static_configs = [{ targets = [ "127.0.0.1:9100" ]; }];
          }
          {
            job_name = "postgres";
            static_configs = [{ targets = [ "127.0.0.1:9187" ]; }];
          }
        ];
        exporters = {
          node = {
            enable = true;
            enabledCollectors = [ "systemd" ];
          };
          postgres = {
            enable = true;
            listenAddress = "127.0.0.1"; # scraped by local prometheus only
            # run as the postgres system user so local socket peer-auth works —
            # no exporter password to manage
            runAsLocalSuperUser = true;
          };
        };
      };
    };
  };

}
