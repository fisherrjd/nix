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
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE4ng5nDLLCyQJ0QOHglRBZkBUI/3FV1c2FIAjwQgIK0 jade@Atlantis" #home desktop
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAX2/pWmcbFAPOSs1Vi4/xHRgFT+IDuWBUNGFyM0YlCh jade@neverland" #home wsl on home desktop
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJbNhnkhqLCDhVYXTQXxuVYkPHnWSBFFmunVSk5ETnZj jade@eldo" # old pc gone nix server
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILaWm9is28MRcO96v72pHvWQuZ+NiM0t3iFmC4mq3jsJ jade@airbook" # m1 macbook air
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDMR5a3uP1lZndQ8BZhirgYwHwbZNdzeoLeAwdOnslZf jade@work" #m1pro work CHARTER
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
