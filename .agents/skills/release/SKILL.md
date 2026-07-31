---
name: release
description: >
  Release a Dev Container Feature from this collection. Covers version bump,
  release notes, root README table sync, tests, commit, and OCI publish.
  Use when the user runs /release, says "release", "publish feature",
  "bump version", "ship this feature", or asks to cut a new feature version
  after changes in src/<feature-id>/.
---

# Release Feature

Ship a new semver of one or more Features in **this** repository
(`sliekens/devcontainer-features`). Do not use marketplace plugin-release
workflows (no `plugin.json`, no external sync-readme-structure).

## Step 0 — Identify the feature

If the feature id is not stated, infer from recent edits under `src/` and
`test/`. If still ambiguous, ask.

Confirm paths exist:

- `src/<feature-id>/devcontainer-feature.json`
- `src/<feature-id>/install.sh`
- `src/<feature-id>/README.md` (must have `## Release Notes`)
- `test/<feature-id>/` (tests expected for any behavioral change)

## Step 1 — Detect what changed

```bash
git status
git diff HEAD -- "src/<feature-id>" "test/<feature-id>" README.md
```

Classify the bump (semver for **this** Feature only):

| Change | Bump |
|---|---|
| Breaking options, install contract, or default behavior consumers rely on | **major** |
| New capability, new option, meaningful default/behavior change | **minor** |
| Bugfix, docs-only, test-only, wording | **patch** |

If unclear, default to **patch** and say what you assumed.

Read the current version from `src/<feature-id>/devcontainer-feature.json`.

## Step 2 — Bump metadata

Update `version` in `src/<feature-id>/devcontainer-feature.json`.

If `description` changed (or the Feature is new), that field feeds the root
README table — do not hand-edit the table (see Step 4).

Keep `id` equal to the directory name.

## Step 3 — Release notes

In `src/<feature-id>/README.md`, under `## Release Notes`, **prepend** a new
section (newest first):

```markdown
## X.Y.Z - YYYY-MM-DD
- <one-line summary of the change>
```

Rules:

- Date is today (session date).
- One bullet per logical change; user-facing wording, not implementation diary.
- Required for any change that affects behavior, options, dependencies, install
  flow, mounts, lifecycle hooks, or usage docs.
- Docs/test-only releases still get a short note if version was bumped.

## Step 4 — Sync root features table

Always run after version/description work (and for new Features):

```bash
./scripts/sync-readme.sh
```

This rewrites the table between `<!-- BEGIN FEATURES TABLE -->` and
`<!-- END FEATURES TABLE -->` in the repo root `README.md` from each
Feature’s `id` + `description`. **Never** maintain that table by hand.

## Step 5 — Tests

```bash
./scripts/test.sh <feature-id>
```

Fix failures before publishing. Do not skip tests for behavioral releases
unless the user explicitly waives them.

Optional dry-run of publish validation (schemas, would-publish list):

```bash
./scripts/publish.sh --dry-run
```

## Step 6 — Commit scope

Commit only release-related files unless the user asks otherwise:

- `src/<feature-id>/`
- `test/<feature-id>/`
- root `README.md` (from sync-readme)
- this skill or other docs only if part of the same change

Leave unrelated dirty files (e.g. local `.devcontainer/` experiments) out of
the release commit.

Use a HEREDOC commit message, for example:

```bash
git add src/<feature-id> test/<feature-id> README.md
git commit -m "$(cat <<'EOF'
Release <feature-id> X.Y.Z

<one-line changelog summary>
EOF
)"
```

Do not push or publish until Step 7 is approved if the user has not already
asked to ship end-to-end.

## Step 7 — Publish to the registry

Default registry (see `scripts/publish.sh`):

| | |
|---|---|
| Registry | `ghcr.io` (override with `REGISTRY=...`) |
| Namespace | `sliekens/devcontainer-features` |
| Tags | `:major`, `:major.minor`, `:major.minor.patch`, `:latest` |

```bash
./scripts/publish.sh
```

Notes:

- Publishes **all** Features under `src/`; already-published exact versions are
  skipped (idempotent). A version bump is required to republish content.
- The script accepts only `--dry-run` as a flag (no single-feature argument in
  the current script). Prefer dry-run first when unsure about auth/registry.
- Post-publish: script may annotate images with `org.opencontainers.image.source`
  (needs `oras`) and check GHCR visibility (needs `gh` auth).
- If publish fails because a Feature repo has zero tags, see
  `./scripts/repair.sh [feature-id]`, then re-run publish.
- To remove a bad version: `./scripts/unpublish.sh <feature-id> <version>`
  (then repair + publish if major/latest tags need restoring).
- Override registry only if the user explicitly asks:
  `REGISTRY=… NAMESPACE=… ./scripts/publish.sh`

## Step 8 — Report

Tell the user:

1. Feature id and **new version**
2. Bump type (major/minor/patch) and why
3. Changelog one-liner(s)
4. Test result
5. Whether commit / publish / push ran, and registry refs if published  
   e.g. `ghcr.io/sliekens/devcontainer-features/<feature-id>:X.Y.Z`

## Checklist (do not skip)

- [ ] Version bumped in `devcontainer-feature.json`
- [ ] Release notes entry with date under `## Release Notes`
- [ ] `./scripts/sync-readme.sh` run
- [ ] `./scripts/test.sh <feature-id>` passed (or user waived)
- [ ] Commit does not mix unrelated workspace dirt
- [ ] Publish only after tests + user intent; dry-run first if auth is uncertain

## Out of scope

- Authoring or redesigning the Feature (use the `devcontainer` skill).
- Plugin marketplace release (other repos’ `plugin.json` flows).
- Hand-editing the root features table.
- Force-republishing the same version without a bump (not supported).
