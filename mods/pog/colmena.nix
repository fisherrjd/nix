final: prev:
let
  inherit (final) colmena;
in
{
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
}

