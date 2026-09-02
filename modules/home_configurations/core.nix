# Core home-manager identity and base settings. Owns the canonical
# `home.sessionVariables`; other modules read individual values via
# `config.home.sessionVariables.<NAME>` rather than redefining them.
{ pkgs, hax, username, home-manager, ... }:
let
  inherit (hax) isLinux;

  homeDirectory =
    if isLinux then
      "/home/${username}"
    else
      "/Users/${username}";
in
{
  programs.home-manager.enable = true;
  programs.home-manager.path = "${home-manager}";

  # broken manpages upstream, see: https://github.com/nix-community/home-manager/issues/3342
  manual.manpages.enable = false;

  home = {
    inherit username homeDirectory;
    stateVersion = "22.11";
    sessionVariables = {
      BASH_SILENCE_DEPRECATION_WARNING = "1";
      EDITOR = "nano";
      GIT_SSH_COMMAND = "${pkgs.openssh}/bin/ssh";
      HISTCONTROL = "ignoreboth";
      # LC_CTYPE was falling back to "C" here: WezTerm sets no locale, and only the
      # eldo (NixOS) host had i18n configured. Hygiene, not a bug fix — tmux 3.7 was
      # verified to decode UTF-8 correctly either way, so this is not what caused the
      # mangled glyphs (that was missing font coverage for U+23BF / U+23FA).
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";
      LESS = "-iR";
      PAGER = "less";
    };
  };
}
