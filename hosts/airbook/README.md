# Airbook

Personal M1 Mackbook Air

## Setup

```bash
# install nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
  sh -s -- install

# generate ssh key
ssh-keygen -o -a 100 -t ed25519 -C "fisherrjd@airbook"

# clone repo
nix-shell -p git
git clone git@github.com:fisherrjd/nix.git ~/cfg
cd ~/cfg

# initial switch. after this, you can use just `hms` to update!
$(nix-build --no-link --expr "with import $(pwd) {}; _nix-darwin-switch" --argstr host "airbook")/bin/switch


# Tailscale Enable
sudo tailscale up 
```

---

## In this directory

### [configuration.nix](./configuration.nix)

This file defines the OS configuration for the `airbook` machine.

### [hardware-configuration.nix](./hardware-configuration.nix)

This is an auto-generated file by [nixos-up](https://github.com/samuela/nixos-up) that configures disks and other plugins for nixos.
