# Bitwarden Secrets Manager CLI (bitwarden-secrets-manager)

Installs the Bitwarden Secrets Manager CLI (`bws`) binary from Bitwarden release assets.

## Example Usage

```json
"features": {
    "ghcr.io/sliekens/devcontainer-features/bitwarden-secrets-manager:1": {
        "version": "latest"
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | Version to install. Use `latest` or a release version like `2.0.0`, `v2.0.0`, or `bws-v2.0.0`. |

## Persistent State

| Host path | Container path | Purpose |
|-----------|---------------|---------|
| `~/.config/bws` | `/var/lib/bitwarden-secrets-manager` | Credentials and CLI state |

This directory is bind-mounted from the host so that credentials are preserved across container rebuilds.

Because Docker cannot bind-mount a directory that does not yet exist, consuming `devcontainer.json` files should add an `initializeCommand` to pre-create this directory on the host before the container starts:

```json
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/sliekens/devcontainer-features/bitwarden-secrets-manager:1": {}
    },
    "initializeCommand": "mkdir -p \"$HOME/.config/bws\""
}
```

## Release Notes

## 1.1.0 - 2026-03-28
- Use bind mount from host `~/.config/bws` instead of a Docker volume for persistent state.

## 1.0.0 - 2026-03-26
- Initial release.
