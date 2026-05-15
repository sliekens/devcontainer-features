# Bitwarden Agent Access (bitwarden-agent-access)

Installs the Bitwarden Agent Access CLI (`aac`) binary from Bitwarden release assets.

Agent Access is an open protocol and CLI tool that allows agents to access credentials from a password manager without exposing the entire vault.

## Example Usage

```json
"features": {
    "ghcr.io/sliekens/devcontainer-features/bitwarden-agent-access:1": {
        "version": "latest"
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | Version to install. Use `latest` or a release version like `0.11.0` or `v0.11.0`. |

## Persistent State

| Host path | Container path | Purpose |
|-----------|---------------|---------|
| `~/.access-protocol` | `/var/lib/bitwarden-agent-access` | Identity keys and connection state |

This directory is bind-mounted from the host so that identity keys and connection state are preserved across container rebuilds.

Because Docker cannot bind-mount a directory that does not yet exist, consuming `devcontainer.json` files should add an `initializeCommand` to pre-create this directory on the host before the container starts:

```json
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/sliekens/devcontainer-features/bitwarden-agent-access:1": {}
    },
    "initializeCommand": "mkdir -p \"$HOME/.access-protocol\""
}
```


## License

This feature is released under the [MIT License](https://github.com/sliekens/devcontainer-features/blob/main/LICENSE).

The installed tool is subject to its own license: [Bitwarden Agent Access license](https://github.com/bitwarden/agent-access/blob/main/LICENSE.txt).

## Links

- [Bitwarden Agent Access repository](https://github.com/bitwarden/agent-access)

## Release Notes

## 1.0.0 - 2026-05-15
- Initial release.
