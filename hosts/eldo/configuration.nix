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
  age = {
    identityPaths = [ "/home/jade/.ssh/id_ed25519" ];
    secrets = {
      litellm = {
        file = ../../secrets/litellm.age;
        mode = "644";
      };
      openwebui = {
        file = ../../secrets/openwebui.age;
        mode = "644";
      };
      github-runner-token = {
        file = ../../secrets/github-runner-token.age;
        mode = "644";
      };
    };
  };
  networking.networkmanager.enable = true;
  time.timeZone = "America/Denver";
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
  environment.systemPackages = with pkgs; [
    vim
    vscode
  ];
  system.stateVersion = "24.05";
  security.sudo = common.security.sudo;
  environment.variables = {
    NIX_HOST = hostname;
  };

  networking.firewall.allowedTCPPorts = [
    25565
    8069
    2026 # <--- DEV Postgres DB
  ];

  networking.hostName = "eldo";
  home-manager.users.jade = common.jade;

  nix = common.nix // {
    nixPath = [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
      "nixos-config=/home/fisherrjd/cfg/hosts/${hostname}/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;
  services =
    {
      ntfy-sh = {
        enable = true;
        settings = {
          base-url = "https://ntfy.jade.rip";
          upstream-base-url = "https://ntfy.sh";
          listen-http = "0.0.0.0:8081";
          web-push-public-key = "BCAoXlScmXxcQtD28mXsk_P6u8YWeQX3qW0K3tUfOnX-dP_yfBPTGYG-GzwpbcYOyZqSnlSUx2O1yQBaH4LQlec";
          web-push-private-key = "s1GJFuYtO2YcDnkr_IfwouyP6C_ekSxsihWDM8yvDwI";
          web-push-file = "/var/lib/ntfy-sh/webpush.db";
          web-push-email-address = "fisherrjd@gmail.com";
        };
      };


      openssh.enable = true;
      postgresql = {
        enable = true;
        ensureDatabases = [ "litellm" ];
        authentication = pkgs.lib.mkOverride 10 ''
          #type   database      DBuser      auth-method
          local   all           all         trust
          host    all           all         127.0.0.1/32 trust
          host    litellm       postgres    0.0.0.0/0              md5
          host    all           postgres    127.0.0.1/32           md5
          host    all           postgres    ::1/128                md5
        '';
      };

      # MINECRAFT STUFF
      minecraft-server = with common.minecraft; {
        enable = true;
        eula = true;
        openFirewall = true;
        declarative = true;
        serverProperties = {
          server-port = 25565;
          motd = "Not Artistic SMP";
          level-name = "community_server";
          level-seed = "46182117";
          server-name = "NotArtistic";
          gamemode = 0;
          difficulty = 3;
          max-players = 10;
          bind = "0.0.0.0"; # Allow connections from any IP address
          hardcore = false;
        };
      };

      github-runners = {
        lists-runner = {
          enable = true;
          name = "lists-runner";
          tokenFile = config.age.secrets.github-runner-token.path;
          url = "https://github.com/fisherrjd/lists-backend";
        };
      };
    };
  # DOCKER COMMENTED OUT FOR NOW
  # users.extraGroups.docker.members = [ username ];
  # virtualisation.docker.enable = true;

  virtualisation.podman.enable = true;
  virtualisation.oci-containers = {
    # backend = "docker";
    backend = "podman";
    containers = {
      litellm = {
        image = "ghcr.io/berriai/litellm:main-v1.74.3-stable";
        volumes = [ "lite-llm:/app" ];
        environmentFiles = [ config.age.secrets.litellm.path ];
        extraOptions = [
          "--network=host"
        ];
      };
      openwebui = {
        image = "ghcr.io/open-webui/open-webui:v0.6.16";
        volumes = [ "open-webui:/app/backend/data" ];
        environmentFiles = [ config.age.secrets.openwebui.path ];
        extraOptions = [
          "--network=host"
        ];
      };
      n8n = {
        image = "docker.n8n.io/n8nio/n8n:1.105.3";
        volumes = [ "n8n_data:/home/node/.n8n" ];
        ports = [ "5678:5678" ];
        environment = {
          GENERIC_TIMEZONE = "America/Denver";
          N8N_EDITOR_BASE_URL = "https://n8n.jade.rip";
          N8N_TEMPLATES_ENABLED = "true";
          N8N_HIRING_BANNER_ENABLED = "false";
          N8N_WEBHOOK_URL = "https://n8n.jade.rip";
          N8N_HOST = "n8n.jade.rip";
        };
      };
      grocery_list = {
        image = "ghcr.io/fisherrjd/lists-backend:v0.3.0-dev";
        ports = [ "8069:8069" ];
        volumes = [ "grocery-list-data:/app/data" ];
      };
    };
  };

}
