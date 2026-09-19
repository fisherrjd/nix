# shellcheck shell=bash
# Library for *.lock.json files, sourced into the refresh_* pog scripts in
# refresh.nix. update_lock resolves the latest version and writes a
# {url, hash} per artifact, ready to pass to fetchurl.
#
# A lock file declares where things come from; version and sources are
# rewritten by update_lock:
#   {
#     "versionFrom": "npm:<package>" | "github:<owner>/<repo>",
#     "artifacts": {
#       "<key>": "npm:<package>"              hash comes from the registry, no download
#       "<key>": "https://.../{version}/..."  hash comes from nix store prefetch-file
#     }
#   }

npm_registry="https://registry.npmjs.org"

latest_version() {
  local auth=()
  case "$1" in
    npm:*) curl -fsSL "$npm_registry/${1#npm:}/latest" | jq -er .version ;;
    github:*)
      if [ -n "${GITHUB_TOKEN:-}" ]; then
        auth=(-H "Authorization: Bearer $GITHUB_TOKEN")
      fi
      curl -fsSL "${auth[@]}" "https://api.github.com/repos/${1#github:}/releases/latest" |
        jq -er .tag_name | sed 's/^[^0-9]*//'
      ;;
    *)
      echo "unknown versionFrom: $1" >&2
      return 1
      ;;
  esac
}

resolve_artifact() {
  local spec="$1" version="$2" url
  case "$spec" in
    npm:*)
      curl -fsSL "$npm_registry/${spec#npm:}/$version" |
        jq -e '{url: .dist.tarball, hash: .dist.integrity}'
      ;;
    *)
      url="${spec//\{version\}/$version}"
      nix store prefetch-file --json "$url" | jq -e --arg url "$url" '{url: $url, hash: .hash}'
      ;;
  esac
}

# update_lock <lock file> [version]
update_lock() {
  local lock="$1" old version sources="{}" key spec source
  old="$(jq -r '.version // "none"' "$lock")"
  version="${2:-$(latest_version "$(jq -er .versionFrom "$lock")")}"
  if [ "$old" = "$version" ]; then
    echo "$(basename "$lock"): $version (up to date)"
    return
  fi
  while IFS=$'\t' read -r key spec; do
    source="$(resolve_artifact "$spec" "$version")"
    sources="$(jq --arg k "$key" --argjson s "$source" '.[$k] = $s' <<<"$sources")"
  done < <(jq -r '.artifacts | to_entries[] | [.key, .value] | @tsv' "$lock")
  jq --arg v "$version" --argjson s "$sources" '.version = $v | .sources = $s' "$lock" >"$lock.tmp"
  mv "$lock.tmp" "$lock"
  echo "$(basename "$lock"): $old -> $version"
}
