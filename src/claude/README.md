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

This feature bind mounts `~/.claude` from the host to `/var/lib/claude` in the container.
On create, it links that directory to `$HOME/.claude` so auth/configuration is reused.

## Release Notes

## 1.1.0 - 2026-03-28
- Use bind mount from host `~/.claude` instead of a Docker volume for persistent state.

## 1.0.0 - 2026-03-26
- Initial release.
