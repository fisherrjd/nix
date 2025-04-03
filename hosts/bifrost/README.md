# Eldo

This is a bare-metal nixos server I am messing with

## Setup

```bash
# generate nix qcow 
nix build .#do-builder
# generate ssh key, add to github
ssh-keygen -o -a 100 -t ed25519 -C "jade@bifrost"

# clone repo
nix-shell -p git
git clone git@github.com:fisherrjd/nix.git ~/cfg
cd ~/cfg

# initial switch. after this, you can use just `hms` to update!
$(nix-build --no-link --expr "with import $(pwd) {}; _nixos-switch" --argstr host "bifrost")/bin/switch

# Tailscale Info
# advertise exit node 
# TODO learn more about these things

sudo tailscale up --advertise-exit-node
```

---

## In this directory

### [configuration.nix](./configuration.nix)
