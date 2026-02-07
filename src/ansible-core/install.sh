#!/usr/bin/env bash
set -euo pipefail
umask 0002

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
COLLECTIONS_OPTION="${COLLECTIONS:-}"
ROLES_OPTION="${ROLES:-}"
mkdir -p "/usr/share/ansible/collections" "/usr/share/ansible/roles"


if ! command -v pipx >/dev/null 2>&1; then
    echo "ERROR: pipx is not available. This feature depends on ghcr.io/devcontainers/features/python:1."
    exit 1
fi

pipx install ansible-core
if [ -n "${COLLECTIONS_OPTION}" ]; then
    NORMALIZED_COLLECTIONS="$(printf '%s' "${COLLECTIONS_OPTION}" | tr ',\n\t' '   ')"
    for collection in ${NORMALIZED_COLLECTIONS}; do
        ansible-galaxy collection install "${collection}" --collections-path "/usr/share/ansible/collections"
    done
fi

if [ -n "${ROLES_OPTION}" ]; then
    NORMALIZED_ROLES="$(printf '%s' "${ROLES_OPTION}" | tr ',\n\t' '   ')"
    for role in ${NORMALIZED_ROLES}; do
        ansible-galaxy role install "${role}" --roles-path "/usr/share/ansible/roles"
    done
fi
