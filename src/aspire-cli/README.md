# Aspire CLI (aspire-cli)

Installs the .NET Aspire CLI.

## Example Usage

```json
"features": {
    "ghcr.io/sliekens/devcontainer-features/aspire-cli:1": {
        "quality": "release"
    }
}
```

## Options

| Option    | Type   | Default   | Description                                                |
| --------- | ------ | --------- | ---------------------------------------------------------- |
| `quality` | string | `release` | Quality to download. Allowed: `release`, `staging`, `dev`. |

## Persistent State

| Host path | Container path | Purpose |
|-----------|---------------|---------|
| `~/.aspire` | `/var/lib/aspire-cli` | CLI state and configuration |

This directory is bind-mounted from the host so that CLI state is preserved across container rebuilds.

Because Docker cannot bind-mount a directory that does not yet exist, consuming `devcontainer.json` files should add an `initializeCommand` to pre-create this directory on the host before the container starts:

```json
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/sliekens/devcontainer-features/aspire-cli:1": {}
    },
    "initializeCommand": "mkdir -p \"$HOME/.aspire\""
}
```

## Release Notes

## 1.3.0 - 2026-03-28
- Use bind mount from host `~/.aspire` instead of a Docker volume for persistent state.

## 1.2.0 - 2026-03-28

- Enabled container tunnel support by default for improved CLI experience in devcontainers (`ASPIRE_ENABLE_CONTAINER_TUNNEL` set to `true`).

## 1.1.0 - 2026-03-27

- Added recommended VS Code extension `microsoft-aspire.aspire-vscode`.

## 1.0.0 - 2026-03-26

- Initial release.
