{ config, flake, pkgs, machine-name, ... }:
let
  hostname = "bifrost";
  username = "jade";
  common = import ../common.nix { inherit config flake machine-name pkgs username; };
in
{
  nix = {
    extraOptions = ''
      max-jobs = auto
      extra-experimental-features = nix-command flakes
    '';
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
    ];
    packages = with pkgs; [ ];
  };

  networking.firewall.enable = false;
  security.sudo.wheelNeedsPassword = false;

  services = {
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "prohibit-password";
        PasswordAuthentication = false;
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

  system.stateVersion = "24.05";
  programs.command-not-found.enable = false;
}
