# Verification Policy

Autopilot is verification-first: results should be terminal-verifiable, not narrative-only.

## Baseline Policy

Before accepting task completion:

1. worker defines a concrete goal-evaluation method (criterion -> check),
2. worker runs implement -> verify -> repair loops until checks pass or hard limits are explicit,
3. collect command-level evidence,
4. capture verification confidence.

Planner default role is to adjudicate worker evidence, not to replicate the full worker verification loop.

## Status Decision Policy

Status choice is behavior policy (not schema policy):

- `done`: acceptance criteria/objective are met with sufficient evidence and acceptable residual risk.
- `needs_adjustment`: acceptance criteria or objective remain unmet, or verification cannot be completed in current execution context.
- `failed`: explicit hard blocker remains after attempted mitigations.

Decision constraints:

- If any acceptance criterion is unmet in evidence, do not mark `done`; use `needs_adjustment` unless scope is explicitly descoped by the user.
- Do not use `needs_adjustment`/`failed` as first response to ordinary test failures; worker should attempt repair loops first.
- Do not duplicate the same item across `objective_gaps`, `next_suggestions`, and `risks_or_unknowns`.

Follow-up triage policy:

- Treat `objective_gaps` and `risks_or_unknowns` as mandatory triage inputs.
- For each non-trivial risk/suggestion, planner must choose one:
  - create follow-up task,
  - defer with explicit rationale,
  - reject with explicit rationale.

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

- worker shows repeated iterate/repair attempts,
- worker documents why remaining scope is not fully verifiable in current execution context,
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
