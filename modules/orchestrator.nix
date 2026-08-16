# modules/orchestrator.nix
#
# Heimdall: the heartbeat agent-loop orchestrator (github.com/fisherrjd/orchestrator).
# Three oneshot timers run `python -m orc pulse <type>` from the live checkout as
# jade — headless claude bills the subscription via ~/.claude OAuth, so HOME must
# be set explicitly (systemd system services don't derive it from User=).
{ config, lib, pkgs, ... }:
let
  cfg = config.services.orchestrator;
  claude-code = pkgs.callPackage ../packages/claude-code-latest.nix { };
  mkPulse = { pulseType, startAt, timeoutSec }: {
    path = [ pkgs.git pkgs.gh pkgs.curl pkgs.jq pkgs.openssh pkgs.python313 pkgs.nix ];
    environment = {
      HOME = "/home/${cfg.user}";
      ORC_STATE_DIR = cfg.stateDir;
      ORC_ATLAS_URL = cfg.atlasUrl;
      ORC_LOKI_URL = cfg.lokiUrl;
      ORC_NTFY_URL = cfg.ntfyUrl;
      ORC_NTFY_TOPIC = cfg.ntfyTopic;
      ORC_CLAUDE_BIN = cfg.claudeBin;
      ORC_DRY_RUN = if cfg.dryRun then "1" else "0";
      DISABLE_AUTOUPDATER = "1";
    };
    script = ''python -m orc pulse ${pulseType}'';
    serviceConfig = {
      User = cfg.user;
      Type = "oneshot";
      WorkingDirectory = cfg.repoPath;
      TimeoutStartSec = timeoutSec;
    };
    inherit startAt;
  };

in
{
  options.services.orchestrator = {
    enable = lib.mkOption { type = lib.types.bool; default = false; };
    user = lib.mkOption { type = lib.types.str; default = "jade"; };
    repoPath = lib.mkOption { type = lib.types.str; default = "/home/jade/github/projects/orchestrator"; };
    stateDir = lib.mkOption { type = lib.types.str; default = "/var/lib/orchestrator"; };
    # explicit pin: immune to PATH drift between nix-profile and the self-updater
    claudeBin = lib.mkOption { type = lib.types.str; default = "${claude-code}/bin/claude"; };
    atlasUrl = lib.mkOption { type = lib.types.str; default = "http://10.0.0.71:3040"; };
    lokiUrl = lib.mkOption { type = lib.types.str; default = "http://127.0.0.1:3100"; };
    ntfyUrl = lib.mkOption { type = lib.types.str; default = "http://127.0.0.1:8081"; };
    ntfyTopic = lib.mkOption { type = lib.types.str; default = "orchestrator"; };
    # safe-by-default rollout lever: pulses run but file nothing until flipped
    dryRun = lib.mkOption { type = lib.types.bool; default = true; };
    logScanInterval = lib.mkOption { type = lib.types.str; default = "*-*-* *:07:00"; };
    repoHealthInterval = lib.mkOption { type = lib.types.str; default = "*-*-* 03:45:00"; };
    staffedInterval = lib.mkOption { type = lib.types.str; default = "*:00/15"; };
    # read-only display API for the atlas Heimdall tab; pods reach it via the
    # flannel gateway (10.42.0.1), same pattern as postgres
    apiPort = lib.mkOption { type = lib.types.int; default = 3050; };
  };

  config = lib.mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d ${cfg.stateDir} 0750 ${cfg.user} users -"
    ];
    systemd.services = {
      orchestrator-log-scan = mkPulse {
        pulseType = "log-scan";
        startAt = cfg.logScanInterval;
        timeoutSec = 600;
      };
      orchestrator-repo-health = mkPulse {
        pulseType = "repo-health";
        startAt = cfg.repoHealthInterval;
        timeoutSec = 900;
      };
      orchestrator-staffed = mkPulse {
        pulseType = "staffed";
        startAt = cfg.staffedInterval;
        timeoutSec = 3900;
      };
      orchestrator-api = {
        path = [ pkgs.python313 pkgs.git ];
        environment = {
          HOME = "/home/${cfg.user}";
          ORC_STATE_DIR = cfg.stateDir;
          ORC_API_PORT = toString cfg.apiPort;
        };
        script = ''python -m orc serve'';
        serviceConfig = {
          User = cfg.user;
          Restart = "on-failure";
          WorkingDirectory = cfg.repoPath;
        };
        wantedBy = [ "multi-user.target" ];
      };
    };
    # GET-only display data; same unauthenticated-on-tailnet posture as atlas
    networking.firewall.allowedTCPPorts = [ cfg.apiPort ];
  };

}
