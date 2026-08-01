# OpenCode (opencode)

Installs `opencode` from official GitHub release assets and persists shared state across devcontainers.

## Example Usage

```json
"features": {
    "ghcr.io/sliekens/devcontainer-features/opencode:1": {}
}
```

Pin a specific version when you need deterministic builds:

```json
"features": {
    "ghcr.io/sliekens/devcontainer-features/opencode:1": {
        "version": "1.3.13"
    }
}
```

## AI assisted installation

Copy the block below into a chat with your coding agent:

> Add `ghcr.io/sliekens/devcontainer-features/opencode:1` to this project's Dev Container. Follow https://github.com/sliekens/devcontainer-features/blob/main/src/opencode/README.md. Use the collection's shared `initializeCommand` pipeline (devcontainer + jq + xargs over `customizations.sliekens[].initializeCommand`) for host bind pre-create; Unix/WSL2 only. Prefer that over hand-written `mkdir` unless asked.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | Version to install. Accepts `latest`, `1.3.13`, or `v1.3.13`. |

## Persistent State

opencode uses XDG base directories for data and configuration:

| Host path | Container path | Purpose |
|-----------|---------------|---------|
| `~/.local/share/opencode` | `/var/lib/opencode` | Data and auth credentials |
| `~/.config/opencode` | `/var/lib/opencode-config` | User configuration |

These directories are bind-mounted from the host so that auth credentials and settings are preserved across container rebuilds.

Docker cannot bind-mount host paths that do not yet exist. Each feature in this collection that needs host paths declares a host init command under `customizations.sliekens.initializeCommand`. Wire a single `initializeCommand` in your `devcontainer.json` to run all of them (works for any number of features):

```json
"initializeCommand": "devcontainer read-configuration --workspace-folder . --include-merged-configuration | jq -r '(.mergedConfiguration.customizations.sliekens // []) | .[] | .initializeCommand' | xargs -I{} bash -c {}"
```

Requires `devcontainer` and `jq` on the host `PATH`.

> **Note:** This host init pipeline runs only on Unix-like systems (Linux, macOS, and source code inside WSL2 on Windows). Native Windows (`cmd.exe`) is not supported — the Dev Containers CLI runs `initializeCommand` via `/bin/sh -c` on Unix and `cmd.exe /c` on native Windows.

### Manual alternative

If you prefer not to automate with the Dev Containers CLI, `jq`, and `xargs`, pre-create the host paths yourself in `initializeCommand`:

```json
"initializeCommand": "mkdir -p \"$HOME/.local/share/opencode\" \"$HOME/.config/opencode\""
```


## License

This feature is released under the [MIT License](https://github.com/sliekens/devcontainer-features/blob/main/LICENSE).

The installed tool is subject to its own license: [opencode license](https://github.com/anomalyco/opencode/blob/dev/LICENSE).

## Links

- [opencode documentation](https://opencode.ai/docs/)

## Release Notes

## 1.0.3 - 2026-08-01
- Declare `customizations.sliekens.initializeCommand` for composable host path pre-create; document automated and manual `initializeCommand` wiring.

## 1.0.1 - 2026-05-14
- Add trailing slash to bind mount source paths to mark them explicitly as directories.

## 1.0.0 - 2026-04-01
- Initial release.
