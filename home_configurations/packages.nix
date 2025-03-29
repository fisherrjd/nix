{ pkgs, flake, lib, machine-name, inputs, ... }:
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
        bruno-cli
        bzip2
        cacert
        caddy
        cachix
        coreutils-full
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
          lib.optionals isDarwin [ ]
        )

        # Packages for only Linux
        (
          lib.optionals isLinux [
            gnutar
          ]
        )

        # TODO: Pog scripts
        [ ]
      ];
}
