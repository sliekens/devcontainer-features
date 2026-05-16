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

Because Docker cannot bind-mount a directory that does not yet exist, consuming `devcontainer.json` files should add an `initializeCommand` to pre-create this directory on the host before the container starts:

```json
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/sliekens/devcontainer-features/mistral-vibe:1": {}
  },
  "initializeCommand": "mkdir -p \"$HOME/.vibe\""
}
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
