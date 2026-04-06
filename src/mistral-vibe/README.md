# Mistral Vibe Dev Container Feature

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
- Version ranges supported by uv

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

| Host path | Container path | Purpose |
|-----------|---------------|---------|
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

### 1.0.1
- Fix absolute paths in `~/.vibe` config by replacing with `~`
- Ensures compatibility across different home directory paths

### 1.0.0
- Initial release
- Uses uv for installation
- State persistence for `.vibe` directory
- Version selection support

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

This feature is licensed under the same terms as the Mistral Vibe CLI itself. See the [Mistral Vibe License](https://github.com/mistralai/mistral-vibe/blob/main/LICENSE) for details.

## Links

- [Mistral Vibe Documentation](https://mistral.ai/products/vibe)
- [Mistral Vibe GitHub](https://github.com/mistralai/mistral-vibe)
- [Python Virtual Environments](https://docs.python.org/3/library/venv.html)
