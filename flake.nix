{
  # Inputs for building the flake things
  inputs = {
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # Mr Cobis git nix repo
    # TODO maybe add Keiths / DigDugs things see if they have anything cobi didn't already steal
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
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, ... }:
    let
      inherit (self.inputs.nixpkgs) lib;
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;
    in
    {
      inherit (self.inputs) jacobi agenix;
      pins = self.inputs;
      packages = forAllSystems
        (system: import self.inputs.nixpkgs {
          inherit system;
          # Define cobi repos as an overlay into me
          overlays = [
            (_: _: { jacobi = import self.inputs.jacobi { inherit system; }; })
            (_: prev: { inherit (prev.jacobi) llama-cpp-latest; })
            (_: _: { nixpkgsRev = self.inputs.nixpkgs.rev; })
          ] ++ import ./overlays.nix;
          config = {
            allowUnfree = true;
          };
        });

      nixosConfigurations = builtins.listToAttrs
        (map
          (name: {
            inherit name;
            value = self.inputs.nixpkgs.lib.nixosSystem {
              pkgs = self.packages.x86_64-linux;
              specialArgs = { flake = self; machine-name = name; };
              modules = [
                self.inputs.agenix.nixosModules.default
                ./hosts/${name}/configuration.nix
              ];
            };
          })
          [
            "neverland"
            "eldo"
            "bifrost"
          ]);

      darwinConfigurations = builtins.listToAttrs
        (map
          (name: {
            inherit name;
            value = self.inputs.nix-darwin.lib.darwinSystem {
              pkgs = self.packages.aarch64-darwin;
              specialArgs = { flake = self; machine-name = name; };
              modules = [
                ./hosts/common_darwin.nix
                "${self.inputs.jacobi}/hosts/modules/darwin/llama-server.nix"
                ./hosts/${name}/configuration.nix
              ];
            };
          })
          [
            "airbook"
            "workbook"
          ]
        );

      colmena = {
        meta = {
          nixpkgs = import self.inputs.nixpkgs {
            system = "x86_64-linux";
          };
        };
        nodes = {
          bifrost = {
            deployment = {
              targetHost = "bifrost";
              allowLocalDeployment = false;
            };
            nixosConfiguration = self.nixosConfigurations."bifrost";
            tags = [
              "proxy"
            ];
          };

        };
      };
      do-builder = self.inputs.nixos-generators.nixosGenerate {
        system = "x86_64-linux";
        format = "do";
        modules = [
          ./generators/do-builder/configuration.nix
        ];
      };
    };


}
