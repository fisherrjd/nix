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
    (_: _: { inherit (flake.inputs.oh-my-pi.packages.${system}) omp; })
    (_: prev: { inherit (prev.jacobi) llama-cpp-latest codex-latest sglang-omni pog; })
    # Hermes 0.22 made the Anthropic SDK an optional extra, and the jacobi package doesn't enable it.
    # Hermes' PM only counts tools in its own ~/.hermes/tools store, so once it installs anything
    # there (agent-browser, cua-driver) it reports the ones the nix wrapper puts on PATH as missing.
    (_: prev: {
      hermes-agent = (prev.jacobi.hermes-agent.override {
        uv-nix = prev.jacobi.uv-nix // {
          mkEnv = args: prev.jacobi.uv-nix.mkEnv (args // prev.lib.optionalAttrs (args.name == "hermes-agent") {
            _deps.hermes-agent = args._deps.hermes-agent ++ [ "anthropic" ];
          });
        };
      }).overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          chmod u+w $out/lib/python3.14/site-packages/pm/install.py
          substituteInPlace $out/lib/python3.14/site-packages/pm/install.py --replace-fail \
            'if package.optional or package.internal:' \
            'if package.optional or package.internal or name in ("ffmpeg", "node", "npm", "ripgrep"):'
        '';
      });
    })
  ] ++ (import ./overlays.nix) ++ overlays;
  config = {
    allowUnfree = true;
  } // config;
}
