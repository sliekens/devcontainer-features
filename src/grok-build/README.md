# Grok Build (grok-build)

Installs the xAI Grok Build CLI (`grok` and `agent`) via the upstream installer and persists shared `~/.grok` state across devcontainers.

## Example Usage

```json
"features": {
    "ghcr.io/sliekens/devcontainer-features/grok-build:1": {}
}
```

Pin a specific Grok version when you need deterministic builds:

```json
"features": {
    "ghcr.io/sliekens/devcontainer-features/grok-build:1": {
        "version": "0.2.51"
    }
}
```

Use the `alpha` channel for pre-release builds:

```json
"features": {
    "ghcr.io/sliekens/devcontainer-features/grok-build:1": {
        "channel": "alpha"
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | Version to install. Use `latest` for the current channel release, or specify a version like `0.2.51`. |
| `channel` | string | `stable` | Release channel when `version` is `latest`. One of `stable`, `alpha`, or `enterprise`. |

## Persistent State

| Host path | Container path | Purpose |
|-----------|---------------|---------|
| `~/.grok` | `/var/lib/grok-build` | Auth, configuration, sessions, and CLI state |

This directory is bind-mounted from the host so that auth and configuration are preserved across container rebuilds.

Because Docker cannot bind-mount a directory that does not yet exist, consuming `devcontainer.json` files should add an `initializeCommand` to pre-create this directory on the host before the container starts:

```json
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/sliekens/devcontainer-features/grok-build:1": {}
    },
    "initializeCommand": "mkdir -p \"$HOME/.grok\""
}
```

## Authentication

Sign in inside the container with `grok login`, or provide a deployment key via the `GROK_DEPLOYMENT_KEY` environment variable.

## License

This feature is released under the [MIT License](https://github.com/sliekens/devcontainer-features/blob/main/LICENSE).

The installed tool is subject to xAI's terms of service.

## Links

- [Grok Build announcement](https://x.ai/news/grok-build-cli)
- [Grok CLI install script](https://x.ai/cli/install.sh)

## Release Notes

## 1.0.0 - 2026-06-15
- Initial release.