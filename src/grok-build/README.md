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

## AI assisted installation

Copy the block below into a chat with your coding agent:

> Add `ghcr.io/sliekens/devcontainer-features/grok-build:1` to this project's Dev Container. Follow https://github.com/sliekens/devcontainer-features/blob/main/src/grok-build/README.md. Use the collection's shared `initializeCommand` pipeline (devcontainer + jq + xargs over `customizations.sliekens[].initializeCommand`) for host bind pre-create; Unix/WSL2 only. Prefer that over hand-written `mkdir` unless asked.

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

Docker cannot bind-mount host paths that do not yet exist. Each feature in this collection that needs host paths declares a host init command under `customizations.sliekens.initializeCommand`. Wire a single `initializeCommand` in your `devcontainer.json` to run all of them (works for any number of features):

```json
"initializeCommand": "devcontainer read-configuration --workspace-folder . --include-merged-configuration | jq -r '(.mergedConfiguration.customizations.sliekens // []) | .[] | .initializeCommand' | xargs -I{} bash -c {}"
```

Requires `devcontainer` and `jq` on the host `PATH`.

> **Note:** This host init pipeline runs only on Unix-like systems (Linux, macOS, and source code inside WSL2 on Windows). Native Windows (`cmd.exe`) is not supported — the Dev Containers CLI runs `initializeCommand` via `/bin/sh -c` on Unix and `cmd.exe /c` on native Windows.

### Manual alternative

If you prefer not to automate with the Dev Containers CLI, `jq`, and `xargs`, pre-create the host paths yourself in `initializeCommand`:

```json
"initializeCommand": "mkdir -p \"$HOME/.grok\""
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

## 1.0.2 - 2026-08-01
- Declare `customizations.sliekens.initializeCommand` for composable host path pre-create; document automated and manual `initializeCommand` wiring.

## 1.0.1 - 2026-07-05
- Install after `rename-user` when present, so `chown` in `install.sh` resolves the container username correctly.

## 1.0.0 - 2026-06-15
- Initial release.