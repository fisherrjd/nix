let
  inherit (constants) pubkeys;
  constants = import ../hosts/constants.nix;
  dev = with pubkeys; [ eldo atlantis bifrost airbook ];

in
{

  "litellm.age".publicKeys = dev;
  "openwebui.age".publicKeys = dev;
  "caddy.age".publicKeys = dev;
}
