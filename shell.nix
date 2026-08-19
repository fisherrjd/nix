{ pkgs ? import ./default.nix { } }:
# Dev shell mirroring the lint checks .github/workflows/build.yml runs:
# `nix-shell --run check` gives a quick local way to run the same
# formatting + static-analysis gate without needing to remember the
# individual `nix run` invocations. Uses ./default.nix (not <nixpkgs>) so it
# resolves the same pinned nixpkgs as the rest of the repo, with no channel
# required.
pkgs.mkShell {
  packages = [ pkgs.nixpkgs-fmt pkgs.statix ];
  shellHook = ''
    check() {
      set -e
      nixpkgs-fmt --check .
      statix check .
    }
  '';
}
