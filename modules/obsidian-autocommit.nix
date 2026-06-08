# modules/obsidian-autocommit.nix
{ config, lib, pkgs, ... }:
let
  cfg = config.services.obsidian-autocommit;

in
{
  options.services.obsidian-autocommit = {
    enable = lib.mkOption { type = lib.types.bool; default = false; };
    user = lib.mkOption { type = lib.types.str; default = "jade"; };
    repoPath = lib.mkOption { type = lib.types.path; default = "/home/jade/syncthing/obsidian"; };
    interval = lib.mkOption { type = lib.types.str; default = "hourly"; };
    gitName = lib.mkOption { type = lib.types.str; default = "eldo"; };
    gitEmail = lib.mkOption { type = lib.types.str; default = "fisherrjd@gmail.com"; };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.obsidian-autocommit = {
      path = [ pkgs.git pkgs.openssh ];
      script = ''
        cd ${cfg.repoPath}
        git add -A
        if git diff --cached --quiet; then exit 0; fi
        git -c user.name="${cfg.gitName}" -c user.email="${cfg.gitEmail}" \
          commit -m "auto: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        git push
      '';
      serviceConfig.User = cfg.user;
      serviceConfig.Type = "oneshot";
      startAt = cfg.interval;
    };
  };

}
