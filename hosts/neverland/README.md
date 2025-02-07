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
  ```

4. You can now run NixOS:

- ```powershell
  wsl -d NixOS
  ```
