#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-.openclaw-autopilot}"
OUT_FILE="$ROOT_DIR/events/checkpoints.jsonl"
TS="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

error() {
  echo "autopilot compact_snapshots: $*" >&2
  exit 1
}

[[ -d "$ROOT_DIR" ]] || error "missing root directory: $ROOT_DIR"
[[ -f "$ROOT_DIR/portfolio.md" ]] || error "missing portfolio.md"
[[ -f "$OUT_FILE" ]] || error "missing checkpoints.jsonl"

ACTIVE_PROJECTS="$(find "$ROOT_DIR/projects" -type f -name '*.md' | wc -l | tr -d ' ')"
ACTIVE_TASKS="$(find "$ROOT_DIR/tasks" -type f -name '*.md' | wc -l | tr -d ' ')"

SUMMARY="snapshot compacted: projects=$ACTIVE_PROJECTS tasks=$ACTIVE_TASKS"

if command -v jq >/dev/null 2>&1; then
  jq -cn \
    --arg ts "$TS" \
    --arg summary "$SUMMARY" \
    --arg projects "$ACTIVE_PROJECTS" \
    --arg tasks "$ACTIVE_TASKS" \
    '{
      ts: $ts,
      scope: "portfolio",
      scope_id: "portfolio",
      window_start: $ts,
      window_end: $ts,
      summary: $summary,
      key_metrics: {
        project_count: ($projects | tonumber),
        task_count: ($tasks | tonumber)
      }
    }' >>"$OUT_FILE"
else
  printf '{"ts":"%s","scope":"portfolio","scope_id":"portfolio","window_start":"%s","window_end":"%s","summary":"%s","key_metrics":{"project_count":%s,"task_count":%s}}\n' \
    "$TS" "$TS" "$TS" "$SUMMARY" "$ACTIVE_PROJECTS" "$ACTIVE_TASKS" >>"$OUT_FILE"
fi

echo "autopilot compact_snapshots: appended checkpoint at $TS"
