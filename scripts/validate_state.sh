#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-.openclaw-autopilot}"
EVENTS_FILE="$ROOT_DIR/events/events.jsonl"
CHECKPOINTS_FILE="$ROOT_DIR/events/checkpoints.jsonl"

error() {
  echo "autopilot validate_state: $*" >&2
  exit 1
}

[[ -d "$ROOT_DIR" ]] || error "missing root directory: $ROOT_DIR"
[[ -f "$ROOT_DIR/portfolio.md" ]] || error "missing portfolio.md"
[[ -d "$ROOT_DIR/projects" ]] || error "missing projects directory"
[[ -d "$ROOT_DIR/tasks" ]] || error "missing tasks directory"
[[ -d "$ROOT_DIR/events" ]] || error "missing events directory"
[[ -f "$EVENTS_FILE" ]] || error "missing events.jsonl"
[[ -f "$CHECKPOINTS_FILE" ]] || error "missing checkpoints.jsonl"

if command -v jq >/dev/null 2>&1; then
  if ! jq -e . "$EVENTS_FILE" >/dev/null 2>&1; then
    error "events.jsonl has invalid JSON lines"
  fi
  if ! jq -e . "$CHECKPOINTS_FILE" >/dev/null 2>&1; then
    error "checkpoints.jsonl has invalid JSON lines"
  fi
else
  echo "autopilot validate_state: jq not found; skipping JSON validation." >&2
fi

echo "autopilot validate_state: ok ($ROOT_DIR)"
