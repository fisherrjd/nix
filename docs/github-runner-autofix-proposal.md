# GitHub Actions → Eldo Runner → Hermes Auto-Fix Pipeline

## Overview

Register eldo as a self-hosted runner on `fisherrjd/nix` (alongside its existing `fisherrjd/ops` registration). When a build fails, a workflow job runs directly on eldo and calls `hermes agent` inline — no webhook platform, no public port, no reverse proxy.

## Architecture

```
Build fails on fisherrjd/nix
    ↓
workflow_run trigger fires on [self-hosted, eldo]
    ↓
hermes agent runs directly on eldo (same machine, same env)
    ↓
Hermes analyzes failure, opens fix PR
    ↓
Discord: "✅ PR #42 opened" or "🔴 Needs manual fix"
```

Compared to the webhook approach: no HMAC secrets, no reverse proxy, no new firewall ports, no new Hermes platform to enable.

---

## Implementation Steps

### 1. Register a Runner on fisherrjd/nix

Navigate to: https://github.com/fisherrjd/nix/settings/actions/runners/new

Generate a registration token, then on eldo:

```bash
# The existing ops runner uses the NixOS github-runners module.
# Add a second runner entry — same machine, separate registration.
```

Add to `~/cfg/hosts/eldo/configuration.nix` alongside the existing runner:

```nix
age.secrets.github-nix-runner-token = {
  file = ../../secrets/github-nix-runner-token.age;
  mode = "644";
};

services.github-runners = {
  # existing
  eldo-runner = { ... };

  # new
  eldo-nix-runner = {
    enable = true;
    name = "eldo-nix-runner";
    url = "https://github.com/fisherrjd/nix";
    tokenFile = config.age.secrets.github-nix-runner-token.path;
    extraLabels = [ "nix" "eldo" ];
    extraPackages = with pkgs; [
      git
      hermes-agent.packages.${pkgs.system}.default
      # nix is already available on eldo
    ];
  };
};
```

Then encrypt the token with agenix:

```bash
# In ~/cfg/secrets/secrets.nix, add:
# "github-nix-runner-token.age".publicKeys = default;

cd ~/cfg
agenix -e secrets/github-nix-runner-token.age
# paste the runner registration token, save
```

### 2. Replace the Notify Workflow

Replace `~/cfg/.github/workflows/build-failure-notify.yml` with this:

```yaml
name: auto-fix on build failure

on:
  workflow_run:
    workflows: [build]
    types: [completed]

jobs:
  auto-fix:
    runs-on: [self-hosted, eldo]
    if: ${{ github.event.workflow_run.conclusion == 'failure' }}
    steps:
      - name: run hermes auto-fix agent
        env:
          GITHUB_TOKEN: ${{ secrets.HERMES_GITHUB_PAT }}
        run: |
          hermes agent \
            --prompt "A Nix CI build failed.

          Repo: fisherrjd/nix
          Run ID: ${{ github.event.workflow_run.id }}
          Branch: ${{ github.event.workflow_run.head_branch }}
          Commit: ${{ github.event.workflow_run.head_sha }}

          ## Step 1 — Diagnose
          Run:
            gh run view ${{ github.event.workflow_run.id }} --repo fisherrjd/nix --json jobs,conclusion,headBranch,headCommit,url
            gh run view ${{ github.event.workflow_run.id }} --repo fisherrjd/nix --log-failed

          Identify the failure type:
          - Hash/rev mismatch → fixable
          - Transient network error → retry once: gh run rerun ${{ github.event.workflow_run.id }} --repo fisherrjd/nix
          - Broken package upstream → fixable if only the hash needs updating
          - Logic/syntax error → not auto-fixable, diagnose only

          ## Step 2 — Propose fix (never merge)
          If fixable, create branch fix/ci-${{ github.event.workflow_run.id }} and apply:
          - flake.lock drift: nix flake update, commit flake.lock only
          - Hash mismatch: update the affected hash, commit

          Open a PR against main describing the root cause and what changed.
          NEVER merge. NEVER push directly to main. Only open the PR.

          ## Step 3 — Notify Discord
          Post one message to Discord #build-failures:
          - If PR opened: '✅ Proposed fix: PR #{number} — {one line summary}'
          - If retried: '🔄 Retried run — transient failure, watching'
          - If not fixable: '🔴 Needs manual fix — {diagnosis}. @jade'" \
            --skills "github-repo-management,github-pr-workflow"
```

**Note:** `HERMES_GITHUB_PAT` is a repo secret — a PAT with `repo` + `pull-requests:write` scope. The ephemeral `GITHUB_TOKEN` can read logs but can't push branches or open PRs, so a PAT is still needed here.

### 3. Add the PAT to Repo Secrets

Generate a fine-grained PAT at https://github.com/settings/personal-access-tokens with:
- Repository access: `fisherrjd/nix` only
- Permissions: `Contents: Read & Write`, `Pull requests: Read & Write`

Add it at: https://github.com/fisherrjd/nix/settings/secrets/actions → `HERMES_GITHUB_PAT`

### 4. Deploy and Test

```bash
# Rebuild eldo with the new runner
nixos-rebuild switch --flake ~/cfg#eldo

# Verify runner appears in GitHub
# https://github.com/fisherrjd/nix/settings/actions/runners

# Test with a branch (not main)
git checkout -b test/trigger-failure
echo "# intentional error" >> flake.nix
git push origin test/trigger-failure
# Open a PR — build fires, failure triggers the workflow
```

---

## What Stays the Same

- The existing `eldo-runner` for `fisherrjd/ops` is untouched
- Hermes config on eldo is untouched (no webhook platform needed)
- All existing agenix secrets are untouched

## What Changes

| Before | After |
|--------|-------|
| `build-failure-notify.yml` posts Discord embed + log file | Replaced by `auto-fix` workflow that calls `hermes agent` |
| No auto-fix capability | Hermes opens fix PRs for known patterns |
| Webhook proposal required new infra | Runner reuses existing eldo registration pattern |

---

## Rollback

```bash
# Disable the workflow without deleting
# Set `on: workflow_run` → remove the job, or add a manual gate

# Or just re-add build-failure-notify.yml from git history
git show HEAD~1:./github/workflows/build-failure-notify.yml > .github/workflows/build-failure-notify.yml
```
