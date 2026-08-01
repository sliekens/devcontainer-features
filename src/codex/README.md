# Codex CLI (codex)

Installs the OpenAI Codex CLI from the official packaged GitHub release assets and persists `~/.codex` in shared state across devcontainers.

The feature installs:

- `codex`
- a bundled `rg` binary that matches the upstream Codex package layout

## Example Usage

```json
"features": {
    "ghcr.io/sliekens/devcontainer-features/codex:1": {}
}
```

Pin a specific Codex version when you need deterministic builds:

```json
"features": {
    "ghcr.io/sliekens/devcontainer-features/codex:1": {
        "version": "0.114.0"
    }
}
```

## AI assisted installation

Copy the block below into a chat with your coding agent:

> Add `ghcr.io/sliekens/devcontainer-features/codex:1` to this project's Dev Container. Follow https://github.com/sliekens/devcontainer-features/blob/main/src/codex/README.md. Use the collection's shared `initializeCommand` pipeline (devcontainer + jq + xargs over `customizations.sliekens[].initializeCommand`) for host bind pre-create; Unix/WSL2 only. Prefer that over hand-written `mkdir` unless asked.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | Version to install. Accepts `latest`, `0.114.0`, `v0.114.0`, or `rust-v0.114.0`. |

## Persistent State

| Host path | Container path | Purpose |
|-----------|---------------|---------|
| `~/.codex` | `/var/lib/codex` | Auth and configuration |

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
"initializeCommand": "mkdir -p \"$HOME/.codex\""
```


## License

This feature is released under the [MIT License](https://github.com/sliekens/devcontainer-features/blob/main/LICENSE).

The installed tool is subject to its own license: [Codex CLI license](https://github.com/openai/codex/blob/main/LICENSE).

## Links

- [Codex CLI documentation](https://developers.openai.com/codex)

## Release Notes

## 1.1.3 - 2026-08-01
- Declare `customizations.sliekens.initializeCommand` for composable host path pre-create; document automated and manual `initializeCommand` wiring.

## 1.1.2 - 2026-05-24
- Fix compatibility with new tarball layout

## 1.1.1 - 2026-05-14
- Add trailing slash to bind mount source path to mark it explicitly as a directory.

## 1.1.0 - 2026-03-28
- Use bind mount from host `~/.codex` instead of a Docker volume for persistent state.

## 1.0.0 - 2026-03-26
- Initial release.
