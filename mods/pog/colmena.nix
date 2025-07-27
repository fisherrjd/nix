final: prev: {
  colb = final.pog {
    name = "cola";
    description = "Run colmena build on a target host";
    flags = [
      {
        name = "host";
        description = "Target host for colmena build";
        required = true;
      }
    ];
    script = h: with h; ''
      cd ~/cfg/colmena
      colmena build --on $host
    '';
  };
}

