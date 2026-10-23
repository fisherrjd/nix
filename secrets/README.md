# keys and secrets

Every credential this setup uses: what it's for, where it lives, and how to replace it.
Last reviewed 2026-10-22.

## server secrets (agenix)

Encrypted `.age` files in this folder. `secrets.nix` lists the keys that can decrypt each one.

| secret | read by | on | owner, mode |
| --- | --- | --- | --- |
| `litellm` | litellm container | eldo | root 0400 |
| `openwebui` | open-webui container | eldo | root 0400 |
| `grafana-secret-key` | grafana | eldo | grafana 400 |
| `factory-github-app-key` | factory runner (fisherrjd-factory app) | eldo | factory-runner 0400 |
| `ops-deployer-token` | ops deploy runner, to register itself | eldo | root 0400 |
| `caddy` | caddy | bifrost | root 600 |

Who can decrypt:

- at boot: each server, with its own ssh host key (`/etc/ssh/ssh_host_ed25519_key`, public half in `hostkeys` in `hosts/constants.nix`)
- to edit: jade's keys on eldo, airbook and neverland (`default` in `secrets.nix`)

Edit a secret: `cd secrets && agenix -e <name>.age`, then rebuild the server that uses it.

Add a secret:

1. add a line to `secrets.nix`
2. `agenix -e <name>.age`
3. in the host config: `age.secrets.<name> = { file = ../../secrets/<name>.age; owner = "<service user>"; mode = "0400"; };`

A server got reinstalled (new host key):

1. `ssh-keyscan -t ed25519 <host>` and paste the key into `hostkeys` in `hosts/constants.nix`
2. `cd secrets && agenix -r` (from eldo, airbook or neverland)
3. rebuild that server

## ssh logins

`logins` in `hosts/constants.nix` lists which keys can log into each machine. The keys themselves are in `pubkeys`.

## github

| key | what it does | where it lives | expires | to replace |
| --- | --- | --- | --- | --- |
| `CACHIX_AUTH_TOKEN` | CI uploads builds to the fisherrjd cache | nix repo, actions secret | unknown | new token on app.cachix.org, `gh secret set CACHIX_AUTH_TOKEN -R fisherrjd/nix` |
| `NIX_TOKEN` | opens and auto-merges the nightly update PRs | nix repo, actions secret | unknown (set 2026-01-05) | being replaced by the fisherrjd-nix-ci app |
| fisherrjd-factory app | factory works on repos through it | eldo, agenix `factory-github-app-key` | no | app settings, generate a private key, `agenix -e factory-github-app-key.age` |
| `ops-deployer-token` | registers the ops deploy runner | eldo, agenix | ~2027-10-20 | fine-grained PAT, fisherrjd/ops only, Administration read and write; `agenix -e ops-deployer-token.age`; rebuild eldo |
| `SYNC_TOKEN` | i-have-adhd upstream sync | i-have-adhd repo, actions secret | unknown (set 2026-08-06) | new PAT, `gh secret set SYNC_TOKEN -R fisherrjd/i-have-adhd` |
| gh CLI token | `gh` on eldo; classic PAT, scopes repo, gist, read:org | eldo, `~/.config/gh/hosts.yml` | unknown | `gh auth login` |
| jade@eldo ssh key | git push from eldo, obsidian-autocommit, fetching factory during a rebuild | eldo, `~/.ssh/id_ed25519` | no | new key, add it on github.com/settings/keys, update `pubkeys.eldo` |

Unused, to delete: `HERMES_GITHUB_PAT` and `DISCORD_WEBHOOK_URL` (nix repo actions secrets), and the offline `nix-runner` self-hosted runner on the nix repo.
