final: _: {
  buzz-relay = final.callPackage ./buzz-relay.nix { };
  claude-code-latest = final.callPackage ./claude-code-latest.nix { };
  sinch-cli = final.callPackage ./sinch-cli.nix { };
}
