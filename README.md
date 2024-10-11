# nix
Nix tings


##bootstrap init
nix-build --no-link --expr 'with import ~/cfg {}; _nixos-switch' --argstr host "neverland"


Follow instructions Here:
https://github.com/nix-community/NixOS-WSL

On your PC:
sudo nix-channel --update
sudo su
cd /root
nix-shell -p git
git clone https://github.com/fisherrjd/nix.git cfg
cd cfg
$(nix-build --no-link --expr "with import $(pwd) {}; _nixos-switch" --argstr host "neverland")/bin/switch

Update via cobis repo
```
nix flake update
hms
```