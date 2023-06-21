{ lib, flake, pkgs, config, machine-name, modulesPath, ... }:
with lib;
let
  hostname = "neverland";
  common = import ../common.nix { inherit config flake machine-name pkgs; };
in
{
  imports = [
    "${common.home-manager}/nixos"
    "${modulesPath}/profiles/minimal.nix"
    flake.inputs.nixos-wsl.nixosModules.wsl
  ];

  environment.variables = {
    NIX_HOST = hostname;
  };
  wsl = {
    enable = true;
    defaultUser = "nixos";
    startMenuLaunchers = true;
    wslConf.automount.root = "/mnt";
    # Enable native Docker support
    # docker-native.enable = true;
    # Enable integration with Docker Desktop (needs to be installed)
    # docker-desktop.enable = true;
  };

  users.users.jade = {
    isNormalUser = true;
    description = "jade";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    openssh.authorizedKeys.keys = with common.pubkeys; [
      atlantis
    ];
  };

  home-manager.users.jade = common.jade;
  networking.hostName = hostname;
  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  programs.command-not-found.enable = false;

  system.stateVersion = "22.05";
}
