#!/usr/bin/env bash
#
# Cloud Agent environment setup for the devcontainer-features collection.
#
# Installs the toolchain required to develop, test, and publish dev container
# features: Docker Engine (for `devcontainer features test`), the Dev Containers
# CLI, ajv-cli (schema validation), oras (OCI publishing), and jq.
#
# This script runs after the repository is checked out. It is idempotent: every
# step checks for existing state before acting, so it is safe to run repeatedly
# and on top of a warm snapshot where the tools are already present.
#
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

log() { printf '\033[0;34m[install]\033[0m %s\n' "$*"; }

ORAS_VERSION="1.2.0"
TARGET_USER="${SUDO_USER:-${USER:-$(id -un)}}"

install_apt_prereqs() {
    local pkgs=(ca-certificates curl gnupg jq fuse-overlayfs uidmap)
    local missing=()
    for p in "${pkgs[@]}"; do
        dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p")
    done
    if [[ ${#missing[@]} -eq 0 ]]; then
        log "apt prerequisites already installed"
        return 0
    fi
    log "installing apt prerequisites: ${missing[*]}"
    sudo apt-get update -qq
    sudo apt-get install -y -qq -o Dpkg::Options::="--force-confold" "${missing[@]}"
}

install_docker() {
    if command -v dockerd >/dev/null 2>&1; then
        log "Docker already installed ($(docker --version 2>/dev/null || echo present))"
    else
        log "setting up Docker apt repository"
        sudo install -m 0755 -d /etc/apt/keyrings
        if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
                | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            sudo chmod a+r /etc/apt/keyrings/docker.gpg
        fi
        local codename
        codename="$(. /etc/os-release && echo "$VERSION_CODENAME")"
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${codename} stable" \
            | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
        log "installing Docker Engine"
        sudo apt-get update -qq
        sudo apt-get install -y -qq -o Dpkg::Options::="--force-confold" \
            docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    fi

    # Nested Cloud Agent VMs cannot use the overlay2 driver on top of an
    # existing overlay filesystem; fuse-overlayfs works with /dev/fuse.
    if [[ ! -f /etc/docker/daemon.json ]]; then
        log "writing /etc/docker/daemon.json (fuse-overlayfs storage driver)"
        sudo mkdir -p /etc/docker
        printf '{\n  "storage-driver": "fuse-overlayfs"\n}\n' \
            | sudo tee /etc/docker/daemon.json >/dev/null
    fi

    if ! id -nG "$TARGET_USER" 2>/dev/null | tr ' ' '\n' | grep -qx docker; then
        log "adding ${TARGET_USER} to the docker group"
        sudo groupadd -f docker
        sudo usermod -aG docker "$TARGET_USER"
    fi
}

install_oras() {
    if command -v oras >/dev/null 2>&1; then
        log "oras already installed ($(oras version 2>/dev/null | awk '/^Version/{print $2}'))"
        return 0
    fi
    log "installing oras ${ORAS_VERSION}"
    local tmp
    tmp="$(mktemp -d)"
    curl -fsSL -o "${tmp}/oras.tar.gz" \
        "https://github.com/oras-project/oras/releases/download/v${ORAS_VERSION}/oras_${ORAS_VERSION}_linux_amd64.tar.gz"
    sudo tar -xzf "${tmp}/oras.tar.gz" -C /usr/local/bin oras
    rm -rf "$tmp"
}

install_node_clis() {
    local npm_bin
    npm_bin="$(command -v npm || true)"
    if [[ -z "$npm_bin" ]]; then
        log "ERROR: npm not found on PATH; cannot install Dev Containers CLI"
        return 1
    fi

    if ! command -v devcontainer >/dev/null 2>&1; then
        log "installing @devcontainers/cli into /usr/local"
        sudo env "PATH=$PATH" "$npm_bin" install -g --prefix /usr/local @devcontainers/cli
    else
        log "@devcontainers/cli already installed ($(devcontainer --version))"
    fi

    if ! command -v ajv >/dev/null 2>&1; then
        log "installing ajv-cli into /usr/local"
        sudo env "PATH=$PATH" "$npm_bin" install -g --prefix /usr/local ajv-cli
    else
        log "ajv-cli already installed"
    fi
}

main() {
    log "starting environment setup (user=${TARGET_USER})"
    install_apt_prereqs
    install_docker
    install_oras
    install_node_clis
    log "environment setup complete"
    log "  docker:       $(docker --version 2>/dev/null || echo MISSING)"
    log "  devcontainer: $(devcontainer --version 2>/dev/null || echo MISSING)"
    log "  oras:         $(oras version 2>/dev/null | awk '/^Version/{print $2}' || echo MISSING)"
    log "  jq:           $(jq --version 2>/dev/null || echo MISSING)"
}

main "$@"
