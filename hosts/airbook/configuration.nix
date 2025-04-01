{ config, flake, machine-name, pkgs, ... }:
let
  # inherit (lib.attrsets) mapAttrs' nameValuePair;

  hostname = "airbook";
  common = import ../common.nix { inherit config flake machine-name pkgs username; };
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
      workbook
    ];
  };

  system.stateVersion = 4;
  ids.gids.nixbld = 350;
  nix = common.nix // {
    nixPath = [
      "darwin=${common.nix-darwin}"
      "darwin-config=${configPath}"
    ];
  };
  services =
    let
      modelPath = name: "/opt/box/models/bartowski/agentica-org_DeepScaleR-1.5B-Preview-GGUF/${name}";
    in
    {
      openssh.enable = true;
      llama-server.servers = {
        r1-7b = {
          enable = true;
          port = 8012;
          model = modelPath "agentica-org_DeepScaleR-1.5B-Preview-Q4_0.gguf";
          ngl = 99;
        };
      };
    };

}
