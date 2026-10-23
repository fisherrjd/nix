{ lib, flake, pkgs, config, machine-name, ... }:
let
  hostname = "neverland";
  username = "jade";
  common = import ../common.nix { inherit flake machine-name pkgs username; };
in
{
  imports = [
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
    # Enable native Docker support
    # docker-native.enable = true;
    # Enable integration with Docker Desktop (needs to be installed)
    # docker-desktop.enable = true;
  };

  users.users.jade = {
    isNormalUser = true;
    description = "jade";
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    # who can log in: hosts/constants.nix `logins`
    openssh.authorizedKeys.keys = common.logins.neverland;
  };

  services = {
    xserver.videoDrivers = [ "nvidia" ];
  } // common.services;

  virtualisation.docker = {
    enable = true;
  };

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    nvidia = {
      open = false;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };

  home-manager.users.jade = common.jade;
  networking.hostName = hostname;
  inherit (common) nix;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  programs.command-not-found.enable = false;

  system.stateVersion = "22.05";
}
