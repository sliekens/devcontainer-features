# GitHub Copilot CLI (copilot-cli)

Installs GitHub Copilot CLI from official release assets and persists shared `~/.copilot` state across devcontainers.

## Example Usage

```json
"features": {
    "ghcr.io/sliekens/devcontainer-features/copilot-cli:1": {
        "version": "latest"
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | Version to install. Use `latest` for the most recent stable release, or specify a version like `1.0.3`. |

## Persistent State

| Host path | Container path | Purpose |
|-----------|---------------|---------|
| `~/.copilot` | `/var/lib/copilot` | Auth and CLI state |

This directory is bind-mounted from the host so that auth is preserved across container rebuilds.

Because Docker cannot bind-mount a directory that does not yet exist, consuming `devcontainer.json` files should add an `initializeCommand` to pre-create this directory on the host before the container starts:

```json
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/sliekens/devcontainer-features/copilot:1": {}
    },
    "initializeCommand": "mkdir -p \"$HOME/.copilot\""
}
```

## Release Notes

## 1.1.1 - 2026-05-14
- Add trailing slash to bind mount source path to mark it explicitly as a directory.

## 1.1.0 - 2026-03-28
- Use bind mount from host `~/.copilot` instead of a Docker volume for persistent state.

## 1.0.0 - 2026-03-26
- Initial release.
