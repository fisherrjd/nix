# Configuration Review & Suggestions

A review of the `cfg/` Nix flake with cleanup and improvement ideas, written as a
learning roadmap. Findings are ordered **correctness first**, then cheap
mechanical wins, then the one structural change that pays for itself, then
deduplication / CI / hygiene.

Every item lists the real `file:line` (verified against the current tree, June
2026) and a concrete fix. Where it teaches a Nix concept, there's a short **Why**.

Hosts in scope: **neverland**, **eldo**, **bifrost** (NixOS) and **airbook**,
**gjallar** (nix-darwin). `workbook` is being retired — see §3.

---

## 1. Correctness / latent bugs

### 1.1 `nixPath` points at a user that doesn't exist
`hosts/eldo/configuration.nix:107` and `hosts/bifrost/configuration.nix:23` set
`nixos-config=/home/fisherrjd/cfg/...`, but the user on both hosts is `jade`
(everything else uses `/home/jade`). `neverland` is correct (`:67`).

These channel-style `nixPath` entries are mostly dead weight under flakes — you
switch via `hms` → `~/cfg#<host>`, not via `<nixos-config>`. Cleanest fix: **drop
the per-host `nixPath` override entirely**. If you want to keep it, fix the user.

> **Why:** `nixPath` feeds the old `<...>` channel lookup (`import <nixos-config>`).
> Flakes pin inputs explicitly, so a stale `nixPath` mostly just misleads future-you.

### 1.2 `flake-compat` is used but not a declared input
`flake-compat.nix:4` reads `lock.nodes.flake-compat.locked`, and `default.nix:1`
defaults `flake` to `import ./flake-compat.nix`. But `flake-compat` is **not** in
`flake.nix` `inputs` — it only exists in `flake.lock` as a *transitive* node. A
future `nix flake update` that drops that transitive node breaks `nix-build` /
`default.nix`. Declare it:

```nix
inputs.flake-compat = { url = "github:edolstra/flake-compat"; flake = false; };
```

### 1.3 `gjallar` silently drops the shared binary cache
`hosts/gjallar/configuration.nix:56-62` overrides `nix.extraOptions` **entirely**,
re-hardcoding the base options and only the `fisherrjd.cachix.org` substituter —
**losing** the `cache.g7c.us` substituter/key that `common.nix:31-35` provides to
every other host. (`workbook` had the same bug; it's leaving anyway. `airbook`
does *not* override `extraOptions`, so it keeps the cache.)

Extend the common value instead of replacing it. The `common.nix` → module
refactor in §4 fixes this for free (you'd append with normal option merging
instead of `//`).

### 1.4 Postgres+TimescaleDB bundled version drift on eldo

`hosts/eldo/configuration.nix` resolved `pkgs.postgresql_16` through the
unstable `nixpkgs` input. The bundled `timescaledb.so` inside that derivation
moves whenever upstream nixpkgs bumps it (2.27.2 → 2.28.0 in 2026-07). Because
the `ge-data` DB records its extension version in `pg_extension`, any silent
bump bricks all connections to `ge-data` with
`ERROR: could not access file "$libdir/timescaledb-<old>": No such file or directory`.

Fixed in `flake.nix` by adding a dedicated `nixpkgs-postgresql` input pinned
to the postgresql_16 commit that ships timescaledb 2.27.2
(`567a49d1913ce81ac6e9582e3553dd90a955875f`), and using it exclusively in the
eldo postgres service. CI check (`.github/workflows/check-postgres-pin.yml`)
fails if the unstable input ever drifts from the pinned one. Full write-up:
`.hermes/plans/2026-07-05-fix-ge-data-timescaledb-mismatch.md`.

---

## 2. Quick mechanical wins (zero/low risk)

### 2.1 `statix` — 10 warnings, all auto-fixable
Run `statix fix` from the repo root. Current findings:

- **Repeated attribute keys** (collapse dotted assigns into nested sets):
  `home.nix:47` (`programs.*`), `hosts/eldo/configuration.nix:20` (`boot.*`),
  `:52` (`networking.*`), `:111` (`systemd.targets.*`),
  `hosts/bifrost/configuration.nix:45` (`networking.*`),
  `hosts/gjallar/configuration.nix:19` (`environment.*`),
  `hosts/eldo/hardware-configuration.nix:12` (`boot.*`).
- **Assignment instead of inherit**: `hosts/eldo/configuration.nix:17` —
  `{ services = common.services; }` → `{ inherit (common) services; }`.
- **Module header lints**: `modules/home_configurations/starship.nix:1`,
  `modules/home_configurations/tmux.nix:1`.

### 2.2 Formatting is already clean — keep it that way
`nixpkgs-fmt --check .` reports `0 / 29` files needing reformatting today. Nothing
to fix; just add the check to CI so it stays green (see §6.4).

### 2.3 Drop the stray empty module
`flake.nix:68` — a literal `{ }` sits in the darwin `modules` list. Harmless, but
delete it.

### 2.4 Delete confirmed dead code
- `mods/hax.nix:12-36` — `ssh.config` and `ssh.mac_meme` are **never referenced**
  (only `hax.ssh.github` is used, at `modules/home_configurations/ssh.nix:53`).
  The whole hardened `Host *` block in `hax.nix` is dead — the live client config
  is in `ssh.nix`. Delete `ssh.config`/`ssh.mac_meme`.
- `hosts/constants.nix:11-23` — `pubkeys.dev`, `pubkeys.work`, `pubkeys.all` are
  unused; every host inlines `with common.pubkeys; [ atlantis ... ]`. Drop the
  lists (or start using them — see §5.1).
- `hosts/common_darwin.nix:3,5` — `subtractLists` and the `work` binding are
  `inherit`ed but never used; `mkDefault` (`:4`) too.
- Dead attrs in `common.nix` — see §4.2.
- Commented-out blocks worth removing or restoring: `bifrost:28-39` (age/caddy),
  `airbook:56-65` (llama-server), `neverland:25-28` (docker-native),
  `common_darwin.nix:12-20`.

---

## 3. Retire the `workbook` host

`workbook` is being removed. It's referenced in 7 places — delete all of them so
the flake still evaluates:

- `hosts/workbook/` — the whole directory (incl. the Charter `certs/`).
- `flake.nix:78` — remove `"workbook"` from the darwin host list.
- `hosts/constants.nix:6` — remove the `workbook` pubkey; `:19` — remove it from
  the `work` list (or delete the list per §2.4).
- `openssh.authorizedKeys.keys` lists that trust it:
  `hosts/eldo/configuration.nix:76`, `hosts/bifrost/configuration.nix:57`,
  `hosts/airbook/configuration.nix:35`.

After this, the work-only bits (Charter `security.pki.certificates`, the
`microcks`/`cassandra` brews) leave with it.

---

## 4. Architecture — the biggest learning win

### 4.1 `common.nix` is a plain attrset, not a module
`hosts/common.nix` returns a big attrset that each host **cherry-picks** from with
`//` and field access:

```nix
nix      = common.nix // { nixPath = [...]; };   # eldo:104, neverland:64, airbook:42, gjallar:50
services = { ... } // common.services;           # neverland:43-45
{ inherit (common) services; }                   # eldo:17 (as an import)
security.sudo = common.security.sudo;            # eldo:87 only
home-manager.users.<u> = common.jade;            # every host
```

This bypasses the NixOS / nix-darwin **module merge system**, so:
- options can't merge across files — you get last-wins `//` instead;
- many returned attrs are silently **never consumed** (§4.2);
- hardening only reaches whoever remembered to wire it — e.g.
  `common.security.sudo` (NOPASSWD + `env_keep`) is applied **only on eldo**;
  bifrost re-rolls its own `wheelNeedsPassword`, neverland gets neither.

**You already have the pattern right next door:** `hosts/common_darwin.nix` *is* a
real module (`options.conf.work` + `config = { ... }`) and is imported cleanly at
`flake.nix:67`. Do the same for `common.nix`.

**Recommendation:** turn `common.nix` into a shared module and put it in each
host's `imports` (the flake already imports `agenix.nixosModules.default` the same
way). Pass `flake`/`machine-name`/`username` via `specialArgs` (they're already
there). Hosts then just `imports = [ ../common.nix ];` and override with normal
priorities (`lib.mkDefault` / `lib.mkForce`) instead of `//`.

> **Why this is the big one:** the module system is *the* core Nix idea — options
> declared once, values merged from many files by priority. `//` is a dumb
> attribute-set overwrite that knows nothing about NixOS options, which is why
> §1.3 (gjallar) and the eldo-only sudo rule happen. Converting `common.nix` makes
> those classes of bug structurally impossible and deletes most of §4.2/§5.

### 4.2 Dead attrs in `common.nix` (caused by 4.1)
Because nothing imports `common.nix` as a module, these are defined but **no host
applies them**:
- `extraGroups` (`common.nix:54`)
- `sysctl_opts` (`:56-61`) — eldo hand-rolls its own `boot.kernel.sysctl:22-26`.
- `defaultLocale` / `extraLocaleSettings` (`:63-75`) — eldo re-hardcodes the
  *identical* locale block at `hosts/eldo/configuration.nix:56-67`.
- `env` (`:77`), `name` (`:79-83`).

Once `common.nix` is a module, apply these centrally (`i18n.*`,
`boot.kernel.sysctl`, `users.users.<name>.extraGroups`) and delete the per-host
copies.

---

## 5. Deduplication

### 5.1 Pubkeys / name single-sourcing
- `firstName`/`lastName` live in `modules/home_configurations/git.nix:3-4` and
  again as `name.first`/`name.last` in `common.nix:79-83` (the latter dead). Put
  the name once (e.g. in `hosts/constants.nix`) and `inherit` it.
- `generators/do-builder/configuration.nix:33-39` hardcodes authorized pubkeys
  instead of using `constants.pubkeys` — and they've **drifted**: its airbook key
  (`...27AgH`, `:38`) differs from `constants.nix:8` (`...bQAyUA`). Import
  `constants.pubkeys` here too so there's one source of truth.

### 5.2 SSH crypto policy is duplicated *and* has diverged
The Ciphers / KexAlgorithms / MACs lists appear in three live places with
**different values**:
- `modules/home_configurations/ssh.nix:13-16` (`hardenedCrypto`, client) — includes
  `aes128-gcm`, `diffie-hellman-group*`.
- `hosts/common.nix:117-129` (server) — comments several ciphers out, no DH-group
  kex.
- `generators/do-builder/configuration.nix:51-64` (server) — a third, shorter set.

Define the lists **once** (e.g. in `constants.nix` or `hax.nix`) and reference them
on both client and server so a policy change lands everywhere. (And delete the
*fourth*, dead copy in `hax.nix` per §2.4.)

---

## 6. Flake & CI structure

### 6.1 Use `genAttrs` for host configs
`flake.nix:40-81` builds `nixosConfigurations` / `darwinConfigurations` with
`builtins.listToAttrs (map ...)`. `lib.genAttrs [ "neverland" ... ] (name: ...)`
is shorter and clearer; you could even derive the list from `builtins.readDir
./hosts`.

### 6.2 CI builds only 2 of 5 hosts
`.github/workflows/build.yml:13-19` builds only `eldo` and `airbook`. Add
`neverland` and `bifrost` (both x86_64-linux) to the matrix. `gjallar` needs the
`sinch-meetings` path input, so it likely stays local-only — note that explicitly.

### 6.3 Pin the cachix action
`.github/workflows/build.yml:27` uses `cachix/cachix-action@master` (the inline
comment even flags it). Pin a release tag so it's reproducible and
dependabot-trackable.

### 6.4 Add a format/lint gate
Add a cheap job running `nixpkgs-fmt --check .` and `statix check .`. This also
guards the **auto-merge update PRs**: `.github/workflows/update.yml:28` runs
`gh pr merge --auto --squash`, so a required lint/build check is your only gate
before an automatic flake bump lands on `main`.

---

## 7. Misc hygiene

- `updated_script.sh` (root) — a one-off k8s pod-age script using macOS-only
  `date -j`. Move it under `scripts/` or package it as a `pog` script next to
  `mods/pog/` so it's on `PATH` and version-pinned.
- `modules/home_configurations/core.nix:23` — `home.stateVersion = "22.11"` differs
  from the hosts' `system.stateVersion` (`24.05` / `22.05`). Fine to leave (don't
  bump blindly), but worth a one-line comment noting it's intentional.
- `README.md` is a stub — a short index linking `POG.md`, `MAC_README.md`, and
  per-host notes would help future-you.
- `ignore` (root, used by fzf at `home.nix:166`) — consider naming it `.fzfignore`
  for discoverability.
- `# learn about this` / `TODO` notes (`gum`/`moreutils` in `packages.nix:44,54`,
  the jacobi `TODO` in `flake.nix:6`) — harmless; a quick pass to resolve or delete
  tidies up.

---

## Suggested order of attack

1. **§1** correctness fixes — nixPath, `flake-compat` input, gjallar cache.
2. **§2** `statix fix` + drop dead code (mechanical, near-zero risk).
3. **§3** retire `workbook` (removes a whole branch of special-casing).
4. **§4** the `common.nix` → module refactor — biggest structural payoff; unlocks
   §4.2 and most of §5.
5. **§5** finish deduplication (name, pubkeys, SSH policy).
6. **§6** tighten flake/CI (genAttrs, matrix, pin cachix, lint gate).
