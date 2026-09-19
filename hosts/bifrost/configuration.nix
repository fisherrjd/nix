{ config, flake, pkgs, machine-name, lib, modulesPath, ... }:
let
  hostname = "bifrost";
  username = "jade";
  common = import ../common.nix { inherit flake machine-name pkgs username; };
  modulesDir = ../../modules/home_configurations;

in
{
  imports =
    lib.optional (builtins.pathExists ./do-userdata.nix) ./do-userdata.nix
    ++ [
      (modulesPath + "/virtualisation/digital-ocean-config.nix")
      (modulesDir + "/starship.nix")
      ../../modules/caddy-config.nix
      # (modulesDir + "/git.nix")

    ];

  #defining nix tings
  inherit (common) nix;

  age = {
    identityPaths = [ "/home/jade/.ssh/id_ed25519" ];
    secrets = {
      caddy = {
        file = ../../secrets/caddy.age;
        owner = "root";
        group = "root";
        mode = "600";
      };
    };
  };

  #define hostname env variable
  environment.variables = {
    NIX_HOST = hostname;
  };
  networking = {
    hostName = hostname;
    firewall.enable = true;
    firewall.allowedTCPPorts = [ 80 443 ];
  };

  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  users.users.jade = {
    isNormalUser = true;
    description = "Jade Fisher";
    extraGroups = [ "networkmanager" "wheel" ];
    openssh.authorizedKeys.keys = common.pubkeys.all;
  };

  security.sudo.wheelNeedsPassword = false;
  environment.systemPackages = with pkgs; [
    claude-code-latest
    git
    vim
  ];
  services = {
    tailscale.enable = true;
  };

  system.stateVersion = "24.05";
  programs.command-not-found.enable = false;


}
