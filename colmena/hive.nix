{ inputs, ... }: # <-- This expects 'inputs' to be passed
let
  test = "test";
in
{
  meta = {
    nixpkgs = inputs.nixpkgs; # <-- Accesses the passed 'inputs'
    specialArgs = { inherit inputs; }; # <-- Also uses 'inputs'
  };
  nodes = {
    bifrost = { name, nodes, ... }: {
      imports = [
        ./hosts/bifrost/configuration.nix
      ];
      deployment.targetHost = "bifrost";
      deployment.replaceUnknownProfiles = false;
      deployment.allowLocalDeployment = false;
      deployment.tags = [ "proxy" ];

    };
  };
}
