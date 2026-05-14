#!/bin/env bash
set -euo pipefail
set -x

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Ensure curl is available
if ! command -v curl &> /dev/null; then
    echo "Installing curl..."
    if command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y curl
    elif command -v apk &> /dev/null; then
        apk add --no-cache curl
    elif command -v dnf &> /dev/null; then
        dnf install -y curl
    elif command -v yum &> /dev/null; then
        yum install -y curl
    else
        echo "ERROR: Unable to install curl. Please install it manually."
        exit 1
    fi
fi

# Ensure libicu is available (required by .NET/Aspire)
if ! ldconfig -p | grep -q libicu 2>/dev/null; then
    echo "Installing libicu..."
    if command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y libicu-dev
    elif command -v apk &> /dev/null; then
        apk add --no-cache icu-libs
    elif command -v dnf &> /dev/null; then
        dnf install -y libicu
    elif command -v yum &> /dev/null; then
        yum install -y libicu
    fi
fi

ASPIRE_INSTALL_URL="https://aspire.dev/install.sh"
TARGET_SCRIPT="/tmp/aspire-install.sh"
QUALITY_OPTION="${QUALITY:-release}"

# Install aspire into /opt/aspire/bin so that aspire setup writes its bundle
# to /opt/aspire (parent of the bin dir, matching aspire's layout convention).
# The directory is world-writable so any container user can run aspire setup
# without needing root. No symlink into /usr/local/bin — aspire uses its own
# resolved path to locate the bundle, so a symlink would redirect it back to
# /usr/local.
ASPIRE_DIR="/opt/aspire"
mkdir --parents "$ASPIRE_DIR/bin"

curl --fail --silent --show-error --location "$ASPIRE_INSTALL_URL" --output "$TARGET_SCRIPT"

bash "$TARGET_SCRIPT" --install-path "$ASPIRE_DIR/bin" --quality "$QUALITY_OPTION"
echo "Aspire installer completed."

# Make /opt/aspire world-writable after the upstream installer runs, so that
# any container user can create the bundle lock and extract the bundle there.
chmod 0777 "$ASPIRE_DIR"

# Expose aspire on PATH via a wrapper script rather than a symlink. A symlink
# would make aspire resolve its install root to /usr/local (based on argv[0]);
# with exec the process sees /opt/aspire/bin/aspire as its own path and writes
# the bundle to /opt/aspire instead.
cat > /usr/local/bin/aspire << 'EOF'
#!/bin/sh
exec /opt/aspire/bin/aspire "$@"
EOF
chmod 0755 /usr/local/bin/aspire

mkdir --parents /var/lib/aspire-cli

install -d -m 0755 /usr/local/share/aspire-cli
install -m 0755 "$SCRIPT_DIR/on_create.sh" /usr/local/share/aspire-cli/on_create.sh
