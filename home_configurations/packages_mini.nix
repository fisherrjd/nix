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
        caddy
        cachix
        coreutils-full
        curl
        diffutils
      ];
}
