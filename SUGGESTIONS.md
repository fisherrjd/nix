# Configuration Review & Suggestions

A review of the `cfg/` Nix configuration with cleanup and improvement ideas.
Findings are grouped by priority. Each item lists the relevant `file:line` and a
concrete fix.

---

## 2. Correctness / latent bugs

### 2.1 Duplicate line in `.curlrc`
`home.nix:442-445` — `--netrc-optional` is written twice. Drop one.

### 2.2 `flake-compat` is used but not a declared input
`flake-compat.nix:4` reads `lock.nodes.flake-compat.locked`, but `flake-compat`
is **not** declared in `flake.nix` `inputs` — it only exists in `flake.lock` as a
transitive dependency. A future `nix flake update` that drops that transitive
node will break `default.nix` / `nix-build`. Add it explicitly:

```nix
inputs.flake-compat = { url = "github:edolstra/flake-compat"; flake = false; };
```

### 2.3 Wrong/inconsistent home dir in `nixPath`
`hosts/eldo/configuration.nix:104` and `hosts/bifrost/configuration.nix:23` set
`nixos-config=/home/fisherrjd/cfg/...`, but the user on both hosts is `jade`
(home `/home/jade`, e.g. the obsidian service uses `/home/jade/...`). `neverland`
correctly uses `/home/jade/`. These channel-style `nixPath` entries are mostly
dead under flakes (you switch via `hms` → `~/cfg#...`), so the cleanest fix is to
**drop the per-host `nixPath` override entirely** and centralize it.

---

## 3. Architecture — the biggest win

### 3.1 `common.nix` is a plain attrset, not a module
`hosts/common.nix` returns a big attrset that each host **cherry-picks** from:

```nix
nix      = common.nix // { nixPath = [...]; };      # eldo, bifrost, ...
services = { ... } // common.services;              # eldo
services = { ... } // common.services;              # neverland
security.sudo = common.security.sudo;               # eldo only
```

This bypasses the NixOS/nix-darwin **module merge system**, so:
- options can't be merged across files (you get last-wins `//` instead),
- many returned attrs are silently **never consumed** (see 3.2), and
- every host re-wires the same plumbing by hand.

**Recommendation:** turn `common.nix` into a real shared module and put it in each
host's `imports` list (the flake already imports `agenix.nixosModules.default`
the same way). Pass `flake`/`machine-name`/`username` via `specialArgs`. Then
hosts just `imports = [ ../common.nix ];` and override with normal option
priorities (`lib.mkDefault`/`mkForce`) instead of `//`.

### 3.2 Dead attrs in `common.nix`
Because of 3.1, these are defined but **no host applies them**:
- `sysctl_opts` (`common.nix:56-61`) — eldo hand-rolls its own `boot.kernel.sysctl`.
- `defaultLocale` / `extraLocaleSettings` (`63-75`) — eldo re-hardcodes the
  identical locale block at `hosts/eldo/configuration.nix:51-62`.
- `extraGroups` (`54`), `env` (`77`), `name` (`79-83`).

Once `common.nix` is a module, apply these centrally (`i18n.*`, `boot.kernel.sysctl`,
`users.users.<name>.extraGroups`) and delete the per-host copies.

### 3.3 `workbook` silently drops the shared cache
`hosts/workbook/configuration.nix:43-56` overrides `nix.extraOptions` **entirely**,
re-hardcoding the base options and the `fisherrjd.cachix.org` substituter — but
**losing** the `cache.g7c.us` substituter/key that `common.nix` provides to every
other host. Extend the common value instead of replacing it (another thing the
module refactor fixes for free).

---

## 4. Duplication to factor out

### 4.1 `sessionVariables` defined twice, verbatim
`home.nix:20-27` and `modules/home_configurations/git.nix:8-15` are identical
blocks; `git.nix` only uses `sessionVariables.EDITOR`. Either pass it in via
`_module.args` or just use `"nano"` directly in `git.nix`.

### 4.2 Name defined in three places
`firstName`/`lastName` appear in `home.nix:10-11` (unused there),
`git.nix:5-6`, and `common.nix:79-83` (`name.first`/`name.last`). Put it once in
`hosts/constants.nix` and `inherit` everywhere.

### 4.3 SSH hardening block copy-pasted
The `Ciphers`/`KexAlgorithms`/`MACs`/`HostKeyAlgorithms` lines are duplicated
across `mods/hax.nix:30-34` (`ssh.config`), `home.nix:340-343` (airbook) and
`home.nix:352-355` (workbook), plus the server side in `common.nix:113-129` and
`generators/do-builder/configuration.nix:51-64`. Define the lists once (e.g. in
`hax.nix` or `constants.nix`) and reference them on both client and server.

### 4.4 Duplicate packages in `home.nix`
- `kubectx` — `home.nix:94` (global) and again at `:176` (isWork).
- `claude-code` — `:153` (isLinux) and `:179` (isAirbook).
- `kubectl`/`kubectx`/`kubectx` cluster in the `isWork` block (`:168, :175-176`).

Deduplicate; keep tools that are truly global out of the per-host lists.

---

## 5. Dead code & unused arguments

  `home.nix:167`). Delete it or wire it in.
- `flake.nix:67` — a stray empty `{ }` module in the darwin `modules` list.
- `home.nix:10,12` — `firstName`/`lastName`/`promptChar` are unused (starship has
  its own `promptChar` in `starship.nix:2`).
- `modules/home_configurations/starship.nix:1` — takes `{ config, pkgs, lib, ... }`,
  none used.
- `modules/home_configurations/git.nix:1` — takes `username`, never used.
- Commented-out blocks worth removing or restoring: `bifrost` age/caddy
  (`:28-39, 73`), `airbook` llama-server (`:56-65`), `common_darwin.nix:12-20`,
  `neverland` docker-native (`:26-28`).

---

## 6. Lint (`statix`) — 8 warnings, all auto-fixable

Run `statix fix` from the repo root. Findings:
- **Repeated attribute keys** (6×): collapse the dotted assignments —
  `programs.*` (`home.nix:44-49`), `boot.*` (`eldo:19-21`), `networking.*`
  (`eldo:47-49`), `systemd.targets.*` (`eldo:108-111`), and others into nested
  sets.
- **Unnecessary concat with empty list** (`hosts/eldo/hardware-configuration.nix`).
- **Assignment instead of inherit** (`eldo:16` — `{ services = common.services; }`
  → `{ inherit (common) services; }`).

Consider adding `statix check` and `nixpkgs-fmt --check` to CI (see §7).

---

## 7. Flake & CI structure

### 7.1 Use `genAttrs` for host configs
`flake.nix:39-77` builds `nixosConfigurations`/`darwinConfigurations` with
`builtins.listToAttrs (map ...)`. `lib.genAttrs [ "neverland" ... ] (name: ...)`
is shorter and clearer. You could even derive the host list from
`builtins.readDir ./hosts`.

### 7.2 CI only builds 2 of 5 hosts
`.github/workflows/build.yml:13-19` builds only `eldo` and `airbook`. Add
`neverland` and `bifrost` to the matrix (both x86_64-linux). `workbook` needs
the Charter certs/secrets so it may stay local-only — note that explicitly.

### 7.3 Pin the cachix action
`.github/workflows/build.yml:27` uses `cachix/cachix-action@master` (the inline
comment even flags it). Pin to a release tag so it's reproducible and
dependabot-trackable.

### 7.4 Add format/lint gate
Add a cheap job running `nixpkgs-fmt --check .` and `statix check` so style/lint
regressions are caught in PRs (including the auto-update PRs from `update.yml`).

---

## 8. Misc hygiene

- `updated_script.sh` (root) — a one-off k8s pod-age script using macOS-only
  `date -j`. Move it under a `scripts/` dir or package it as a `pog` script next
  to `mods/pog/k8s.nix` so it's on PATH and version-pinned.
- `home.nix:191` — `home.stateVersion = "22.11"` while hosts are on `24.05`. Fine
  to leave (don't bump blindly), but worth a comment noting it's intentional.
- `README.md` is a stub — a short index linking `POG.md`, `MAC_README.md`, and the
  per-host READMEs would help future-you.
- `ignore` (root, used by fzf at `home.nix:311`) — consider naming it
  `.fzfignore` for discoverability.
- Lots of `# learn about this` / `TODO` notes (`gum`, `moreutils`, jacobi TODO in
  `flake.nix:6`) — harmless, but a quick pass to resolve or delete them tidies up.

---

## Suggested order of attack

1. **§1** rotate + agenix the ntfy key, tighten secret modes.
2. **§2** quick correctness fixes (curlrc, flake-compat input, nixPath).
3. **§6** `statix fix` + `nixpkgs-fmt` (mechanical, zero-risk).
4. **§3** the `common.nix` → module refactor (biggest structural payoff; unlocks
   §3.2/§3.3/§4 cleanups).
5. **§4–§5** dedupe and delete dead code.
6. **§7** tighten flake/CI.
