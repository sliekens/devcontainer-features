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

This feature uses a persistent volume named `tea-cli` mounted at `/var/lib/tea-cli` (shared across containers).  
On create, it links that directory to `$HOME/.config/tea` for stable user configuration.
