final: prev:
let
  inherit (final) kubectl;
  
  envConfig = {
    beta = { gwContext = "beta-gw"; kopsContext = "dev-kops-shared"; namespace = "pinxt-dev"; };
    int = { gwContext = "int-gw"; kopsContext = "dev-kops-shared"; namespace = "pinxt-int"; };
    stable = { gwContext = "dev-gw"; kopsContext = "dev-idp-shared"; namespace = "pinxt"; };
    qa = { gwContext = "qa-gw"; kopsContext = "qa-idp-shared"; namespace = "pinxt"; };
    uat = { gwContext = "uat-gw"; kopsContext = "uat-kops-shared"; namespace = "pinxt"; };
    # perf1 = { gwContext = "perf1-gw-eks"; kopsContext = "perf1-idp-eks"; namespace = "pinxt"; };
    perf2 = { gwContext = "perf2-gw-eks"; kopsContext = "perf2-idp-eks"; namespace = "pinxt"; };
    # perf3 = { gwContext = "perf3-gw-eks"; kopsContext = "perf3-idp-eks"; namespace = "pinxt"; };

  };
in
rec {

  krdb = final.pog {
    name = "krdb";
    description = "Restart gateway, appservice, jwtfactory in a specific environment";
    flags = [
      {
        name = "environment";
        short = "e";
        description = "Target environment for pod restarts";
        required = true;
        completion = ''echo "beta int stable qa uat"'';
      }
      {
        name = "gateway";
        short = "g";
        description = "Target which gateway for pod restarts";
        required = false;
        completion = ''echo "video shared sgui"'';
      }
    ];
    
  script = helpers: with helpers; ''
    set -euo pipefail
    
    ENV_CONFIG='${builtins.toJSON envConfig}'
    
    config=$(echo "$ENV_CONFIG" | ${final.jq}/bin/jq -r --arg env "$environment" '.[$env] // empty')
    if [ -z "$config" ]; then
      echo "Invalid environment: $environment"
      echo "Valid environments: beta, int, stable, qa, uat"
      exit 1
    fi
    
    gw_context=$(echo "$config" | ${final.jq}/bin/jq -r '.gwContext')
    kops_context=$(echo "$config" | ${final.jq}/bin/jq -r '.kopsContext')
    namespace=$(echo "$config" | ${final.jq}/bin/jq -r '.namespace')
    gateway_type="''${gateway:-shared}"
    
    echo "Restarting $environment environment (gateway: $gateway_type)..."
    
    ${kubectl}/bin/kubectl --context "$gw_context-$gateway_type" -n "$namespace" rollout restart deployment pinxtgateway jwtfactory
    ${kubectl}/bin/kubectl --context "$kops_context" -n "$namespace" rollout restart deployment pinxtappservices
    
    echo "Restart completed for $environment"
  '';
  };

  k8s_pog_scripts = [
    krdb
  ];
}
