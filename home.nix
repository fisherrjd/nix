{ pkgs ? import ./default.nix { }, flake ? null, machine-name ? "void", home-manager ? null , username}:
let
  inherit (pkgs.hax) isDarwin isLinux isM1;
  inherit (pkgs.hax) attrIf optionalString words;

  firstName = "jade";
  lastName = "fisher";

  promptChar = ">";

  jacobi = flake.inputs.jacobi.packages.${pkgs.system};
  
  homeDirectory = "/Users/${username}";

  sessionVariables = {
    BASH_SILENCE_DEPRECATION_WARNING = "1";
    EDITOR = "nano";
    GIT_SSH_COMMAND = "${pkgs.openssh}/bin/ssh";
    HISTCONTROL = "ignoreboth";
    LESS = "-iR";
    PAGER = "less";
  };

  optList = conditional: list: if conditional then list else [ ];
in
{
  nixpkgs.overlays = import ./overlays.nix;

  programs.home-manager.enable = true;
  programs.home-manager.path = "${home-manager}";

  programs.btop.enable = true;
  programs.htop.enable = true;
  programs.dircolors.enable = true;

  # broken manpages upstream, see: https://github.com/nix-community/home-manager/issues/3342
  manual.manpages.enable = false;

  home = {
    inherit username homeDirectory sessionVariables;

    stateVersion = "22.11";

    packages = with pkgs;
      lib.flatten [
        bash-completion
        bashInteractive
        bat
        bzip2
        cacert
        caddy
        cachix
        clolcat
        coreutils-full
        cowsay
        curl
        diffutils
        dos2unix
        dyff
        ed
        erdtree
        fd
        figlet
        file
        fq
        gawk
        genpass
        gitAndTools.delta
        gnugrep
        gnumake
        gnupg
        gnused
        gnutar
        gron
        gum
        gzip
        htmlq
        jq
        just
        kubectl
        kubectx
        libarchive
        libnotify
        loop
        lsof
        man-pages
        manix
        moreutils
        nano
        nanorc
        netcat-gnu
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
        procps
        pssh
        q
        ranger
        re2c
        rlwrap
        ruff
        scc
        scrypt
        shfmt
        statix
        time
        unzip
        vale
        watch
        wget
        which
        xh
        yank
        yq-go
        zip

        (writeShellScriptBin "machine-name" ''
          echo "${machine-name}"
        '')
        hms

        (with jacobi; [
          nixup
          hax.comma
        ])
      ];
  };

  programs.less.enable = true;
  programs.lesspipe.enable = true;
  programs.lsd.enable = true;


  # Youtube command line things
  programs.yt-dlp = {
    enable = true;
    extraConfig = ''
      --embed-thumbnail
      --embed-metadata
      --embed-subs
      --sub-langs all
      --downloader aria2c
      --downloader-args aria2c:'-c -x8 -s8 -k1M'
    '';
  };

  programs.bash = {
    inherit sessionVariables;
    enable = true;
    historyFileSize = -1;
    historySize = -1;
    shellAliases = {
      ls = "ls --color=auto";
      l = "lsd -lA --permission octal";
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

      # asdf and base nix
    '' + (if isM1 then ''
      export CONFIGURE_OPTS="--build aarch64-apple-darwin20"
    ''
    else ""
    ) + (
      if isDarwin then ''
        # add brew to path
        brew_path="/opt/homebrew/bin/brew"
        if [ -f /usr/local/bin/brew ]; then
          brew_path="/usr/local/bin/brew"
        fi
        eval "$($brew_path shellenv)"

        # load asdf if its there
        asdf_dir="$(brew --prefix asdf)"
        [[ -e "$asdf_dir/asdf.sh" ]] && source "$asdf_dir/asdf.sh"
        [[ -e "$asdf_dir/etc/bash_completion.d/asdf.bash" ]] && source "$asdf_dir/etc/bash_completion.d/asdf.bash"
      '' else ''
        [[ -e $HOME/.asdf/asdf.sh ]] && source $HOME/.asdf/asdf.sh
        [[ -e $HOME/.asdf/completions/asdf.bash ]] && source $HOME/.asdf/completions/asdf.bash
      ''
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


  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
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
  # BIG BOOM
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
    compression = true;
    includes = [ "config.d/*" ];
    extraConfig =
      let
        mac_meme = ''
          XAuthLocation /opt/X11/bin/xauth
        '';
      in
      ''
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

  # starship config
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      character = {
        success_symbol = "[${promptChar}](bright-green)";
        error_symbol = "[${promptChar}](bright-red)";
      };
      golang = {
        style = "fg:#00ADD8";
        symbol = "go ";
      };
      directory.style = "fg:#d442f5";
      localip = {
        disabled = true;
      };
      nix_shell = {
        pure_msg = "";
        impure_msg = "";
        format = "via [$symbol$state($name)]($style) ";
      };
      kubernetes = {
        disabled = false;
        style = "fg:#326ce5";
      };
      terraform = {
        disabled = false;
        format = "via [$symbol $version]($style) ";
        symbol = "🌴";
      };
      nodejs = { symbol = "⬡ "; };
      hostname = {
        style = "bold fg:46";
      };
      username = {
        style_user = "bold fg:93";
      };

      # disabled plugins
      aws.disabled = true;
      cmd_duration.disabled = true;
      gcloud.disabled = true;
      package.disabled = true;
    };
  };

  # gitconfig
  programs.git =
    let
      gs = text:
        let
          script = pkgs.writers.writeBash "git-script" ''
            set -eo pipefail
            cd -- ''${GIT_PREFIX:-.}
            ${text}
          '';
        in
        "! ${script}";
    in
    {
      enable = true;
      package = pkgs.gitAndTools.gitFull;
      userName = "${firstName} ${lastName}";
      userEmail = "fisherrjd@gmail.com";
      aliases = {
        A = "add -A";
        pu = "pull";
        pur = "pull --rebase";
        cam = "commit -am";
        ca = "commit -a";
        cm = "commit -m";
        ci = "commit";
        co = "checkout";
        cod = gs ''git co $(git default) "$@"'';
        st = "status";
        br = gs ''
          esc=$'\e'
          reset=$esc[0m
          red=$esc[31m
          yellow=$esc[33m
          green=$esc[32m
          git -c color.ui=always branch -vv "$@" | ${pkgs.gnused}/bin/sed -E \
            -e "s/: (gone)]/: $red\1$reset]/" \
            -e "s/[:,] (ahead [0-9]*)([],])/: $green\1$reset\2/g" \
            -e "s/[:,] (behind [0-9]*)([],])/: $yellow\1$reset\2/g"
          git --no-pager stash list
        '';
        brf = gs "git f --quiet && git br";
        f = "fetch --all";
        hide = "update-index --skip-worktree";
        unhide = "update-index --no-skip-worktree";
        hidden = "! git ls-files -v | grep '^S' | cut -c3-";
        branch-name = "!git rev-parse --abbrev-ref HEAD";
        default = gs "git symbolic-ref refs/remotes/origin/HEAD | sed s@refs/remotes/origin/@@";
        # Delete the remote version of the current branch
        unpublish = "!git push origin :$(git branch-name)";
        # Push current branch
        put = gs ''git push "$@"'';
        # Pull without merging
        get = "!git pull origin $(git branch-name) --ff-only";
        # update a branch without checkout
        gd = gs "git fetch origin $(git default):$(git default)";
        # Pull Master without switching branches
        got =
          "!f() { CURRENT_BRANCH=$(git branch-name) && git checkout $1 && git pull origin $1 --ff-only && git checkout $CURRENT_BRANCH;  }; f";
        gone = gs ''git branch -vv | ${pkgs.gnused}/bin/sed -En "/: gone]/s/^..([^[:space:]]*)\s.*/\1/p"'';
        # Recreate your local branch based on the remote branch
        recreate = ''
          !f() { [[ -n $@ ]] && git checkout master && git branch -D "$@" && git pull origin "$@":"$@" && git checkout "$@"; }; f'';
        reset-submodule = "!git submodule update --init";
        s = gs "git br && git -c color.status=always status | grep -E --color=never '^\\s\\S|:$' || true";
        sl = "!git --no-pager log -n 15 --oneline --decorate";
        sla = "log --oneline --decorate --graph --all";
        lol = "log --graph --decorate --pretty=oneline --abbrev-commit";
        lola = "log --graph --decorate --pretty=oneline --abbrev-commit --all";
        shake = "remote prune origin";
      };
      extraConfig = {
        checkout.defaultRemote = "origin";
        color.ui = true;
        fetch.prune = true;
        init.defaultBranch = "main";
        pull.ff = "only";
        push.default = "simple";
        rebase.instructionFormat = "<%ae >%s";
        core = {
          editor = if isDarwin then "code --wait" else "nano";
          pager = "delta --dark";
          autocrlf = "input";
          hooksPath = "/dev/null";
        };
        delta = {
          navigate = true;
          line-numbers = true;
          side-by-side = true;
          line-numbers-left-format = "";
          line-numbers-right-format = "│ ";
        };
        push = {
          autoSetupRemote = true;
        };
      };

    };

  # fix vscode
  imports =
    if isLinux then [
      "${flake.inputs.vscode-server}/modules/vscode-server/home.nix"
    ] else [ ];

  ${attrIf isLinux "services"}.vscode-server.enable = isLinux;
}
