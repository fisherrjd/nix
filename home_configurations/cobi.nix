{ pkgs, flake, ... }:

let
  jacobi = flake.inputs.jacobi.packages.${pkgs.system};
  inherit (pkgs.hax) isDarwin isLinux;
in
{
  home.packages = with jacobi;
    lib.flatten [
      nixup
      hax.comma
      docker_pog_scripts
    ];

}
