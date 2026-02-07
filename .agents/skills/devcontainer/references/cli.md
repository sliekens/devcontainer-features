# CLI

Use this reference for exact `devcontainer` CLI workflows.

Status:

- derived from the installed CLI help output in this environment
- observed version: `devcontainer@0.84.0`

Re-check `devcontainer --help` before automating flags that may drift.

## Primary commands

- `devcontainer up`
  - create and run a dev container
- `devcontainer build [path]`
  - build the image only
- `devcontainer set-up`
  - configure an existing container as a dev container
- `devcontainer read-configuration`
  - inspect effective configuration
- `devcontainer run-user-commands`
  - rerun configured lifecycle/user commands
- `devcontainer exec <cmd>`
  - execute one command in a running container
- `devcontainer outdated`
  - inspect lockfile version drift
- `devcontainer upgrade`
  - update the lockfile

Feature commands:

- `devcontainer features test`
- `devcontainer features package`
- `devcontainer features publish`
- `devcontainer features info`
- `devcontainer features resolve-dependencies`

## Command chooser

- choose `read-configuration` first for merge or targeting questions
- choose `build` when only image validation is needed
- choose `up` when container creation and lifecycle behavior must be exercised
- choose `run-user-commands` when only user/lifecycle commands changed
- choose `exec` for one-off commands in a running container

## Shared flags

- targeting:
  - `--workspace-folder`
  - `--config`
  - `--override-config`
  - `--container-id`
  - `--id-label`
- diagnostics:
  - `--log-level`
  - `--include-configuration`
  - `--include-merged-configuration`
- reproducibility:
  - `--user-data-folder`
  - `--container-session-data-folder`
- lifecycle control:
  - `--skip-post-create`
  - `--skip-post-attach`
  - `--skip-non-blocking-commands`
  - `--prebuild`

## Output guidance

- `read-configuration` is the main inspection command for automation and debugging
- use `--output-format json` only on commands that advertise support for it
- do not assume `read-configuration` supports `--output-format` in this CLI version

## Examples

### Inspect effective config

```bash
devcontainer read-configuration \
  --workspace-folder /path/repo \
  --include-configuration \
  --include-merged-configuration
```

### Build image only

```bash
devcontainer build --workspace-folder /path/repo --log-level debug
```

### Start container

```bash
devcontainer up --workspace-folder /path/repo --log-level debug
```

### Run command in a running container

```bash
devcontainer exec npm test --workspace-folder /path/repo
```

### Test dedicated Feature repository

```bash
devcontainer features test --project-folder .
```
