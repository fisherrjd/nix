{
  meta = { nixpkgs = <nixpkgs>; }; # Adjust if not using flakes or pass differently
  nodes = {
    bifrost = { ... }: {
      imports = [ ../hosts/bifrost/configuration.nix ];
      deployment.targetHost = "dummy"; # Doesn't matter for 'build'
    };
  };
}
