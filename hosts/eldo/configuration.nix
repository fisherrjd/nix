{ config, flake, pkgs, machine-name, ... }:
let
  hostname = "eldo";
  username = "jade";
  ts_ip = "100.66.184.28";
  common = import ../common.nix {
    inherit config flake machine-name pkgs username;
  };
in
{
  imports =
    [
      # Include the results of the hardware scan.
      "${common.home-manager}/nixos"
      ./hardware-configuration.nix
      ../../modules/obsidian-autocommit.nix
      { services = common.services; }
    ];
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv4.conf.default.forwarding" = 1;
  };
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
      github-runner-token-nix = {
        file = ../../secrets/github-runner-token-nix.age;
        mode = "644";
      };
      ntfy = {
        file = ../../secrets/ntfy.age;
        mode = "644";
      };
    };
  };
  networking.networkmanager.enable = true;
  networking.interfaces.enp24s0.ipv6.addresses = [ ];
  networking.enableIPv6 = false;
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
    25566
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

  services.obsidian-autocommit = {
    enable = true;
    user = username;
    repoPath = "/home/${username}/syncthing/obsidian";
    gitName = hostname;
    # interval and gitEmail use the module defaults — no need to redeclare
  };

  systemd.services = {
    hermes-cron-learning = {
      path = [ pkgs.hermes-agent pkgs.nodejs ];
      environment = {
        HERMES_HOME = "/home/${username}/.hermes";
        HERMES_ACCEPT_HOOKS = "1";
      };
      script = ''
        hermes -p learning cron tick --accept-hooks
      '';
      serviceConfig = {
        User = username;
        Type = "oneshot";
        TimeoutStartSec = "600";
      };
      startAt = "*:0/10"; # every 10 minutes
    };
  };
  services =
    {
      ntfy-sh = {
        enable = true;
        settings = {
          base-url = "https://ntfy.jade.rip";
          upstream-base-url = "https://ntfy.sh";
          listen-http = "0.0.0.0:8081";
          environmentFiles = [ config.age.secrets.litellm.path ];
          web-push-file = "/var/lib/ntfy-sh/webpush.db";
          web-push-email-address = "fisherrjd@gmail.com";
        };
      };

      syncthing = {
        enable = true;
        user = username;
        dataDir = "/home/${username}/syncthing";
        configDir = "/home/${username}/.config/syncthing";
        openDefaultPorts = true;
        guiAddress = "0.0.0.0:8384";
        settings = {
          devices = {
            "eldo" = {
              id = "WXGANFF-PYFZNOY-JMMYYOK-CIGDYOK-7TIFCIQ-QXGBKUZ-KBFT3BC-IDQA3A6";
              name = "eldo";
            };
            "atlantis" = {
              id = "7ZCBLK3-K37ZMV4-E3RMCJO-57GVJ4R-POJLDTM-TGMF7Y7-J3TLI6V-2734LAA";
              name = "atlantis";
            };
            "airbook" = {
              id = "7LP4WCW-SJFJC4S-KWM3WTR-PNKUNWV-EZ6BZDZ-NSFKBQ7-WQZFE6U-CRYIDA5";
              name = "airbook";
            };
          };
          folders = {
            "obsidian" = {
              path = "/home/${username}/syncthing/obsidian";
              devices = [ "eldo" "atlantis" "airbook" ];
              ignorePatterns = [
                ".git/"
                ".obsidian/"
                "**/.git/**"
                "**/.obsidian/**"
              ];
            };
          };
        };
      };

      k3s = {
        enable = true;
        role = "server";
        extraFlags = "--disable traefik --tls-san '${ts_ip}'";
      };

      openssh.enable = true;
      postgresql = {
        enable = true;
        ensureDatabases = [ "litellm" ];
      };
    };

  virtualisation.podman = {
    enable = true;
    dockerCompat = true; # provide docker → podman symlink for hermes-agent
  };

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
        environment = {
          PORT = "3001";
        };
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

    };
  };
}
