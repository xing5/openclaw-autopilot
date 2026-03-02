# Worker Return Contract

All worker completions must return the following structure in plain text or JSON-like form.
If any required field is missing, planner marks the result invalid and requests correction.

## Core Fields (Always Required)

- `task_id`
- `event_nonce` (must match the nonce persisted in task state at dispatch time)
- `status` (`done|failed|needs_adjustment`)
- `summary` (2-8 lines, concise)
- `evidence` (array of command outputs, artifact paths, or links)
- `verification` object with:
  - `confidence` (`high|medium|low`)
  - `complete` (`true|false`)

## Conditional Fields (Required When Applicable)

- `objective_gaps` (required when acceptance criteria/outcome gaps remain; omit or empty when none)
- `risks_or_unknowns` (required when non-trivial risk/unknown exists; omit or empty when none)
- `verification.why_not_fully_verifiable` (required when `verification.complete` is `false`)

## Diagnostic Fields (Optional, But Recommended)

- `verification.checks_attempted`
- `verification.checks_passed`
- `verification.checks_failed`
- `verification.goal_evaluation_method`
- `verification.iteration_cycles`
- `next_suggestions` (non-blocking, opportunistic improvements only)

## Status Field

- `status` is an enum with allowed values: `done|failed|needs_adjustment`.
- Decision policy for choosing status values is defined in `references/verification-policy.md`.

## Evidence Quality Rules

Evidence should be directly inspectable and executable where possible.

Good evidence examples:

- test command outputs with pass/fail summary
- artifact paths in workspace
- remote command output excerpts with host/context
- commit hash + diff summary

Weak evidence examples:

- "it should work"
- no commands or artifacts
- unverifiable narrative claims

## Frontend Required Addendum

When task category is frontend/UI, worker must include:

- unit test results
- integration test results
- Playwright e2e result summary

Visual comparison is optional when baseline tooling exists; include when available.

## Remote Validation Required Addendum

When task requires cluster/GPU/runtime environment:

- worker must run checks in a live SSH terminal context
- include host/context + command outputs + log/artifact pointers
- do not claim `done` without explicit remote evidence unless planner later accepts soft-gate judgment

## Suggested Completion Template

```text
task_id: task-...
event_nonce: nonce-...
status: done|failed|needs_adjustment
summary:
- ...
evidence:
- cmd: ...
  output: ...
- artifact: ...
verification:
  confidence: high
  complete: true
# required if verification.complete == false
# why_not_fully_verifiable: "..."
# optional diagnostics
# checks_attempted: [...]
# checks_passed: [...]
# checks_failed: [...]
# goal_evaluation_method: [...]
# iteration_cycles: 3
# include when gaps exist
# objective_gaps:
# - ...
# include when risks/unknowns exist
# risks_or_unknowns:
# - ...
# optional
# next_suggestions:
# - ...
```
