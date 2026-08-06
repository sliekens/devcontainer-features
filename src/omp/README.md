# Oh My Pi (omp)

Installs the [Oh My Pi](https://omp.sh/) coding agent CLI (`omp`) by downloading the official prebuilt release binary (noninteractive adaptation of the [upstream installer](https://omp.sh/install)), and persists shared `~/.omp` state across devcontainers.

## Peer dependency (required for full harness)

Oh My Pi is a coding-agent harness that uses a JavaScript runtime for plugins, code-execution workers, and related features. **This feature does not install a runtime for you.**

| Runtime     | Minimum     | Role                                                                                                                          |
| ----------- | ----------- | ----------------------------------------------------------------------------------------------------------------------------- |
| **Bun**     | **1.3.14+** | **Recommended peer** for the full harness (matches upstream `engines.bun` and the Bun Worker used for JS code execution).     |
| **Node.js** | current LTS | Optional peer when Node is already part of your container toolchain. Not every harness path is proven to work under Node-only. |

The CLI is always installed from the official prebuilt GitHub release asset to `/usr/local/bin/omp`. That path does not require Bun or Node at install time. Upstream also documents `bun install -g @oh-my-pi/pi-coding-agent` when you manage Bun yourself; this feature deliberately does **not** use that install channel (root `bun install -g` leaves packages under `/root/.bun` and is a poor fit for multi-user containers).

Without Bun (or Node for tooling you already run that way), the binary may start, but harness features that need a JS runtime can fail. Treat a runtime as required for real use.

### Ways to satisfy the peer dependency

Pick one (or any equivalent approach). **Do not silently choose for the user** when adding this feature via an agent—scan first, then ask if needed (see [AI assisted installation](#ai-assisted-installation)).

1. **Node as a Dev Container Feature** (common when the project already uses Node):
   ```json
   "features": {
       "ghcr.io/devcontainers/features/node:2": {
           "version": "lts"
       },
       "ghcr.io/sliekens/devcontainer-features/omp:1": {}
   }
   ```
2. **Base image that already includes Node or Bun** (for example a `javascript-node` image, or a custom image that installs Bun). Confirm with `node --version` / `bun --version`.
3. **Install Bun in the image or a lifecycle hook** (https://bun.sh/docs/installation) when you prefer Bun as the peer runtime.
4. **Image / Dockerfile** that already provisions Node or Bun on `PATH` before features that need them at runtime.

Soft ordering via `installsAfter` is declared so `omp` installs after `node` when both are present.

## Example Usage

Prebuilt binary install on a generic base image (add a peer runtime separately for full harness use):

```json
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/sliekens/devcontainer-features/omp:1": {}
  }
}
```

With the Node feature (peer runtime via Node):

```json
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/devcontainers/features/node:2": {
      "version": "lts"
    },
    "ghcr.io/sliekens/devcontainer-features/omp:1": {}
  }
}
```

Pin a specific Oh My Pi version when you need deterministic builds:

```json
"features": {
    "ghcr.io/sliekens/devcontainer-features/omp:1": {
        "version": "17.2.9"
    }
}
```

## AI assisted installation

Copy the block below into a chat with your coding agent:

> Add `ghcr.io/sliekens/devcontainer-features/omp:1` to this project's Dev Container. Follow https://github.com/sliekens/devcontainer-features/blob/main/src/omp/README.md.
>
> **Peer runtime (required for full harness):** This feature installs the `omp` CLI from the official prebuilt binary and needs **Bun 1.3.14+** (recommended) or **Node.js** as a peer for plugins / code-execution. It does **not** install a runtime. Before adding the feature:
>
> 1. **Scan** the existing `devcontainer.json` / Dockerfile / base image / already-declared features for Node or Bun (e.g. `javascript-node` images, `ghcr.io/devcontainers/features/node`, custom Bun installs, `bun`/`node` on PATH in the image). Run or reason about `node --version` and `bun --version` when possible.
> 2. If a suitable runtime is already present (or will be after other features install), add only the `omp` feature.
> 3. If no suitable runtime is present, **stop and ask the user** how they want to obtain one — do not silently pick for them. Offer concrete options such as:
>    - install Bun in the image or a lifecycle hook (https://bun.sh/docs/installation) — best match for upstream harness
>    - add `ghcr.io/devcontainers/features/node:2` (e.g. `"version": "lts"`) when Node is preferred for the rest of the toolchain
>    - use a base image that already includes Node or Bun
>    - proceed with CLI-only install for now and add a runtime later (limited harness)
> 4. After the user chooses (or the scan finds a runtime), add the feature and wire host bind pre-create via the collection's shared `initializeCommand` pipeline (devcontainer + jq + xargs over `customizations.sliekens[].initializeCommand`); Unix/WSL2 only. Prefer that over hand-written `mkdir` unless asked.

## Options

| Option    | Type   | Default  | Description                                                      |
| --------- | ------ | -------- | ---------------------------------------------------------------- |
| `version` | string | `latest` | Version to install. Accepts `latest`, `17.2.9`, or `v17.2.9`. |

## Persistent State

| Host path | Container path | Purpose                                                                 |
| --------- | -------------- | ----------------------------------------------------------------------- |
| `~/.omp`  | `/var/lib/omp` | Auth, settings, sessions, plugins, logs, and agent state under `~/.omp` |

This directory is bind-mounted from the host so that auth and configuration are preserved across container rebuilds. Project-local Oh My Pi config under the workspace (for example `<repo>/.omp/`) is separate from this host bind.

Docker cannot bind-mount host paths that do not yet exist. Each feature in this collection that needs host paths declares a host init command under `customizations.sliekens.initializeCommand`. Wire a single `initializeCommand` in your `devcontainer.json` to run all of them (works for any number of features):

```json
"initializeCommand": "devcontainer read-configuration --workspace-folder . --include-merged-configuration | jq -r '(.mergedConfiguration.customizations.sliekens // []) | .[] | .initializeCommand' | xargs -I{} bash -c {}"
```

Requires `devcontainer` and `jq` on the host `PATH`.

> **Note:** This host init pipeline runs only on Unix-like systems (Linux, macOS, and source code inside WSL2 on Windows). Native Windows (`cmd.exe`) is not supported — the Dev Containers CLI runs `initializeCommand` via `/bin/sh -c` on Unix and `cmd.exe /c` on native Windows.

### Manual alternative

If you prefer not to automate with the Dev Containers CLI, `jq`, and `xargs`, pre-create the host paths yourself in `initializeCommand`:

```json
"initializeCommand": "mkdir -p \"$HOME/.omp\""
```

## License

This feature is released under the [MIT License](https://github.com/sliekens/devcontainer-features/blob/main/LICENSE).

The installed tool is subject to its own license: [Oh My Pi license](https://github.com/can1357/oh-my-pi/blob/main/LICENSE).

## Links

- [Oh My Pi website](https://omp.sh/)
- [Oh My Pi quickstart](https://omp.sh/docs/quickstart)
- [Upstream install script](https://omp.sh/install)
- [GitHub: can1357/oh-my-pi](https://github.com/can1357/oh-my-pi)
- [npm package `@oh-my-pi/pi-coding-agent`](https://www.npmjs.com/package/@oh-my-pi/pi-coding-agent)

## Release Notes

## 1.0.0 - 2026-08-06

- Initial release. Noninteractive install of prebuilt `omp` to `/usr/local/bin`; bind-mount host `~/.omp`; Bun 1.3.14+ (recommended) or Node.js treated as a required peer dependency for the full harness (documented for agents and humans; no `dependsOn`).
