## TODO: 


## Quick Start

1. Enable WSL if you haven't done already:

- ```powershell
  wsl --install --no-distribution
  ```

2. Download `nixos-wsl.tar.gz` from [the latest release](https://github.com/nix-community/NixOS-WSL/releases/latest).

3. Import the tarball into WSL:

- ```powershell
  wsl --import NixOS $env:USERPROFILE\NixOS\ nixos-wsl.tar.gz --version 2
  (If re-installing run this first: wsl --unregister NixOS)
  ```

4. You can now run NixOS:

- ```powershell
  wsl -d NixOS
  ```


## Setup

```bash

# generate ssh key, add to github
ssh-keygen -o -a 100 -t ed25519 -C "jade@neverland"

# clone repo
nix-shell -p git
git clone git@github.com:fisherrjd/nix.git ~/cfg
cd ~/cfg

# initial switch. after this, you can use just `hms` to update!
$(nix-build --no-link --expr "with import $(pwd) {}; _nixos-switch" --argstr host "neverland")/bin/switch

```


---

## In this directory

### [configuration.nix](./configuration.nix)

This is an auto-generated file by [nixos-up](https://github.com/samuela/nixos-up) that configures disks and other plugins for nixos.
