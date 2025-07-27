final: prev: {
  colb = final.pog {
    name = "colb";
    description = "Run colmena build on a target host";
    flags = [
      {
        name = "host";
        description = "Target host for colmena build";
        required = true;
      }
    ];
    script = h: with h; ''
      "cd ~/cfg/colmena || exit"
      "colmena build --on $host"
    '';
  };
}

