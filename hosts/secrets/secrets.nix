let
  constants = import ../../hosts/constants.nix;
  inherit (constants) dev;
in
{
  "litellm.age".publicKeys = dev;
  "openwebui.age".publicKeys = dev;
  "caddy.age".publicKeys = dev;
}
