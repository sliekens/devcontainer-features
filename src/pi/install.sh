#!/usr/bin/env bash
# Noninteractive install of Pi, derived from https://pi.dev/install.sh
# (animation, prompts, interactive Node bootstrap, and locked-install
# experimental path removed). Official install is npm-only.
set -euo pipefail

PI_PACKAGE="@earendil-works/pi-coding-agent"
PI_CMD="pi"
# Pi publishes npm-shrinkwrap.json, so the installer can bypass npm's
# release-age gate without reopening transitive dependency ranges.
PI_NPM_INSTALL_MIN_AGE_ARG="--min-release-age=0"
# Always install into the system prefix so the binary is not tied to an
# nvm version directory (the Node feature puts nvm first on PATH).
NPM_PREFIX="/usr/local"
INSTALL_DIR="${NPM_PREFIX}/bin"
STATE_DIR="/var/lib/pi"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Minimum Node.js version required by Pi (engines.node).
PI_MIN_NODE_MAJOR=22
PI_MIN_NODE_MINOR=19
PI_MIN_NODE_PATCH=0

if [ "$(id -u)" -ne 0 ]; then
    echo "Script must run as root."
    exit 1
fi

normalize_version() {
    case "$1" in
        "" | latest)
            echo "latest"
            ;;
        v*)
            echo "${1#v}"
            ;;
        *)
            echo "$1"
            ;;
    esac
}

package_spec() {
    local version
    version="$(normalize_version "${VERSION:-latest}")"
    if [ "$version" = "latest" ]; then
        printf '%s' "$PI_PACKAGE"
    else
        printf '%s@%s' "$PI_PACKAGE" "$version"
    fi
}

node_version_is_new_enough() {
    # Expects a version string like v22.19.0 or 22.19.0
    local version major minor patch version_ifs
    version="${1#v}"
    case "$version" in
        [0-9]*) ;;
        *) return 1 ;;
    esac
    version="${version%%[!0-9.]*}"
    version_ifs=${IFS-}
    IFS=.
    # shellcheck disable=SC2086
    set -- $version
    IFS=$version_ifs
    major="${1:-0}"
    minor="${2:-0}"
    patch="${3:-0}"
    case "$major" in '' | *[!0-9]*) return 1 ;; esac
    case "$minor" in '' | *[!0-9]*) minor=0 ;; esac
    case "$patch" in '' | *[!0-9]*) patch=0 ;; esac

    [ "$major" -gt "$PI_MIN_NODE_MAJOR" ] && return 0
    [ "$major" -eq "$PI_MIN_NODE_MAJOR" ] && [ "$minor" -gt "$PI_MIN_NODE_MINOR" ] && return 0
    [ "$major" -eq "$PI_MIN_NODE_MAJOR" ] && [ "$minor" -eq "$PI_MIN_NODE_MINOR" ] && [ "$patch" -ge "$PI_MIN_NODE_PATCH" ] && return 0
    return 1
}

print_peer_dependency_help() {
    cat <<EOF
Pi requires Node.js as a peer dependency (this feature does not install one):

  - Node.js ${PI_MIN_NODE_MAJOR}.${PI_MIN_NODE_MINOR}.${PI_MIN_NODE_PATCH}+ with npm
    (required for this feature's install path; matches https://pi.dev/install.sh)

Valid ways to obtain a runtime in a dev container include:

  - Feature: ghcr.io/devcontainers/features/node:2 with version >= ${PI_MIN_NODE_MAJOR}.${PI_MIN_NODE_MINOR}.${PI_MIN_NODE_PATCH} (or lts / 24)
  - Base image whose shipped Node is already >= ${PI_MIN_NODE_MAJOR}.${PI_MIN_NODE_MINOR}.${PI_MIN_NODE_PATCH} (verify; major-only tags may lag)

Bun can install/run Pi outside this feature (\`bun install -g ${PI_PACKAGE}\`);
this feature deliberately follows the official npm installer only.

See: https://github.com/sliekens/devcontainer-features/blob/main/src/pi/README.md
EOF
}

require_node_npm() {
    if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
        echo "error: Node.js ${PI_MIN_NODE_MAJOR}.${PI_MIN_NODE_MINOR}.${PI_MIN_NODE_PATCH}+ and npm are required to install Pi with this feature." >&2
        print_peer_dependency_help >&2
        return 1
    fi

    local node_version
    node_version="$(node --version 2>/dev/null || true)"
    if ! node_version_is_new_enough "$node_version"; then
        echo "error: Pi requires Node.js ${PI_MIN_NODE_MAJOR}.${PI_MIN_NODE_MINOR}.${PI_MIN_NODE_PATCH} or newer. Found ${node_version:-unknown}." >&2
        print_peer_dependency_help >&2
        return 1
    fi
}

npm_supports_min_release_age() {
    npm install -g --help 2>&1 | grep -q -- '--min-release-age'
}

run_npm_install() {
    local spec
    local -a args

    spec="$(package_spec)"
    args=(
        install
        -g
        --prefix "$NPM_PREFIX"
        --ignore-scripts
        --no-fund
        --no-audit
        --progress=false
    )

    if npm_supports_min_release_age; then
        args+=("$PI_NPM_INSTALL_MIN_AGE_ARG")
    fi

    echo "Installing Pi with npm --prefix ${NPM_PREFIX}: ${spec}"
    npm "${args[@]}" "$spec"
}

ensure_stable_bin() {
    local installed=""
    local target="${INSTALL_DIR}/${PI_CMD}"

    if [ -x "$target" ]; then
        return 0
    fi

    # Prefer the prefix we requested; fall back to npm's reported global bin.
    if [ -x "${NPM_PREFIX}/bin/${PI_CMD}" ]; then
        installed="${NPM_PREFIX}/bin/${PI_CMD}"
    elif command -v "$PI_CMD" >/dev/null 2>&1; then
        installed="$(command -v "$PI_CMD")"
    fi

    if [ -z "$installed" ]; then
        echo "Pi install finished but \`${PI_CMD}\` was not found under ${NPM_PREFIX}/bin or on PATH."
        echo "npm prefix -g: $(npm prefix -g 2>/dev/null || echo n/a)"
        echo "PATH=${PATH}"
        exit 1
    fi

    install -d -m 0755 "$INSTALL_DIR"
    # Copy rather than symlink when the binary already lives outside INSTALL_DIR
    # so the CLI remains available if an nvm default version changes later.
    if [ "$installed" != "$target" ]; then
        if [ -L "$installed" ]; then
            # Resolve to the real file when npm/nvm left a symlink.
            install -m 0755 "$(readlink -f "$installed")" "$target"
        else
            install -m 0755 "$installed" "$target"
        fi
    fi
}

verify_install() {
    if [ ! -x "${INSTALL_DIR}/${PI_CMD}" ]; then
        echo "Expected executable at ${INSTALL_DIR}/${PI_CMD}."
        exit 1
    fi

    # Prefer the stable path for the smoke check.
    if ! "${INSTALL_DIR}/${PI_CMD}" --version 2>/dev/null; then
        echo "warning: \`${INSTALL_DIR}/${PI_CMD} --version\` did not succeed."
        ls -la "${INSTALL_DIR}/${PI_CMD}" || true
    fi
}

main() {
    local version

    version="$(normalize_version "${VERSION:-latest}")"

    install -d -m 0700 "$STATE_DIR"
    chown "${_REMOTE_USER:-root}:${_REMOTE_USER:-root}" "$STATE_DIR" 2>/dev/null || true
    install -d -m 0755 /usr/local/share/pi
    install -d -m 0755 "$INSTALL_DIR"

    require_node_npm
    run_npm_install
    ensure_stable_bin

    install -m 0755 "$SCRIPT_DIR/on_create.sh" /usr/local/share/pi/on_create.sh

    verify_install
    echo "Installed Pi CLI (${version}) to ${INSTALL_DIR}/${PI_CMD}"
}

main "$@"
