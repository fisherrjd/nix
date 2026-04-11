# Fix for atomicwrites-1.4.1 missing setuptools build dependency
# Issue: After nix flake update, atomicwrites now requires explicit setuptools
# in build-system.requires but nixpkgs definition hasn't been updated
# Error: 'No module named setuptools' during wheel build
# Affected: hermes-agent-env → hermes-agent → system-path → nixos-system-eldo

final: prev: {
  # Override atomicwrites to add setuptools to nativeBuildInputs
  atomicwrites = prev.atomicwrites.overridePythonAttrs (oldAttrs: {
    nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ prev.python3.pkgs.setuptools ];
  });
}
