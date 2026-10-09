{ config, lib, pkgs, ... }:
let
  inherit (lib) literalExpression mkEnableOption filterAttrs mkIf mkOption types;
  inherit (lib) concatMapStringsSep escapeShellArg mapAttrs' nameValuePair optionalString;
  cfg = config.services.splash;
  defaultUser = "_splash";
  homeDir = "/private/var/lib/splash";
  splashName = name: "splash" + optionalString (name != "") ("-" + name);
  enabledServers = filterAttrs (name: conf: conf.enable) cfg.servers;
in
{
  options.services.splash = {
    servers = mkOption {
      type = types.attrsOf (types.submodule (_: {
        options = {
          enable = mkEnableOption "splash server launchd service";
          package = mkOption {
            type = types.package;
            default = pkgs.splash;
            defaultText = literalExpression "pkgs.splash";
            description = "The splash package to run.";
          };
          address = mkOption {
            type = types.str;
            default = "127.0.0.1";
            description = "The address to bind to. Anything but loopback should set apiKeyFile.";
          };
          port = mkOption {
            type = types.port;
            default = 8000;
            description = "The port to bind to.";
          };
          model = mkOption {
            type = types.str;
            example = "unsloth/Qwen3.8-27B-GGUF:UD-Q4_K_M";
            description = "Hugging Face model: OWNER/REPO, or a GGUF's OWNER/REPO:VARIANT. Downloaded on first start.";
          };
          apiKeyFile = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "File holding the API key (e.g. an agenix secret path). Read at start into SPLASH_API_KEY.";
          };
          extraFlags = mkOption {
            type = types.listOf types.str;
            default = [ ];
            example = [ "--max-memory" "28G" "--idle-release" "off" ];
            description = "Extra flags passed to `splash serve`.";
          };
        };
      }));
      default = { };
    };
    user = mkOption {
      type = types.str;
      default = defaultUser;
      description = "User under which to run splash. Models are downloaded into this user's home.";
    };
    group = mkOption {
      type = types.str;
      default = defaultUser;
      description = "Group under which to run splash.";
    };
    home = mkOption {
      type = types.str;
      default = homeDir;
      description = "HOME for the service: holds the Hugging Face cache and Splash's data directory.";
    };
  };

  config = mkIf (enabledServers != { }) {
    system.activationScripts = {
      launchd = {
        text = lib.mkBefore ''
          # shellcheck disable=SC2174
          ${pkgs.coreutils}/bin/mkdir -p -m 0750 ${cfg.home}
          # shellcheck disable=SC2174
          ${pkgs.coreutils}/bin/mkdir -p -m 0750 ${cfg.home}/log
          ${pkgs.coreutils}/bin/chown ${cfg.user}:${cfg.group} ${cfg.home}
          ${pkgs.coreutils}/bin/chown ${cfg.user}:${cfg.group} ${cfg.home}/log
        '';
      };
    };
    launchd.daemons = mapAttrs'
      (name: conf: nameValuePair (splashName name) (
        let
          serve = pkgs.writers.writeBash "splash-serve-${splashName name}" ''
            export HOME=${escapeShellArg cfg.home}
            ${optionalString (conf.apiKeyFile != null) ''
              SPLASH_API_KEY="$(<${escapeShellArg conf.apiKeyFile})"
              export SPLASH_API_KEY
            ''}
            exec ${lib.getExe conf.package} serve \
              --model ${escapeShellArg conf.model} \
              --host ${escapeShellArg conf.address} \
              --port ${toString conf.port} \
              ${concatMapStringsSep " " escapeShellArg conf.extraFlags}
          '';
        in
        {
          command = serve;
          serviceConfig = {
            GroupName = cfg.group;
            Label = "jade.splash.${splashName name}";
            RunAtLoad = true;
            KeepAlive = true;
            StandardOutPath = "${cfg.home}/log/${splashName name}.out";
            StandardErrorPath = "${cfg.home}/log/${splashName name}.err";
            UserName = cfg.user;
            WorkingDirectory = cfg.home;
          };
        }
      ))
      enabledServers;
    users = mkIf (cfg.user == defaultUser) {
      users."${cfg.user}" = {
        inherit (config.users.groups."${cfg.user}") gid;
        createHome = false;
        description = "splash service user";
        home = cfg.home;
        shell = "/bin/bash";
        uid = lib.mkDefault 801;
      };
      knownUsers = [ "${cfg.user}" ];
      groups."${cfg.user}" = {
        gid = lib.mkDefault 801;
        description = "splash service user group";
      };
      knownGroups = [ "${cfg.user}" ];
    };
  };
}
