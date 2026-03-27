# AGENTS.md

Instructions for AI agents working on this repository.

## Repository Overview

This repository contains [dev container features](https://containers.dev/implementors/features/) published to an OCI registry.

- **Registry**: `ghcr.io`
- **Namespace**: `sliekens/devcontainer-features`
- **Feature reference format**: `ghcr.io/sliekens/devcontainer-features/<feature-id>:<version>`

## Key Files

| Path | Purpose |
|------|---------|
| `src/<feature>/devcontainer-feature.json` | Feature metadata (id, version, options) |
| `src/<feature>/install.sh` | Installation script (runs as root) |
| `src/<feature>/README.md` | Feature documentation and release notes |
| `test/<feature>/test.sh` | Feature tests |
| `scripts/publish.sh` | Publish features to registry |
| `scripts/test.sh` | Run feature tests locally |
| `scripts/test-pull.sh` | Test pulling from registry |

## Common Tasks

### Testing a feature
```bash
./scripts/test.sh <feature-id>
# Or test all:
./scripts/test.sh
```

### Publishing features
```bash
./scripts/publish.sh           # All features
./scripts/publish.sh <feature> # Single feature
```

### Creating a new feature
1. Create `src/<feature-id>/devcontainer-feature.json` with required fields: `id`, `name`, `version`
2. Create `src/<feature-id>/install.sh` (must be executable)
3. Add a "Release Notes" section to `src/<feature-id>/README.md` with the initial release entry
4. Create `test/<feature-id>/test.sh` for tests
5. Test with `./scripts/test.sh <feature-id>`
6. Publish with `./scripts/publish.sh <feature-id>`

## Versioning

Features use semantic versioning. To release a new version:
1. Bump `version` in `devcontainer-feature.json`
2. Update the "Release Notes" section in `src/<feature-id>/README.md` with a new entry for that version
3. Run `./scripts/publish.sh <feature-id>`

Release notes updates are required for any feature change that affects behavior, options, dependencies, install flow, or docs tied to usage.

The publish script is idempotent - it skips already-published versions.

## Dependencies

Required tools (installed in .devcontainer):
- `@devcontainers/cli` - Feature testing and packaging
- `oras` - OCI artifact publishing
- `jq` - JSON processing
- Docker or Podman - Container runtime

## Specification References

- [Feature spec](https://containers.dev/implementors/features/)
- [Distribution spec](https://containers.dev/implementors/features-distribution/)

## Notes

- The registry does not require authentication (LAN-only)
- Features are published with semver tags: `:1`, `:1.0`, `:1.0.0`, `:latest`
- Collection metadata (`ghcr.io/sliekens:latest`) has a known pull issue with the registry - this doesn't affect feature usage
