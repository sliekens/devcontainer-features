# Configuration

Use this reference for repository dev container definition work: `devcontainer.json`, Dockerfile/image/Compose selection, lifecycle, env, mounts, and compatibility.

## Core rules

- `image` is required in image mode.
- `build.dockerfile` is the canonical Dockerfile key.
- If legacy top-level `dockerFile` is encountered, migrate it to `build.dockerfile` during edits.
- `dockerComposeFile` and `service` are required in Compose mode.
- In Compose mode, `workspaceFolder` must resolve to the in-container workspace path.

## Orchestration selection

- Image mode:
  - fastest when a maintained base image already captures the toolchain
- Dockerfile mode:
  - use when repo-specific build dependencies or system packages belong in the image
- Compose mode:
  - use when the dev environment requires multiple cooperating services

See [decision trees](decision-trees.md) for the chooser.

## Lifecycle contract

Order is fixed:

1. `initializeCommand`
2. `onCreateCommand`
3. `updateContentCommand`
4. `postCreateCommand`
5. `postStartCommand`
6. `postAttachCommand`

Behavior:

- failures short-circuit later lifecycle steps
- `waitFor` defaults to `updateContentCommand`
- object-form commands run in parallel within that object only

## Env, users, and merge behavior

- `containerEnv` is static container state
- `remoteEnv` is session-oriented/editor-side state
- `containerUser` affects container processes
- `remoteUser` affects remote/editor operations
- local `devcontainer.json` wins over image metadata where merge precedence matters

## `remoteUser`

- `remoteUser` is the user tools and editors should use for their processes inside the container.
- `remoteUser` also applies to lifecycle-related processes that run after container creation.
- If `remoteUser` is not set, it defaults to the container user.
- `remoteUser` does not change the user the container as a whole runs as; that is `containerUser`.
- `remoteUser` can be inherited from image metadata, and merge precedence is last value wins.

Operational guidance:

- Use `containerUser` when the whole container runtime should run as that user.
- Use `remoteUser` when the container may keep one runtime user, but developer-facing processes should run as another.
- On Linux, if bind mounts are involved and `remoteUser` or `containerUser` is set, check `updateRemoteUserUID` to avoid permission problems.
- Do not treat `remoteUser` as a substitute for `containerUser`; they solve different problems.
- When creating Features, remember Feature scripts receive `_REMOTE_USER` and `_REMOTE_USER_HOME`.

Important merge behaviors:

- `containerEnv` / `remoteEnv`: last value wins per key
- `forwardPorts`: union without duplicates
- `mounts`: list union with last conflicting source winning
- `hostRequirements`: max-like merge for numeric resource requirements
- `shutdownAction`: last value wins

## Compatibility notes

- Prefer `forwardPorts` over `appPort`.
- Codespaces ignores most bind mounts except specific cases like the Docker socket.
- Clone Repository in Container Volume mode has `workspaceMount` / `workspaceFolder` limitations in some tools.
- Treat tool-specific `customizations` as implementation-specific contracts.

## Migration guidance

When editing existing config:

- migrate top-level `dockerFile` to `build.dockerfile`
- keep `workspaceMount` and `workspaceFolder` paired if either is customized
- replace brittle local-only bind mounts with volume or tool-compatible alternatives when remote/cloud support matters

## Validation path

- Use [checklists](checklists.md) for schema and layout validation.
- Use [cli](cli.md) for `read-configuration`, `build`, and `up`.
- Use [persistence](persistence.md) when choosing image layers vs mounts vs volumes.
