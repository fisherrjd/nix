{ config, flake, machine-name, pkgs, ... }:
let
  # inherit (lib.attrsets) mapAttrs' nameValuePair;

  hostname = "airbook";
  common = import ../common.nix { inherit config flake machine-name pkgs; };
  configPath = "/Users/jade/cfg/hosts/${hostname}/configuration.nix";
  username = "jade";


  # runner-defaults = {
  #   enable = true;
  #   replace = true;
  #   url = "https://github.com/fisherrjd/nix";
  #   extraLabels = [ "nix" "m1" ];
  # };
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
  ### can't get this working?
  # services.github-runners = mapAttrs' nameValuePair {
  #   jpetrucciani-nix = runner-defaults // {
  #     extraPackages = with pkgs; [ gh cachix ];
  #     tokenFile = "/etc/default/gh.token";
  #   };
  # };
}
