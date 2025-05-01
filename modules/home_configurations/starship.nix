{ config, pkgs, lib, ... }:
let
  promptChar = "> ";
in
{
  programs.starship.enable = true;
  programs.starship = {
    settings = {
      add_newline = false;
      character = {
        success_symbol = "[${promptChar}](bold green)";
        error_symbol = "[${promptChar}](bold red)";
      };
      directory = {
        style = "fg:#8b9467";
      };
      git_branch = {
        symbol = "\uF418 ";
        style = "fg:blue";
      };
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
        style = "bold bright-green";
      };
      username = {
        style_user = "bold fg:93";
      };
      python = {
        symbol = "\u🐍 ";
        style = "fg:blue";
      };
      rust = {
        symbol = "\u🦀 ";
        style = "fg:orange";
      };
      ruby = {
        symbol = "\u💎 ";
        style = "fg:blue";
      };
    };
  };
}
