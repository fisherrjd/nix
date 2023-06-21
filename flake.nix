{
  inputs = {
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    jacobi.url = "github:jpetrucciani/nix";
    nixpkgs.url = "nixpkgs/nixos-unstable";
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    vscode-server = {
      url = "github:msteen/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, ... }:
    let
      inherit (self.inputs.nixpkgs) lib;
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;
    in
    {
      pins = self.inputs;
      packages = forAllSystems
        (system: import self.inputs.nixpkgs {
          inherit system;
          overlays = [ ] ++ import ./overlays.nix;
          config = {
            allowUnfree = true;
          };
        });

      nixosConfigurations = builtins.listToAttrs
        (map
          (name: {
            inherit name; value = self.inputs.nixpkgs.lib.nixosSystem {
            pkgs = self.packages.x86_64-linux;
            specialArgs = { flake = self; machine-name = name; };
            modules = [ ./hosts/${name}/configuration.nix ];
          };
          })
          [
            "neverland"
          ]);
    };
}
