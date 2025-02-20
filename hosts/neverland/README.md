## TODO: 


## Quick Start

1. Enable WSL if you haven't done already:

- ```powershell
  wsl --install --no-distribution
  ```

2. Download `nixos-wsl.tar.gz` from [the latest release](https://github.com/nix-community/NixOS-WSL/releases/latest).

3. Import the tarball into WSL:

- ```
  wsl --import NixOS $env:USERPROFILE\NixOS\ nixos-wsl.tar.gz --version 2 --user jade
  (If re-installing run this first: wsl --unregister NixOS)
  ```

4. You can now run NixOS:

- ```powershell wsl -d NixOS```
  
## Changing the Default WSL User

To change the default user for your NixOS WSL distribution, follow these steps:

1. Change the ```wsl.defaultUser``` setting in your configuration to the desired username.
  ```/etc/nixos/configuration.nix```
2. Apply the configuration:
   ```sudo nixos-rebuild boot```
   Do not use ```nixos-rebuild switch```! It may lead to the new user account being misconfigured.
3. Exit the WSL shell and stop your NixOS distro:
   ```wsl -t NixOS```
4. Start a shell inside NixOS and immediately exit it to apply the new generation:
   ```wsl -d NixOS --user root exit```
5. Stop the distro again:
   ```wsl -t NixOS```
6. Open a WSL shell. Your new username should be applied now!


## Setup

```bash



# generate ssh key, add to github
ssh-keygen -o -a 100 -t ed25519 -C "jade@neverland"

# clone repo
nix-shell -p git
git clone git@github.com:fisherrjd/nix.git ~/cfg
cd ~/cfg

# initial switch. after this, you can use just `hms` to update!
$(nix-build --no-link --expr --extra-experimental-features flakes "with import $(pwd) {}; _nixos-switch" --argstr host "neverland")/bin/switch

```


---

## In this directory

### [configuration.nix](./configuration.nix)

This is an auto-generated file by [nixos-up](https://github.com/samuela/nixos-up) that configures disks and other plugins for nixos.
