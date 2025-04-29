{
  meta = {
    nixpkgs = <nixpkgs>;
  };
  nodes = {
    bifrost = { ... }: {
      imports = [ ../hosts/bifrost/configuration.nix ];
      deployment.targetHost = "bifrost"; # Doesn't matter for 'build'
      deployment.targetUser = "jade";
    };
  };
}
