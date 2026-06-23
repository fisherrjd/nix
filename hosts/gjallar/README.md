# Gjallar

Work M5 Macbook Pro (Sinch)

## Setup

```bash
# install nix
curl -L https://nixos.org/nix/install | sh

# generate ssh key, add to github
ssh-keygen -o -a 100 -t ed25519 -C "jade@gjallar"

# clone repo
nix-shell -p git
git clone git@github.com:fisherrjd/nix.git ~/cfg
cd ~/cfg

# initial switch. after this, you can use just `hms` to update!
$(nix-build --no-link --expr "with import $(pwd) {}; _nix-darwin-switch" --argstr host "gjallar")/bin/switch
```

---

## In this directory

### [configuration.nix](./configuration.nix)

This file defines the OS configuration for the `gjallar` machine.
