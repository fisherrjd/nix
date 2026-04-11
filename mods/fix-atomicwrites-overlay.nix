# Fix for atomicwrites-1.4.1 missing setuptools build dependency
# Issue: After nix flake update, atomicwrites now requires explicit setuptools
# in build-system.requires but nixpkgs definition hasn't been updated
# Error: 'No module named setuptools' during wheel build
# Affected: hermes-agent-env → hermes-agent → system-path → nixos-system-eldo
#
# Fix: Override python3 package set to inject setuptools into atomicwrites

final: prev: {
  python3 = prev.python3.override {
    packageOverrides = pyfinal: pyprev: {
      atomicwrites = pyprev.atomicwrites.overridePythonAttrs (oldAttrs: {
        nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ pyfinal.setuptools ];
      });
    };
  };
}
