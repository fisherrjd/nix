{ pkgs, flake, ... }:

let
  jacobi = flake.inputs.jacobi.packages.${pkgs.system};
  inherit (pkgs.hax) isDarwin isLinux;
in
{
  cobiFlakes = with jacobi; [
    nixup
    hax.comma
  ];
}
