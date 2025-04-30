let
  # TODO Abstract keys properly from common
  # common = import ../common.nix;
  common = import ../common.nix;
in
{

  "litellm.age".publicKeys = common.pubkeys;
  "openwebui.age".publicKeys = common.pubkeys;
  "caddy.age".publicKeys = common.pubkeys;
}
