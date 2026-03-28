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

This feature bind mounts `~/.copilot` from the host to `/var/lib/copilot` in the container.
On create, it links that directory to `$HOME/.copilot` so auth and CLI state can be reused.

## Release Notes

## 1.1.0 - 2026-03-28
- Use bind mount from host `~/.copilot` instead of a Docker volume for persistent state.

## 1.0.0 - 2026-03-26
- Initial release.
