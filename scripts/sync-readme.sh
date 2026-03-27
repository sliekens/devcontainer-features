#!/usr/bin/env bash
#
# Sync the features table in README.md from devcontainer-feature.json files.
#
# Replaces the content between <!-- BEGIN FEATURES TABLE --> and
# <!-- END FEATURES TABLE --> markers with a generated table based on
# the id and description fields in each src/*/devcontainer-feature.json.
#
# Usage:
#   ./scripts/sync-readme.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
README="$REPO_DIR/README.md"
SRC_DIR="$REPO_DIR/src"

BEGIN_MARKER="<!-- BEGIN FEATURES TABLE -->"
END_MARKER="<!-- END FEATURES TABLE -->"

if ! grep -qF "$BEGIN_MARKER" "$README"; then
    echo "error: marker '$BEGIN_MARKER' not found in $README" >&2
    exit 1
fi

# Build the table rows, sorted by feature id
table="| Feature | Description |"$'\n'
table+="|---------|-------------|"$'\n'
while IFS= read -r feature_id; do
    description="$(jq -r '.description' "$SRC_DIR/$feature_id/devcontainer-feature.json")"
    table+="| [\`${feature_id}\`](src/${feature_id}/README.md) | ${description} |"$'\n'
done < <(find "$SRC_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)

# Replace everything between the markers (markers themselves are preserved)
awk \
    -v begin="$BEGIN_MARKER" \
    -v end="$END_MARKER" \
    -v table="$table" \
    '
    $0 == begin { print; printf "%s", table; skip=1; next }
    $0 == end   { skip=0 }
    !skip        { print }
    ' "$README" > "$README.tmp"

mv "$README.tmp" "$README"

echo "README.md features table updated."
