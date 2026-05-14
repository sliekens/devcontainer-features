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
- Updates all supplementary group memberships in `/etc/group` to reflect the new username.

## Compatibility

### docker-in-docker

`docker-in-docker` determines which user to add to the `docker` group by reading `_REMOTE_USER`. When `remoteUser` is set to your host username (e.g. `${localEnv:USER}`), `_REMOTE_USER` is that username — which doesn't exist in the base image yet. `docker-in-docker` then falls back to `root`, leaving the renamed user without docker access.

Fix this by forcing `docker-in-docker` to use `vscode` (the pre-rename username):

```json
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "remoteUser": "${localEnv:USER}",
    "features": {
        "ghcr.io/devcontainers/features/docker-in-docker:2": {
            "username": "vscode"
        },
        "ghcr.io/sliekens/devcontainer-features/rename-user:1": {}
    }
}
```

This ensures `docker-in-docker` adds `vscode` to the `docker` group, and rename-user then updates that membership to the final username.

## Release Notes

## 1.0.1 - 2026-05-13
- Fix supplementary group memberships not being updated in `/etc/group` after rename.
- Document `docker-in-docker` compatibility: pass `"username": "vscode"` to `docker-in-docker` when using both features together.

## 1.0.0 - 2026-05-10
- Initial release.
