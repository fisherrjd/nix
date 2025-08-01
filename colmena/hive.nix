let
  flake = import ../flake.nix;
in
{
  meta = {
    nixpkgs = <nixpkgs>;
  };
  bifrost = {
    imports = [ ../hosts/bifrost/configuration.nix ];
    deployment.targetHost = "bifrost"; # Doesn't matter for 'build'
    deployment.targetUser = "jade";
  };

}
