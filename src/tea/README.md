# Gitea CLI (tea)

Installs the [Gitea CLI](https://gitea.com/gitea/tea) from Gitea releases and configures shell completion via `/etc/bash_completion.d/tea` (bash) and `_tea` files in standard zsh completion directories.

## Example Usage

```json
"features": {
    "ghcr.io/sliekens/devcontainer-features/tea:1": {
        "version": "latest"
    }
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| `version` | Version to install (`latest`, `0.12.0`, or `v0.12.0`) | string | `latest` |

## Persistent State

| Host path | Container path | Purpose |
|-----------|---------------|---------|
| `~/.config/tea` | `/var/lib/tea-cli` | CLI configuration and auth tokens |

This directory is bind-mounted from the host so that configuration is preserved across container rebuilds.

Because Docker cannot bind-mount a directory that does not yet exist, consuming `devcontainer.json` files should add an `initializeCommand` to pre-create this directory on the host before the container starts:

```json
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/sliekens/devcontainer-features/tea:1": {}
    },
    "initializeCommand": "mkdir -p \"$HOME/.config/tea\""
}
```


## License

This feature is released under the [MIT License](https://github.com/sliekens/devcontainer-features/blob/main/LICENSE).

The installed tool is subject to its own license: [Gitea CLI (tea) license](https://gitea.com/gitea/tea/src/branch/main/LICENSE).

## Links

- [Gitea CLI (tea)](https://gitea.com/gitea/tea)

## Release Notes

## 1.1.1 - 2026-05-14
- Add trailing slash to bind mount source path to mark it explicitly as a directory.

## 1.1.0 - 2026-03-28
- Use bind mount from host `~/.config/tea` instead of a Docker volume for persistent state.

## 1.0.0 - 2026-03-26
- Initial release.
