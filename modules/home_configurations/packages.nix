{ pkgs, flake, lib, machine-name, ... }:
{
  home.packages = with pkgs;
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
        cachix
        calibre-web
        coreutils-full
        colmena
        curl
        diffutils
        docker
        dyff
        erdtree
        fd
        figlet
        file
        fq
        gawk
        gitAndTools.delta
        gnugrep
        gnumake
        gnupg
        gnused
        gron
        gum # learn about this
        gzip
        htmlq
        hms
        jq
        kubectl
        kubectx
        kubernetes-helm
        lsof
        man-pages
        manix
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
          ]
        )
        # Secrets
        flake.inputs.agenix.packages.${pkgs.system}.default

        # TODO: Pog scripts
        [ ]
      ];
}
