#!/usr/bin/env bash
# Noninteractive install of Oh My Pi (omp), derived from https://omp.sh/install
# (interactive bun bootstrap and bun-install channel removed; peer runtimes are
# not installed by this feature). Always installs the official prebuilt binary.
# Upstream: https://raw.githubusercontent.com/can1357/oh-my-pi/main/scripts/install.sh
set -euo pipefail

REPO="can1357/oh-my-pi"
OMP_CMD="omp"
INSTALL_DIR="/usr/local/bin"
STATE_DIR="/var/lib/omp"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Minimum Bun version required by upstream (engines.bun / install script).
MIN_BUN_VERSION="1.3.14"

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

release_tag() {
    local version
    version="$(normalize_version "${VERSION:-latest}")"
    if [ "$version" = "latest" ]; then
        echo "latest"
    else
        echo "v${version}"
    fi
}

print_peer_dependency_help() {
    cat <<EOF
Oh My Pi (omp) expects a JavaScript runtime as a peer dependency for the full
harness (code-execution worker, plugins, and related features). This feature
does not install one:

  - Bun ${MIN_BUN_VERSION}+ (recommended; matches upstream engines.bun)
  - Node.js (when you already use Node in the container; not a proven substitute
    for every Bun Worker harness path)

Valid ways to obtain a runtime in a dev container include:

  - Feature: ghcr.io/devcontainers/features/node:2
  - Base image that already includes Node or Bun
  - Install Bun yourself (https://bun.sh/docs/installation) in the image or a lifecycle hook

This feature always installs the official prebuilt \`omp\` CLI binary. Without a
peer runtime, some harness capabilities may be unavailable.

See: https://github.com/sliekens/devcontainer-features/blob/main/src/omp/README.md
EOF
}

ensure_packages() {
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update -y
        apt-get install -y --no-install-recommends "$@"
        rm -rf /var/lib/apt/lists/*
    elif command -v apk >/dev/null 2>&1; then
        apk add --no-cache "$@"
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y "$@"
    elif command -v yum >/dev/null 2>&1; then
        yum install -y "$@"
    else
        echo "Unsupported package manager. Install these packages manually: $*"
        exit 1
    fi
}

ensure_basics() {
    local missing=()

    command -v curl >/dev/null 2>&1 || missing+=("curl")

    if [ ! -d /etc/ssl/certs ] && [ ! -f /etc/ssl/cert.pem ]; then
        missing+=("ca-certificates")
    fi

    if [ "${#missing[@]}" -gt 0 ]; then
        ensure_packages "${missing[@]}"
    fi
}

has_bun() {
    command -v bun >/dev/null 2>&1
}

# Normalized host architecture (x64|arm64).
host_arch() {
    case "$(uname -m)" in
        x86_64 | amd64) echo "x64" ;;
        arm64 | aarch64) echo "arm64" ;;
        *) uname -m ;;
    esac
}

version_ge() {
    local current="$1"
    local minimum="$2"
    local current_major current_rest current_minor current_patch
    local minimum_major minimum_rest minimum_minor minimum_patch

    # Defensive: non-numeric segments become 0 so set -e arithmetic does not abort.
    case "$current" in
        '' | *[!0-9.]* | .* | *.) current="0.0.0" ;;
    esac
    case "$minimum" in
        '' | *[!0-9.]* | .* | *.) minimum="0.0.0" ;;
    esac

    current_major="${current%%.*}"
    current_rest="${current#*.}"
    current_minor="${current_rest%%.*}"
    current_patch="${current_rest#*.}"
    current_patch="${current_patch%%.*}"

    minimum_major="${minimum%%.*}"
    minimum_rest="${minimum#*.}"
    minimum_minor="${minimum_rest%%.*}"
    minimum_patch="${minimum_rest#*.}"
    minimum_patch="${minimum_patch%%.*}"

    current_major="${current_major:-0}"
    current_minor="${current_minor:-0}"
    current_patch="${current_patch:-0}"
    minimum_major="${minimum_major:-0}"
    minimum_minor="${minimum_minor:-0}"
    minimum_patch="${minimum_patch:-0}"

    if [ "$current_major" -ne "$minimum_major" ]; then
        [ "$current_major" -gt "$minimum_major" ]
        return $?
    fi

    if [ "$current_minor" -ne "$minimum_minor" ]; then
        [ "$current_minor" -gt "$minimum_minor" ]
        return $?
    fi

    [ "$current_patch" -ge "$minimum_patch" ]
}

bun_version_is_new_enough() {
    local version_raw version_clean
    version_raw="$(bun --version 2>/dev/null || true)"
    if [ -z "$version_raw" ]; then
        return 1
    fi
    version_clean="${version_raw%%-*}"
    version_ge "$version_clean" "$MIN_BUN_VERSION"
}

install_binary() {
    local platform arch binary binary_url release_json latest requested
    local smoke_output

    if [ "$(uname -s)" != "Linux" ]; then
        echo "The omp feature only supports Linux containers."
        exit 1
    fi

    platform="linux"
    arch="$(host_arch)"
    case "$arch" in
        x64 | arm64) ;;
        *)
            echo "Unsupported architecture: $arch"
            exit 1
            ;;
    esac

    # Prefer Alpine marker for musl assets. Avoid treating multi-loader hosts
    # that happen to have a musl ldd as musl (upstream self-update had related
    # misclassification issues).
    if [ -f /etc/alpine-release ]; then
        platform="linux-musl"
    elif command -v ldd >/dev/null 2>&1 && ldd --version 2>&1 | head -n 1 | grep -qi musl; then
        platform="linux-musl"
    fi

    binary="omp-${platform}-${arch}"
    requested="$(release_tag)"

    if [ "$requested" = "latest" ]; then
        echo "Fetching latest Oh My Pi release..."
        release_json="$(curl -fsSL --connect-timeout 10 --max-time 60 \
            -H "Accept: application/vnd.github+json" \
            -H "X-GitHub-Api-Version: 2022-11-28" \
            "https://api.github.com/repos/${REPO}/releases/latest")"
        latest="$(printf '%s\n' "$release_json" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' | head -n 1)"
    else
        echo "Fetching Oh My Pi release ${requested}..."
        if ! release_json="$(curl -fsSL --connect-timeout 10 --max-time 60 \
            -H "Accept: application/vnd.github+json" \
            -H "X-GitHub-Api-Version: 2022-11-28" \
            "https://api.github.com/repos/${REPO}/releases/tags/${requested}")"; then
            echo "Release tag not found: ${requested}"
            exit 1
        fi
        latest="$(printf '%s\n' "$release_json" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/' | head -n 1)"
    fi

    if [ -z "$latest" ]; then
        echo "Failed to fetch release tag"
        exit 1
    fi
    echo "Using version: $latest"

    install -d -m 0755 "$INSTALL_DIR"
    binary_url="https://github.com/${REPO}/releases/download/${latest}/${binary}"
    echo "Downloading ${binary}..."
    curl -fsSL --connect-timeout 10 --speed-limit 1024 --speed-time 30 \
        "$binary_url" -o "${INSTALL_DIR}/${OMP_CMD}"
    chmod +x "${INSTALL_DIR}/${OMP_CMD}"

    # Verify the binary can start before reporting success. Bun musl builds link
    # libstdc++/libgcc dynamically; stock Alpine may need those packages.
    if ! smoke_output="$("${INSTALL_DIR}/${OMP_CMD}" --version 2>&1)"; then
        echo "omp was downloaded to ${INSTALL_DIR}/${OMP_CMD} but cannot start:"
        echo "$smoke_output" | sed 's/^/    /'
        if [ "$platform" = "linux-musl" ]; then
            echo "The musl build links libstdc++/libgcc dynamically. Install them, then re-run:"
            if command -v apk >/dev/null 2>&1; then
                echo "    apk add libstdc++ libgcc"
            else
                echo "    (install the libstdc++ and libgcc runtime packages for your distro)"
            fi
        fi
        exit 1
    fi
}

verify_install() {
    if [ ! -x "${INSTALL_DIR}/${OMP_CMD}" ]; then
        echo "Expected executable at ${INSTALL_DIR}/${OMP_CMD}."
        exit 1
    fi

    if ! "${INSTALL_DIR}/${OMP_CMD}" --version >/dev/null 2>&1; then
        echo "error: \`${INSTALL_DIR}/${OMP_CMD} --version\` failed after install."
        ls -la "${INSTALL_DIR}/${OMP_CMD}" || true
        exit 1
    fi
}

warn_if_no_peer_runtime() {
    if has_bun && bun_version_is_new_enough; then
        return 0
    fi
    if command -v node >/dev/null 2>&1; then
        return 0
    fi
    echo "warning: no Bun ${MIN_BUN_VERSION}+ or Node.js detected on PATH."
    print_peer_dependency_help
}

main() {
    local version

    version="$(normalize_version "${VERSION:-latest}")"

    install -d -m 0700 "$STATE_DIR"
    chown "${_REMOTE_USER:-root}:${_REMOTE_USER:-root}" "$STATE_DIR" 2>/dev/null || true
    install -d -m 0755 /usr/local/share/omp
    install -d -m 0755 "$INSTALL_DIR"

    ensure_basics
    install_binary

    install -m 0755 "$SCRIPT_DIR/on_create.sh" /usr/local/share/omp/on_create.sh

    verify_install
    warn_if_no_peer_runtime
    echo "Installed Oh My Pi CLI (${version}) to ${INSTALL_DIR}/${OMP_CMD}"
}

main "$@"
