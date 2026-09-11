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
    # Both from the wisp flake, so the page and the binary it documents are always the same
    # revision. The docs used to be a hand-written copy under packages/wisp-docs here, and it
    # drifted until it described a wisp with no workspaces, no hosts and no close-out.
    (_: _: { inherit (flake.inputs.wisp.packages.${system}) wisp wisp-docs; })
    (_: prev: { inherit (prev.jacobi) llama-cpp-latest codex-latest hermes-agent sglang-omni pog; })
  ] ++ (import ./overlays.nix) ++ overlays;
  config = {
    allowUnfree = true;
  } // config;
}
