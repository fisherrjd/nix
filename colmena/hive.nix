{
  meta = {
    nixpkgs = <nixpkgs>; # <-- Accesses the passed 'inputs'
  };
  nodes = {
    bifrost = { name, nodes, ... }: {
      imports = [
        ../hosts/bifrost/configuration.nix
      ];
      deployment.targetHost = "bifrost";
      deployment.replaceUnknownProfiles = false;
      deployment.allowLocalDeployment = false;
      deployment.tags = [ "proxy" ];

    };
  };
}
