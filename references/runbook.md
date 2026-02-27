# Runbook

## Start New Portfolio

1. Ensure `.openclaw-autopilot/` exists.
2. Create/update `portfolio.md` from template.
3. Add initial projects and seed tasks.
4. Emit `project_created` and `task_created` events.

## Event-Driven Operation

Primary trigger sources:

- worker completion messages
- human unblock responses
- new project/task intake

On each trigger:

1. append event(s),
2. refresh affected snapshots,
3. schedule runnable tasks.

## Cron Safety Net

Configure a periodic cron tick to:

- detect stale `running` tasks,
- reconcile missing worker outcomes,
- compact noisy snapshots,
- kick planner when event flow stalls.

## Human Block Handling

When blocked, emit:

- `BLOCK_ID`
- reason and requested action
- impact if unresolved

Accept free-text response, map to open block, emit `block_resolved`, and continue.

## Failure and Retry Guidance

- First failure: retry if fix is obvious.
- Repeated failure: switch to `needs_adjustment` and rescope task.
- Hard blocker: `blocked_human` only when human action is actually required.

## Compactness Rules

- Keep `portfolio.md` short.
- Keep project files focused on current active work.
- Keep deep history in JSONL logs and periodic checkpoints.

## Recovery

On restart:

1. read latest snapshots,
2. replay tail of `events.jsonl` if needed,
3. identify runnable tasks,
4. resume scheduler.
