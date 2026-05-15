# Claude CLI (claude)

Installs the official Anthropic Claude CLI using the upstream installer (`https://claude.ai/install.sh`) and persists shared `~/.claude` state across devcontainers.

## Example Usage

```json
"features": {
    "ghcr.io/sliekens/devcontainer-features/claude:1": {
        "version": "stable"
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `stable` | Version/channel to install. Use `stable`, `latest`, or a specific version (e.g. `2.1.58`). |

## Persistent State

| Host path | Container path | Purpose |
|-----------|---------------|---------|
| `~/.claude` | `/var/lib/claude-container/data` | Auth, settings, and conversation history |
| `~/.claude.json` | `/var/lib/claude-container/claude.json` | Settings file |

These paths are bind-mounted from the host so that auth and settings are preserved across container rebuilds.

Because Docker cannot bind-mount paths that do not yet exist, consuming `devcontainer.json` files should add an `initializeCommand` to pre-create these paths on the host before the container starts:

```json
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/sliekens/devcontainer-features/claude:1": {
            "version": "stable"
        }
    },
    "initializeCommand": "mkdir -p \"$HOME/.claude\" && { [ -f \"$HOME/.claude.json\" ] || touch \"$HOME/.claude.json\"; }"
}
```

## Known Issues

Claude stores absolute paths in its settings, e.g. for marketplace plugins. If the container username differs from the host username (e.g. `vscode` vs `steven`), the container home directory will be `/home/vscode` while the bind-mounted settings files contain paths rooted at `/home/steven`. These paths will not resolve correctly inside the container.

Add the [`rename-user`](../rename-user/README.md) feature alongside this one. It reads `remoteUser` and renames the default `vscode` user at image build time — no custom Dockerfile needed.

```json
{
    "remoteUser": "${localEnv:USER}",
    "features": {
        "ghcr.io/sliekens/devcontainer-features/rename-user:1": {},
        "ghcr.io/sliekens/devcontainer-features/claude:1": {
            "version": "stable"
        }
    },
    "initializeCommand": "mkdir -p \"$HOME/.claude\" && { [ -f \"$HOME/.claude.json\" ] || touch \"$HOME/.claude.json\"; }"
}
```

The container home directory matches the host home directory, so all absolute paths in Claude's settings resolve correctly. Auth, settings, and history are shared between the container and any Claude CLI installed directly on the host.


## License

This feature is released under the [MIT License](https://github.com/sliekens/devcontainer-features/blob/main/LICENSE).

The installed tool is subject to its own license: [Claude Code license](https://github.com/anthropics/claude-code/blob/main/LICENSE.md).

## Links

- [Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code/overview)

## Release Notes

## 1.2.3 - 2026-05-14
- Add trailing slash to bind mount source path to mark it explicitly as a directory.

## 1.2.2 - 2026-05-10
- Install after `rename-user` when present, so `chown` in `install.sh` resolves the container username correctly.

## 1.2.1 - 2026-04-18
- Fix `EACCES: permission denied` errors when Claude creates its lock directory. The bind mount targets moved from `/var/lib/claude` and `/var/lib/claude.json` to `/var/lib/claude-container/data` and `/var/lib/claude-container/claude.json`. The parent directory `/var/lib/claude-container/` is now owned by the container user so Claude can create adjacent lock directories without hitting permission errors.

## 1.2.0 - 2026-03-28
- Also bind mount `~/.claude.json` from the host for persistent settings.

## 1.1.0 - 2026-03-28
- Use bind mount from host `~/.claude` instead of a Docker volume for persistent state.

## 1.0.0 - 2026-03-26
- Initial release.
