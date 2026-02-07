# Decision Trees

## Task family

Q: What is the task changing?
- repository dev container definition -> use [configuration](configuration.md)
- Dev Container Feature -> use [features](features.md)
- CLI execution or debugging -> use [cli](cli.md)

## Repository context

Q: Where does the work live?
- application repo with `.devcontainer/devcontainer.json` -> definition work
- application repo with a local Feature -> `.devcontainer/<feature-id>/`
- dedicated Feature collection repo -> `src/<feature-id>/` and optional `test/<feature-id>/`

## Configuration chooser

Q: Are multiple cooperating services required?
- Yes -> Compose
- No -> continue

Q: Does the repo need custom image build steps?
- Yes -> Dockerfile mode with `build.dockerfile`
- No -> image mode

## Dependency placement

Q: Is the dependency reusable across repositories?
- Yes -> Feature
- No -> continue

Q: Is it required to build the image or install system packages?
- Yes -> Dockerfile/image layer
- No -> lifecycle hook or local bootstrap

## Feature context chooser

Q: Is the Feature meant only for this repository?
- Yes -> project-local `.devcontainer/<feature-id>/`
- No -> dedicated Feature repository

Q: Does it need semver release and publish flow?
- Yes -> dedicated Feature repository
- No -> project-local Feature is acceptable

## CLI chooser

Q: Need only merged/effective config?
- Yes -> `read-configuration`

Q: Need only image validation?
- Yes -> `build`

Q: Need lifecycle and container startup behavior?
- Yes -> `up`

Q: Need to rerun lifecycle commands without rebuilding?
- Yes -> `run-user-commands`

Q: Need a one-off command in a running container?
- Yes -> `exec`
