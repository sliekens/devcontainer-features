# My Dev Container Features

A collection of [dev container features](https://containers.dev/implementors/features/) for personal use.

## Usage

Reference features in your `devcontainer.json`:

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/sliekens/devcontainer-features/ansible-core:1": {
            "collections": "community.general"
        }
    }
}
```

## Available Features

| Feature | Description |
|---------|-------------|
| [`ansible`](src/ansible/README.md) | Installs Ansible CLI tooling (`ansible-core`/`ansible`) |
| [`ansible-lint`](src/ansible-lint/README.md) | Installs `ansible-lint` via pip |
| [`codex`](src/codex/README.md) | Installs the OpenAI Codex CLI (latest release) |
| [`claude`](src/claude/README.md) | Installs the Anthropic Claude CLI with shared state |
| [`tea`](src/tea/README.md) | Installs the Gitea CLI from releases and enables shell completion via `profile.d` |

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
