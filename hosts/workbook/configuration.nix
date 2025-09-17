{ lib, config, flake, machine-name, pkgs, ... }:
let
  # inherit (lib.attrsets) mapAttrs' nameValuePair;
  inherit (lib) mkDefault;
  hostname = "workbook";
  common = import ../common.nix { inherit config flake machine-name pkgs username; };
  username = "P3175941";
  configPath = "/Users/${username}/cfg/hosts/${hostname}/configuration.nix";
in
{
  imports = [
    "${common.home-manager}/nix-darwin"
  ];

  home-manager.users.P3175941 = common.jade;

  documentation.enable = false;
  time.timeZone = common.timeZone;
  environment.variables = {
    NIX_HOST = hostname;
    NIXDARWIN_CONFIG = configPath;
  };
  environment.darwinConfig = configPath;
  users.users.P3175941 = {
    name = username;
    home = "/Users/${username}";
    openssh.authorizedKeys.keys = with common.pubkeys; [
      atlantis
      neverland
      eldo
    ];
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

  homebrew.enable = true;

}
