let
  inherit (constants) pubkeys;
  constants = import ../hosts/constants.nix;
  default = with pubkeys; [ eldo airbook neverland ];
in
{
  "litellm.age".publicKeys = default;
  "openwebui.age".publicKeys = default;
  "caddy.age".publicKeys = default;
  "github-runner-token.age".publicKeys = default;
}
