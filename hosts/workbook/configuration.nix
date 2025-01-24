{ config, flake, machine-name, pkgs, ... }:
let
  # inherit (lib.attrsets) mapAttrs' nameValuePair;

  hostname = "workbook";
  common = import ../common.nix { inherit config flake machine-name pkgs username; };
  username = "P3175941";
  configPath = "/Users/${username}/cfg/hosts/${hostname}/configuration.nix";

in
{
  imports = [
    "${common.home-manager}/nix-darwin"

  ];

  home-manager.users.${username} = common.jade;

  documentation.enable = false;

  time.timeZone = common.timeZone;
  environment.variables = {
    NIX_HOST = hostname;
    NIXDARWIN_CONFIG = configPath;
  };
  environment.darwinConfig = configPath;

  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
    openssh.authorizedKeys.keys = with common.pubkeys; [
      atlantis
      neverland
      eldo
    ];
  };

  system.stateVersion = 4;
  nix = common.nix // {
    useDaemon = true;
    nixPath = [
      "darwin=${common.nix-darwin}"
      "darwin-config=${configPath}"
    ];
  };

  services.openssh.enable = true;
}
