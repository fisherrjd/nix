let
  inherit (constants) pubkeys;
  constants = import ../hosts/constants.nix;
  default = with pubkeys; [ eldo airbook neverland ];
in
{
  "litellm.age".publicKeys = default;
  "openwebui.age".publicKeys = default;
  "caddy.age".publicKeys = default ++ [ pubkeys.bifrost ];
  "grafana-secret-key.age".publicKeys = default;
  "factory-github-app-key.age".publicKeys = default;
  "ops-deployer-token.age".publicKeys = default;
}
