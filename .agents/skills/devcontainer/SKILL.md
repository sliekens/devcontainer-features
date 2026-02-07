---
name: devcontainer
description: Create, update, validate, operate, and troubleshoot Dev Container setups, including `devcontainer.json`, local or published Dev Container Features, and `devcontainer` CLI workflows. Use for existing repos, project-local `.devcontainer` Features, dedicated Feature collections, config migration, lifecycle/debugging, and release or validation tasks.
---

# Dev Container

Use this skill for any task that changes or operates a dev container at the repository, Feature, or CLI layer.

## Mission and boundaries

- Cover three task families with one entry point:
  - repository dev container definitions
  - Dev Container Features
  - `devcontainer` CLI operations
- Lock repository context early so file layout and release path stay correct.
- Prefer canonical schema keys and migrate legacy keys during edits.
- Keep operational command details in references instead of the root workflow.

## First pass

1. Lock task family
- definition work: `devcontainer.json`, Dockerfile/image/compose, lifecycle, mounts, ports, env, customizations
- Feature work: project-local Feature or dedicated Feature repository
- CLI work: `devcontainer up/build/read-configuration/exec/features/...`

2. Lock repository context
- application repository with `.devcontainer/devcontainer.json`
- application repository with a project-local Feature under `.devcontainer/<feature-id>/`
- dedicated Feature collection repository with `src/<feature-id>/` and optional `test/<feature-id>/`

3. Load only the references needed
- definition work: [configuration](references/configuration.md)
- Feature work: [features](references/features.md)
- CLI work: [cli](references/cli.md)

4. Load shared references when needed
- [decision trees](references/decision-trees.md)
- [checklists](references/checklists.md)
- [troubleshooting](references/troubleshooting.md)
- [persistence](references/persistence.md)

## Branching workflow

### Definition work

- Read [configuration](references/configuration.md).
- Choose image vs Dockerfile vs Compose before editing.
- Migrate legacy top-level `dockerFile` to `build.dockerfile` instead of preserving it.
- Use [persistence](references/persistence.md) for mounts, volumes, and state placement.
- Use [cli](references/cli.md) for validation and inspection commands.

### Feature work

- Read [features](references/features.md).
- Lock local vs dedicated repository layout before creating files.
- Project-local Feature:
  - `.devcontainer/<feature-id>/devcontainer-feature.json`
  - `.devcontainer/<feature-id>/install.sh`
- Dedicated Feature repository:
  - `src/<feature-id>/devcontainer-feature.json`
  - `src/<feature-id>/install.sh`
  - optional `test/<feature-id>/test.sh`
- Use [persistence](references/persistence.md) for durable assets, mounts, and `${devcontainerId}` guidance.
- Use [cli](references/cli.md) for `devcontainer features ...` commands when direct CLI execution is needed.

### CLI work

- Read [cli](references/cli.md).
- Prefer explicit workspace or container targeting.
- Prefer inspection before mutation when debugging.
- Re-check `devcontainer --help` before relying on flags that may have changed.

## Shared rules

- If more than one task family applies, do design work first and CLI execution second.
- Keep outputs aligned to the locked repository context.
- Use [checklists](references/checklists.md) before close-out.
- Use [troubleshooting](references/troubleshooting.md) before inventing ad-hoc fixes.

## Completion criteria

- task family and repository context are explicit
- canonical config shape is used
- validation path is clear
- persistence strategy is intentional where state matters
- release or publish path matches the repository context
