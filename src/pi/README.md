# Pi (pi)

Installs the [Pi](https://pi.dev/) coding agent CLI (`pi`) with a noninteractive install derived from the [upstream installer](https://pi.dev/install.sh), and persists shared `~/.pi` state across devcontainers.

## Peer dependency (required)

Pi is an npm package. **This feature installs via npm only** (same as `https://pi.dev/install.sh`) and does **not** install a JavaScript runtime for you.

| Runtime           | Minimum              | Role                                                            |
| ----------------- | -------------------- | --------------------------------------------------------------- |
| **Node.js + npm** | Node.js **22.19.0+** | **Required peer** for this feature at install time and runtime. |

The CLI is installed to `/usr/local/bin/pi` (via `npm install -g --prefix /usr/local`) so it is not tied to an nvm version directory when the Node feature is also present.

Upstream also documents installing Pi with Bun (`bun install -g @earendil-works/pi-coding-agent`). That path is valid for users who manage Pi themselves; this feature deliberately does **not** install via Bun, so a Bun-only container does not satisfy this feature’s install path.

### Ways to satisfy the peer dependency

Pick one (or any equivalent approach). **Do not silently choose for the user** when adding this feature via an agent—scan first, then ask if needed (see [AI assisted installation](#ai-assisted-installation)).

1. **Node as a Dev Container Feature** (recommended when the base image may lag behind Node releases). Soft ordering via `installsAfter` is declared so `pi` installs after `node` when both are present:
   ```json
   "features": {
       "ghcr.io/devcontainers/features/node:2": {
           "version": "22.19.0"
       },
       "ghcr.io/sliekens/devcontainer-features/pi:1": {}
   }
   ```
   `version` may also be `"lts"`, `"24"`, or any other Node release **≥ 22.19.0**. A bare `"22"` only works if the feature resolves to a patch that is new enough (verify with `node --version` after rebuild).
2. **Base image that already includes Node ≥ 22.19.0**. Confirm with `node --version`—some `javascript-node:1-22-*` tags still ship older 22.x builds (e.g. 22.16.x) and are **not** sufficient alone.
3. **Image / Dockerfile** that already provisions Node ≥ 22.19.0 with npm on `PATH` before this feature runs.

If a new-enough Node+npm is not available when the feature installs, install fails with a short error and points back here.

## Example Usage

With the Node feature on a generic base image (recommended):

```json
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/devcontainers/features/node:2": {
      "version": "22.19.0"
    },
    "ghcr.io/sliekens/devcontainer-features/pi:1": {}
  }
}
```

Using LTS Node via the same feature (currently Node 24.x as of this writing—still ≥ 22.19.0):

```json
{
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/devcontainers/features/node:2": {
      "version": "lts"
    },
    "ghcr.io/sliekens/devcontainer-features/pi:1": {}
  }
}
```

Pin a specific Pi version when you need deterministic builds:

```json
"features": {
    "ghcr.io/sliekens/devcontainer-features/pi:1": {
        "version": "0.83.0"
    }
}
```

## AI assisted installation

Copy the block below into a chat with your coding agent:

> Add `ghcr.io/sliekens/devcontainer-features/pi:1` to this project's Dev Container. Follow https://github.com/sliekens/devcontainer-features/blob/main/src/pi/README.md.
>
> **Peer runtime (required):** This feature installs Pi with npm and needs Node.js **22.19.0+** with npm. It does **not** install a runtime. Before adding the feature:
>
> 1. **Scan** the existing `devcontainer.json` / Dockerfile / base image / already-declared features for Node (e.g. `javascript-node` images, `ghcr.io/devcontainers/features/node`, custom installs). Run or reason about `node --version` when possible — some `javascript-node:1-22-*` images still ship Node **below** 22.19.0.
> 2. If a suitable Node+npm is already present (or will be after other features install), add only the `pi` feature.
> 3. If no suitable runtime is present, **stop and ask the user** how they want to obtain one — do not silently pick for them. Offer concrete options such as:
>    - add `ghcr.io/devcontainers/features/node:2` with `version` **≥ 22.19.0** (or `"lts"` / `"24"` when appropriate)
>    - use a base image whose shipped Node is already ≥ 22.19.0 (verify before relying on major-only tags)
>    - manage Pi with Bun themselves (`bun install -g @earendil-works/pi-coding-agent`) instead of this feature
> 4. After the user chooses (or the scan finds a runtime), add the feature and wire host bind pre-create via the collection's shared `initializeCommand` pipeline (devcontainer + jq + xargs over `customizations.sliekens[].initializeCommand`); Unix/WSL2 only. Prefer that over hand-written `mkdir` unless asked.

## Options

| Option    | Type   | Default  | Description                                                   |
| --------- | ------ | -------- | ------------------------------------------------------------- |
| `version` | string | `latest` | Version to install. Accepts `latest`, `0.83.0`, or `v0.83.0`. |

## Persistent State

| Host path | Container path | Purpose                                                                 |
| --------- | -------------- | ----------------------------------------------------------------------- |
| `~/.pi`   | `/var/lib/pi`  | Auth, settings, sessions, and installed Pi packages (`~/.pi/agent/`, …) |

This directory is bind-mounted from the host so that auth and configuration are preserved across container rebuilds. Project-local Pi config under the workspace (if any) is separate from this host bind.

Docker cannot bind-mount host paths that do not yet exist. Each feature in this collection that needs host paths declares a host init command under `customizations.sliekens.initializeCommand`. Wire a single `initializeCommand` in your `devcontainer.json` to run all of them (works for any number of features):

```json
"initializeCommand": "devcontainer read-configuration --workspace-folder . --include-merged-configuration | jq -r '(.mergedConfiguration.customizations.sliekens // []) | .[] | .initializeCommand' | xargs -I{} bash -c {}"
```

Requires `devcontainer` and `jq` on the host `PATH`.

> **Note:** This host init pipeline runs only on Unix-like systems (Linux, macOS, and source code inside WSL2 on Windows). Native Windows (`cmd.exe`) is not supported — the Dev Containers CLI runs `initializeCommand` via `/bin/sh -c` on Unix and `cmd.exe /c` on native Windows.

### Manual alternative

If you prefer not to automate with the Dev Containers CLI, `jq`, and `xargs`, pre-create the host paths yourself in `initializeCommand`:

```json
"initializeCommand": "mkdir -p \"$HOME/.pi\""
```

## License

This feature is released under the [MIT License](https://github.com/sliekens/devcontainer-features/blob/main/LICENSE).

The installed tool is subject to its own license: [Pi license](https://github.com/earendil-works/pi/blob/main/LICENSE).

## Links

- [Pi documentation](https://pi.dev/docs/latest)
- [Pi quickstart](https://pi.dev/docs/latest/quickstart)
- [Upstream install script](https://pi.dev/install.sh)
- [npm package `@earendil-works/pi-coding-agent`](https://www.npmjs.com/package/@earendil-works/pi-coding-agent)

## Release Notes

## 1.0.0 - 2026-08-06

- Initial release. Noninteractive npm install of Pi to `/usr/local`; bind-mount host `~/.pi`; Node.js 22.19+ with npm treated as a required peer dependency (documented for agents and humans; no `dependsOn`).
