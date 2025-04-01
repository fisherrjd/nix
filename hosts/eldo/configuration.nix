# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, flake, pkgs, machine-name, ... }:

let
  hostname = "eldo";
  username = "jade";
  common = import ../common.nix { inherit config flake machine-name pkgs username; };
in
{
  imports =
    [
      # Include the results of the hardware scan.
      "${common.home-manager}/nixos"
      ./hardware-configuration.nix
      { services = common.services; }
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # age = {
  #   identityPaths = [ "/home/jade/.ssh/id_ed25519" ];
  #   secrets = {
  #     litellm = {
  #       file = ../../secrets/litellm.age;
  #       mode = "644";
  #     };
  #   };
  # };
  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Denver";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.jade = {
    isNormalUser = true;
    description = "Jade Fisher";
    extraGroups = [ "networkmanager" "wheel" ];
    openssh.authorizedKeys.keys = with common.pubkeys; [
      atlantis
      neverland
      airbook
      workbook
    ];
    packages = with pkgs; [ ];
  };

  programs.nix-ld.enable = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim
    vscode
  ];


  system.stateVersion = "24.05"; # Did you read the comment?

  # begin jade fuckin around
  security.sudo = common.security.sudo;

  #define hostname env variable
  environment.variables = {
    NIX_HOST = hostname;
  };
  networking.hostName = "eldo"; # Define your hostname.

  #TODO: Learn what this is doing??? 
  #TODO: I think its enabling home manager stuff from jade user in common 
  home-manager.users.jade = common.jade;

  #defining nix tings
  nix = common.nix // {
    nixPath = [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
      "nixos-config=/home/fisherrjd/cfg/hosts/${hostname}/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };

  virtualisation.docker.enable = true;

  # system sleep settings
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  services =
    {
      openssh.enable = true;
      postgresql = {
        enable = true;
        ensureDatabases = [ "litellm" ];
        authentication = pkgs.lib.mkOverride 10 ''
          #type database  DBuser  auth-method
          local all       all     trust
          host all all 127.0.0.1/32 trust
          host all all 0.0.0.0/0 trust
          host    all            postgres         127.0.0.1/32           md5
          host    all            postgres         ::1/128                md5
          host    litellm        postgres         0.0.0.0/0              md5
        '';
      };
    };
  users.extraGroups.docker.members = [ username ];

  virtualisation.oci-containers = {
    backend = "docker";

    containers.litellm = {
      image = "ghcr.io/berriai/litellm:main-v1.63.11-nightly";
      volumes = [ "lite-llm:/app" ]; # Persists container data

      # --- Provide Database Connection URL ---
      environment = {
        DATABASE_URL = "postgresql://postgres@127.0.0.1:5432/litellm";
        LITELLM_MODEL_LIST = ''
          [
            {
              "model_name": "airbook-local",
              "litellm_params": {
                "model": "airbook/depseek",
                "api_base": "http://airbook:8012/v1",
                "api_key": "no_key"
              }
            }
          ]
        '';
      };
      extraOptions = [
        "--network=host" # Connects container directly to host network
      ];

      autoStart = true; # Start container on boot/rebuild
    };
  };
}
