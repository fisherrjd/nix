{ config, flake, pkgs, machine-name, lib, modulesPath, ... }:
let
  hostname = "bifrost";
  username = "jade";
  common = import ../common.nix { inherit config flake machine-name pkgs username; };
  modulesDir = ../../modules/home_configurations;

in
{
  imports =
    lib.optional (builtins.pathExists ./do-userdata.nix) ./do-userdata.nix
    ++ [
      (modulesPath + "/virtualisation/digital-ocean-config.nix")
      (modulesDir + "/starship.nix")
      # (modulesDir + "/git.nix")

    ];

  #defining nix tings
  nix = common.nix // {
    nixPath = [
      "nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixos"
      "nixos-config=/home/fisherrjd/cfg/hosts/${hostname}/configuration.nix"
      "/nix/var/nix/profiles/per-user/root/channels"
    ];
  };

  # age = {
  #   identityPaths = [ "/home/jade/.ssh/id_ed25519" ];
  #   secrets = {
  #     caddy = {
  #       file = ../../secrets/caddy.age;
  #       path = "/etc/default/caddy";
  #       owner = "root";
  #       group = "root";
  #       mode = "644";
  #     };
  #   };
  # };

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

  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  security.sudo.wheelNeedsPassword = false;
  environment.systemPackages = with pkgs; [
    git
    vim
  ];
  services = {
    tailscale.enable = true;
    caddy = {
      # package = pkgs.zaddy;
      enable = true;
      virtualHosts = {
        # Push Notifications
        "ntfy.jade.rip".extraConfig = ''
          reverse_proxy * {
            to eldo:8081
          }
        '';
        "chat.jade.rip".extraConfig = ''
          reverse_proxy * {
            to eldo:8080
          }
        '';
        "osrs.jade.rip".extraConfig = ''
          reverse_proxy * {
            to eldo:8000
          }
        '';
        "llama.jade.rip".extraConfig = ''
          reverse_proxy * {
            to airbook:6969
          }
        '';
        "n8n.jade.rip".extraConfig = ''
          reverse_proxy * {
            to eldo:5678
          }
        '';
        "litellm.jade.rip".extraConfig = ''
          reverse_proxy * {
            to eldo:4000
          }
        '';
        "nix.jade.rip".extraConfig = ''
          redir https://github.com/fisherrjd/nix permanent
        '';
        "ge.jade.rip".extraConfig = ''
          reverse_proxy * {
            to eldo:5173
          }
        '';
      };
    };
  };

  system.stateVersion = "24.05";
  programs.command-not-found.enable = false;


}
