# Ansible Lint (ansible-lint)

Install `ansible-lint` via `pipx` and inject `ansible-core` into the same environment for compatibility.

This feature depends on `ghcr.io/devcontainers/features/python:1` to provide Python tooling (`pipx`/`pip`).

## Example Usage

```json
"features": {
    "ghcr.io/sliekens/devcontainer-features/ansible:1": {},
    "ghcr.io/sliekens/devcontainer-features/ansible-lint:1": {}
}
```


## AI assisted installation

Copy the block below into a chat with your coding agent:

> Add `ghcr.io/sliekens/devcontainer-features/ansible-lint:1` to this project's Dev Container. Follow https://github.com/sliekens/devcontainer-features/blob/main/src/ansible-lint/README.md. Use the collection's shared `initializeCommand` pipeline (devcontainer + jq + xargs over `customizations.sliekens[].initializeCommand`) for host bind pre-create; Unix/WSL2 only. Prefer that over hand-written `mkdir` unless asked.

## License

This feature is released under the [MIT License](https://github.com/sliekens/devcontainer-features/blob/main/LICENSE).

The installed tool is subject to its own license: [ansible-lint license](https://github.com/ansible/ansible-lint/blob/main/COPYING).

## Links

- [ansible-lint documentation](https://docs.ansible.com/projects/lint/)

## Release Notes

## 1.0.0 - 2026-03-26
- Initial release.
