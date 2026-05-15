# opencode

Installs `opencode` from official GitHub release assets and persists shared state across devcontainers.

## Example Usage

```json
"features": {
    "ghcr.io/sliekens/devcontainer-features/opencode:1": {}
}
```

Pin a specific version when you need deterministic builds:

```json
"features": {
    "ghcr.io/sliekens/devcontainer-features/opencode:1": {
        "version": "1.3.13"
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | Version to install. Accepts `latest`, `1.3.13`, or `v1.3.13`. |

## Persistent State

opencode uses XDG base directories for data and configuration:

| Host path | Container path | Purpose |
|-----------|---------------|---------|
| `~/.local/share/opencode` | `/var/lib/opencode` | Data and auth credentials |
| `~/.config/opencode` | `/var/lib/opencode-config` | User configuration |

These directories are bind-mounted from the host so that auth credentials and settings are preserved across container rebuilds.

Because Docker cannot bind-mount a directory that does not yet exist, consuming `devcontainer.json` files should add an `initializeCommand` to pre-create these directories on the host before the container starts:

```json
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/sliekens/devcontainer-features/opencode:1": {}
    },
    "initializeCommand": "mkdir -p \"$HOME/.local/share/opencode\" \"$HOME/.config/opencode\""
}
```


## License

This feature is released under the [MIT License](https://github.com/sliekens/devcontainer-features/blob/main/LICENSE).

The installed tool is subject to its own license: [opencode license](https://github.com/anomalyco/opencode/blob/dev/LICENSE).

## Links

- [opencode documentation](https://opencode.ai/docs/)

## Release Notes

## 1.0.1 - 2026-05-14
- Add trailing slash to bind mount source paths to mark them explicitly as directories.

## 1.0.0 - 2026-04-01
- Initial release.
