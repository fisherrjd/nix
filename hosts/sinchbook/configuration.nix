{ lib, config, flake, machine-name, pkgs, ... }:
let
  # inherit (lib.attrsets) mapAttrs' nameValuePair;
  inherit (lib) mkDefault;
  hostname = "sinchbook";
  common = import ../common.nix { inherit config flake machine-name pkgs username; };
  username = "jadfis";
  configPath = "/Users/${username}/cfg/hosts/${hostname}/configuration.nix";
in
{
  imports = [
    "${common.home-manager}/nix-darwin"
  ];

  home-manager.users.jadfis = common.jade;

  documentation.enable = false;
  time.timeZone = common.timeZone;
  environment.variables = {
    NIX_HOST = hostname;
    NIXDARWIN_CONFIG = configPath;
  };
  environment.darwinConfig = configPath;
  users.users.jadfis = {
    name = username;
    home = "/Users/${username}";
    openssh.authorizedKeys.keys = with common.pubkeys; [
      atlantis
      eldo
    ];
  };
  system.primaryUser = mkDefault username;
  system.stateVersion = 4;
  ids.gids.nixbld = 350;

  nix = common.nix // {
    enable = false;
    nixPath = [
      "nixpkgs=${flake.inputs.nixpkgs}"
      "darwin=${common.nix-darwin}"
      "darwin-config=${configPath}"
    ];
    extraOptions = ''
      max-jobs = auto
      narinfo-cache-negative-ttl = 10
      extra-experimental-features = nix-command flakes
      extra-substituters = https://fisherrjd.cachix.org
      extra-trusted-public-keys = fisherrjd.cachix.org-1:21bdYeKCoWN19OGUDTGU41o60gnEsLHY5+tIpEq7w+A=
    '';
  };
  services.openssh.enable = true;

  homebrew = {
    enable = true;
    taps = [
    ];
    brews = [
    ];
    casks = [
    ];
  };
}
