#!/usr/bin/env bash
# Noninteractive install of Cursor CLI (agent / cursor-agent), derived from
# https://cursor.com/install. Vendors the official linux tarball into the image
# instead of writing to ~/.local/share/cursor-agent and ~/.local/bin.
set -euo pipefail

CURSOR_INSTALLER_URL="https://cursor.com/install"
INSTALL_DIR="/usr/local/bin"
PACKAGE_DIR="/usr/local/lib/cursor-agent"
STATE_DIR="/var/lib/cursor-agent"
SHARE_DIR="/usr/local/share/cursor-agent"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$(id -u)" -ne 0 ]; then
    echo "Script must run as root."
    exit 1
fi

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
    command -v tar >/dev/null 2>&1 || missing+=("tar")

    if [ ! -d /etc/ssl/certs ] && [ ! -f /etc/ssl/cert.pem ]; then
        missing+=("ca-certificates")
    fi

    if [ ! -e /usr/lib/x86_64-linux-gnu/libstdc++.so.6 ] \
        && [ ! -e /usr/lib/aarch64-linux-gnu/libstdc++.so.6 ] \
        && [ ! -e /usr/lib/libstdc++.so.6 ]; then
        if command -v apt-get >/dev/null 2>&1; then
            missing+=("libstdc++6")
        elif command -v apk >/dev/null 2>&1; then
            missing+=("libstdc++")
        elif command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
            missing+=("libstdc++")
        fi
    fi

    if [ "${#missing[@]}" -gt 0 ]; then
        ensure_packages "${missing[@]}"
    fi
}

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

map_platform() {
    if [ "$(uname -s)" != "Linux" ]; then
        echo "The cursor-agent feature only supports Linux containers."
        exit 1
    fi

    case "$(uname -m)" in
        x86_64 | amd64)
            PACKAGE_ARCH="x64"
            ;;
        aarch64 | arm64)
            PACKAGE_ARCH="arm64"
            ;;
        *)
            echo "Unsupported architecture: $(uname -m)"
            exit 1
            ;;
    esac
}

resolve_latest_version() {
    local installer version=""
    installer="$(curl -fsSL "$CURSOR_INSTALLER_URL")"
    if [[ "$installer" =~ downloads\.cursor\.com/lab/([0-9]{4}\.[0-9]{2}\.[0-9]{2}-[a-f0-9]+) ]]; then
        version="${BASH_REMATCH[1]}"
    fi
    if [ -z "$version" ]; then
        echo "Unable to resolve the current Cursor CLI version from ${CURSOR_INSTALLER_URL}."
        exit 1
    fi
    printf '%s\n' "$version"
}

find_package_dir() {
    local root="$1"
    local found

    if [ -f "${root}/cursor-agent" ]; then
        printf '%s\n' "$root"
        return 0
    fi
    if [ -f "${root}/dist-package/cursor-agent" ]; then
        printf '%s\n' "${root}/dist-package"
        return 0
    fi

    found="$(find "$root" -maxdepth 3 -type f -name cursor-agent -print -quit)"
    if [ -n "$found" ]; then
        dirname "$found"
        return 0
    fi

    return 1
}

install_package() {
    local version="$1"
    local download_url="https://downloads.cursor.com/lab/${version}/linux/${PACKAGE_ARCH}/agent-cli-package.tar.gz"
    local tmp_dir archive_path package_src

    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "${tmp_dir:-}"' EXIT

    archive_path="${tmp_dir}/agent-cli-package.tar.gz"
    echo "Downloading Cursor CLI ${version} (${PACKAGE_ARCH})..."
    if ! curl -fsSL "$download_url" -o "$archive_path"; then
        echo "Failed to download ${download_url}"
        echo "Specify a published version such as 2026.08.11-e8db854, or use latest."
        exit 1
    fi

    tar -xzf "$archive_path" -C "$tmp_dir"

    if ! package_src="$(find_package_dir "$tmp_dir")"; then
        echo "Unexpected Cursor CLI archive layout for ${download_url}."
        echo "Archive contents:"
        tar -tzf "$archive_path" | head -n 50
        exit 1
    fi

    rm -rf "$PACKAGE_DIR"
    install -d -m 0755 "$(dirname "$PACKAGE_DIR")"
    cp -a "$package_src" "$PACKAGE_DIR"

    if [ ! -e "${PACKAGE_DIR}/cursor-agent" ]; then
        echo "Cursor CLI package did not contain cursor-agent."
        exit 1
    fi
    chmod 0755 "${PACKAGE_DIR}/cursor-agent"
    if [ -e "${PACKAGE_DIR}/node" ]; then
        chmod 0755 "${PACKAGE_DIR}/node"
    fi

    rm -f "${INSTALL_DIR}/agent" "${INSTALL_DIR}/cursor-agent"
    ln -s "${PACKAGE_DIR}/cursor-agent" "${INSTALL_DIR}/agent"
    ln -s "${PACKAGE_DIR}/cursor-agent" "${INSTALL_DIR}/cursor-agent"

    trap - EXIT
    rm -rf "$tmp_dir"
}

verify_install() {
    if [ ! -x "${PACKAGE_DIR}/cursor-agent" ]; then
        echo "Expected executable at ${PACKAGE_DIR}/cursor-agent."
        exit 1
    fi

    if ! "${INSTALL_DIR}/agent" --version >/dev/null 2>&1; then
        echo "error: \`${INSTALL_DIR}/agent --version\` failed after install."
        ls -la "${PACKAGE_DIR}/cursor-agent" "${INSTALL_DIR}/agent" || true
        if command -v ldd >/dev/null 2>&1 && [ -e "${PACKAGE_DIR}/node" ]; then
            ldd "${PACKAGE_DIR}/node" || true
        fi
        exit 1
    fi
}

main() {
    local version owner

    version="$(normalize_version "${VERSION:-latest}")"
    ensure_basics
    map_platform

    if [ "$version" = "latest" ]; then
        version="$(resolve_latest_version)"
    fi

    owner="${_REMOTE_USER:-root}"
    if ! id "$owner" >/dev/null 2>&1; then
        owner="root"
    fi

    install -d -m 0700 "$STATE_DIR"
    chown "${owner}:${owner}" "$STATE_DIR"
    install -d -m 0755 "$SHARE_DIR"
    install -d -m 0755 "$INSTALL_DIR"

    install_package "$version"
    install -m 0755 "$SCRIPT_DIR/on_create.sh" "${SHARE_DIR}/on_create.sh"

    verify_install
    echo "Installed Cursor CLI ${version}"
    "${INSTALL_DIR}/agent" --version
}

main "$@"
