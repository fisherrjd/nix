# nix
Nix tings


##bootstrap init
nix-build --no-link --expr 'with import ~/cfg {}; _nixos-switch' --argstr host "neverland"
