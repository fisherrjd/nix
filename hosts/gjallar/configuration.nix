{ lib, config, flake, machine-name, pkgs, ... }:
let
  # inherit (lib.attrsets) mapAttrs' nameValuePair;
  inherit (lib) mkDefault;
  hostname = "gjallar";
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
  environment.systemPath = [ "/opt/homebrew/bin" "/opt/homebrew/sbin" ];

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
      airbook
      eldo
    ];
  };
  system.primaryUser = mkDefault username;
  system.stateVersion = 4;
  ids.gids.nixbld = 350;

  nix = common.nix // {
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

  services.sinch-meetings = {
    enable = true;
    user   = username;
  };

  homebrew = {
    enable = true;
    taps = [
    ];
    brews = [
    ];
    casks = [
      "font-caskaydia-cove-nerd-font"
    ];
  };
}
