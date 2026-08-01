# Mistral Vibe (mistral-vibe)

Installs [Mistral Vibe](https://mistral.ai/products/vibe) CLI coding agent in devcontainers using Python virtual environment and persists shared state across sessions.

## Features

- Installs Mistral Vibe CLI using `pip install mistral-vibe` in an isolated virtual environment
- Persists `~/.vibe` state across devcontainer recreations
- Supports version selection via pip's version resolution
- Automatic Python and pip installation if not present

## Usage

Add this feature to your `devcontainer.json`:

```json
{
  "features": {
    "ghcr.io/sliekens/devcontainer-features/mistral-vibe": {
      "version": "latest"
    }
  }
}
```

## AI assisted installation

Copy the block below into a chat with your coding agent:

> Add `ghcr.io/sliekens/devcontainer-features/mistral-vibe:1` to this project's Dev Container. Follow https://github.com/sliekens/devcontainer-features/blob/main/src/mistral-vibe/README.md. Use the collection's shared `initializeCommand` pipeline (devcontainer + jq + xargs over `customizations.sliekens[].initializeCommand`) for host bind pre-create; Unix/WSL2 only. Prefer that over hand-written `mkdir` unless asked.

## Options

### `version` (string)

Version to install. Default: `"latest"`

- `"latest"` - Install the latest version
- Specific versions like `"2.7.3"`
- Version ranges supported by pip

Example:

```json
{
  "features": {
    "ghcr.io/sliekens/devcontainer-features/mistral-vibe": {
      "version": "2.7.3"
    }
  }
}
```

## Persistent State

| Host path | Container path  | Purpose                                  |
| --------- | --------------- | ---------------------------------------- |
| `~/.vibe` | `/var/lib/vibe` | API keys, configuration, session history |

This directory is bind-mounted from the host so that state is preserved across container rebuilds.

Docker cannot bind-mount host paths that do not yet exist. Each feature in this collection that needs host paths declares a host init command under `customizations.sliekens.initializeCommand`. Wire a single `initializeCommand` in your `devcontainer.json` to run all of them (works for any number of features):

```json
"initializeCommand": "devcontainer read-configuration --workspace-folder . --include-merged-configuration | jq -r '(.mergedConfiguration.customizations.sliekens // []) | .[] | .initializeCommand' | xargs -I{} bash -c {}"
```

Requires `devcontainer` and `jq` on the host `PATH`.

> **Note:** This host init pipeline runs only on Unix-like systems (Linux, macOS, and source code inside WSL2 on Windows). Native Windows (`cmd.exe`) is not supported — the Dev Containers CLI runs `initializeCommand` via `/bin/sh -c` on Unix and `cmd.exe /c` on native Windows.

### Manual alternative

If you prefer not to automate with the Dev Containers CLI, `jq`, and `xargs`, pre-create the host paths yourself in `initializeCommand`:

```json
"initializeCommand": "mkdir -p \"$HOME/.vibe\""
```

## Installation Process

1. Installs Python and pip if not present using system package manager
2. Creates isolated virtual environment at `/opt/mistral-vibe/venv`
3. Uses `pip install mistral-vibe` to install the CLI in the virtual environment
4. Creates wrapper scripts in `/usr/local/bin` for system-wide access
5. Sets up state directory `/var/lib/vibe` with proper permissions
6. Creates symbolic link from `$HOME/.vibe` to the state directory

## Commands Available

After installation, these commands are available:

- `vibe` - Main Mistral Vibe CLI
- `vibe-acp` - Agent Client Protocol mode

## Requirements

- Linux container (tested on Ubuntu, Debian, Alpine)
- Internet access to download Python packages and mistral-vibe
- Approximately 200MB disk space (includes Python and dependencies)

## Release Notes

## 1.2.1 - 2026-08-01
- Declare `customizations.sliekens.initializeCommand` for composable host path pre-create; document automated and manual `initializeCommand` wiring.

## 1.2.0 - 2026-05-28

- Replace unofficial `nmallet.vscode-mistral-vibe` extension with official `mistralai.mistral-vibe-code`

## 1.1.2 - 2026-05-14

- Fix wrapper script argument forwarding by writing wrappers with quoted heredocs and preserving `"$@"`.

## 1.1.1 - 2026-05-14

- Add trailing slash to bind mount source path to mark it explicitly as a directory.

## 1.1.0 - 2026-04-11

- Add `nmallet.vscode-mistral-vibe` VSCode extension to devcontainer feature.

## 1.0.2 - 2026-04-06

- Fix absolute paths in `~/.vibe/config.toml` by replacing with `~`.

## 1.0.1 - 2026-04-06

- Fix absolute paths in `~/.vibe` config by replacing with `~`.

## 1.0.0 - 2026-04-05

- Initial release.

## Troubleshooting

### "vibe command not found"

Ensure `/usr/local/bin` is in your PATH. The feature creates symlinks there for system-wide access.

### Installation fails

Make sure your container has:

- Internet access
- Sufficient disk space
- Supported package manager (apt, apk, dnf, or yum)

### State not persisting

Verify that:

- The bind mount is working correctly
- The `onCreateCommand` is being executed
- You're not overriding the `.vibe` directory in your Dockerfile

## License

This feature is released under the [MIT License](https://github.com/sliekens/devcontainer-features/blob/main/LICENSE).

The installed tool is subject to its own license: [Mistral Vibe license](https://github.com/mistralai/mistral-vibe/blob/main/LICENSE).

## Links

- [Mistral Vibe Documentation](https://mistral.ai/products/vibe)
- [Mistral Vibe GitHub](https://github.com/mistralai/mistral-vibe)
- [Python Virtual Environments](https://docs.python.org/3/library/venv.html)
