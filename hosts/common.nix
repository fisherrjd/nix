{ pkgs, flake, machine-name, username, ... }:
let
  inherit (flake.inputs) home-manager nix-darwin;
  jade = import ../home.nix {
    inherit home-manager flake machine-name pkgs username;
  };

in
{
  inherit home-manager jade nix-darwin pkgs;

  nix = {
    extraOptions = ''
      max-jobs = auto
      narinfo-cache-negative-ttl = 10
      extra-experimental-features = nix-command flakes
      extra-substituters = https://jacobi.cachix.org https://fisherrjd.cachix.org
      extra-trusted-public-keys = jacobi.cachix.org-1:JJghCz+ZD2hc9BHO94myjCzf4wS3DeBLKHOz3jCukMU= fisherrjd.cachix.org-1:21bdYeKCoWN19OGUDTGU41o60gnEsLHY5+tIpEq7w+A=
    '';
    settings = {
      trusted-users = [ "root" "jade" "P3175941" ];
    };
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
  pubkeys = {
    atlantis = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE4ng5nDLLCyQJ0QOHglRBZkBUI/3FV1c2FIAjwQgIK0 jade@Atlantis"; #home desktop
    neverland = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAX2/pWmcbFAPOSs1Vi4/xHRgFT+IDuWBUNGFyM0YlCh jade@neverland"; #home wsl on home desktop
    eldo = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJbNhnkhqLCDhVYXTQXxuVYkPHnWSBFFmunVSk5ETnZj jade@eldo"; # old pc gone nix server
    airbook = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILaWm9is28MRcO96v72pHvWQuZ+NiM0t3iFmC4mq3jsJ jade@airbook"; # m1 macbook air
    workbook = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDMR5a3uP1lZndQ8BZhirgYwHwbZNdzeoLeAwdOnslZf jade@work"; #m1pro work CHARTER
    bifrost = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKz+MKsAIJwcp/KOmafEWebxPiZ+GrqvGrfYKi6VSljR jade@bifrost"; #DO droplet
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
}
