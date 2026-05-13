#!/usr/bin/env bash
set -euo pipefail

TARGET="${_REMOTE_USER:-}"

if [ -z "$TARGET" ] || [ "$TARGET" = "vscode" ]; then
    exit 0
fi

if id "$TARGET" &>/dev/null; then
    echo "User '$TARGET' already exists, skipping rename."
    exit 0
fi

usermod -l "$TARGET" -d "/home/$TARGET" -m vscode
groupmod -n "$TARGET" vscode
# Update supplementary group memberships — usermod -l doesn't update /etc/group member lists
sed -i "s/\bvscode\b/$TARGET/g" /etc/group
sed -i "s/vscode/$TARGET/g" /etc/sudoers.d/vscode
mv /etc/sudoers.d/vscode "/etc/sudoers.d/$TARGET"
