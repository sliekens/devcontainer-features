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
    "ghcr.io/sliekens/devcontainer-features/ansible:2": {
        "collections": "community.general,ansible.posix",
        "roles": "geerlingguy.docker"
    }
}
```

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
