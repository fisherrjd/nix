let
  flake = import ../flake-compat.nix;
in
{
  meta = {
    nixpkgs = flake.packages.x86_64-linux;
    specialArgs = {
      inherit flake;
      machine-name = "bifrost";
    };
  };
  bifrost = {
    imports = [
      flake.inputs.agenix.nixosModules.default
      ../hosts/bifrost/configuration.nix
    ];
    deployment.targetHost = "bifrost";
    deployment.targetUser = "jade";
  };

}
