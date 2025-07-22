final: prev: {
  pog_test = final.pog {
    name = "pog_test";
    description = "A custom pog script";
    flags = [
      # define your flags here
    ];
    script = h: with h; ''
      echo "test" 
    '';
  };
}

