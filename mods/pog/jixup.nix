# A pog wrapper around jacobi's `nixup`.
#
# nixup is entirely env-var driven (see lines 66-90 of the nixup script:
# POG_REPO, POG_BRANCH, POG_UPDATE, POG_WITH_*). So jixup declares each nixup
# option as a real pog flag -- giving proper `--help` and bare usage like
# `jixup --with_uv --with_golang` -- and just maps every flag to its env var.
#
# The `--with_*` flags are generated from `withPkgs`, so we never hand-maintain
# 21 near-identical arms; jixup-only addons go in `addonFlags`.
# Instantiated in packages.nix with pog (builder) + jacobi nixup + lib.
{ pog, nixup, lib }:
let
  inherit (lib) toUpper map concatMapStringsSep;

  # CHANGE ME: your fork of jpetrucciani/nix (must be a fork so the
  # generated default.nix can resolve jfmt/nixup/hax/etc.)
  defaultRepo = "fisherrjd/nix";

  # every `--with_X` nixup supports (mirrors nixup's own list)
  withPkgs = [
    "bun" "crystal" "db_pg" "db_redis" "dotnet" "elixir" "golang" "java"
    "nim" "node" "nvidia" "ocaml" "php" "poetry" "pulumi" "python" "ruby"
    "rust" "terraform" "uv" "vlang"
  ];

  withFlags = map
    (s: { name = "with_${s}"; short = ""; bool = true; description = "include ${s}"; })
    withPkgs;

  # `[ -n "$with_uv" ] && export POG_WITH_UV=1` for each
  withExports = concatMapStringsSep "\n"
    (s: ''[ -n "$with_${s}" ] && export POG_WITH_${toUpper s}=1'')
    withPkgs;

  # jixup-only addons live here
  addonFlags = [
    { name = "envrc"; bool = true; description = "also drop a direnv .envrc (if absent)"; }
  ];
in
pog {
  name = "jixup";
  description = "nixup, pinned to my fork + a few addons";
  runtimeInputs = [ nixup ];
  flags = [
    { name = "repo"; short = "r"; default = defaultRepo; description = "GitHub repo to pin (owner/repo)"; }
    { name = "branch"; short = "b"; default = "main"; description = "branch to pin to"; }
    { name = "srcpath"; short = "s"; default = ""; description = "fs path to import pkgs from"; }
    { name = "update"; short = "u"; bool = true; description = "update the pin in ./default.nix"; }
  ] ++ withFlags ++ addonFlags;
  script = ''
    # jixup flags -> nixup's env-var interface (lines 66-90 of nixup)
    export POG_REPO="$repo"
    export POG_BRANCH="$branch"
    [ -n "$srcpath" ] && export POG_SRCPATH="$srcpath"

    if [ -n "$update" ]; then
      export POG_UPDATE=1
      nixup            # edits ./default.nix in place and exits
      exit $?
    fi

    ${withExports}
    nixup              # streams default.nix to stdout, like nixup

    if [ -n "$envrc" ] && [ ! -f .envrc ]; then
      printf 'watch_file default.nix\nuse nix\n' > .envrc
    fi
  '';
}
