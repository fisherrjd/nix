{ common, ... }:
let
  common = import ../common.nix;
  authorizedKeys = builtins.attrValues common.pubkeys;

in
{

  # litellm
  # "litellm.age".publicKeys = common.pubkeys;
  # "openwebui.age".publicKeys = common.pubkeys;
  "secret1.age".publicKeys = authorizedKeys;
}
