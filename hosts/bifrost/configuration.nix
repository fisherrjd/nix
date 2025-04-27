{ config, flake, pkgs, machine-name, lib, modulesPath, ... }:
let
  hostname = "bifrost";
  username = "jade";
  common = import ../common.nix { inherit config flake machine-name pkgs username; };

in
{
  imports = lib.optional (builtins.pathExists ./do-userdata.nix) ./do-userdata.nix ++ [
    (modulesPath + "/virtualisation/digital-ocean-config.nix")
  ];

  #defining nix tings
  nix = common.nix // {
    nixPath = [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
      "nixos-config=/home/fisherrjd/cfg/hosts/${hostname}/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };

  #define hostname env variable
  environment.variables = {
    NIX_HOST = hostname;
  };
  networking.hostName = hostname; # Define your hostname.

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  users.users.jade = {
    isNormalUser = true;
    description = "Jade Fisher";
    extraGroups = [ "networkmanager" "wheel" ];
    openssh.authorizedKeys.keys = with common.pubkeys; [
      atlantis
      neverland
      airbook
      workbook
      eldo
    ];
    packages = with pkgs; [ ];
  };

  networking.firewall.enable = false;
  security.sudo.wheelNeedsPassword = false;
  environment.systemPackages = with pkgs; [
    git
    vim
  ];
  services = {
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = true;
        KexAlgorithms = [
          "curve25519-sha256"
          "curve25519-sha256@libssh.org"
        ];
        Ciphers = [
          "chacha20-poly1305@openssh.com"
          "aes256-gcm@openssh.com"
          "aes256-ctr"
        ];
        Macs = [
          "hmac-sha2-512-etm@openssh.com"
          "hmac-sha2-256-etm@openssh.com"
          "umac-128-etm@openssh.com"
        ];
        X11Forwarding = true;
      };
    };
    tailscale.enable = true;

  };

  # home-manager.users.jade = common.jade;


  system.stateVersion = "24.05";
  programs.command-not-found.enable = false;
}
