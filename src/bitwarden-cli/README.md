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

## AI assisted installation

Copy the block below into a chat with your coding agent:

> Add `ghcr.io/sliekens/devcontainer-features/bitwarden-cli:1` to this project's Dev Container. Follow https://github.com/sliekens/devcontainer-features/blob/main/src/bitwarden-cli/README.md. Use the collection's shared `initializeCommand` pipeline (devcontainer + jq + xargs over `customizations.sliekens[].initializeCommand`) for host bind pre-create; Unix/WSL2 only. Prefer that over hand-written `mkdir` unless asked.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | Version to install. Use `latest` or a release version like `2026.2.0` or `v2026.2.0`. |

## Persistent State

| Host path | Container path | Purpose |
|-----------|---------------|---------|
| `~/.config/Bitwarden CLI` | `/home/vscode/.config/Bitwarden CLI` | Vault data and session |

This directory is bind-mounted from the host so that vault data and session are preserved across container rebuilds.

Docker cannot bind-mount host paths that do not yet exist. Each feature in this collection that needs host paths declares a host init command under `customizations.sliekens.initializeCommand`. Wire a single `initializeCommand` in your `devcontainer.json` to run all of them (works for any number of features):

```json
"initializeCommand": "devcontainer read-configuration --workspace-folder . --include-merged-configuration | jq -r '(.mergedConfiguration.customizations.sliekens // []) | .[] | .initializeCommand' | xargs -I{} bash -c {}"
```

Requires `devcontainer` and `jq` on the host `PATH`.

> **Note:** This host init pipeline runs only on Unix-like systems (Linux, macOS, and source code inside WSL2 on Windows). Native Windows (`cmd.exe`) is not supported — the Dev Containers CLI runs `initializeCommand` via `/bin/sh -c` on Unix and `cmd.exe /c` on native Windows.

### Manual alternative

If you prefer not to automate with the Dev Containers CLI, `jq`, and `xargs`, pre-create the host paths yourself in `initializeCommand`:

```json
"initializeCommand": "mkdir -p \"$HOME/.config/Bitwarden CLI\""
```


## License

This feature is released under the [MIT License](https://github.com/sliekens/devcontainer-features/blob/main/LICENSE).

The installed tool is subject to its own license: [Bitwarden CLI license](https://github.com/bitwarden/clients/blob/main/LICENSE.txt).

## Links

- [Bitwarden CLI documentation](https://bitwarden.com/help/cli/)

## Release Notes

## 1.1.2 - 2026-08-01
- Declare `customizations.sliekens.initializeCommand` for composable host path pre-create; document automated and manual `initializeCommand` wiring.

## 1.1.1 - 2026-05-14
- Add trailing slash to bind mount source path to mark it explicitly as a directory.

## 1.1.0 - 2026-03-28
- Use bind mount from host `~/.config/Bitwarden CLI` instead of a Docker volume for persistent state.

## 1.0.1 - 2026-03-27
- Fixed latest version resolution to only consider `cli-*` releases, ignoring unrelated `web-*` and `desktop-*` releases from the same repository.

## 1.0.0 - 2026-03-26
- Initial release.
