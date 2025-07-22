# this file provides a simple pog script to print the current date and time
final: prev: {
  datetime = final.pog {
    name = "datetime";
    description = "print the current date and time";
    flags = [ ];
    script = ''
      date
    '';
  };
}
