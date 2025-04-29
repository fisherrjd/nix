# /home/jade/cfg/hosts/bifrost/configuration.nix (Temporary)
{ config, pkgs, lib, ... }: {
  imports = [ ]; # Make sure no other imports are causing trouble initially
  system.stateVersion = "23.11"; # Or your target version (e.g., "24.05") - THIS IS REQUIRED!
  networking.hostName = "bifrost-test";
  # Add a minimal bootloader config if needed for evaluation
  # boot.loader.grub.enable = true;
  # boot.loader.grub.device = "/dev/sda"; # Or "/dev/vda", etc.
}
