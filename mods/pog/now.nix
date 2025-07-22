# this file provides a simple pog script to print the current date and time
final: prev: {
  now = final.pog {
    name = "now";
    description = "print the current date and time";
    flags = [ ];
    script = ''
      date
    '';
  };
}
