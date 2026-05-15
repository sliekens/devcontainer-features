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

| Host path | Container path | Purpose |
|-----------|---------------|---------|
| `~/.config/gh` | `/var/lib/github-cli/config` | Configuration |
| `~/.local/share/gh` | `/var/lib/github-cli/state` | State |

These directories are bind-mounted from the host so that auth and configuration are preserved across container rebuilds.

Because Docker cannot bind-mount a directory that does not yet exist, consuming `devcontainer.json` files should add an `initializeCommand` to pre-create these directories on the host before the container starts:

```json
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/sliekens/devcontainer-features/github-cli:1": {}
    },
    "initializeCommand": "mkdir -p \"$HOME/.config/gh\" \"$HOME/.local/share/gh\""
}
```


## License

This feature is released under the [MIT License](https://github.com/sliekens/devcontainer-features/blob/main/LICENSE).

The installed tool is subject to its own license: [GitHub CLI license](https://github.com/cli/cli/blob/trunk/LICENSE).

## Links

- [GitHub CLI manual](https://cli.github.com/manual)

## Release Notes

## 1.1.1 - 2026-05-14
- Add trailing slash to bind mount source paths to mark them explicitly as directories.

## 1.1.0 - 2026-03-28
- Use bind mounts from host `~/.config/gh` and `~/.local/share/gh` instead of Docker volumes for persistent state.

## 1.0.0 - 2026-03-26
- Initial release.
