final: prev:
(x: { hax = x; }) (
  with prev;
  with lib;
  lib // rec {
    inherit (stdenv) isLinux isDarwin isAarch64;
    inherit (pkgs) fetchFromGitHub;
    isM1 = isDarwin && isAarch64;
    attrIf = check: name: if check then name else null;
    words = splitString " ";

    ssh = rec {
      github = ''
        Host github.com
          User git
          Hostname github.com
          PreferredAuthentications publickey
      '';
      mac_meme = ''
        IPQoS 0x00
          XAuthLocation /opt/X11/bin/xauth
      '';
      config = ''
        Include config.d/*

        Host *
          User jade
          PasswordAuthentication no
          Compression yes
          IdentitiesOnly yes
          # secure stuff
          Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
          KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256
          MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com
          HostKeyAlgorithms ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,sk-ssh-ed25519-cert-v01@openssh.com,rsa-sha2-256,rsa-sha2-256-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-512-cert-v01@openssh.com
          ${optionalString isDarwin mac_meme}
      '';
    };
  }
)
