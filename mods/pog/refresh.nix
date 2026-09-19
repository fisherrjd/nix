final: _:
let
  # Refresh script for a package whose version and hashes live inline in its
  # .nix file: `script` rewrites $target_file using the helpers below, then the
  # package is built and `verify` runs against the output. The old file is put
  # back if any of that fails. Wire the result into the package as
  # passthru.updateScript and list the attr in .github/workflows/update_pkgs.yml.
  mkCfgPackageRefresh =
    { name
    , attr
    , target
      # bash that sets $new_version and rewrites $target_file
    , script
      # bash run after the build, with $output and $new_version in scope
    , verify ? ""
    }:
    final.pog {
      inherit name;
      description = "update ${attr} to the latest (or given) version, build it, and verify it";
      runtimeInputs = with final; [ coreutils curl gnugrep jq nix nixpkgs-fmt perl ];
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
        repo="$(realpath -e -- "''${repo:-$HOME/cfg}")"
        target_file="$repo/${target}"
        backup="$(mktemp)"
        cp -- "$target_file" "$backup"
        restore() {
          status=$?
          if [ "$status" -ne 0 ]; then
            cp -- "$backup" "$target_file"
            echo "${name}: failed, restored ${target}" >&2
          fi
          rm -f -- "$backup"
        }
        trap restore EXIT

        # set_version <version>: rewrite the one `version = "..."` assignment
        set_version() {
          NEW="$1" perl -0pi -e '
            (s/^(\s*version = ")[^"]+(";)/$1 . $ENV{NEW} . $2/me) == 1
              or die "expected one version assignment\n";
          ' "$target_file"
        }

        # set_hash <attr name> <hash>: rewrite the first `hash = "..."` inside `<attr name> = {`
        set_hash() {
          KEY="$1" NEW="$2" perl -0pi -e '
            (s/(\b\Q$ENV{KEY}\E = \{.*?hash = ")[^"]+(";)/$1 . $ENV{NEW} . $2/se) == 1
              or die "expected a hash under $ENV{KEY}\n";
          ' "$target_file"
        }

        ${script}

        nixpkgs-fmt "$target_file" >/dev/null 2>&1
        if cmp --silent -- "$backup" "$target_file"; then
          echo "${name}: $new_version (up to date)"
          exit 0
        fi

        output="$(nix build "path:$repo#${attr}" --no-link --print-build-logs --print-out-paths)"
        ${verify}
        echo "${name}: verified ${attr} $new_version"
      '';
    };
in
rec {
  refresh_claude_code_latest = mkCfgPackageRefresh {
    name = "refresh_claude_code_latest";
    attr = "claude-code-latest";
    target = "packages/claude-code-latest.nix";
    # npm publishes an SRI sha512 per tarball, so nothing is downloaded to hash
    script = ''
      registry="https://registry.npmjs.org/@anthropic-ai"
      new_version="''${version:-$(curl -fsSL "$registry/claude-code/latest" | jq -er .version)}"
      set_version "$new_version"
      while IFS=$'\t' read -r system npm_platform; do
        hash="$(curl -fsSL "$registry/claude-code-$npm_platform/$new_version" | jq -er .dist.integrity)"
        if ! printf '%s\n' "$hash" | grep -Eq '^sha512-[A-Za-z0-9+/]{86}==$'; then
          echo "invalid hash for $system: $hash" >&2
          exit 1
        fi
        set_hash "$system" "$hash"
      done < <(nix eval --json "path:$repo#claude-code-latest.npmPlatforms" | jq -r 'to_entries[] | [.key, .value] | @tsv')
    '';
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
