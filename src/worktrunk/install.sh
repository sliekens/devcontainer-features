#!/usr/bin/env bash
set -euo pipefail

REPO_OWNER="max-sixty"
REPO_NAME="worktrunk"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/var/lib/worktrunk-config"
SHARE_DIR="/usr/local/share/worktrunk"
# Worktrunk reads optional system config from XDG_CONFIG_DIRS (default: /etc/xdg).
SYSTEM_CONFIG_DIR="/etc/xdg/worktrunk"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TAB_COMPLETIONS="${TABCOMPLETIONS:-true}"

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
    command -v jq >/dev/null 2>&1 || missing+=("jq")
    command -v tar >/dev/null 2>&1 || missing+=("tar")

    if ! command -v xz >/dev/null 2>&1; then
        if command -v apt-get >/dev/null 2>&1; then
            missing+=("xz-utils")
        else
            missing+=("xz")
        fi
    fi

    if [ ! -d /etc/ssl/certs ] && [ ! -f /etc/ssl/cert.pem ]; then
        missing+=("ca-certificates")
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

github_api_get() {
    local url="$1"
    curl -fsSL \
        -H "Accept: application/vnd.github+json" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "$url"
}

resolve_release_json() {
    local requested_version
    requested_version="$(normalize_version "${VERSION:-latest}")"

    if [ "$requested_version" = "latest" ]; then
        github_api_get "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest"
        return
    fi

    github_api_get "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases/tags/v${requested_version}"
}

# Worktrunk publishes statically linked musl builds, which run on both glibc and
# musl based images.
map_target() {
    if [ "$(uname -s)" != "Linux" ]; then
        echo "The worktrunk feature only supports Linux containers."
        exit 1
    fi

    case "$(uname -m)" in
        x86_64 | amd64)
            PACKAGE_TARGET="x86_64-unknown-linux-musl"
            ;;
        aarch64 | arm64)
            PACKAGE_TARGET="aarch64-unknown-linux-musl"
            ;;
        *)
            echo "Unsupported architecture: $(uname -m)"
            exit 1
            ;;
    esac
}

verify_checksum() {
    local archive_path="$1"
    local checksum_url="$2"
    local expected

    if ! command -v sha256sum >/dev/null 2>&1; then
        echo "sha256sum is unavailable; skipping checksum verification."
        return
    fi

    if ! expected="$(curl -fsSL "$checksum_url" | awk 'NF {print $1; exit}')"; then
        echo "Unable to download the checksum for $(basename "$archive_path")."
        exit 1
    fi

    local actual
    actual="$(sha256sum "$archive_path" | awk '{print $1}')"

    if [ "$expected" != "$actual" ]; then
        echo "Checksum mismatch for $(basename "$archive_path"): expected ${expected}, got ${actual}."
        exit 1
    fi
}

# Container-safe default for worktree-path. Lives in system config so it does
# not touch the host-shared user config or per-repo project config; either can
# still override.
install_system_config() {
    install -d -m 0755 "$SYSTEM_CONFIG_DIR"
    install -m 0644 "$SCRIPT_DIR/system-config.toml" "${SYSTEM_CONFIG_DIR}/config.toml"
}

# Append a snippet to an rc file once, keyed by a marker comment.
append_once() {
    local rc_file="$1"
    local marker="$2"
    local snippet="$3"

    if [ ! -f "$rc_file" ]; then
        return
    fi

    if grep -qF "$marker" "$rc_file"; then
        return
    fi

    printf '\n%s\n%s\n' "$marker" "$snippet" >> "$rc_file"
}

# Worktrunk bundles tab completions with its shell integration: the generated
# snippet registers a lazy clap completer and the `wt` wrapper function that
# makes `wt switch` change the current directory. Evaluating it at shell startup
# (instead of baking in a snapshot) keeps it in sync when `wt` is upgraded.
install_shell_integration() {
    local marker="# worktrunk shell integration (devcontainer feature)"

    local bash_rc
    for bash_rc in /etc/bash.bashrc /etc/bash/bashrc /etc/bashrc; do
        append_once "$bash_rc" "$marker" \
            'if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init bash)"; fi'
    done

    local zsh_rc
    for zsh_rc in /etc/zsh/zshrc /etc/zshrc; do
        append_once "$zsh_rc" "$marker" \
            'if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi'
    done

    if [ -d /etc/fish ]; then
        install -d -m 0755 /etc/fish/conf.d
        cat > /etc/fish/conf.d/worktrunk.fish <<'EOS'
# worktrunk shell integration (devcontainer feature)
if type -q wt
    command wt config shell init fish | source
end
EOS
        chmod 0644 /etc/fish/conf.d/worktrunk.fish
    fi
}

main() {
    ensure_basics
    map_target

    install -d -m 0700 "$CONFIG_DIR"
    install -d -m 0755 "$SHARE_DIR"

    local release_json
    release_json="$(resolve_release_json)"

    local release_tag
    release_tag="$(printf '%s' "$release_json" | jq -r '.tag_name // empty')"
    if [ -z "$release_tag" ]; then
        echo "Unable to resolve a worktrunk release tag."
        exit 1
    fi

    local release_version="${release_tag#v}"
    local asset_name="worktrunk-${PACKAGE_TARGET}.tar.xz"

    local download_url
    download_url="$(printf '%s' "$release_json" | jq -r --arg asset "$asset_name" '.assets[] | select(.name == $asset) | .browser_download_url' | head -n 1)"

    if [ -z "$download_url" ]; then
        echo "No compatible asset was found for ${PACKAGE_TARGET} in release ${release_tag}."
        echo "Available assets:"
        printf '%s' "$release_json" | jq -r '.assets[].name | select(endswith(".tar.xz"))'
        exit 1
    fi

    local checksum_url
    checksum_url="$(printf '%s' "$release_json" | jq -r --arg asset "${asset_name}.sha256" '.assets[] | select(.name == $asset) | .browser_download_url' | head -n 1)"

    local tmp_dir
    tmp_dir="$(mktemp -d)"
    trap 'rm -rf "${tmp_dir:-}"' EXIT

    local archive_path="${tmp_dir}/${asset_name}"
    curl -fsSL "$download_url" -o "$archive_path"

    if [ -n "$checksum_url" ]; then
        verify_checksum "$archive_path" "$checksum_url"
    else
        echo "Release ${release_tag} does not publish a checksum for ${asset_name}; skipping verification."
    fi

    tar -xJf "$archive_path" -C "$tmp_dir"

    local extract_dir="${tmp_dir}/worktrunk-${PACKAGE_TARGET}"
    local binary
    for binary in wt git-wt; do
        if [ ! -f "${extract_dir}/${binary}" ]; then
            echo "Release archive did not contain the ${binary} binary."
            exit 1
        fi
        install -m 0755 "${extract_dir}/${binary}" "${INSTALL_DIR}/${binary}"
    done

    if [ "$TAB_COMPLETIONS" = "true" ]; then
        install_shell_integration
    fi

    install_system_config

    install -m 0755 "$SCRIPT_DIR/on_create.sh" "${SHARE_DIR}/on_create.sh"

    "${INSTALL_DIR}/wt" --version
    echo "Installed worktrunk ${release_version}."
}

main "$@"
