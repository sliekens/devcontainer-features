# Troubleshooting

## Effective config is wrong

Symptoms:

- unexpected merged values
- wrong features, mounts, env, or service selection

Actions:

1. Run `devcontainer read-configuration`.
2. Check repository context and config discovery path.
3. Confirm legacy keys were migrated instead of mixed with canonical keys.

## Container startup hangs or attach fails

Symptoms:

- `up` never completes
- attach stalls after create

Actions:

1. Inspect lifecycle order and `waitFor`.
2. Re-run with higher log level.
3. Use `--skip-post-create` or `--prebuild` to isolate lifecycle phases.

## Workspace or mount path is wrong

Symptoms:

- repository not mounted correctly
- wrong `workspaceFolder`
- missing `.git` inside container

Actions:

1. Validate `workspaceMount` and `workspaceFolder` as a pair.
2. In Compose mode, confirm service mount target matches `workspaceFolder`.
3. Replace remote-incompatible bind mounts with volumes or tool-compatible alternatives when needed.

## Feature install or order fails

Symptoms:

- dependency cycle
- missing dependency
- install runs in unexpected order

Actions:

1. Confirm the Feature context is correct: project-local vs dedicated repository.
2. Expand `dependsOn` recursively.
3. Check `installsAfter` and consuming `overrideFeatureInstallOrder` for contradictions.
4. Confirm local Features live under `.devcontainer/` and use relative `./` references.

## Feature packaging or publish fails

Symptoms:

- tarball misses required files
- tests or release flow fail

Actions:

1. Confirm file layout matches repository context.
2. Confirm `devcontainer-feature.json` and executable `install.sh` exist at feature root.
3. For dedicated repositories, use repo scripts or `devcontainer features ...`.

## CLI command cannot find the right target

Symptoms:

- `exec` fails to find a running container
- `up` or `read-configuration` targets the wrong repo

Actions:

1. Pass explicit `--workspace-folder`.
2. Use `--container-id` or `--id-label` when acting on an existing container.
3. Check whether current working directory mismatches the intended repository root.
