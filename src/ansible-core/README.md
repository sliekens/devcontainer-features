# Ansible Core (ansible-core)

Install Ansible Core tooling using `pipx`.

This feature installs:
- `ansible-core` via `pipx`
- Optional Ansible Galaxy collections and roles

This feature depends on `ghcr.io/devcontainers/features/python:1` to provide Python tooling (`pipx`/`pip`).

## Example Usage

```json
"features": {
    "ghcr.io/sliekens/devcontainer-features/ansible-core:1": {
        "collections": "community.general,ansible.posix",
        "roles": "geerlingguy.docker"
    }
}
```

## Compatibility

This version supports images where the Python feature can provide `pipx`.
