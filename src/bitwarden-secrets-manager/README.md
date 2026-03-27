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

This feature uses a persistent volume named `bitwarden-secrets-manager` mounted at `/var/lib/bitwarden-secrets-manager`.  
On create, it links that directory to `$HOME/.config/bws` so credentials and CLI state can be persisted across recreates.

## Release Notes

## 1.0.0 - 2026-03-26
- Initial release.
