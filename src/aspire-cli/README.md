# Aspire CLI (aspire-cli)

Installs the Aspire CLI.

## Example Usage

```json
"features": {
    "ghcr.io/sliekens/devcontainer-features/aspire-cli:1": {
        "quality": "release"
    }
}
```

## AI assisted installation

Copy the block below into a chat with your coding agent:

> Add `ghcr.io/sliekens/devcontainer-features/aspire-cli:1` to this project's Dev Container. Follow https://github.com/sliekens/devcontainer-features/blob/main/src/aspire-cli/README.md. Use the collection's shared `initializeCommand` pipeline (devcontainer + jq + xargs over `customizations.sliekens[].initializeCommand`) for host bind pre-create; Unix/WSL2 only. Prefer that over hand-written `mkdir` unless asked.

## Options

| Option    | Type   | Default   | Description                                                |
| --------- | ------ | --------- | ---------------------------------------------------------- |
| `quality` | string | `release` | Quality to download. Allowed: `release`, `staging`, `dev`. |

## Persistent State

| Host path | Container path | Purpose |
|-----------|---------------|---------|
| `~/.aspire` | `/var/lib/aspire-cli` | CLI state and configuration |

This directory is bind-mounted from the host so that CLI state is preserved across container rebuilds.

Docker cannot bind-mount host paths that do not yet exist. Each feature in this collection that needs host paths declares a host init command under `customizations.sliekens.initializeCommand`. Wire a single `initializeCommand` in your `devcontainer.json` to run all of them (works for any number of features):

```json
"initializeCommand": "devcontainer read-configuration --workspace-folder . --include-merged-configuration | jq -r '(.mergedConfiguration.customizations.sliekens // []) | .[] | .initializeCommand' | xargs -I{} bash -c {}"
```

Requires `devcontainer` and `jq` on the host `PATH`.

> **Note:** This host init pipeline runs only on Unix-like systems (Linux, macOS, and source code inside WSL2 on Windows). Native Windows (`cmd.exe`) is not supported — the Dev Containers CLI runs `initializeCommand` via `/bin/sh -c` on Unix and `cmd.exe /c` on native Windows.

### Manual alternative

If you prefer not to automate with the Dev Containers CLI, `jq`, and `xargs`, pre-create the host paths yourself in `initializeCommand`:

```json
"initializeCommand": "mkdir -p \"$HOME/.aspire\""
```


## License

This feature is released under the [MIT License](https://github.com/sliekens/devcontainer-features/blob/main/LICENSE).

The installed tool is subject to its own license: [Aspire license](https://github.com/microsoft/aspire/blob/main/LICENSE.TXT).

## Links

- [Aspire documentation](https://aspire.dev/docs/)

## Release Notes

## 1.3.4 - 2026-08-01
- Declare `customizations.sliekens.initializeCommand` for composable host path pre-create; document automated and manual `initializeCommand` wiring.

## 1.3.3 - 2026-05-16
- It's just Aspire now

## 1.3.2 - 2026-05-14
- Install aspire binary to `/opt/aspire/bin` and expose it via a wrapper script so aspire bundle operations work as a nonroot user.
- Hand ownership of `/opt/aspire` to the container user at container start so bundle locking and extraction work without elevated privileges.

## 1.3.1 - 2026-05-14
- Add trailing slash to bind mount source path to mark it explicitly as a directory.

## 1.3.0 - 2026-03-28
- Use bind mount from host `~/.aspire` instead of a Docker volume for persistent state.

## 1.2.0 - 2026-03-28

- Enabled container tunnel support by default for improved CLI experience in devcontainers (`ASPIRE_ENABLE_CONTAINER_TUNNEL` set to `true`).

## 1.1.0 - 2026-03-27

- Added recommended VS Code extension `microsoft-aspire.aspire-vscode`.

## 1.0.0 - 2026-03-26

- Initial release.
