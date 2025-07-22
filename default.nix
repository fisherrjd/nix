{ flake ? import ./flake-compat.nix
, nixpkgs ? flake.inputs.nixpkgs
, overlays ? [ ]
, config ? { }
, system ? builtins.currentSystem
}:
import nixpkgs {
  inherit system;
  overlays = [
    # Ensure pog is available as final.pog in all overlays
    (_: _: { nixpkgsRev = nixpkgs.rev; })
    # (_: _: { pog = import flake.inputs.pog { inherit system; }; })
    (_: _: { jacobi = import flake.inputs.jacobi { inherit system; }; })
    (_: prev: { inherit (prev.jacobi) llama-cpp-latest; })
    (_: _: { nixpkgsRev = flake.inputs.nixpkgs.rev; })
  ] ++ (import ./overlays.nix) ++ overlays;
  config = {
    allowUnfree = true;
  } // config;
}
