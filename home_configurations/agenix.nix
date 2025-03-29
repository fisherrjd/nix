{ pkgs, flake, ... }:

let
  agenix = flake.inputs.agenix.packages.${pkgs.system}.default;
  inherit (pkgs.hax) isDarwin isLinux;
in
{
  home.packages = with agenix; [
    agenix
  ];

}
