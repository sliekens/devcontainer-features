# GitHub CLI with Persistent State (github-cli)

Wraps the official GitHub CLI feature and adds persistent volume mounts for config and state.

## Example Usage

```json
"features": {
    "ghcr.io/sliekens/devcontainer-features/github-cli:1": {}
}
```

## Options

This feature does not expose configurable options.

## Persistent State

This feature bind mounts directories from the host user's home:

- `~/.config/gh` → `/var/lib/github-cli/config`
- `~/.local/share/gh` → `/var/lib/github-cli/state`

On create, it symlinks these to `$HOME/.config/gh` and `$HOME/.local/share/gh` in the container.

## Release Notes

## 1.1.0 - 2026-03-28
- Use bind mounts from host `~/.config/gh` and `~/.local/share/gh` instead of Docker volumes for persistent state.

## 1.0.0 - 2026-03-26
- Initial release.
