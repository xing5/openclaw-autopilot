---
name: autopilot
description: Autonomous multi-project planner and dispatcher for coding agents. Use when the user wants goal decomposition, parallel task execution, continuous replanning, structured worker status tracking, and unblock requests only when human input is required.
metadata:
  {
    "openclaw":
      {
        "emoji": "🧭",
        "requires": { "config": ["acp.enabled", "acp.dispatch.enabled"] },
      },
  }
---

# Autopilot

Autopilot runs a continuous planning loop across multiple projects:

1. Keep a compact portfolio state.
2. Decompose work into runnable tasks.
3. Dispatch coding tasks to ACP workers (default `codex`).
4. Replan from worker outcomes.
5. Ask humans only when policy/access/product decisions are required.

## Read This First

- Load state contract: `references/state-model.md`
- Load worker return contract: `references/worker-contract.md`
- Load verification policy: `references/verification-policy.md`
- Load runbook: `references/runbook.md`

## Trigger Conditions

Use this skill when the user asks for:

- autonomous orchestration across projects
- planner + worker execution
- event-driven progress with occasional unblocks
- delegation to Codex/ACP workers with verifiable outcomes

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
6. Dispatch tasks to ACP workers.
7. Wait for next event and repeat.

## Dispatch Policy

- Default worker backend: ACP (`runtime: "acp"`), `agentId: "codex"`.
- Every dispatched task prompt must include:
  - task objective and scope boundaries
  - explicit acceptance criteria
  - required verification commands
  - required return schema from `references/worker-contract.md`
- Track worker session/run identifiers in task state.

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
