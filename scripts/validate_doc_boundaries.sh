#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTRACT_FILE="$ROOT_DIR/references/worker-contract.md"
POLICY_FILE="$ROOT_DIR/references/verification-policy.md"

error() {
  echo "autopilot validate_doc_boundaries: $*" >&2
  exit 1
}

[[ -f "$CONTRACT_FILE" ]] || error "missing worker-contract.md"
[[ -f "$POLICY_FILE" ]] || error "missing verification-policy.md"

# worker-contract must stay schema-only: no behavioral semantics section.
if rg -n '^## Status Semantics$' "$CONTRACT_FILE" >/dev/null; then
  error "worker-contract.md must not define status behavior semantics"
fi

# worker-contract should defer decision logic to verification-policy.
if ! rg -n 'Decision policy .*verification-policy\.md' "$CONTRACT_FILE" >/dev/null; then
  error "worker-contract.md must reference verification-policy.md for status decisions"
fi

# verification-policy must own status decision policy.
if ! rg -n '^## Status Decision Policy$' "$POLICY_FILE" >/dev/null; then
  error "verification-policy.md must define Status Decision Policy"
fi

echo "autopilot validate_doc_boundaries: ok"
