{ config, pkgs, lib, ... }:
let promptChar = ">";
in
{
  # Enable the starship program system-wide
  programs.starship.enable = true;
  programs.starship = {
    settings = {
      add_newline = false;
      character = {
        success_symbol = "[${promptChar}](bright-green)";
        error_symbol = "[${promptChar}](bright-green)";
      };
      directory.style = "fg:#d442f5";
      nix_shell = {
        pure_msg = "";
        impure_msg = "";
        format = "via [$symbol$state($name)]($style) ";
      };
      kubernetes = {
        disabled = false;
        style = "fg:#326ce5";
      };

      nodejs = { symbol = "⬡ "; };
      hostname = {
        style = "bold bright-blue";
      };
      username = {
        style_user = "bold fg:93";
      };

    };
  };
}
