# Cursor CLI (cursor-agent)

Installs the Cursor CLI (`agent` and `cursor-agent`) from official release assets and persists shared `~/.cursor` state across devcontainers.

## Example Usage

```json
"features": {
    "ghcr.io/sliekens/devcontainer-features/cursor-agent:1": {}
}
```

Pin a specific Cursor CLI version when you need deterministic builds:

```json
"features": {
    "ghcr.io/sliekens/devcontainer-features/cursor-agent:1": {
        "version": "2026.08.11-e8db854"
    }
}
```

## AI assisted installation

Copy the block below into a chat with your coding agent:

> Add `ghcr.io/sliekens/devcontainer-features/cursor-agent:1` to this project's Dev Container. Follow https://github.com/sliekens/devcontainer-features/blob/main/src/cursor-agent/README.md. Use the collection's shared `initializeCommand` pipeline (devcontainer + jq + xargs over `customizations.sliekens[].initializeCommand`) for host bind pre-create; Unix/WSL2 only. Prefer that over hand-written `mkdir` unless asked.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | Version to install. Use `latest` for the current installer release, or specify a version like `2026.08.11-e8db854`. |

## Persistent State

| Host path | Container path | Purpose |
|-----------|---------------|---------|
| `~/.cursor` | `/var/lib/cursor-agent` | Auth, CLI config (`cli-config.json`), MCP config, and sessions |

This directory is bind-mounted from the host so that auth and configuration are preserved across container rebuilds. The feature sets `AGENT_CLI_CREDENTIAL_STORE=file` so login tokens are stored in `~/.cursor/auth.json` rather than a host keychain.

Docker cannot bind-mount host paths that do not yet exist. Each feature in this collection that needs host paths declares a host init command under `customizations.sliekens.initializeCommand`. Wire a single `initializeCommand` in your `devcontainer.json` to run all of them (works for any number of features):

```json
"initializeCommand": "devcontainer read-configuration --workspace-folder . --include-merged-configuration | jq -r '(.mergedConfiguration.customizations.sliekens // []) | .[] | .initializeCommand' | xargs -I{} bash -c {}"
```

Requires `devcontainer` and `jq` on the host `PATH`.

> **Note:** This host init pipeline runs only on Unix-like systems (Linux, macOS, and source code inside WSL2 on Windows). Native Windows (`cmd.exe`) is not supported — the Dev Containers CLI runs `initializeCommand` via `/bin/sh -c` on Unix and `cmd.exe /c` on native Windows.

### Manual alternative

If you prefer not to automate with the Dev Containers CLI, `jq`, and `xargs`, pre-create the host paths yourself in `initializeCommand`:

```json
"initializeCommand": "mkdir -p \"$HOME/.cursor\""
```

## Authentication

Sign in inside the container with `agent login`, or provide an API key via the `CURSOR_API_KEY` environment variable.

## Commands

The upstream installer exposes `agent` as the primary command and `cursor-agent` as a legacy alias. This feature installs both, pointing at the same package under `/usr/local/lib/cursor-agent`.

The [Grok Build](../grok-build/README.md) feature also provides an `agent` command. If you enable both features, `cursor-agent` remains unambiguous.

## Known Issues

Cursor stores some settings as absolute paths. If the container username differs from the host username (e.g. `vscode` vs your host login), those paths will not resolve correctly inside the container.

Add the [`rename-user`](../rename-user/README.md) feature alongside this one. It reads `remoteUser` and renames the default `vscode` user at image build time — no custom Dockerfile needed.

```json
{
    "remoteUser": "${localEnv:USER}",
    "features": {
        "ghcr.io/sliekens/devcontainer-features/rename-user:1": {},
        "ghcr.io/sliekens/devcontainer-features/cursor-agent:1": {}
    },
    "initializeCommand": "devcontainer read-configuration --workspace-folder . --include-merged-configuration | jq -r '(.mergedConfiguration.customizations.sliekens // []) | .[] | .initializeCommand' | xargs -I{} bash -c {}"
}
```

## License

This feature is released under the [MIT License](https://github.com/sliekens/devcontainer-features/blob/main/LICENSE).

The installed tool is subject to Cursor's terms of service.

## Links

- [Cursor CLI](https://cursor.com/cli)
- [Cursor CLI documentation](https://cursor.com/docs/cli/overview)
- [Cursor CLI install script](https://cursor.com/install)

## Release Notes

## 1.0.0 - 2026-08-23
- Initial release.
