{ lib, flake, machine-name, pkgs, ... }:
let
  inherit (lib) mkDefault;
  hostname = "airbook";
  username = "jade";
  common = import ../common.nix { inherit flake machine-name pkgs username; };
  configPath = "/Users/${username}/cfg/hosts/${hostname}/configuration.nix";
in
{
  imports = [
    "${common.home-manager}/nix-darwin"
  ];

  home-manager.users.jade = common.jade;

  documentation.enable = false;

  time.timeZone = common.timeZone;
  environment.variables = {
    NIX_HOST = hostname;
    NIXDARWIN_CONFIG = configPath;
  };
  environment.darwinConfig = configPath;

  users.users.jade = {
    name = username;
    home = "/Users/${username}";
    shell = pkgs.bashInteractive;
    openssh.authorizedKeys.keys = common.pubkeys.all;
  };
  system.primaryUser = mkDefault username;

  system.stateVersion = 4;
  ids.gids.nixbld = 350;
  nix = common.nix // {
    nixPath = [
      "darwin=${common.nix-darwin}"
      "darwin-config=${configPath}"
    ];
  };
  services.openssh.enable = true;
  launchd.user.agents.caffeinate = {
    serviceConfig = {
      Label = "jade.caffeinate";
      ProgramArguments = [ "/usr/bin/caffeinate" "-dims" ];
      RunAtLoad = true;
      KeepAlive = true; # Keeps caffeinate running even if it exits
    };
  };

  # 1. Enable the Homebrew module
  homebrew = {
    enable = true; # turn the module on

    # 2. Where the Homebrew installation lives (only needed if it’s not in /opt/homebrew or /usr/local)
    # homebrewDirectory = "/opt/homebrew";

    # 3. Taps you need
    taps = [ ];

    # 4. Formulae (CLI tools)
    brews = [ ];

    # 5. Casks (GUI apps)
    casks = [
      "blackhole-2ch"
      "visual-studio-code"
      "firefox"
      "discord"
      "webex"
    ];

  };
}
