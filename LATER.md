# Later: nix cleanup follow-ups

Uncommitted on purpose. These come from the 2026-10-22 review. Delete each item once it's done.

**Review session: next up is item 3 of 11.**
- 1: deferred.
- 2: done in PR #528 (branch `hm-use-global-pkgs`), waiting on your review and builds.
- 6: done.
- 3–5 and 7–12: not discussed yet.

Order = suggested work order. Each item names the Nix concept it teaches.

## Cohesion (the main issue)

### 1. Make the shared NixOS config a real module (deferred)

`hosts/common.nix` is a function that returns values, and each host copies them over by hand:
eldo uses `imports = [ { inherit (common) services; } ]`, neverland uses `services = {...} // common.services`,
bifrost gets only `nix`, and the Mac hosts use `nix = common.nix // {...}`. `//` keeps only the right-hand value
for a key that appears on both sides, so one copy disappears with no error. Modules are combined by the module
system instead, and real conflicts fail the build.

Step 1 (NixOS hosts only, ~30 min):
1. Create `hosts/common_nixos.nix` as a module: `time.timeZone`, `i18n`, `security.sudo`,
   `services.tailscale`, `services.openssh`.
2. Add `./hosts/common_nixos.nix` to `nixosConfigurations` `modules` in flake.nix.
3. Delete the hand-copied lines from eldo, neverland and bifrost.

Watch out: bifrost gains `PermitRootLogin = "no"`, so root ssh with the DigitalOcean metadata key stops working.
Colmena deploys as `jade`, so deploys are unaffected. The DigitalOcean module only sets openssh defaults
(`mkDefault`), so our values override them without conflicts.

Later steps (~1 h): shared `nix` settings for both NixOS and Mac hosts, then move the Mac hosts (airbook, gjallar) off `common.nix // {...}`.

### 2. Give home-manager the system's pkgs (`useGlobalPkgs`) (PR #528)

Without `home-manager.useGlobalPkgs = true`, home-manager (HM) evaluates its own plain copy of nixpkgs, with no
overlays and no unfree packages. So `pkgs.hax`, `pkgs.hms` and `pkgs.claude-code-latest` don't exist inside HM
modules, and `home.nix` passes them in through `_module.args` as `opkgs` and `hax`. Each HM host also evaluates
nixpkgs twice.

Concept: every module receives a `pkgs` argument, but who evaluates the module decides which one. NixOS modules
get the `pkgs` passed to `nixosSystem` (your overlaid set). HM modules get HM's own copy unless `useGlobalPkgs` is set.

Fix (~30 min, 9 files, doesn't depend on item 1):
1. flake.nix: add `home-manager.nixosModules.home-manager` and `darwinModules.home-manager`, plus
   `{ home-manager.useGlobalPkgs = true; }`.
2. Remove the `"${common.home-manager}/nixos"` and `/nix-darwin` imports from eldo, neverland, airbook and gjallar.
3. HM modules: `opkgs` → `pkgs`, `hax.` → `pkgs.hax.` (core.nix, ssh.nix, packages.nix). Then delete the
   `_module.args` forwarding of `hax` and `opkgs` in home.nix.

Leave out `useUserPackages`. It moves packages from `~/.nix-profile` to `/etc/profiles/per-user/jade`,
and two places hard-code `~/.nix-profile`: the bash-completion lines in `home.nix:87-91` and gjallar's launchd job
in `hosts/gjallar/configuration.nix:132`. Turning it on would break both.

Build afterwards: eldo, neverland, airbook, gjallar.

### 3. Per-host boilerplate repeats things the flake already knows

- `hostname = "eldo"` restates the `machine-name` specialArg. `networking.hostName` and `NIX_HOST` could come from
  `machine-name` in the common module.
- The `caffeinate` launchd agent is identical in airbook and gjallar. Move it to `hosts/common_darwin.nix`.
- `nixPath` and `darwinConfig` are rebuilt the same way in both Mac hosts.

Concept: specialArgs as the single source of host identity. ~30 min, after item 1.

## Flake hygiene

### 4. `flake-compat.nix` borrows jacobi's flake-compat

`lock.nodes.flake-compat` is jacobi's transitive input, not yours. Your own inputs get suffixed lock node names
(your nixpkgs is node `nixpkgs_10`). If cobi drops flake-compat, `default.nix` and colmena break.

Fix: add input `flake-compat = { url = "github:edolstra/flake-compat"; flake = false; };` and read
`lock.nodes.${lock.nodes.root.inputs.flake-compat}.locked`.

Concept: flake.lock node naming, root vs transitive inputs. ~10 min.

### 5. home-manager, nix-darwin and nixpkgs use indirect (registry) refs

`home-manager` and `nix-darwin` have no `url`, and `nixpkgs/nixos-unstable` is an indirect ref. They resolve
through the global flake registry of whoever runs `nix flake update` (the lock shows `"type": "indirect"`).

Fix: `github:nix-community/home-manager`, `github:nix-darwin/nix-darwin`, `github:NixOS/nixpkgs/nixos-unstable`.
Re-locking after a url change bumps those inputs, so do it as part of a normal update.

Concept: indirect vs direct flake refs; the flake registry. ~10 min plus an update build.

### 7. Stray top-level outputs

- `jacobi`, `agenix` and `pins` are not standard outputs, and nothing in the repo reads them. Check external use,
  then drop them.
- `do-builder` is also non-standard. nixos-generators looks to be superseded by nixpkgs' own image builder
  (`nixos-rebuild build-image`); verify before migrating.
- Remove the 4 trailing blank lines at the end of flake.nix.

~10 min (do-builder migration excluded).

### 8. skribbl doesn't follow your nixpkgs

The lock has 11 nixpkgs copies, and skribbl brings its own. jacobi's are deliberate: cobi's packages are tested
against his pin.

Fix: `skribbl.inputs.nixpkgs.follows = "nixpkgs";`, then check that gjallar still builds. ~5 min plus a darwin build.

## Polish

### 9. Nix settings as raw text

`hosts/common.nix` and `generators/do-builder/configuration.nix` use `nix.extraOptions` strings. Use structured
`nix.settings` instead: `experimental-features = [ ... ]`, `extra-substituters = [ ... ]`, `max-jobs = "auto"`.
Typos become eval errors.

### 10. Small idiom fixes

- eldo: `inherit (pkgs) system` → `system = pkgs.stdenv.hostPlatform.system` (`pkgs.system` is deprecated).
- eldo: `pkgs.lib.mkAfter` → `lib.mkAfter` (`lib` is already an arg).
- bifrost: unused `config` arg.

### 11. bifrost imports a home-manager module as a NixOS module

`modules/home_configurations/starship.nix` only works on bifrost because NixOS also happens to have
`programs.starship.settings`. Either put bifrost on HM (after item 2) or keep a NixOS-specific starship module.

### 12. colmena/hive.nix duplicates bifrost's module list

It re-lists agenix plus the bifrost config, separately from `nixosConfigurations.bifrost`. Options: have colmena
read the flake output, or replace colmena with
`nixos-rebuild switch --flake .#bifrost --target-host bifrost --sudo`.

## Separate (not flake cohesion)

eldo: `"rcon.password" = "fart"` is in git and in the world-readable store. The firewall keeps the port closed,
but any local user can read the password. Moving it to agenix needs a preStart that patches server.properties.
