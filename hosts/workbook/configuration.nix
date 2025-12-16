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
    JAVA_11 = "/Users/P3175941/Library/Java/JavaVirtualMachines/azul-11.0.25/Contents/Home";
    JAVA_21 = "/Users/P3175941/Library/Java/JavaVirtualMachines/azul-21.0.5/Contents/Home";
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

  homebrew = {
    enable = true;
    taps = [
      "microcks/tap"
    ];
    brews = [
      "cassandra"
      "awscli"
      "microcks-cli"
    ];
    casks = [
      "bruno"
      "notion"
      "amazon-q"
    ];
  };

}
