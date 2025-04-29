{
  meta = { nixpkgs = <nixpkgs>; }; # Adjust if not using flakes or pass differently
  nodes = {
    host-a = { ... }: {
      imports = [ ../hosts/bifrost/configuration.nix ];
      deployment.targetHost = "bifrost"; # Doesn't matter for 'build'
      deployment.tags = [ "bifrost" ];
    };
  };
}
