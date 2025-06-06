{ pkgs, username, ... }:
let
  inherit (pkgs.hax) isDarwin isLinux isM1;

  firstName = "jade";
  lastName = "fisher";

  sessionVariables = {
    BASH_SILENCE_DEPRECATION_WARNING = "1";
    EDITOR = "nano";
    GIT_SSH_COMMAND = "${pkgs.openssh}/bin/ssh";
    HISTCONTROL = "ignoreboth";
    LESS = "-iR";
    PAGER = "less";
  };
in
{
  # gitconfig
  programs.git =
    let
      gs = text:
        let
          script = pkgs.writers.writeBash "git-script" ''
            set -eo pipefail
            cd -- ''${GIT_PREFIX:-.}
            ${text}
          '';
        in
        "! ${script}";
    in
    {
      enable = true;
      package = pkgs.gitAndTools.gitFull;
      userName = "${firstName} ${lastName}";
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
        cod = gs ''git co $(git default) "$@"'';
        st = "status";
        br = gs ''
          esc=$'\e'
          reset=$esc[0m
          red=$esc[31m
          yellow=$esc[33m
          green=$esc[32m
          git -c color.ui=always branch -vv "$@" | ${pkgs.gnused}/bin/sed -E \
            -e "s/: (gone)]/: $red\1$reset]/" \
            -e "s/[:,] (ahead [0-9]*)([],])/: $green\1$reset\2/g" \
            -e "s/[:,] (behind [0-9]*)([],])/: $yellow\1$reset\2/g"
          git --no-pager stash list
        '';
        brf = gs "git f --quiet && git br";
        f = "fetch --all";
        hide = "update-index --skip-worktree";
        unhide = "update-index --no-skip-worktree";
        hidden = "! git ls-files -v | grep '^S' | cut -c3-";
        branch-name = "!git rev-parse --abbrev-ref HEAD";
        default = gs "git symbolic-ref refs/remotes/origin/HEAD | sed s@refs/remotes/origin/@@";
        # Delete the remote version of the current branch
        unpublish = "!git push origin :$(git branch-name)";
        # Push current branch
        put = gs ''git push "$@"'';
        # Pull without merging
        get = "!git pull origin $(git branch-name) --ff-only";
        # update a branch without checkout
        gd = gs "git fetch origin $(git default):$(git default)";
        # Pull Master without switching branches
        got =
          "!f() { CURRENT_BRANCH=$(git branch-name) && git checkout $1 && git pull origin $1 --ff-only && git checkout $CURRENT_BRANCH;  }; f";
        gone = gs ''git branch -vv | ${pkgs.gnused}/bin/sed -En "/: gone]/s/^..([^[:space:]]*)\s.*/\1/p"'';
        # Recreate your local branch based on the remote branch
        recreate = ''
          !f() { [[ -n $@ ]] && git checkout master && git branch -D "$@" && git pull origin "$@":"$@" && git checkout "$@"; }; f'';
        reset-submodule = "!git submodule update --init";
        s = gs "git br && git -c color.status=always status | grep -E --color=never '^\\s\\S|:$' || true";
        sl = "!git --no-pager log -n 15 --oneline --decorate";
        sla = "log --oneline --decorate --graph --all";
        lol = "log --graph --decorate --pretty=oneline --abbrev-commit";
        lola = "log --graph --decorate --pretty=oneline --abbrev-commit --all";
        shake = "remote prune origin";
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
          editor = sessionVariables.EDITOR;
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

