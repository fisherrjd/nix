# modules/monitoring.nix
{ config, lib, ... }:
let
  cfg = config.services.monitoring;

in
{
  options.services.monitoring = {
    enable = lib.mkOption { type = lib.types.bool; default = false; };
    port = lib.mkOption { type = lib.types.port; default = 3000; };
  };

  config = lib.mkIf cfg.enable {
    services.grafana = {
      enable = true;
      settings = {
        server = {
          http_addr = "0.0.0.0"; # reachable over tailnet at http://eldo:<port>
          http_port = cfg.port;
        };
        # required since NixOS 26.05 (no built-in default anymore). This is the
        # old upstream default — fine while nothing sensitive lives in
        # grafana's DB; swap for an agenix secret if that changes.
        security.secret_key = "SW2YcwTIb9zpOOhoPsMm";
      };
    };
  };

}
