let
  constants = import ../../hosts/constants.nix;
  # inherit (constants) dev;
in
{
  "litellm.age".publicKeys = constants.dev;
  "openwebui.age".publicKeys = constants.dev;
  "caddy.age".publicKeys = constants.dev;
}
