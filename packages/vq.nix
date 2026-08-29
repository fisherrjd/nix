{ lib
, stdenvNoCC
, bash
, coreutils
, findutils
, fzf
, gawk
, glab
, gnugrep
, gnused
, jq
, tmux
  # Absolute path to the SinchFunctions workspace root (the container: repos, docs,
  # .worktrees and the working_items vault). Overridable at runtime with VQ_WORKSPACE;
  # this is only the default baked into the script.
, workspacePath ? "/Users/jadfis/voice/functions"
}:

let
  runtimeDeps = [
    bash
    coreutils
    findutils
    fzf
    gawk
    glab
    gnugrep
    gnused
    jq
    tmux
  ];
in
stdenvNoCC.mkDerivation {
  pname = "vq";
  version = "0.1.0";

  src = ./vq;

  dontUnpack = true;
  dontBuild = true;

  # Deliberately not makeWrapper. vq re-invokes itself for the fzf --preview and
  # --bind actions, and a wrapper leaves $out/bin/.vq-wrapped reachable without
  # the wrapper's PATH; baking PATH and the self-path into the script keeps
  # those re-entrant calls identical to the top-level one.
  installPhase = ''
    runHook preInstall

    install -Dm755 $src/vq $out/bin/vq
    substituteInPlace $out/bin/vq \
      --replace-fail '@runtimePath@' '${lib.makeBinPath runtimeDeps}' \
      --replace-fail '@self@' "$out/bin/vq" \
      --replace-fail '@workspacePath@' '${workspacePath}'

    runHook postInstall
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ bash ];
  installCheckPhase = ''
    runHook preInstallCheck

    bash -n $out/bin/vq
    grep -q '@runtimePath@\|@self@\|@workspacePath@' $out/bin/vq \
      && { echo "unsubstituted placeholder left in vq"; exit 1; } || true

    runHook postInstallCheck
  '';

  meta = {
    description = "Item-centric tmux session picker for the SinchFunctions workspace";
    longDescription = ''
      Claude Squad's session TUI without its git worktree layer. The unit of work
      is an item, not a branch: one vault folder, a manifest declaring which repos
      it touches, and a worktree per repo under .worktrees. Agent sessions run with
      cwd at the workspace root so the vault, docs, every repo and every worktree
      resolve in one scope. Sources the picker from local item folders plus open
      GitLab items.
    '';
    license = lib.licenses.mit;
    mainProgram = "vq";
    platforms = lib.platforms.unix;
  };
}
