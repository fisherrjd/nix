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
      modelPath = name: "/opt/box/models/${name}";
    in
    {
      openssh.enable = true;
      llama-server.servers = {
        r1-7b = {
          enable = true;
          port = 8012;
          model = modelPath "Rombos-Coder-V2.5-Qwen-7b-Q5_K_M.gguf";
          ngl = 99;
        };
      };
    };

}
