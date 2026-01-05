{ pkgs ? import ./default.nix { }, flake ? null, machine-name ? "void", home-manager ? null, username }:
let
  inherit (pkgs.hax) isDarwin isLinux isM1;
  inherit (pkgs.hax) attrIf optionalString words;
  notBifrost = machine-name != "bifrost";
  isWork = machine-name == "workbook";
  isAirbook = machine-name == "airbook";
  isEldo = machine-name == "eldo";

  firstName = "jade";
  lastName = "fisher";
  promptChar = ">";

  homeDirectory =
    if isLinux then
      "/home/${username}"
    else
      "/Users/${username}";

  sessionVariables = {
    BASH_SILENCE_DEPRECATION_WARNING = "1";
    EDITOR = "nano";
    GIT_SSH_COMMAND = "${pkgs.openssh}/bin/ssh";
    HISTCONTROL = "ignoreboth";
    LESS = "-iR";
    PAGER = "less";
  };

in
{
  imports = [
    ./modules/home_configurations/starship.nix
    ./modules/home_configurations/cobi.nix
    ./modules/home_configurations/git.nix
    # Look more into these ex: optionalAttrs
    (pkgs.lib.optionalAttrs isLinux "${flake.inputs.vscode-server}/modules/vscode-server/home.nix")
  ];

  _module.args = {
    inherit flake;
    inherit machine-name;
  };

  programs.home-manager.enable = true;
  programs.home-manager.path = "${home-manager}";

  programs.btop.enable = true;
  programs.htop.enable = true;
  programs.dircolors.enable = true;

  # broken manpages upstream, see: https://github.com/nix-community/home-manager/issues/3342
  manual.manpages.enable = false;

  home = {
    inherit username homeDirectory sessionVariables;
    packages = with pkgs;
      lib.flatten
        [
          (writeShellScriptBin "machine-name" ''
            echo "${machine-name}"
          '')
          bash-completion
          bashInteractive
          bat
          bzip2
          cacert
          caddy
          coreutils-full
          colmena
          curl
          diffutils
          docker
          doggo
          dyff
          erdtree
          fd
          figlet
          file
          fq
          gawk
          delta
          gnugrep
          gnumake
          gnupg
          gnused
          gron
          gum # learn about this
          gzip
          htmlq
          jq
          k9s
          kubectl
          kubectx
          kubernetes-helm
          lsof
          man-pages
          manix
          # minecraft-server
          moreutils # learn about this
          nano
          nanorc
          netcat-gnu
          ntfy-sh
          nil
          nix
          nix-info
          nix-output-monitor
          nix-prefetch-github
          nix-prefetch-scripts
          nix-tree
          nix-update
          nixpkgs-fmt
          nixpkgs-review
          nodePackages.prettier
          openssh
          p7zip
          patch
          pigz
          podman
          podman-compose
          procps
          pssh
          ranger
          redis
          re2c
          rlwrap
          ruff
          scc
          scrypt
          shfmt
          statix
          tmux
          unzip
          uv
          vale
          watch
          wget
          which
          xh
          yank
          yq-go
          zip
          # Packages for only Macs
          (
            lib.optionals isDarwin [
            ]
          )

          # Packages for only Linux
          (
            lib.optionals isLinux [
              gnutar
              claude-code
            ]
          )
          # Secrets
          flake.inputs.agenix.packages.${pkgs.system}.default

          #Packages NOT on Bifrost
          (lib.optionals notBifrost [
            hms
          ])
          (lib.optionals isWork [
            awscli2
            k8s_pog_scripts
            # amazon-q-cli
            nodejs
            ssm-session-manager-plugin
          ])
          (lib.optionals isAirbook [
            claude-code
            (pkgs.writeShellScriptBin "mcp-osrs" ''
              export PATH="${pkgs.nodejs}/bin:$PATH"
              exec ${pkgs.nodejs}/bin/npx -y @jayarrowz/mcp-osrs "$@"
            '')
          ])
          # Jade's Pog scripts
          [
            colmena_pog_scripts
          ]
        ];

    stateVersion = "22.11";
  };


  programs.less.enable = true;
  programs.lesspipe.enable = true;
  # programs.lsd.enable = true;

  programs.bash = {
    inherit sessionVariables;
    enable = true;
    historyFileSize = -1;
    historySize = -1;
    shellAliases = {
      ls = "ls --color=auto";
      # l = "lsd -lA --permission octal";
      ll = "ls -ahlFG";
      mkdir = "mkdir -pv";
      fzfp = "${pkgs.fzf}/bin/fzf --preview 'bat --style=numbers --color=always {}'";
      strip = ''${pkgs.gnused}/bin/sed -E 's#^\s+|\s+$##g' '';

      # git
      g = "git";
      ga = "git add -A .";
      cm = "git commit -m ";

      # misc
      space = "du -Sh | sort -rh | head -10";
      now = "date +%s";
      uneek = "awk '!a[$0]++'";
    };
    bashrcExtra =
      if isDarwin then ''
        export PATH="$PATH:${homeDirectory}/.nix-profile/bin"
      '' else "";
    initExtra = ''
      HISTCONTROL=ignoreboth
      set +h
      export PATH="$PATH:$HOME/.bin/"
      export PATH="$PATH:$HOME/.npm/bin/"

      # base nix
    '' + (if isM1 then ''
      export CONFIGURE_OPTS="--build aarch64-apple-darwin20"
    ''
    else ""
    ) + ''
      # additional aliases
      [[ -e ~/.aliases ]] && source ~/.aliases

      # bash completions
      export XDG_DATA_DIRS="$HOME/.nix-profile/share:''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
      source ~/.nix-profile/etc/profile.d/bash_completion.sh
      source ~/.nix-profile/share/bash-completion/completions/git
      source ~/.nix-profile/share/bash-completion/completions/ssh
      complete -o bashdefault -o default -o nospace -F __git_wrap__git_main g
      # there are often duplicate path entries on non-nixos; remove them
      NEWPATH=
      OLDIFS=$IFS
      IFS=:
      for entry in $PATH;do
        if [[ ! :$NEWPATH: == *:$entry:* ]];then
          if [[ -z $NEWPATH ]];then
            NEWPATH=$entry
          else
            NEWPATH=$NEWPATH:$entry
          fi
        fi
      done

      IFS=$OLDIFS
      export PATH="$NEWPATH"
      unset OLDIFS NEWPATH
    '' + (if isLinux then ''
      ${pkgs.figlet}/bin/figlet "$(hostname)" | ${pkgs.clolcat}/bin/clolcat
      echo
    '' else "");
  };

  # https://github.com/ajeetdsouza/zoxide
  programs.zoxide = {
    enable = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.nushell = {
    enable = true;
  };

  programs.readline = {
    enable = true;
    variables = {
      show-all-if-ambiguous = true;
      skip-completed-text = true;
      completion-query-items = -1;
      expand-tilde = false;
      bell-style = false;
    };
    bindings = {
      "\\e[1;5D" = "backward-word";
      "\\e[1;5C" = "forward-word";
      "\\e[5D" = "backward-word";
      "\\e[5C" = "forward-word";
      "\\e\\e[D" = "backward-word";
      "\\e\\e[C" = "forward-word";
    };
  };

  # https://github.com/cantino/mcfly
  programs.mcfly = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableBashIntegration = false;
    defaultCommand = "fd -tf -c always -H --ignore-file ${./ignore} -E .git";
    defaultOptions = words "--ansi --reverse --multi --filepath-word";
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [ "config.d/*" ];
    matchBlocks."*".compression = true;
    extraConfig =
      let
        mac_meme = ''
          XAuthLocation /opt/X11/bin/xauth
        '';
      in
      ''
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
          # secure stuff
          Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
          KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256
          MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com
          HostKeyAlgorithms ssh-ed25519,rsa-sha2-256,rsa-sha2-512
          ${optionalString isDarwin mac_meme}

        Host workbook
          HostName 10.0.0.61
          User P3175941
          PasswordAuthentication no
          IdentitiesOnly yes
          # secure stuff
          Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
          KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha256
          MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com
          HostKeyAlgorithms ssh-ed25519,rsa-sha2-256,rsa-sha2-512
          ${optionalString isDarwin mac_meme}
      '';
  };

  home.file = {
    ssh_config_github = {
      target = ".ssh/config.d/github";
      text = pkgs.hax.ssh.github;
    };
    curlrc = {
      target = ".curlrc";
      text = ''
        --netrc-optional
        --netrc-optional
      '';
    };
    sqliterc = {
      target = ".sqliterc";
      text = ''
        .output /dev/null
        .headers on
        .mode column
        .prompt "> " ". "
        .separator ROW "\n"
        .nullvalue NULL
        .output stdout
      '';
    };
    prettierrc = {
      target = ".prettierrc.js";
      text = builtins.readFile ./.prettierrc.js;
    };
  };





  ${attrIf isLinux "services"}.vscode-server.enable = isLinux;
}
