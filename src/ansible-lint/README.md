# Ansible Lint (ansible-lint)

Install `ansible-lint` via `pipx` and inject `ansible-core` into the same environment for compatibility.

This feature depends on `ghcr.io/devcontainers/features/python:1` to provide Python tooling (`pipx`/`pip`).

## Example Usage

```json
"features": {
    "ghcr.io/sliekens/devcontainer-features/ansible:2": {},
    "ghcr.io/sliekens/devcontainer-features/ansible-lint:1": {}
}
```


## License

This feature is released under the [MIT License](https://github.com/sliekens/devcontainer-features/blob/main/LICENSE).

The installed tool is subject to its own license: [ansible-lint license](https://github.com/ansible/ansible-lint/blob/main/COPYING).

## Links

- [ansible-lint documentation](https://docs.ansible.com/projects/lint/)

## Release Notes

## 1.0.0 - 2026-03-26
- Initial release.
