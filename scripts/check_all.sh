#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_DIR="${1:-$ROOT_DIR/.openclaw-autopilot}"

"$ROOT_DIR/scripts/validate_doc_boundaries.sh"
if [[ -d "$STATE_DIR" ]]; then
  "$ROOT_DIR/scripts/validate_state.sh" "$STATE_DIR"
else
  echo "autopilot check_all: state dir not found, skipping validate_state ($STATE_DIR)" >&2
fi

echo "autopilot check_all: ok"
