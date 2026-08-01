# Gitea CLI (tea)

Installs the [Gitea CLI](https://gitea.com/gitea/tea) from Gitea releases and configures shell completion via `/etc/bash_completion.d/tea` (bash) and `_tea` files in standard zsh completion directories.

## Example Usage

```json
"features": {
    "ghcr.io/sliekens/devcontainer-features/tea:1": {
        "version": "latest"
    }
}
```

## AI assisted installation

Copy the block below into a chat with your coding agent:

> Add `ghcr.io/sliekens/devcontainer-features/tea:1` to this project's Dev Container. Follow https://github.com/sliekens/devcontainer-features/blob/main/src/tea/README.md. Use the collection's shared `initializeCommand` pipeline (devcontainer + jq + xargs over `customizations.sliekens[].initializeCommand`) for host bind pre-create; Unix/WSL2 only. Prefer that over hand-written `mkdir` unless asked.

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| `version` | Version to install (`latest`, `0.12.0`, or `v0.12.0`) | string | `latest` |

## Persistent State

| Host path | Container path | Purpose |
|-----------|---------------|---------|
| `~/.config/tea` | `/var/lib/tea-cli` | CLI configuration and auth tokens |

This directory is bind-mounted from the host so that configuration is preserved across container rebuilds.

Docker cannot bind-mount host paths that do not yet exist. Each feature in this collection that needs host paths declares a host init command under `customizations.sliekens.initializeCommand`. Wire a single `initializeCommand` in your `devcontainer.json` to run all of them (works for any number of features):

```json
"initializeCommand": "devcontainer read-configuration --workspace-folder . --include-merged-configuration | jq -r '(.mergedConfiguration.customizations.sliekens // []) | .[] | .initializeCommand' | xargs -I{} bash -c {}"
```

Requires `devcontainer` and `jq` on the host `PATH`.

> **Note:** This host init pipeline runs only on Unix-like systems (Linux, macOS, and source code inside WSL2 on Windows). Native Windows (`cmd.exe`) is not supported — the Dev Containers CLI runs `initializeCommand` via `/bin/sh -c` on Unix and `cmd.exe /c` on native Windows.

### Manual alternative

If you prefer not to automate with the Dev Containers CLI, `jq`, and `xargs`, pre-create the host paths yourself in `initializeCommand`:

```json
"initializeCommand": "mkdir -p \"$HOME/.config/tea\""
```


## License

This feature is released under the [MIT License](https://github.com/sliekens/devcontainer-features/blob/main/LICENSE).

The installed tool is subject to its own license: [Gitea CLI (tea) license](https://gitea.com/gitea/tea/src/branch/main/LICENSE).

## Links

- [Gitea CLI (tea)](https://gitea.com/gitea/tea)

## Release Notes

## 1.1.3 - 2026-08-01
- Declare `customizations.sliekens.initializeCommand` for composable host path pre-create; document automated and manual `initializeCommand` wiring.

## 1.1.1 - 2026-05-14
- Add trailing slash to bind mount source path to mark it explicitly as a directory.

## 1.1.0 - 2026-03-28
- Use bind mount from host `~/.config/tea` instead of a Docker volume for persistent state.

## 1.0.0 - 2026-03-26
- Initial release.
