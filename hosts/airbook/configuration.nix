{ lib, config, flake, machine-name, pkgs, ... }:
let
  # inherit (lib.attrsets) mapAttrs' nameValuePair;
  inherit (lib) mkDefault;
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
  system.primaryUser = mkDefault username;

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
      # llama-server.servers = {
      #   Qwen3-4B-UD-Q6_K_XL = {
      #     enable = true;
      #     package = pkgs.llama-cpp-latest;
      #     port = 6969;
      #     model = unsloth "Qwen3-4B-UD-Q6_K_XL.gguf";
      #     ngl = 99;
      #     extraFlags = ''--ctx-size 32768 --seed 420 --prio 2 --temp 0.6 --min-p 0.0 --top-k 20 --top-p 0.95'';
      #   };
      # };
      # llama-server.servers = {
      #   Bartowski_Qwen3-4B-Q8_0 = {
      #     enable = true;
      #     port = 8012;
      #     model = bartowski "Qwen_Qwen3-4B-Q8_0.gguf";
      #     ngl = 99;
      #   };
      # };

    };
  # launchd.user.agents.caffeinate = {
  #   serviceConfig = {
  #     Label = "jade.caffeinate";
  #     ProgramArguments = [ "/usr/bin/caffeinate" "-dims" ];
  #     RunAtLoad = true;
  #     KeepAlive = true; # Keeps caffeinate running even if it exits
  #   };
  # };
}
