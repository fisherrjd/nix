let
  inherit (constants) pubkeys hostkeys;
  constants = import ../hosts/constants.nix;
  # jade's keys, for editing with `agenix -e`
  default = with pubkeys; [ eldo airbook neverland ];
  # + the host key the server decrypts with at boot
  forEldo = default ++ [ hostkeys.eldo ];
  forBifrost = default ++ [ pubkeys.bifrost hostkeys.bifrost ];
in
{
  "litellm.age".publicKeys = forEldo;
  "openwebui.age".publicKeys = forEldo;
  "caddy.age".publicKeys = forBifrost;
  "grafana-secret-key.age".publicKeys = forEldo;
  "factory-github-app-key.age".publicKeys = forEldo;
  "ops-deployer-token.age".publicKeys = forEldo;
}
