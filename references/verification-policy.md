# Verification Policy

Autopilot is verification-first: results should be terminal-verifiable, not narrative-only.

## Baseline Policy

Before accepting task completion:

1. confirm acceptance criteria were exercised,
2. collect command-level evidence,
3. capture verification confidence.

## Frontend Policy

Default required checks:

- unit tests
- integration tests
- Playwright e2e tests

If visual comparison tooling exists, include visual checks as additional evidence.

## Remote Runtime Policy

For tasks that depend on remote/GPU/cluster behavior:

- run verification in live SSH context,
- capture command outputs and artifact/log references,
- include enough context for replay (host label, directory, command lines).

## Soft-Gate Judgment

Planner may still mark `done` with incomplete verification when all are true:

- strong implementation evidence exists,
- residual risk is explicitly documented,
- confidence is recorded with rationale,
- immediate follow-up validation is low-value relative to current portfolio goals.

Otherwise choose `needs_adjustment` and create follow-up validation tasks.

## Never-Rely-On-Human-Verification Rule

Do not ask humans to manually verify routine coding correctness.
Human intervention should be reserved for:

- policy decisions,
- priority tradeoffs,
- access credential or environment unblocks,
- product intent clarifications.

## Evidence Checklist

For each completed task include:

- commands run
- pass/fail signals
- artifacts/logs
- verification confidence
- explicit note on any unverified scope
