# tea (tea)

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

This feature bind mounts `~/.config/tea` from the host to `/var/lib/tea-cli` in the container.
On create, it links that directory to `$HOME/.config/tea` for stable user configuration.

## Release Notes

## 1.1.0 - 2026-03-28
- Use bind mount from host `~/.config/tea` instead of a Docker volume for persistent state.

## 1.0.0 - 2026-03-26
- Initial release.
