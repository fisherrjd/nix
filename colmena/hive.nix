{
  meta = {
    nixpkgs = <nixpkgs>; # <-- Accesses the passed 'inputs'
  };
  bifrost = { name, nodes, ... }: {
    imports = [
      ../hosts/bifrost/configtest.nix
    ];
    deployment.targetHost = "104.236.220.8";
    deployment.replaceUnknownProfiles = false;
    deployment.allowLocalDeployment = false;
    deployment.tags = [ "proxy" ];

  };
}
