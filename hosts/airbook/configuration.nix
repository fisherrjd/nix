{ config, flake, machine-name, pkgs, ... }:
let
  # inherit (lib.attrsets) mapAttrs' nameValuePair;

  hostname = "airbook";
  common = import ../common.nix { inherit config flake machine-name pkgs username; };
  configPath = "/Users/jade/cfg/hosts/${hostname}/configuration.nix";
  username = "jade";

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
      bartowski = name: "/opt/box/models/bartowski/${name}";
      unsloth = name: "/opt/box/models/unsloth/${name}";
    in
    {
      openssh.enable = true;
      llama-server.servers = {
        Unsloth_Qwen3-4B-Q8_0 = {
          enable = true;
          port = 8012;
          model = unsloth "Qwen3-4B-Q8_0.gguf";
          ngl = 99;
        };
      };
      # llama-server.servers = {
      #   Bartowski_Qwen3-4B-Q8_0 = {
      #     enable = true;
      #     port = 8012;
      #     model = bartowski "Qwen_Qwen3-4B-Q8_0.gguf";
      #     ngl = 99;
      #   };
      # };
    };


  launchd.user.agents.testAgent = { };
}
