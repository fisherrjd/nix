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

  cola = final.pog {
    name = "cola";
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

  colmena_pog_scripts = [
    cola
    colb
  ];
}

