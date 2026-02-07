# Checklists

## Context lock

- [ ] Lock task family first: definition, Feature, or CLI
- [ ] Lock repository context first: application repo, project-local Feature, or dedicated Feature repository
- [ ] Keep file layout and release path aligned with that context

## Definition work

- [ ] Use `build.dockerfile`, not legacy top-level `dockerFile`
- [ ] If legacy top-level `dockerFile` exists, migrate it
- [ ] Choose exactly one primary mode: image, Dockerfile, or Compose
- [ ] Validate lifecycle placement and `waitFor`
- [ ] Validate user/env split: `containerEnv` vs `remoteEnv`
- [ ] Validate mounts, workspace path, and cross-tool compatibility
- [ ] Prefer `forwardPorts` over `appPort`

## Feature work

- [ ] Feature `id` is lowercase and matches the directory name
- [ ] Project-local context uses `.devcontainer/<feature-id>/`
- [ ] Dedicated repository context uses `src/<feature-id>/`
- [ ] `devcontainer-feature.json` includes required metadata
- [ ] `install.sh` is executable and idempotent
- [ ] `dependsOn` and `installsAfter` are used correctly
- [ ] Local Features use relative `./<feature-id>` references from `.devcontainer/`
- [ ] Dedicated repositories add tests and release notes where appropriate

## CLI work

- [ ] Use explicit `--workspace-folder` or container targeting
- [ ] Use `read-configuration` before debugging merge or targeting issues
- [ ] Use `--output-format json` only where the current command supports it
- [ ] Use deterministic log level and state folders when scripting

## Persistence

- [ ] Decide what must survive rebuilds vs only survive container restarts
- [ ] Put immutable dependencies in image layers
- [ ] Put shared or durable runtime state in mounts/volumes
- [ ] Do not rely on `/tmp` for Feature assets needed after install
- [ ] Use `${devcontainerId}` only in fields where prebuild safety is preserved

## Close-out

- [ ] Validation path is documented
- [ ] Publish or release path matches the locked repository context
- [ ] Troubleshooting notes exist for any non-obvious tradeoff
