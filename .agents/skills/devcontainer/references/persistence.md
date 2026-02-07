# Persistence

Use this reference when state placement matters.

## Persistence model

Choose where state belongs before adding installs, mounts, or caches.

- Image layer:
  - immutable toolchains and system packages
  - survives rebuild outputs because it is part of the built image
- Workspace mount:
  - live repository files
  - usually bind-mounted source code
- Named volume or additional mount:
  - durable runtime state that should survive container recreation or rebuilds
  - preferred for caches or per-devcontainer data that should not live in the workspace
- CLI host state:
  - `--user-data-folder` for persisted CLI/user state across sessions
  - `--container-session-data-folder` for session-oriented CLI caches

## Guidance

- Put stable dependencies in image layers, not in per-start commands.
- Put mutable runtime data in mounts or volumes.
- Prefer volumes over bind mounts when cloud or remote compatibility matters.
- Treat bind mounts carefully on Linux when UID/GID mapping matters.

## Unsupported or tool-limited persistence

- Do not assume `workspaceMount` is universally available:
  - some tools do not support `workspaceMount`, `workspaceFolder`, and related local workspace variables in Clone Repository in Container Volume mode
- Do not assume bind mounts are portable to cloud-hosted environments:
  - Codespaces ignores bind mounts except the Docker socket
  - volume mounts remain the safer persistence mechanism there
- Do not assume a bind-mounted workspace exposes the same underlying filesystem in local and remote environments:
  - cloud environments may not have access to the same host paths as a local machine
- If remote or cloud compatibility matters, prefer:
  - default workspace behavior where possible
  - named volumes for durable state
  - avoiding host-path-specific persistence assumptions

## Feature-specific persistence

- Do not assume Feature installer files remain available after the initial build.
- If a lifecycle hook needs a bundled asset later, copy it to a persistent in-container path outside `/tmp`.
- Use Feature `mounts` only when the mount is part of the intended runtime contract.
- Do not hardcode `/home/vscode` or another fixed user-home path in Feature metadata unless the Feature is intentionally image-specific.
- If persistence belongs conceptually to the developer user, prefer:
  - a user-independent persistent location, or
  - resolving the home path at install/runtime via `_REMOTE_USER_HOME`
- If the final mount target depends on the consuming repository's chosen `remoteUser`, the consuming `devcontainer.json` is usually the right place for that mount.

Recommended Feature pattern:

1. Mount a named volume to a stable path such as `/var/lib/<feature>`.
2. In `install.sh`, create the user-facing directory or symlink under `_REMOTE_USER_HOME`.
3. Fix ownership for both the stable volume path and the user-facing symlink/target.

Example:

```json
"mounts": [
  {
    "source": "my-feature-data-${devcontainerId}",
    "target": "/var/lib/my-feature",
    "type": "volume"
  }
]
```

```bash
install -d -m 0755 /var/lib/my-feature
install -d -m 0755 "${_REMOTE_USER_HOME}/.local/share"
ln -snf /var/lib/my-feature "${_REMOTE_USER_HOME}/.local/share/my-feature"
chown -h "${_REMOTE_USER}:${_REMOTE_USER}" "${_REMOTE_USER_HOME}/.local/share/my-feature"
chown -R "${_REMOTE_USER}:${_REMOTE_USER}" /var/lib/my-feature
```

## `${devcontainerId}`

- `${devcontainerId}` is intended for values that must be unique per dev container and stable across rebuilds.
- Use it for things like per-container volume names.
- Do not use it in build-time fields that would break prebuild flows.

## Common choices

- language/toolchain install -> image layer or Feature install step
- repo bootstrap cache -> volume or cache directory with explicit lifecycle handling
- database/data-dir for local dev -> named volume
- editor/session probe cache -> `--container-session-data-folder`
