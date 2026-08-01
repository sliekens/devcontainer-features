# Ansible (ansible)

Install Ansible CLI tooling using `pipx`.

This feature installs:
- `ansible` via `pipx`
- Optional Ansible Galaxy collections and roles

This feature depends on `ghcr.io/devcontainers/features/python:1` to provide Python tooling (`pipx`/`pip`).

If you only need core tooling, use `ansible-core`.

If you also want linting, use the separate `ansible-lint` feature.

## Example Usage

```json
"features": {
    "ghcr.io/sliekens/devcontainer-features/ansible:1": {
        "collections": "community.general,ansible.posix",
        "roles": "geerlingguy.docker"
    }
}
```

## AI assisted installation

Copy the block below into a chat with your coding agent:

> Add `ghcr.io/sliekens/devcontainer-features/ansible:1` to this project's Dev Container. Follow https://github.com/sliekens/devcontainer-features/blob/main/src/ansible/README.md. Use the collection's shared `initializeCommand` pipeline (devcontainer + jq + xargs over `customizations.sliekens[].initializeCommand`) for host bind pre-create; Unix/WSL2 only. Prefer that over hand-written `mkdir` unless asked.

## Compatibility

This version supports images where the Python feature can provide `pipx`.


## License

This feature is released under the [MIT License](https://github.com/sliekens/devcontainer-features/blob/main/LICENSE).

The installed tool is subject to its own license: [Ansible license](https://github.com/ansible/ansible/blob/devel/COPYING).

## Links

- [Ansible documentation](https://docs.ansible.com)

## Release Notes

## 1.0.0 - 2026-03-26
- Initial release.
