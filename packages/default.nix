final: _: {
  claude-code-latest = final.callPackage ./claude-code-latest.nix { };
  sinch-cli = final.callPackage ./sinch-cli.nix { };
  wisp-docs = final.callPackage ./wisp-docs { };
}
