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

## AI assisted installation

Copy the block below into a chat with your coding agent:

> Add `ghcr.io/sliekens/devcontainer-features/worktrunk:1` to this project's Dev Container. Follow https://github.com/sliekens/devcontainer-features/blob/main/src/worktrunk/README.md. Use the collection's shared `initializeCommand` pipeline (devcontainer + jq + xargs over `customizations.sliekens[].initializeCommand`) for host bind pre-create; Unix/WSL2 only. Prefer that over hand-written `mkdir` unless asked.

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

Docker cannot bind-mount host paths that do not yet exist. Each feature in this collection that needs host paths declares a host init command under `customizations.sliekens.initializeCommand`. Wire a single `initializeCommand` in your `devcontainer.json` to run all of them (works for any number of features):

```json
"initializeCommand": "devcontainer read-configuration --workspace-folder . --include-merged-configuration | jq -r '(.mergedConfiguration.customizations.sliekens // []) | .[] | .initializeCommand' | xargs -I{} bash -c {}"
```

Requires `devcontainer` and `jq` on the host `PATH`.

> **Note:** This host init pipeline runs only on Unix-like systems (Linux, macOS, and source code inside WSL2 on Windows). Native Windows (`cmd.exe`) is not supported — the Dev Containers CLI runs `initializeCommand` via `/bin/sh -c` on Unix and `cmd.exe /c` on native Windows.

### Manual alternative

If you prefer not to automate with the Dev Containers CLI, `jq`, and `xargs`, pre-create the host paths yourself in `initializeCommand`:

```json
"initializeCommand": "mkdir -p \"$HOME/.config/worktrunk\""
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

## 1.1.1 - 2026-08-01
- Declare `customizations.sliekens.initializeCommand` for composable host path pre-create; document automated and manual `initializeCommand` wiring.

## 1.1.0 - 2026-07-31
- Install system config at `/etc/xdg/worktrunk/config.toml` with nested `worktree-path` (`.worktrees/{{ branch }}`) so worktrees land on the workspace mount as an unprivileged user.
- Does not modify user or project `worktree-path`; user/project config can still override the system default.

## 1.0.0 - 2026-07-25
- Initial release.
