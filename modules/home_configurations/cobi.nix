{ pkgs, flake, lib, ... }:

let
  # legacyPackages, not packages: the flake's `packages` output is the filtered
  # `__j_packages` set, which excludes the pog script lists and nixup.
  jacobi = flake.inputs.jacobi.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  home.packages = with jacobi;
    lib.flatten [
      nixup
      docker_pog_scripts
      k8s_pog_scripts
      aws_pog_scripts
      curl_pog_scripts
      aq
      mica
      # zaddy
    ];

}
