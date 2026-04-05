#!/usr/bin/env bash
set -euo pipefail

REPO_OWNER="mistralai"
REPO_NAME="mistral-vibe"
INSTALL_DIR="/usr/local/bin"
STATE_DIR="/var/lib/vibe"
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

    if [ "${#missing[@]}" -gt 0 ]; then
        ensure_packages "${missing[@]}"
    fi
}



install_vibe() {
    local version="${VERSION:-latest}"
    
    echo "Installing mistral-vibe (version: $version) using pip..."
    
    # Install Python and pip if not present
    ensure_packages python3 python3-pip python3-venv
    
    # Create a persistent directory for the virtual environment
    local venv_dir="/opt/mistral-vibe/venv"
    mkdir -p "$venv_dir"
    
    # Create a virtual environment for isolation
    python3 -m venv "$venv_dir"
    source "$venv_dir/bin/activate"
    
    # Install mistral-vibe using pip
    if [ "$version" = "latest" ] || [ "$version" = "stable" ]; then
        if pip install mistral-vibe; then
            echo "Mistral Vibe installed successfully!"
        else
            echo "Failed to install mistral-vibe"
            exit 1
        fi
    else
        if pip install "mistral-vibe==$version"; then
            echo "Mistral Vibe installed successfully!"
        else
            echo "Failed to install mistral-vibe version $version"
            exit 1
        fi
    fi
    
    # Create wrapper scripts that use the persistent virtual environment
    cat > "$INSTALL_DIR/vibe" << EOF
#!/bin/bash
exec /opt/mistral-vibe/venv/bin/python /opt/mistral-vibe/venv/bin/vibe ""$@""
EOF
    chmod 0755 "$INSTALL_DIR/vibe"
    
    cat > "$INSTALL_DIR/vibe-acp" << EOF
#!/bin/bash
exec /opt/mistral-vibe/venv/bin/python /opt/mistral-vibe/venv/bin/vibe-acp ""$@""
EOF
    chmod 0755 "$INSTALL_DIR/vibe-acp"
    
    # Test the installation
    if command -v vibe >/dev/null 2>&1; then
        vibe --version || true
    fi
}

main() {
    local version="${VERSION:-latest}"

    ensure_basics
    install -d -m 0700 "$STATE_DIR"
    install -d -m 0755 /usr/local/share/vibe

    install_vibe
    install -m 0755 "$SCRIPT_DIR/on_create.sh" /usr/local/share/vibe/on_create.sh

    if command -v vibe >/dev/null 2>&1; then
        echo "Installed Mistral Vibe CLI (version: $version)"
        vibe --version || true
    else
        echo "Installation completed but vibe command not found in PATH"
        exit 1
    fi
}

main "$@"