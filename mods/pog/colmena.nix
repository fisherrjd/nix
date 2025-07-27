final: prev: {
  colb = final.pog {
    name = "cola";
    description = "Run colmena apply on a target host";
    flags = [
      {
        name = "host";
        description = "Target host for colmena apply";
        required = true;
      }
    ];
    script = h: with h; ''
      cd ~/cfg/colmena
      colmena build --on ${h.host}
    '';
  };
}

