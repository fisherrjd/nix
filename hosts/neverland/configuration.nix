{ lib, flake, pkgs, config, machine-name, ... }:
let
  hostname = "neverland";
  username = "jade";
  common = import ../common.nix { inherit flake machine-name pkgs username; };
in
{
  imports = [
    "${common.home-manager}/nixos"
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
    useWindowsDriver = true;
    wslConf.automount.root = "/mnt";
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

<<<<<<< HEAD
=======
  systemd.tmpfiles.rules = [
    "d /var/lib/sglang-omni 0755 jade users -"
  ];

  # systemd.services.sglang-omni = {
  #   description = "sglang-omni TTS server (voice cloning)";
  #   after = [ "network.target" ];
  #   wantedBy = [ "multi-user.target" ];
  #   environment = {
  #     HF_HOME = "/var/lib/sglang-omni";
  #     LD_LIBRARY_PATH = "/usr/lib/wsl/lib:/run/opengl-driver/lib";
  #   };
  #   serviceConfig = {
  #     ExecStart = "${sglang}/bin/sgl-omni serve --model-path Qwen/Qwen3-TTS-12Hz-1.7B-Base --port 8000 --mem-fraction-static 0.7 --config /var/lib/sglang-omni/configs/qwen3_tts_1_7b.yaml --isolate-stage vocoder";
  #     Restart = "on-failure";
  #     User = "jade";
  #     WorkingDirectory = "/var/lib/sglang-omni";
  #   };
  # };

>>>>>>> e2e9f6c (cleanup)
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
  programs.nix-ld.enable = true;

  system.stateVersion = "22.05";
}
