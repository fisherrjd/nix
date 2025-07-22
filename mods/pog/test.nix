final: prev: {
  my_pog_script = final.pog {
    name = "my_pog_script";
    description = "A custom pog script";
    flags = [
      # define your flags here
    ];
    script = h: with h; ''
      echo "test" 
    '';
  };
}

