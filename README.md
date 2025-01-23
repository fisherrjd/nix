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

Update Everything
```
nix flake update
hms
```

Update only Jacobi
```
nix flake lock --update-input jacobi
hms
```

Docs for installing nix baremetal box!

1. Enable open ssh in /etc/nixos/configuration.nix
2. 


#Random Tidbits

SSH KEYGEN
ssh-keygen -o -a 100 -t ed25519 -C "jade@<identifier>"