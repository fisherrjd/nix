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
          {
            name = "Loki";
            type = "loki";
            url = "http://127.0.0.1:3100";
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

      # Loki: log storage (single binary, filesystem, tsdb v13). Config is
      # validated at build time, so mistakes fail `nix build`, not the switch.
      loki = {
        enable = true;
        configuration = {
          auth_enabled = false;
          server = {
            http_listen_address = "127.0.0.1";
            http_listen_port = 3100;
            grpc_listen_address = "127.0.0.1";
            grpc_listen_port = 9095;
          };
          common = {
            path_prefix = "/var/lib/loki";
            replication_factor = 1;
            # advertise loopback — gRPC only listens there; the default would
            # advertise the LAN IP and every internal query would hang
            instance_addr = "127.0.0.1";
            ring.kvstore.store = "inmemory";
            storage.filesystem = {
              chunks_directory = "/var/lib/loki/chunks";
              rules_directory = "/var/lib/loki/rules";
            };
          };
          schema_config.configs = [
            {
              from = "2026-01-01";
              store = "tsdb";
              object_store = "filesystem";
              schema = "v13";
              index = { prefix = "index_"; period = "24h"; };
            }
          ];
          storage_config.tsdb_shipper = {
            active_index_directory = "/var/lib/loki/tsdb-index";
            cache_location = "/var/lib/loki/tsdb-cache";
          };
          compactor = {
            working_directory = "/var/lib/loki/compactor";
            retention_enabled = true;
            delete_request_store = "filesystem"; # mandatory in Loki 3.x with retention on
          };
          # same loopback rule for the query-frontend the queriers dial back to
          frontend.address = "127.0.0.1";
          limits_config.retention_period = "30d";
          analytics.reporting_enabled = false;
        };
      };

      # Alloy ships journald + k3s pod logs to Loki (promtail is EOL and gone
      # from nixpkgs); its config lives in environment.etc below
      alloy = {
        enable = true;
        extraFlags = [ "--disable-reporting" ];
      };
    };

    # Alloy runs as DynamicUser with the systemd-journal group (journal is
    # covered), but /var/log/pods is root-only — read-only bypass:
    systemd.services.alloy.serviceConfig.AmbientCapabilities = [ "CAP_DAC_READ_SEARCH" ];

    environment.etc."alloy/config.alloy".text = ''
      loki.write "local" {
        endpoint {
          url = "http://127.0.0.1:3100/loki/api/v1/push"
        }
      }

      // ---- systemd journal ----
      loki.relabel "journal" {
        forward_to = []
        rule {
          source_labels = ["__journal__systemd_unit"]
          target_label  = "unit"
        }
      }

      loki.source.journal "journal" {
        max_age       = "12h"
        relabel_rules = loki.relabel.journal.rules
        labels        = {job = "systemd-journal", host = "eldo"}
        forward_to    = [loki.write.local.receiver]
      }

      // ---- k3s pod logs: /var/log/pods/<ns>_<pod>_<uid>/<container>/N.log (CRI format) ----
      local.file_match "pod_logs" {
        path_targets = [{"__path__" = "/var/log/pods/*/*/*.log"}]
      }

      discovery.relabel "pod_logs" {
        targets = local.file_match.pod_logs.targets
        rule {
          source_labels = ["__path__"]
          regex         = "/var/log/pods/([^_]+)_([^_]+)_[^/]+/([^/]+)/.*"
          target_label  = "namespace"
          replacement   = "$1"
        }
        rule {
          source_labels = ["__path__"]
          regex         = "/var/log/pods/([^_]+)_([^_]+)_[^/]+/([^/]+)/.*"
          target_label  = "pod"
          replacement   = "$2"
        }
        rule {
          source_labels = ["__path__"]
          regex         = "/var/log/pods/([^_]+)_([^_]+)_[^/]+/([^/]+)/.*"
          target_label  = "container"
          replacement   = "$3"
        }
        rule {
          target_label = "job"
          replacement  = "k8s-pods"
        }
      }

      loki.source.file "pod_logs" {
        targets    = discovery.relabel.pod_logs.output
        forward_to = [loki.process.pod_logs.receiver]
      }

      loki.process "pod_logs" {
        stage.cri {}
        forward_to = [loki.write.local.receiver]
      }
    '';
  };

}
