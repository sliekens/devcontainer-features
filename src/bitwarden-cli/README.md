# Bitwarden CLI (bitwarden-cli)

Installs the official Bitwarden CLI binary from Bitwarden release assets.

## Example Usage

```json
"features": {
    "ghcr.io/sliekens/devcontainer-features/bitwarden-cli:1": {
        "version": "latest"
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | Version to install. Use `latest` or a release version like `2026.2.0` or `v2026.2.0`. |

## Persistent State

| Host path | Container path | Purpose |
|-----------|---------------|---------|
| `~/.config/Bitwarden CLI` | `/home/vscode/.config/Bitwarden CLI` | Vault data and session |

This directory is bind-mounted from the host so that vault data and session are preserved across container rebuilds.

Because Docker cannot bind-mount a directory that does not yet exist, consuming `devcontainer.json` files should add an `initializeCommand` to pre-create this directory on the host before the container starts:

```json
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/sliekens/devcontainer-features/bitwarden-cli:1": {}
    },
    "initializeCommand": "mkdir -p \"$HOME/.config/Bitwarden CLI\""
}
```

## Release Notes

## 1.1.1 - 2026-05-14
- Add trailing slash to bind mount source path to mark it explicitly as a directory.

## 1.1.0 - 2026-03-28
- Use bind mount from host `~/.config/Bitwarden CLI` instead of a Docker volume for persistent state.

## 1.0.1 - 2026-03-27
- Fixed latest version resolution to only consider `cli-*` releases, ignoring unrelated `web-*` and `desktop-*` releases from the same repository.

## 1.0.0 - 2026-03-26
- Initial release.
