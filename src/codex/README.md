# Codex CLI (codex)

Installs the OpenAI Codex CLI from the official packaged GitHub release assets and persists `~/.codex` in shared state across devcontainers.

The feature installs:

- `codex`
- a bundled `rg` binary that matches the upstream Codex package layout

## Example Usage

```json
"features": {
    "ghcr.io/sliekens/devcontainer-features/codex:1": {}
}
```

Pin a specific Codex version when you need deterministic builds:

```json
"features": {
    "ghcr.io/sliekens/devcontainer-features/codex:1": {
        "version": "0.114.0"
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | Version to install. Accepts `latest`, `0.114.0`, `v0.114.0`, or `rust-v0.114.0`. |

## Persistent State

| Host path | Container path | Purpose |
|-----------|---------------|---------|
| `~/.codex` | `/var/lib/codex` | Auth and configuration |

This directory is bind-mounted from the host so that auth and configuration are preserved across container rebuilds.

Because Docker cannot bind-mount a directory that does not yet exist, consuming `devcontainer.json` files should add an `initializeCommand` to pre-create this directory on the host before the container starts:

```json
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/sliekens/devcontainer-features/codex:1": {}
    },
    "initializeCommand": "mkdir -p \"$HOME/.codex\""
}
```

## Release Notes

## 1.1.0 - 2026-03-28
- Use bind mount from host `~/.codex` instead of a Docker volume for persistent state.

## 1.0.0 - 2026-03-26
- Initial release.
