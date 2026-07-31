# Worktrunk (worktrunk)

Installs the [Worktrunk](https://worktrunk.dev) CLI (`wt` and `git-wt`) from official GitHub release assets, sets a container-safe system default for worktree placement, sets up shell integration with tab completions, and persists `~/.config/worktrunk` across devcontainers.

Worktrunk manages git worktrees for parallel AI agent workflows.

## Example Usage

```json
"features": {
    "ghcr.io/sliekens/devcontainer-features/worktrunk:1": {}
}
```

Pin a specific version when you need deterministic builds:

```json
"features": {
    "ghcr.io/sliekens/devcontainer-features/worktrunk:1": {
        "version": "0.69.2"
    }
}
```

Skip shell integration if you manage your own rc files:

```json
"features": {
    "ghcr.io/sliekens/devcontainer-features/worktrunk:1": {
        "tabCompletions": false
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `version` | string | `latest` | Version to install. Use `latest` for the most recent release, or specify a version like `0.69.2` or `v0.69.2`. |
| `tabCompletions` | boolean | `true` | Install Worktrunk shell integration (tab completions and the `wt` directory-switching wrapper) for bash, zsh, and fish. |

## Supported Platforms

Linux containers on `x86_64` and `aarch64`. The feature installs the statically linked musl builds, which run on both glibc and musl based images.

## Shell Integration

With `tabCompletions` enabled (the default), the feature adds a snippet to the system rc files (`/etc/bash.bashrc`, `/etc/zsh/zshrc`, `/etc/fish/conf.d/worktrunk.fish`) that evaluates `wt config shell init <shell>` at shell startup.

That snippet is what Worktrunk itself installs via `wt config shell install`. It registers tab completions *and* defines the `wt` shell function that lets `wt switch` change the current directory — without it, `wt` still runs but cannot move your shell into a worktree.

Because the snippet is evaluated at startup rather than baked in, it stays correct if `wt` is later upgraded inside the container.

The integration only applies to interactive shells. To use it in a script, source the rc file or run `eval "$(wt config shell init bash)"` explicitly.

## Worktree path default

Worktrunk’s upstream default creates worktrees as **siblings** of the repository directory:

```text
/workspace          → main worktree
/workspace.topic    → worktree for branch "topic"
```

That fails in typical Dev Containers: the workspace is bind-mounted at `/workspace` (or similar), the process runs as an unprivileged `remoteUser`, and creating `/workspace.topic` requires write access to `/`.

This feature installs a **system** config file that nests worktrees under the repository instead:

| Path | Role |
|------|------|
| `/etc/xdg/worktrunk/config.toml` | System default (feature-managed) |

```toml
worktree-path = "{{ repo_path }}/.worktrees/{{ branch | sanitize }}"
```

Example with the workspace at `/workspace` and branch `topic`:

```text
/workspace                     → main worktree
/workspace/.worktrees/topic    → worktree for branch "topic"
```

New worktrees therefore stay on the same bind mount (or named volume) as the project.

This feature does **not** write `worktree-path` into user config (`~/.config/worktrunk`) or project config (`.config/wt.toml`). You can still override the system default in either place; user config wins over system config. For example, restore sibling layout when the parent of the repo is writable:

```toml
# ~/.config/worktrunk/config.toml
worktree-path = "{{ repo_path }}/../{{ repo }}.{{ branch | sanitize }}"
```

If you keep nested worktrees, add `.worktrees/` to the repository’s `.gitignore` (or equivalent) so checkouts are not committed by accident.

## Persistent State

| Host path | Container path | Purpose |
|-----------|---------------|---------|
| `~/.config/worktrunk` | `/var/lib/worktrunk-config` | User configuration (`config.toml`), approvals, and plugin settings |

This directory is bind-mounted from the host so that configuration is preserved across container rebuilds.

Because Docker cannot bind-mount a directory that does not yet exist, consuming `devcontainer.json` files should add an `initializeCommand` to pre-create this directory on the host before the container starts:

```json
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/sliekens/devcontainer-features/worktrunk:1": {}
    },
    "initializeCommand": "mkdir -p \"$HOME/.config/worktrunk\""
}
```

Per-repository state lives in `.git/wt/` inside each worktree and is not managed by this feature.

## Requirements

Worktrunk drives `git`, so the container needs `git` on `PATH`. Devcontainer base images already include it; otherwise add `ghcr.io/devcontainers/features/git`.

## License

This feature is released under the [MIT License](https://github.com/sliekens/devcontainer-features/blob/main/LICENSE).

The installed tool is subject to its own license: [worktrunk license](https://github.com/max-sixty/worktrunk/blob/main/LICENSE).

## Links

- [Worktrunk documentation](https://worktrunk.dev)
- [Worktrunk on GitHub](https://github.com/max-sixty/worktrunk)

## Release Notes

## 1.1.0 - 2026-07-31
- Install system config at `/etc/xdg/worktrunk/config.toml` with nested `worktree-path` (`.worktrees/{{ branch }}`) so worktrees land on the workspace mount as an unprivileged user.
- Does not modify user or project `worktree-path`; user/project config can still override the system default.

## 1.0.0 - 2026-07-25
- Initial release.
