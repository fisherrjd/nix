# Uses `opkgs` (home.nix's overlaid pkgs) rather than the module's plain
# `pkgs`, because several entries below (hms, hermes-agent, codex-latest,
# colmena_pog_scripts, ...) are provided by overlays not present on
# home-manager's default pkgs.
{ opkgs, flake, machine-name, ... }:
let
  inherit (opkgs.hax) isLinux;
  isWork = machine-name == "gjallar";
  isAirbook = machine-name == "airbook";
  jacobi = flake.inputs.jacobi.packages.${opkgs.stdenv.hostPlatform.system};
in
{
  home.packages = with opkgs;
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
        curl
        diffutils
        doggo
        duckdb
        dyff
        erdtree
        fd
        ffmpeg
        figlet
        file
        fq
        gawk
        delta
        gh
        gnugrep
        gnumake
        gnupg
        gnused
        gron
        gum # learn about this
        gzip
        hms
        htmlq
        jq
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
        prettier
        openssh
        p7zip
        patch
        pigz
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

        # Packages for only Linux
        (
          lib.optionals isLinux [
            gnutar
            ntfy-sh
            claude-code
            codex-latest
            hermes-agent
            procps
            colmena
            colmena_pog_scripts
          ]
        )
        # Secrets
        flake.inputs.agenix.packages.${opkgs.stdenv.hostPlatform.system}.default

        (lib.optionals isWork [
          awscli2
          ssm-session-manager-plugin
          opencode
          pi-coding-agent
          glab
        ])
      ];
}
