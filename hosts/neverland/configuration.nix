{ lib, flake, pkgs, config, machine-name, modulesPath, ... }:
with lib;
let
  hostname = "neverland";
  username = "jade";
  common = import ../common.nix { inherit config flake machine-name pkgs username; };
in
{
  imports = [
    "${common.home-manager}/nixos"
    # "${modulesPath}/profiles/minimal.nix"
    flake.inputs.nixos-wsl.nixosModules.wsl
  ];

  boot.tmp.useTmpfs = true;

  environment.variables = {
    NIX_HOST = hostname;
  };
  wsl = {
    enable = true;
    defaultUser = "jade";
    startMenuLaunchers = true;
    wslConf.automount.root = "/mnt";
    nativeSystemd = true;
    # Enable native Docker support
    # docker-native.enable = true;
    # Enable integration with Docker Desktop (needs to be installed)
    # docker-desktop.enable = true;
  };

  users.users.jade = {
    isNormalUser = true;
    description = "jade";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    # KeyList for access this is stored in /hosts/common.nix under pubkeys
    openssh.authorizedKeys.keys = with common.pubkeys; [
      atlantis
    ];
  };

  services = {
    xserver.videoDrivers = [ "nvidia" ];
  } // common.services;

  virtualisation.docker = {
    enable = true;
  };

  hardware = {
    opengl = {
      enable = true;
      driSupport32Bit = true;
    };
    nvidia = {
      open = false;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };

  home-manager.users.jade = common.jade;
  networking.hostName = hostname;
  nix = common.nix // {
    nixPath = [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
      "nixos-config=/home/jade/cfg/hosts/${hostname}/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  programs.command-not-found.enable = false;

  system.stateVersion = "22.05";
}