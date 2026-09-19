<!-- Build a pog script: `nix build .#pog_test` -->

# Pog — Scripting Like a *NERD*

A collection of handy pog scripts for Docker, Kubernetes, AWS, and more.

---

## 🛠 Jade's Pogs

### - `colmena_pog_scripts`

### - `refresh_pog_scripts`

Package updaters. Each rewrites the version and hashes inline in the package's `.nix`
file to the latest (or `--version X`) release, builds the package, verifies it, and
restores the old file on failure. CI runs them nightly via `.github/workflows/update_pkgs.yml`.

- `refresh_claude_code_latest`

---
