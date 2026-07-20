{ hax, machine-name, ... }:
let
  inherit (hax) isDarwin optionalString;
  isWork = machine-name == "gjallar";

  # macOS needs xauth pointed at the XQuartz location for X11 forwarding.
  macXAuth = optionalString isDarwin ''
    XAuthLocation /opt/X11/bin/xauth
  '';

  # Hardened crypto, shared by the hosts below.
  hardenedCrypto = ''
    Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
    KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256
    MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com
    HostKeyAlgorithms ssh-ed25519,rsa-sha2-256,rsa-sha2-512
  '';
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [ "config.d/*" ];
    settings."*".Compression = true;
    extraConfig = ''
      ${optionalString isWork ''
      Host bastion
        User p3175941
        IdentityFile ~/.ssh/id_ed25519
        PasswordAuthentication no
        ProxyCommand sh -c 'export AWS_PROFILE="it-cloud-shared-services"; aws ssm start-session --target "$(aws ec2 describe-instances --filters "Name=tag:Name,Values=shared-bastion" "Name=instance-state-name,Values=running" --output text --query "Reservations[*].Instances[0].InstanceId")" --document-name AWS-StartSSHSession --parameters "portNumber=%p"'
      ''}

      Host airbook
        User jade
        PasswordAuthentication no
        IdentitiesOnly yes
        ${hardenedCrypto}
        ${macXAuth}

      Host gjallar
        HostName 192.168.50.197
        User jadfis
        PasswordAuthentication no
        IdentitiesOnly yes
        ${hardenedCrypto}
        ${macXAuth}
    '';
  };

  home.file.ssh_config_github = {
    target = ".ssh/config.d/github";
    text = hax.ssh.github;
  };
}
