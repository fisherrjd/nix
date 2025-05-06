let
  inherit (constants) pubkeys;
  constants = import ../hosts/constants.nix;
  default = with pubkeys; [ eldo airbook neverland biforst ];
in
{
  "litellm.age".publicKeys = default;
  "openwebui.age".publicKeys = default;
  "caddy.age".publicKeys = default;
}
