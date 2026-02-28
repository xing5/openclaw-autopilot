---
name: autopilot
description: Autonomous multi-project planner and dispatcher for coding agents. Use when the user wants goal decomposition, parallel task execution, continuous replanning, structured worker status tracking, and unblock requests only when human input is required.
metadata:
  {
    "openclaw":
      {
        "emoji": "🧭",
        "requires": { "config": ["skills.entries.coding-agent.enabled"] },
      },
  }
---

# Autopilot

Autopilot runs a continuous planning loop across multiple projects:

1. Keep a compact portfolio state.
2. Decompose work into runnable tasks.
3. Dispatch coding tasks to subagent workers (default `codex`).
4. Replan from worker outcomes.
5. Ask humans only when policy/access/product decisions are required.

## Read This First

- Load state contract: `references/state-model.md`
- Load worker return contract: `references/worker-contract.md`
- Load verification policy: `references/verification-policy.md`
- Load runbook: `references/runbook.md`
- Load dispatch template: `references/dispatch-template.md`

## Trigger Conditions

Use this skill when the user asks for:

- autonomous orchestration across projects
- planner + worker execution
- event-driven progress with occasional unblocks
- delegation to Codex subagent workers with verifiable outcomes
- first-time setup phrases like "setup autopilot", "initialize autopilot", "start autopilot"

## Control Surface

- Use one dedicated control session for planner updates and unblock requests.
- Keep default updates concise: only deltas and next actions.
- Provide detail only when asked.

## Core Loop

Run this loop continuously while runnable tasks exist:

1. Ingest event (new goal, worker completion, unblock reply, cron safenet tick).
2. Append immutable event log entry.
3. Refresh affected project/task snapshots.
4. Recompute runnable task set.
5. Schedule by priority, then round-robin across projects.
6. Dispatch tasks to subagent workers.
7. Wait for next event and repeat.

## Wake Mechanisms (EVENT-DRIVEN)

Workers auto-notify on completion via `openclaw system event`, triggering immediate planner wake.

**Setup (do on first dispatch):**
1. Create/update cron safenet job at 15-minute interval
2. Save `childSessionKey` from `sessions_spawn` into each task file
3. Generate and persist `event_nonce` per task dispatch
4. Workers include auto-notify in their completion: `openclaw system event --text "TASK_COMPLETE: ${taskId} ${event_nonce}" --mode now`

**How it works:**
- **Primary**: Worker completes → runs system event → planner wakes immediately → ingests completion → dispatches next task
- **Safenet**: Cron tick (every 15m) checks for:
  - Stale/crashed workers running >2h with no progress
  - Idle portfolio with runnable tasks (no workers running but tasks queued) → auto-dispatch
  - Progress reporting to user with portfolio status summary

Planner behavior is event-driven with cron safenet checks.

## Dispatch Policy

- Default worker backend: **subagent** (`runtime: "subagent"`) with coding-agent skill
- Workers must invoke the `coding-agent` skill as the execution interface for coding work.
- Do not bypass `coding-agent` with ad-hoc direct shell commands except for explicit recovery/debug tasks.
- Every dispatched task prompt must include:
  - explicit first instruction: "Use the `coding-agent` skill for implementation"
  - task objective and scope boundaries
  - explicit acceptance criteria
  - required verification commands
  - required return schema from `references/worker-contract.md`
  - **auto-notify command**: `openclaw system event --text "TASK_COMPLETE: ${taskId} ${event_nonce}" --mode now`
- Track worker session/run identifiers in task state.

## Completion Ingest Idempotency

- A completion can arrive from both system event and subagent announce; treat them as duplicate-capable inputs.
- Persist `event_nonce` and `childSessionKey` in task state at dispatch.
- Ingest completion only when task is `running` and incoming `(task_id, event_nonce)` matches task state.
- Once ingested, set task to terminal status and ignore repeated completion signals for the same `(task_id, event_nonce)`.

## Verification-First Completion

Never treat "implementation exists" as sufficient.

- For coding tasks, require terminal-verifiable checks.
- For frontend tasks, require unit + integration + Playwright e2e by default.
- For remote/GPU tasks, require executed SSH-session evidence.

Use the full policy in `references/verification-policy.md`.

## Human Unblock Protocol

When blocked on access/policy/priority/product decisions:

1. Emit a structured block message using `BLOCK_ID`.
2. Ask one concrete question.
3. List expected action and impact.

Accept normal free-text user replies, map to the open `BLOCK_ID`, log resolution, and resume.

## State Rules

- Source of truth is workspace files under `.openclaw-autopilot/`.
- Ensure `.openclaw-autopilot/events/events.jsonl` and `.openclaw-autopilot/events/checkpoints.jsonl` both exist before dispatch.
- Keep snapshots concise and LLM-friendly.
- Keep `events.jsonl` append-only and never rewrite history.
- Use checkpoint rollups for compaction rather than deleting event history.

## Soft-Gate Judgment Rule

Verification is a default hard expectation, but final completion can use planner judgment.

- If verification is incomplete, planner may mark `done` only when:
  - evidence quality is high,
  - residual risk is explicitly documented,
  - confidence and rationale are recorded.
- Otherwise mark `needs_adjustment` and create follow-up validation tasks.
- Do not ask humans to manually verify routine coding results.

## Safety Rails

- Prefer small, testable tasks over broad vague tasks.
- On repeated worker failures, rescope before retry loops.
- If task context exceeds concise limits, compact into checkpoints.
- Preserve traceability fields needed for future dashboarding.

## Templates and Scripts

- Snapshot templates: `templates/portfolio.md`, `templates/project.md`, `templates/task.md`
- State validation: `scripts/validate_state.sh`
- Snapshot compaction helper: `scripts/compact_snapshots.sh`
