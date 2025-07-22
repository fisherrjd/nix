inputs: [
  # Add the pog overlay from the pog flake input so final.pog is available
  inputs.pog.overlay
  (import ./mods/hax.nix)
  (import ./mods/mods.nix)

  # Jade's Pogs
  (import ./mods/pog/test.nix)
]
