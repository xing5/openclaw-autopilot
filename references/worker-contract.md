# Worker Return Contract

All worker completions must return the following structure in plain text or JSON-like form.
If any required field is missing, planner marks the result invalid and requests correction.

## Required Fields

- `task_id`
- `status` (`done|failed|needs_adjustment`)
- `summary` (2-8 lines, concise)
- `evidence` (array of command outputs, artifact paths, or links)
- `verification` object
- `next_suggestions` (array, may be empty)
- `risks_or_unknowns` (array, may be empty)

## Verification Object

- `checks_attempted` (array of commands/check names)
- `checks_passed` (array)
- `checks_failed` (array)
- `why_not_fully_verifiable` (string or null)
- `confidence` (`high|medium|low`)

## Status Semantics

- `done`: objective met with sufficient evidence and acceptable risk.
- `failed`: cannot progress due to hard blocker or repeated unrecoverable errors.
- `needs_adjustment`: partial progress or verification gap requiring revised scope/follow-up.

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
status: done|failed|needs_adjustment
summary:
- ...
evidence:
- cmd: ...
  output: ...
- artifact: ...
verification:
  checks_attempted: [...]
  checks_passed: [...]
  checks_failed: [...]
  why_not_fully_verifiable: null
  confidence: high
next_suggestions:
- title: ...
  rationale: ...
risks_or_unknowns:
- ...
```
