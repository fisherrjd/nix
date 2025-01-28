final: prev:
let
  git = "${prev.git}/bin/git";
in
rec {
  inherit (prev) nvd writeShellScriptBin;
  inherit (prev.stdenv) isDarwin isLinux;

  flags = "--extra-experimental-features nix-command --extra-experimental-features flakes";

  ### GENERAL STUFF
  _nixos-switch = { host }: writeShellScriptBin "switch" ''
    toplevel="$(nix build ${flags} --no-link --print-out-paths ~/cfg#nixosConfigurations.${host}.config.system.build.toplevel)"
    ${nvd}/bin/nvd diff /run/current-system "$toplevel"
    sudo nix-env -p /nix/var/nix/profiles/system --set "$toplevel"
    sudo "$toplevel"/bin/switch-to-configuration switch
    
  '';
  _nix-darwin-switch = { host }:
    writeShellScriptBin "switch" ''
      profile=/nix/var/nix/profiles/system
      toplevel="$(nix build ${flags} --no-link --print-out-paths ~/cfg#darwinConfigurations.${host}.system)"
      ${nvd}/bin/nvd diff "$profile" "$toplevel"
      sudo -H nix-env -p "$profile" --set "$toplevel"
      "$toplevel"/activate-user
      sudo "$toplevel"/activate
    '';
  _hms = {
    default = ''
      ${git} -C ~/cfg/ pull origin main
      home-manager switch
    '';
    nixOS = ''
      ${git} -C ~/cfg/ pull origin main
      "$(nix-build --no-link --expr 'with import ~/cfg {}; _nixos-switch' --argstr host "$(machine-name)")"/bin/switch
    '';
    darwin = ''
      ${git} -C ~/cfg/ pull origin main
      "$(nix-build --no-link --expr 'with import ~/cfg {}; _nix-darwin-switch' --argstr host "$(machine-name)")"/bin/switch
    '';
    switch = if isLinux then _hms.nixOS else (if isDarwin then _hms.darwin else _hms.default);
  };

  hms = writeShellScriptBin "hms" _hms.switch;
}
