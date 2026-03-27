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

This feature uses a persistent volume named `copilot-cli` mounted at `/var/lib/copilot-cli`.  
On create, it links that directory to `$HOME/.copilot` so auth and CLI state can be reused.

## Release Notes

## 1.0.0 - 2026-03-26
- Initial release.
