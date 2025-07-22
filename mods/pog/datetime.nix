# This is a standalone pog script module for a simple utility: showing the current date and time.
final: prev:
with prev;
rec {
  pog_datetime = pog {
    name = "datetime";
    description = "show the current date and time";
    flags = [ ];
    script = ''
      date
    '';
  };
}
