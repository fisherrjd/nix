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
    shell = pkgs.bashInteractive;
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
      unsloth = name: "/opt/box/models/unsloth/${name}";
      hunyuan = name: "/opt/box/models/hunyuan/${name}";
      bartowski = name: "/opt/box/models/bartowski/${name}";
    in
    {
      openssh.enable = true;
      llama-server.servers = {
        Qwen2_5-VL-7B-Instruct-Q4_K_M = {
          enable = true;
          package = pkgs.llama-cpp-latest;
          port = 6969;
          model = unsloth "Qwen2.5-VL-7B-Instruct-Q4_K_M.gguf";
          ngl = 99;
          extraFlags = ''
            --ctx-size 8192 
            --seed 420 
            --prio 2 
            --temp 0.6 
            --min-p 0.0 
            --top-k 20 
            --top-p 0.95 
          '';
        };
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
      "visual-studio-code"
      "firefox"
      "discord"
      "webex"
    ];

  };
}
