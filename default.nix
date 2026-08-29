{ flake ? import ./flake-compat.nix
, nixpkgs ? flake.inputs.nixpkgs
, overlays ? [ ]
, config ? { }
, system ? builtins.currentSystem
}:
import nixpkgs {
  inherit system;
  overlays = [
    (_: _: { jacobi = import flake.inputs.jacobi { inherit system; }; })
    (_: _: { wisp = flake.inputs.wisp.packages.${system}.wisp; })
    (_: prev: { inherit (prev.jacobi) llama-cpp-latest hermes-agent sglang-omni codex-latest pog; })
  ] ++ (import ./overlays.nix) ++ overlays;
  config = {
    allowUnfree = true;
  } // config;
}
