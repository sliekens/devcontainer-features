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
