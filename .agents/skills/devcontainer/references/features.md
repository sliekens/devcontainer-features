# Features

Use this reference for Dev Container Feature creation and maintenance, whether the Feature is local to one repository or lives in a dedicated Feature collection.

## Lock context first

Choose one context before creating files.

- Project-local Feature:
  - lives under `.devcontainer/<feature-id>/`
  - referenced from consuming `devcontainer.json` as `./<feature-id>`
  - best when the Feature is only meant for one repository
- Dedicated Feature repository:
  - lives under `src/<feature-id>/`
  - optional tests under `test/<feature-id>/`
  - best when the Feature needs semver release flow and reuse across repositories

Do not mix the two layouts in one task.

## Required metadata

- `id`, `version`, and `name`
- `id` must match the feature directory name
- keep `id` lowercase

Recommended metadata:

- `description`
- `documentationURL`
- `licenseURL`
- `keywords`

## Options

- option types are `string` or `boolean`
- include a `default` for every option
- use `enum` for strict values
- use `proposals` for suggested but open-ended values
- option names are normalized to env vars for `install.sh`

## Install script contract

- `install.sh` runs as `root`
- keep it idempotent
- keep it compatible with the supported distro family
- treat repeated installation as possible, especially when the same Feature appears with different options
- keep heavy immutable work in the install step, not in consuming repo lifecycle hooks

## Dependencies and order

- `dependsOn` is hard and recursive
- `installsAfter` is soft and non-recursive
- `overrideFeatureInstallOrder` belongs in the consuming `devcontainer.json`, not the Feature metadata
- cycles or inconsistent ordering should fail resolution

## Distribution

- local Features must stay under `.devcontainer/` and use relative `./` references
- dedicated repositories package the contents of the feature folder
- packaged tarball name is `devcontainer-feature-<id>.tgz`
- OCI publish should carry semver tags and metadata annotation support where tooling provides it

## Lifecycle contributed by Features

Feature lifecycle hooks run before user-provided `devcontainer.json` hooks for the same lifecycle phase.

Supported hook types:

- string
- array
- object

Object form runs commands in parallel within the object only.

## Persistence-specific rules

- If a Feature needs assets after install, copy them somewhere persistent outside `/tmp`.
- Do not assume installers or temporary extracted files remain available after the build.
- Distinguish image-time state from runtime state:
  - use `install.sh` for image-layer files and helper-script installation
  - if a path is populated by a Feature `mounts` entry, treat it as runtime state
  - ownership fixes, first-run migration, and reconciliation with existing user files for mounted paths belong in a runtime lifecycle hook, because the mount hides image-layer changes made during `install.sh`
- For per-devcontainer durable storage, named volumes plus `${devcontainerId}` are the right pattern when the data must survive rebuilds without colliding across containers.
- Avoid hardcoding user-home paths like `/home/vscode` in Feature metadata `mounts`.
- If persistence needs to be tied to the eventual dev user, prefer:
  - a neutral/stable mount target, or
  - configuring the user-scoped path from `install.sh` using `_REMOTE_USER_HOME` when only image-layer state is involved
  - configuring the user-scoped path from lifecycle logic when it depends on mounted runtime state or the final runtime home
- Use Feature metadata `mounts` for user-independent paths when possible.
- If the correct persistent path depends on the consuming repo's final user model, prefer putting that mount in the consuming `devcontainer.json` instead of the Feature metadata.

Example pattern for mounted per-devcontainer state:

```json
{
  "id": "my-feature",
  "name": "My Feature",
  "version": "1.0.0",
  "mounts": [
    {
      "source": "my-feature-data-${devcontainerId}",
      "target": "/var/lib/my-feature",
      "type": "volume"
    }
  ],
  "onCreateCommand": "/usr/local/share/my-feature/on_create.sh"
}
```

```bash
# install.sh
install -d -m 0755 /usr/local/share/my-feature
install -m 0755 ./on_create.sh /usr/local/share/my-feature/on_create.sh
```

```bash
# on_create.sh
#!/usr/bin/env bash
set -euo pipefail

install -d -m 0755 /var/lib/my-feature
if command -v sudo >/dev/null 2>&1; then
  sudo -n chown -R "$(id -u):$(id -g)" /var/lib/my-feature || chown -R "$(id -u):$(id -g)" /var/lib/my-feature
else
  chown -R "$(id -u):$(id -g)" /var/lib/my-feature
fi

install -d -m 0755 "$HOME/.local/share"
ln -snf /var/lib/my-feature "$HOME/.local/share/my-feature"
```

Why this works:

- the volume target is stable and user-independent
- the user-facing path is derived from the actual runtime home
- the symlink keeps tools happy without hardcoding `/home/vscode`
- ownership is applied to the mounted volume, not to an image layer that will be hidden at container start

## Validation and release path

- project-local context:
  - validate directory layout and local reference shape in the consuming `devcontainer.json`
- dedicated repository context:
  - use repo-provided scripts if present
  - in this repository, use `./scripts/test.sh <feature-id>` and `./scripts/publish.sh <feature-id>`
  - or use [cli](cli.md) for `devcontainer features ...`

Use [decision trees](decision-trees.md), [checklists](checklists.md), and [troubleshooting](troubleshooting.md) as needed.
