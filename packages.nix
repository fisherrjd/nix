{ pkgs, flake, ... }:

let
  jacobi = flake.inputs.jacobi.packages.${pkgs.system};
in
{
  flakeInputs = with jacobi;[
    nixup
    hax.comma
  ];
}
