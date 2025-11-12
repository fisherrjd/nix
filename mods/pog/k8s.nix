final: prev:
let
  inherit (final) colmena;
in
rec {
  colb = final.pog {
    name = "colb";
    description = "Run colmena build on a target host";
    flags = [
      {
        name = "destination";
        description = "Target host for colmena build";
        required = true;
      }
    ];
    script = ''
      cd ~/cfg/colmena || exit
      ${colmena}/bin/colmena build --on "$destination"
    '';
  };

    krdb = final.pog {
    name = "krdb";
    description = "Restart gateway, appservice, jwtfactory in a specific environment ";
    flags = [
      {
        name = "environment";
        description = "Target environment for pod restarts";
        required = true;
      }
    ];
    script = ''
      cd ~/cfg/colmena || exit
      ${colmena}/bin/colmena build --on "$destination"
    '';
  };

  k8s_pog_scripts = [
    krdb
  ];
}

