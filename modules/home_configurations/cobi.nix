{ pkgs, flake, ... }:

let
  jacobi = flake.inputs.jacobi.packages.${pkgs.stdenv.hostPlatform.system};
  inherit (pkgs.hax) isDarwin isLinux;
in
{
  home.packages = with jacobi;
    lib.flatten [
      nixup
      hax.comma
      docker_pog_scripts
      k8s_pog_scripts
      aws_pog_scripts
      # zaddy
    ];

}
