final: _:
let
  # Refresh script for a package driven by a *.lock.json (see update-lock.sh):
  # bump the lock, build the package, run `verify` against the output, and put
  # the old lock back if any of that fails. Wire the result into the package as
  # passthru.updateScript and list the attr in .github/workflows/update_pkgs.yml.
  mkLockRefresh =
    { name
    , attr
    , lock
      # bash run after the build, with $output and $new_version in scope
    , verify ? ""
    }:
    final.pog {
      inherit name;
      description = "update ${attr} to the latest (or given) version, build it, and verify it";
      runtimeInputs = with final; [ coreutils curl gnused jq nix ];
      flags = [
        {
          name = "version";
          short = "";
          description = "target version; defaults to the latest release";
        }
        {
          name = "repo";
          envVar = "CFG_REPO";
          description = "cfg checkout to update; defaults to $HOME/cfg";
        }
      ];
      script = ''
        set -euo pipefail
        ${builtins.readFile ./update-lock.sh}
        repo="$(realpath -e -- "''${repo:-$HOME/cfg}")"
        lock_file="$repo/${lock}"
        backup="$(mktemp)"
        cp -- "$lock_file" "$backup"
        restore() {
          status=$?
          if [ "$status" -ne 0 ]; then
            cp -- "$backup" "$lock_file"
            echo "${name}: failed, restored ${lock}" >&2
          fi
          rm -f -- "$backup" "$lock_file.tmp"
        }
        trap restore EXIT

        update_lock "$lock_file" "$version"
        if cmp --silent -- "$backup" "$lock_file"; then
          exit 0
        fi

        new_version="$(jq -er .version "$lock_file")"
        output="$(nix build "path:$repo#${attr}" --no-link --print-build-logs --print-out-paths)"
        ${verify}
        echo "${name}: verified ${attr} $new_version"
      '';
    };
in
rec {
  refresh_claude_code_latest = mkLockRefresh {
    name = "refresh_claude_code_latest";
    attr = "claude-code-latest";
    lock = "packages/claude-code-latest.lock.json";
    verify = ''
      reported="$("$output/bin/claude" --version)"
      case "$reported" in
        "$new_version "*) ;;
        *)
          echo "expected claude $new_version, binary reports: $reported" >&2
          exit 1
          ;;
      esac
    '';
  };

  refresh_pog_scripts = [
    refresh_claude_code_latest
  ];
}
