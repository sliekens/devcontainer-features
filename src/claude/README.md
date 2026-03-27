# Claude CLI (claude)

Installs the official Anthropic Claude CLI using the upstream installer (`https://claude.ai/install.sh`) and persists shared `~/.claude` state across devcontainers.

## Example Usage

```json
"features": {
    "ghcr.io/sliekens/devcontainer-features/claude:1": {
        "version": "stable"
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `stable` | Version/channel to install. Use `stable`, `latest`, or a specific version (e.g. `2.1.58`). |

## Persistent State

This feature uses a persistent volume named `claude` mounted at `/var/lib/claude` (shared across containers).  
On create, it links that directory to `$HOME/.claude` so auth/configuration is reused.

## Release Notes

## 1.0.0 - 2026-03-26
- Initial release.
