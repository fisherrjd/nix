# eldo

This is a bare-metal nixos server I am messing with 

## bootstrap

```bash
# load nixos iso
Boot USB 

# generate ssh key, add to github
ssh-keygen -o -a 100 -t ed25519 -C "fisherrjd@eldo"

# clone repo
nix-shell -p git
git clone git@github.com:fisherrjd/nix.git ~/cfg
cd ~/cfg

# initial switch. after this, you can use just `hms` to update!
$(nix-build --no-link --expr "with import $(pwd) {}; _nixos-switch" --argstr host "eldo")/bin/switch

# Tailscale Info
# advertise exit node 
# TODO learn more about these things

sudo tailscale up --advertise-exit-node
```

---

## In this directory

### [configuration.nix](./configuration.nix)

This file defines the OS configuration for the `eldo` machine.

### [hardware-configuration.nix](./hardware-configuration.nix)

This is an auto-generated file by [nixos-up](https://github.com/samuela/nixos-up) that configures disks and other plugins for nixos.