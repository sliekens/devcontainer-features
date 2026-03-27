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

This feature uses a shared volume named `codex` mounted at `/var/lib/codex`.  
On container creation, it links `/var/lib/codex` to `$HOME/.codex`, so auth and configuration are preserved across rebuilds of the same feature-enabled devcontainer.

## Release Notes

## 1.0.0 - 2026-03-26
- Initial release.
