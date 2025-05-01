{ config, ... }:
{
  programs.git = {
    enable = true;
    package = config.pkgs.gitAndTools.gitFull;
    userName = "${config.firstName} ${config.lastName}";
    userEmail = "fisherrjd@gmail.com";
    aliases = {
      A = "add -A";
      pu = "pull";
      pur = "pull --rebase";
      cam = "commit -am";
      ca = "commit -a";
      cm = "commit -m";
      ci = "commit";
      co = "checkout";
      # ... (rest of aliases)
    };
    extraConfig = {
      checkout.defaultRemote = "origin";
      color.ui = true;
      fetch.prune = true;
      init.defaultBranch = "main";
      pull.ff = "only";
      push.default = "simple";
      rebase.instructionFormat = "<%ae >%s";
      core = {
        editor = config.sessionVariables.EDITOR;
        pager = "delta --dark";
        autocrlf = "input";
        hooksPath = "/dev/null";
      };
      delta = {
        navigate = true;
        line-numbers = true;
        side-by-side = true;
        line-numbers-left-format = "";
        line-numbers-right-format = "│ ";
      };
      push = {
        autoSetupRemote = true;
      };
    };
  };
}
