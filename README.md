# My Dev Container Features

A collection of opinionated [dev container features](https://containers.dev/implementors/features/) built for my own workflows — open for anyone to use.

## Usage

Reference features in your `devcontainer.json`:

```jsonc
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/sliekens/devcontainer-features/ansible-core:1": {
      "collections": "community.general",
    },
  },
}
```

### Host path pre-create (bind mounts)

Several features bind-mount host paths (CLI auth and config) so state is shared with tools on the host. Docker cannot mount those sources until they exist.

Features that need this declare a host init command under `customizations.sliekens.initializeCommand`. Add **one** `initializeCommand` to your `devcontainer.json` — it runs every feature’s command and composes when you enable more than one:

```json
"initializeCommand": "devcontainer read-configuration --workspace-folder . --include-merged-configuration | jq -r '(.mergedConfiguration.customizations.sliekens // []) | .[] | .initializeCommand' | xargs -I{} bash -c {}"
```

Requires `devcontainer` and `jq` on the host `PATH`.

> **Note:** This pipeline runs only on Unix-like systems (Linux, macOS, and source code inside WSL2 on Windows). Native Windows (`cmd.exe`) is not supported — the Dev Containers CLI runs `initializeCommand` via `/bin/sh -c` on Unix and `cmd.exe /c` on native Windows.

As an alternative to automating with the Dev Containers CLI, `jq`, and `xargs`, you can pre-create the host paths yourself (see each feature’s README for the exact `mkdir` / `touch` recipe).

## Available Features

<!-- BEGIN FEATURES TABLE -->
| Feature | Description |
|---------|-------------|
| [`ansible`](src/ansible/README.md) | Installs `ansible` and associated CLI tools using pipx |
| [`ansible-core`](src/ansible-core/README.md) | Installs `ansible-core` via pipx with optional Ansible Galaxy collections and roles |
| [`ansible-lint`](src/ansible-lint/README.md) | Installs `ansible-lint` using pipx |
| [`aspire-cli`](src/aspire-cli/README.md) | Installs the Aspire CLI (`aspire`) |
| [`bitwarden-agent-access`](src/bitwarden-agent-access/README.md) | Installs the Bitwarden Agent Access CLI (`aac`) binary from Bitwarden release assets. |
| [`bitwarden-cli`](src/bitwarden-cli/README.md) | Installs the official Bitwarden CLI (`bw`) binary from Bitwarden release assets. |
| [`bitwarden-secrets-manager`](src/bitwarden-secrets-manager/README.md) | Installs the Bitwarden Secrets Manager CLI (`bws`) binary from Bitwarden release assets. |
| [`claude`](src/claude/README.md) | Installs `claude` (Claude Code) via the upstream native installer and persists shared state across devcontainers. |
| [`codex`](src/codex/README.md) | Installs the OpenAI `codex` CLI from the official packaged release assets and persists `~/.codex` in shared state across devcontainers. |
| [`copilot`](src/copilot/README.md) | Installs the GitHub `copilot` CLI from official release assets and persists shared `~/.copilot` state across devcontainers. |
| [`github-cli`](src/github-cli/README.md) | Wraps the official `gh` (GitHub CLI) feature and adds persistent volume mounts for config and state |
| [`grok-build`](src/grok-build/README.md) | Installs the xAI `grok` CLI (Grok Build) via the upstream installer and persists shared `~/.grok` state across devcontainers. |
| [`mistral-vibe`](src/mistral-vibe/README.md) | Installs Mistral Vibe CLI coding agent using Python virtual environment and persists shared state across devcontainers. |
| [`mono`](src/mono/README.md) | Installs `mono-complete` from the official Mono stable repository |
| [`omp`](src/omp/README.md) | Installs the Oh My Pi coding agent CLI (`omp`) from official prebuilt release assets (noninteractive, derived from https://omp.sh/install) and persists shared `~/.omp` state across devcontainers. Requires Bun 1.3.14+ or Node.js as a peer dependency for the full harness. |
| [`opencode`](src/opencode/README.md) | Installs `opencode` from official GitHub release assets and persists shared state across devcontainers. |
| [`pi`](src/pi/README.md) | Installs the Pi coding agent CLI (`pi`) via a noninteractive npm install and persists shared `~/.pi` state across devcontainers. Requires Node.js 22.19+ with npm as a peer dependency. |
| [`rename-user`](src/rename-user/README.md) | Renames the default container user (`vscode`) to match the configured `remoteUser`, preserving sudo access. |
| [`tea`](src/tea/README.md) | Installs the Gitea CLI (`tea`) from Gitea releases and enables shell completion via bash_completion.d and zsh site-functions. |
| [`worktrunk`](src/worktrunk/README.md) | Installs the Worktrunk CLI (`wt` and `git-wt`) from official GitHub release assets, sets a container-safe system worktree-path default, and persists `~/.config/worktrunk` across devcontainers. |
<!-- END FEATURES TABLE -->

## Registry

Features are published to: `ghcr.io/sliekens/devcontainer-features/<feature-id>:<version>`

### Version Tags

Each feature is published with multiple version tags following [semver](https://semver.org/):

- `:1` - Major version (recommended for most users)
- `:1.0` - Minor version
- `:1.0.0` - Exact patch version
- `:latest` - Latest version (may include breaking changes)

**Recommendation**: Pin to the major version (e.g., `:1`) to receive bug fixes and minor updates without breaking changes.

## Development

See [CONTRIBUTING.md](CONTRIBUTING.md) for information on:

- Creating new features
- Testing features locally
- Publishing to the registry

## Resources

- [Dev Container Feature Specification](https://containers.dev/implementors/features/)
- [Feature Distribution Specification](https://containers.dev/implementors/features-distribution/)
- [Dev Container CLI](https://github.com/devcontainers/cli)
