final: prev:
let
  inherit (final) kubectl;  # This grabs kubectl from final
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
    case "$environment" in
      beta)
        echo "Restarting BETA environment..."
        ${kubectl}/bin/kubectl --context beta-gw-shared -n pinxt-dev rollout restart deployment pinxtgateway jwtfactory
        ${kubectl}/bin/kubectl --context dev-kops-shared -n pinxt-dev rollout restart deployment pinxtappservices
        ;;
        
      int)
        echo "Restarting INT environment..."
        ${kubectl}/bin/kubectl --context int-gw-shared -n pinxt-int rollout restart deployment pinxtgateway jwtfactory
        ${kubectl}/bin/kubectl --context dev-kops-shared -n pinxt-int rollout restart deployment pinxtappservices
        ;;
        
      stable)
        echo "Restarting STABLE environment..."
        ${kubectl}/bin/kubectl --context dev-gw-shared -n pinxt rollout restart deployment pinxtgateway jwtfactory
        ${kubectl}/bin/kubectl --context dev-kops-shared -n pinxt rollout restart deployment pinxtappservices
        ;;
        
      qa)
        echo "Restarting QA environment..."
        ${kubectl}/bin/kubectl --context qa-gw-shared -n pinxt rollout restart deployment pinxtgateway jwtfactory
        ${kubectl}/bin/kubectl --context qa-kops-shared -n pinxt rollout restart deployment pinxtappservices
        ;;
        
      uat)
        echo "Restarting UAT environment..."
        ${kubectl}/bin/kubectl --context uat-gw-shared -n pinxt rollout restart deployment pinxtgateway jwtfactory
        ${kubectl}/bin/kubectl --context uat-kops-shared -n pinxt rollout restart deployment pinxtappservices
        ;;
        
      *)
        echo "Invalid environment: $environment"
        echo "Valid environments: beta, int, stable, qa, uat"
        exit 1
        ;;
    esac
    
    echo "Restart completed for $environment"
  '';
  };

  k8s_pog_scripts = [
    krdb
  ];
}