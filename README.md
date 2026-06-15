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
| [`mistral-vibe`](src/mistral-vibe/README.md) | Installs Mistral Vibe CLI coding agent using Python virtual environment and persists shared state across devcontainers. |
| [`mono`](src/mono/README.md) | Installs `mono-complete` from the official Mono stable repository |
| [`opencode`](src/opencode/README.md) | Installs `opencode` from official GitHub release assets and persists shared state across devcontainers. |
| [`rename-user`](src/rename-user/README.md) | Renames the default container user (`vscode`) to match the configured `remoteUser`, preserving sudo access. |
| [`tea`](src/tea/README.md) | Installs the Gitea CLI (`tea`) from Gitea releases and enables shell completion via bash_completion.d and zsh site-functions. |
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
