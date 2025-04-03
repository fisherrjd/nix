{ pkgs, ... }:
{
  nix = {
    extraOptions = ''
      max-jobs = auto
      extra-experimental-features = nix-command flakes
    '';
  };
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  environment.systemPackages = with pkgs; [
    bashInteractive
    bash-completion
    coreutils-full
    curl
    jq
    lsof
    moreutils
    nano
    nix
    q
    wget
    yq-go
  ];

  users.extraUsers.jade = {
    createHome = true;
    isNormalUser = true;
    home = "/home/jade";
    description = "jade";
    group = "users";
    extraGroups = [ "wheel" ];
    useDefaultShell = true;
    openssh.authorizedKeys.keys = [
      # ADD KEYS
    ];
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
