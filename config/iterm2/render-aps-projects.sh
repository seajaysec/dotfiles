#!/usr/bin/env bash
# Render aps-projects.json from the __HOME__ template (machine-local paths).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="${SCRIPT_DIR}/DynamicProfiles/aps-projects.json.in"
OUT="${1:-${SCRIPT_DIR}/DynamicProfiles/aps-projects.json}"

if [[ ! -f "$TEMPLATE" ]]; then
  echo "render-aps-projects.sh: missing template: $TEMPLATE" >&2
  exit 1
fi

# Escape sed replacement metacharacters in HOME.
home_escaped="${HOME//\\/\\\\}"
home_escaped="${home_escaped//|/\\|}"
home_escaped="${home_escaped//&/\\&}"

sed "s|__HOME__|${home_escaped}|g" "$TEMPLATE" >"$OUT"
echo "Rendered $(basename "$OUT") for HOME=${HOME}"
