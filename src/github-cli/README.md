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

This feature mounts two persistent volumes that are shared across containers using this feature:

- `github-cli-config-${devcontainerId}` → `/var/lib/github-cli/config`
- `github-cli-state-${devcontainerId}` → `/var/lib/github-cli/state`

On create, it symlinks these to:

- `$HOME/.config/gh`
- `$HOME/.local/share/gh`
