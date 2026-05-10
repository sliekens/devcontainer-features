# Rename Container User (rename-user)

Renames the default `vscode` container user to match the `remoteUser` configured in `devcontainer.json`, preserving group membership and passwordless sudo access.

Use this feature to avoid path mismatches when bind-mounting host paths that contain the host username (e.g. `~/.claude`). With matching usernames, the container home directory resolves to the same absolute path as the host home directory.

## Example Usage

Set `remoteUser` to `${localEnv:USER}` and add this feature. No Dockerfile customization is needed.

```json
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "remoteUser": "${localEnv:USER}",
    "features": {
        "ghcr.io/sliekens/devcontainer-features/rename-user:1": {}
    }
}
```

## Behavior

- Reads the target username from `_REMOTE_USER`, which the devcontainer CLI sets from the `remoteUser` property.
- If `remoteUser` is unset or is already `vscode`, the feature does nothing.
- Renames the user login, home directory, primary group, and sudoers file entry.

## Release Notes

## 1.0.0 - 2026-05-10
- Initial release.
