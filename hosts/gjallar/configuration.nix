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
