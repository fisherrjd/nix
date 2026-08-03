{ lib, config, flake, machine-name, pkgs, ... }:
let
  # inherit (lib.attrsets) mapAttrs' nameValuePair;
  inherit (lib) mkDefault;
  hostname = "gjallar";
  common = import ../common.nix { inherit config flake machine-name pkgs username; };
  username = "jadfis";
  configPath = "/Users/${username}/cfg/hosts/${hostname}/configuration.nix";
in
{
  imports = [
    "${common.home-manager}/nix-darwin"
  ];

  home-manager.users.jadfis = common.jade;

  documentation.enable = false;
  time.timeZone = common.timeZone;

  environment = {
    systemPath = [ "/opt/homebrew/bin" "/opt/homebrew/sbin" ];
    systemPackages = with pkgs; [
      nodejs
      (callPackage ../../packages/sinch-cli.nix { })
    ];
    variables = {
      NIX_HOST = hostname;
      NIXDARWIN_CONFIG = configPath;
    };
    darwinConfig = configPath;
  };

  networking = {
    hostName = hostname;
    localHostName = hostname;
    computerName = hostname;
  };

  users.users.jadfis = {
    name = username;
    home = "/Users/${username}";
    openssh.authorizedKeys.keys = with common.pubkeys; [
      atlantis
      airbook
      eldo
    ];
  };
  system = {
    # nix-darwin's uninstaller evaluates a separate default config with docs
    # enabled. Current nixpkgs/nix-darwin pins disagree on nixos-render-docs
    # flags, so building the uninstaller pulls in a broken darwin manual. We do
    # not use the uninstaller from the system profile on gjallar, so skip it.
    tools.darwin-uninstaller.enable = false;
    primaryUser = mkDefault username;
    stateVersion = 4;
  };
  ids.gids.nixbld = 350;

  nix = common.nix // {
    nixPath = [
      "nixpkgs=${flake.inputs.nixpkgs}"
      "darwin=${common.nix-darwin}"
      "darwin-config=${configPath}"
    ];
  };
  services = {
    openssh.enable = true;

    skribbl = {
      enable = true;
      user = username;
      secretsDir = "/Users/${username}/.config/sinch/meetings";
      vaultPath = "/Users/${username}/vaults/meetings";
      logDir = "/Users/${username}/Library/Logs/sinch-meetings";
    };
  };

  launchd.user.agents.caffeinate = {
    serviceConfig = {
      Label = "jade.caffeinate";
      ProgramArguments = [ "/usr/bin/caffeinate" "-dims" ];
      RunAtLoad = true;
      KeepAlive = true; # Keeps caffeinate running even if it exits
    };
  };

  # Wake the Mac at 9:13 daily (works with the lid closed, on AC power) so the
  # 9:15 gitlab-issue-agent launchd job below actually fires. caffeinate cannot
  # prevent lid-close sleep, and launchd skips a missed StartCalendarInterval if
  # the machine was off. pmset stores one repeating wake event system-wide and
  # re-running the command is idempotent, so an activation script is the
  # declarative-enough home for it (nix-darwin has no native pmset repeat option).
  system.activationScripts.postActivation.text = ''
    echo "setting daily 07:13 wake for gitlab-issue-agent" >&2
    pmset repeat wake MTWRFSU 07:13:00
  '';

  # Daily GitLab status to Slack: `triage functions --slack` runs the full cycle
  # (triage to files -> KB digest folding the verdicts in -> ONE Slack post).
  # LM Studio server is started best-effort first; if it or the model is
  # unavailable, triage records errors and the digest falls back to facts-only,
  # so the post still goes out.
  launchd.user.agents.gitlab-issue-agent = {
    serviceConfig = {
      Label = "com.sinch.gitlab-issue-agent";
      ProgramArguments = [
        "/bin/sh"
        "-c"
        (lib.concatStringsSep "; " [
          "/Users/${username}/.lmstudio/bin/lms server start || true"
          "/Users/${username}/.nix-profile/bin/direnv exec . triage functions --slack"
        ])
      ];
      WorkingDirectory = "/Users/${username}/github/gitlab-issue-agent";
      StartCalendarInterval = [{ Hour = 7; Minute = 15; }];
      RunAtLoad = false; # no catch-up burst after wake
      StandardOutPath = "/Users/${username}/github/gitlab-issue-agent/out/agent.log";
      StandardErrorPath = "/Users/${username}/github/gitlab-issue-agent/out/agent.log";
    };
  };

  homebrew = {
    enable = true;
    taps = [
    ];
    brews = [
    ];
    casks = [
      "font-caskaydia-cove-nerd-font"
    ];
  };
}
