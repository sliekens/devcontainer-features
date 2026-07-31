# AGENTS.md

Instructions for AI agents working on this repository.

## Repository Overview

This repository contains [dev container features](https://containers.dev/implementors/features/) published to an OCI registry.

- **Registry**: `ghcr.io`
- **Namespace**: `sliekens/devcontainer-features`
- **Feature reference format**: `ghcr.io/sliekens/devcontainer-features/<feature-id>:<version>`

## Key Files

| Path                                      | Purpose                                 |
| ----------------------------------------- | --------------------------------------- |
| `src/<feature>/devcontainer-feature.json` | Feature metadata (id, version, options) |
| `src/<feature>/install.sh`                | Installation script (runs as root)      |
| `src/<feature>/README.md`                 | Feature documentation and release notes |
| `test/<feature>/test.sh`                  | Feature tests                           |
| `scripts/publish.sh`                      | Publish features to registry            |
| `scripts/test.sh`                         | Run feature tests locally               |
| `scripts/sync-readme.sh`                  | Regenerate root README features table   |
| `.agents/skills/release/`                 | Full Feature release workflow for agents |

## Common Tasks

### Testing a feature

```bash
./scripts/test.sh <feature-id>
# Or test all:
./scripts/test.sh
```

### Publishing features

```bash
./scripts/publish.sh --dry-run # Validation only
./scripts/publish.sh           # Publish all features
```

### Creating a new feature

1. Create `src/<feature-id>/devcontainer-feature.json` with required fields: `id`, `name`, `version`
2. Create `src/<feature-id>/install.sh` (must be executable)
3. Add a "Release Notes" section to `src/<feature-id>/README.md` with the initial release entry
4. Create `test/<feature-id>/test.sh` for tests
5. Test with `./scripts/test.sh <feature-id>`
6. Publish with `./scripts/publish.sh <feature-id>`

## Versioning

Features use semantic versioning. To release a new version (see also the `release` skill):

1. Bump `version` in `devcontainer-feature.json`
2. Update the "Release Notes" section in `src/<feature-id>/README.md` with a new entry for that version
3. Run `./scripts/sync-readme.sh` (refreshes the root README features table from each feature `description`)
4. Run `./scripts/test.sh <feature-id>`
5. Run `./scripts/publish.sh` (publishes all features; already-published versions are skipped)

Release notes updates are required for any feature change that affects behavior, options, dependencies, install flow, or docs tied to usage.

The publish script is idempotent - it skips already-published versions. Do not hand-edit the root features table; always use `sync-readme.sh`.

## Dependencies

Required tools (installed in .devcontainer):

- `@devcontainers/cli` - Feature testing and packaging
- `ajv-cli` - JSON schema validation
- `oras` - OCI artifact publishing
- `jq` - JSON processing
- Docker or Podman - Container runtime

## Specification References

- [Feature spec](https://containers.dev/implementors/features/)
- [Distribution spec](https://containers.dev/implementors/features-distribution/)

## Notes

- Features are published with semver tags: `:1`, `:1.0`, `:1.0.0`, `:latest`

## Feature-specific Notes

### opencode

opencode uses XDG base directories (not a single `~/.opencode` dir):

| Directory                 | Purpose                                                |
| ------------------------- | ------------------------------------------------------ |
| `~/.local/share/opencode` | Data **and** auth credentials (`auth.json` lives here) |
| `~/.config/opencode`      | User configuration (`opencode.json`/`opencode.jsonc`)  |
| `~/.cache/opencode`       | Ephemeral binary cache — not worth persisting          |
| `~/.local/state/opencode` | Runtime state — not worth persisting                   |

Both data and config are bind-mounted because auth lives in the data dir (not config). This was confirmed by reading `packages/opencode/src/global/index.ts` and `packages/opencode/src/auth/index.ts` in the [anomalyco/opencode](https://github.com/anomalyco/opencode) repo.

The upstream install script (`https://opencode.ai/install` → redirects to a script on the `dev` branch) places the binary in `$HOME/.opencode/bin/opencode` and modifies shell rc files. This feature vendors the install by downloading the release asset (`opencode-linux-{x64,arm64}.tar.gz`) from GitHub, which contains a single `opencode` binary at the archive root.

Release tags use the format `v{semver}` (e.g. `v1.3.13`).
