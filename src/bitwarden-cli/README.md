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

This feature bind mounts `~/.config/Bitwarden CLI` from the host into the container.
The on-create hook ensures the mounted directory is available and writable.

## Release Notes

## 1.1.0 - 2026-03-28
- Use bind mount from host `~/.config/Bitwarden CLI` instead of a Docker volume for persistent state.

## 1.0.1 - 2026-03-27
- Fixed latest version resolution to only consider `cli-*` releases, ignoring unrelated `web-*` and `desktop-*` releases from the same repository.

## 1.0.0 - 2026-03-26
- Initial release.
