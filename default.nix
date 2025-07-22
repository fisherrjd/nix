{ flake ? import ./flake-compat.nix
, nixpkgs ? flake.inputs.nixpkgs
, overlays ? [ ]
, config ? { }
, system ? builtins.currentSystem
}:
import nixpkgs {
  inherit system;
  overlays = [
    (_: _: { nixpkgsRev = nixpkgs.rev; })
    (_: _: { jacobi = import flake.inputs.jacobi { inherit system; }; })
    (_: prev: { inherit (prev.jacobi) llama-cpp-latest; })
    (_: _: { nixpkgsRev = flake.inputs.nixpkgs.rev; })
    (_: _: { pog = flake.inputs.pog.packages.${system}.default; })
  ] ++ (import ./overlays.nix) ++ overlays;
  config = {
    allowUnfree = true;
  } // config;
}
