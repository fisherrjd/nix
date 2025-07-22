final: prev: {
  __test = final.pog {
    name = "__test";
    description = "A custom pog script";
    flags = [
      # define your flags here
    ];
    script = h: with h; ''
      echo "test" 
    '';
  };
}

