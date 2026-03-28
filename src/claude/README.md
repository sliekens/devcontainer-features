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

This feature bind mounts `~/.claude` and `~/.claude.json` from the host into the container so auth and settings are reused across devcontainers.

Because Docker cannot bind-mount a file that does not yet exist, consuming `devcontainer.json` files should add an `initializeCommand` to pre-create `~/.claude.json` on the host before the container starts:

```json
"initializeCommand": "[ -f \"$HOME/.claude.json\" ] || touch \"$HOME/.claude.json\""
```

## Release Notes

## 1.2.0 - 2026-03-28
- Also bind mount `~/.claude.json` from the host for persistent settings.

## 1.1.0 - 2026-03-28
- Use bind mount from host `~/.claude` instead of a Docker volume for persistent state.

## 1.0.0 - 2026-03-26
- Initial release.
