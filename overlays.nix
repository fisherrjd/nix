[
  (import ./mods/hax.nix)
  (import ./mods/mods.nix)

  # CI Fix: atomicwrites missing setuptools build dependency (run #24274955512)
  (import ./mods/fix-atomicwrites-overlay.nix)

  # Jade's Pogs
  (import ./mods/pog/colmena.nix)
  (import ./mods/pog/k8s.nix)

]
