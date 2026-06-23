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
      LESS = "-iR";
      PAGER = "less";
    };
  };
}
