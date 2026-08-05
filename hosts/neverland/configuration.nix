{ lib, flake, pkgs, config, machine-name, modulesPath, ... }:
with lib;
let
  hostname = "neverland";
  username = "jade";
  common = import ../common.nix { inherit config flake machine-name pkgs username; };
  # .wsl wrapper points LD_LIBRARY_PATH/TRITON_LIBCUDA_PATH at /usr/lib/wsl/lib,
  # where the Windows host exposes libcuda.
  sglang = pkgs.jacobi.sglang-omni.wsl;
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
      eldo
      airbook
    ];
  };

  services = {
    xserver.videoDrivers = [ "nvidia" ];
  } // common.services;

  virtualisation.docker = {
    enable = true;
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/sglang-omni 0755 jade users -"
  ];

  systemd.services.sglang-omni = {
    description = "sglang-omni TTS server (voice cloning)";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    environment = {
      HF_HOME = "/var/lib/sglang-omni";
    };
    serviceConfig = {
      ExecStart = "${sglang}/bin/sgl-omni serve --model-path Qwen/Qwen3-TTS-12Hz-1.7B-Base --port 8000";
      Restart = "on-failure";
      User = "jade";
      WorkingDirectory = "/var/lib/sglang-omni";
    };
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
