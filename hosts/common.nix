{ pkgs, flake, machine-name, username, isDarwin ? false, ... }:
let
  inherit (flake.inputs) home-manager nix-darwin;

  mms = import
    (fetchTarball {
      url = "https://github.com/mkaito/nixos-modded-minecraft-servers/archive/68f2066499c035fd81c9dacfea2f512d6b0b62e5.tar.gz";
      sha256 = "1nmw497ahb9hjjh0kwr1z782q41gcw5kw4dl4alg8pnyhgq141r1";
    });

  jade = import ../home.nix {
    inherit home-manager flake machine-name pkgs username;
  };
  constants = import ./constants.nix;

  _base_nix_options = ''
    max-jobs = auto
    narinfo-cache-negative-ttl = 10
    extra-experimental-features = nix-command flakes
  '';
  subs = {
    jade = {
      url = "https://fisherrjd.cachix.org";
      key = "fisherrjd.cachix.org-1:21bdYeKCoWN19OGUDTGU41o60gnEsLHY5+tIpEq7w+A=";
    };
    g7c = {
      url = "https://cache.g7c.us";
      key = "cache.g7c.us:dSWpE2B5zK/Fahd7npIQWM4izRnVL+a4LiCAnrjdoFY=";
    };
  };
in
{
  inherit (constants) pubkeys;
  inherit home-manager jade nix-darwin mms pkgs;

  nix = {
    extraOptions = ''
      ${_base_nix_options}
      extra-substituters = ${subs.g7c.url} ${subs.jade.url}
      extra-trusted-public-keys = ${subs.g7c.key} ${subs.jade.key}
    '';
    settings = {
      trusted-users = [ "root" "jade" "P3175941" ];
    };

    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
    } // (if pkgs.hax.isDarwin
    then { interval = { Weekday = 0; Hour = 3; Minute = 0; }; }
    else { dates = "Sun *-*-* 03:00:00"; });

    optimise = {
      automatic = true;
    } // (if pkgs.hax.isDarwin
    then { interval = { Weekday = 0; Hour = 4; Minute = 0; }; }
    else { dates = "Sun *-*-* 04:00:00"; });
  };

  extraGroups = [ "wheel" "networkmanager" "docker" "podman" ];

  sysctl_opts = {
    "fs.inotify.max_user_watches" = 1048576;
    "fs.inotify.max_queued_events" = 1048576;
    "fs.inotify.max_user_instances" = 1048576;
    "net.core.rmem_max" = 2500000;
  };

  defaultLocale = "en_US.UTF-8";
  extraLocaleSettings = let utf8 = "en_US.UTF-8"; in
    {
      LC_ADDRESS = utf8;
      LC_IDENTIFICATION = utf8;
      LC_MEASUREMENT = utf8;
      LC_MONETARY = utf8;
      LC_NAME = utf8;
      LC_NUMERIC = utf8;
      LC_PAPER = utf8;
      LC_TELEPHONE = utf8;
      LC_TIME = utf8;
    };

  env = { };

  name = rec {
    first = "jade";
    last = "fisher";
    full = "${first} ${last}";
  };
  timeZone = "America/Denver";

  security.sudo = {
    extraRules = [
      {
        users = [ "jade" "fisherrjd" "P3175941" ];
        commands = [
          {
            command = "ALL";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
    extraConfig = ''
      Defaults env_keep+=NIX_HOST
      Defaults env_keep+=NIXOS_CONFIG
      Defaults env_keep+=NIXDARWIN_CONFIG
    '';
    wheelNeedsPassword = false;
  };
  services = {
    tailscale.enable = true;
    # netdata.enable = true;
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        KexAlgorithms = [
          "curve25519-sha256"
          "curve25519-sha256@libssh.org"
        ];
        Ciphers = [
          "chacha20-poly1305@openssh.com"
          "aes256-gcm@openssh.com"
          # "aes128-gcm@openssh.com"
          "aes256-ctr"
          # "aes192-ctr"
          # "aes128-ctr"
        ];
        Macs = [
          "hmac-sha2-512-etm@openssh.com"
          "hmac-sha2-256-etm@openssh.com"
          "umac-128-etm@openssh.com"
        ];
      };
    };
  };

  minecraft = {
    conf = {
      jre8 = pkgs.temurin-bin-8;
      jre17 = pkgs.temurin-bin-17;
      jre18 = pkgs.temurin-bin-18;
      jre19 = pkgs.temurin-bin-19;
      jre21 = pkgs.temurin-bin-21;

      jvmOpts = builtins.concatStringsSep " " [
        "-Xmx8192M"
        "-Xms4096M"
        "-XX:+UseG1GC"
        "-XX:+ParallelRefProcEnabled"
        "-XX:MaxGCPauseMillis=200"
        "-XX:+UnlockExperimentalVMOptions"
        "-XX:+DisableExplicitGC"
        "-XX:+AlwaysPreTouch"
        "-XX:G1NewSizePercent=40"
        "-XX:G1MaxNewSizePercent=50"
        "-XX:G1HeapRegionSize=16M"
        "-XX:G1ReservePercent=15"
        "-XX:G1HeapWastePercent=5"
        "-XX:G1MixedGCCountTarget=4"
        "-XX:InitiatingHeapOccupancyPercent=20"
        "-XX:G1MixedGCLiveThresholdPercent=90"
        "-XX:G1RSetUpdatingPauseTimePercent=5"
        "-XX:SurvivorRatio=32"
        "-XX:+PerfDisableSharedMem"
        "-XX:MaxTenuringThreshold=1"
      ];

      defaults = {
        white-list = false;
        spawn-protection = 0;
        max-tick-time = 5 * 60 * 1000;
        allow-flight = true;
      };
    };
  };
}
