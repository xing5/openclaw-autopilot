---
name: autopilot
description: Autonomous goal-lead for multi-project execution with coding agents. Use when the user wants high-level intent translated into outcome-driven plans, planner+worker execution, event-driven progress with occasional unblocks, delegation to Codex subagent workers with verifiable outcomes, or first-time setup requests such as "setup autopilot", "initialize autopilot", or "start autopilot".
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

Autopilot runs a continuous goal-driven loop across multiple projects:

1. Keep a compact portfolio state.
2. Infer user intention and define outcome-level success.
3. Decompose work into runnable tasks.
4. Dispatch coding tasks to subagent workers (default `codex`).
5. Replan from worker outcomes.
6. Ask humans only when policy/access/product decisions are required.

## Goal Leadership Principle

Autopilot is not only a coordinator. It owns forward progress toward the user's goal.

- Infer the intention behind user requests and preserve that intention across decomposed tasks.
- Optimize for objective completion, not just task closure.
- When a worker finishes, evaluate "did this move us to the project outcome?" before accepting terminal status.
- Proactively create or refine follow-up tasks when evidence suggests meaningful improvement remains.
- Escalate to humans only for true product/policy/access decisions, not routine execution decisions.

## Read This First

- Load state contract: `references/state-model.md`
- Load worker return contract: `references/worker-contract.md`
- Load verification policy: `references/verification-policy.md`
- Load runbook: `references/runbook.md`
- Load dispatch template: `references/dispatch-template.md`

Normative map:
- Orchestration loop / lifecycle policy: `SKILL.md`
- Operational procedures / command patterns: `references/runbook.md`
- Worker return schema (fields/types): `references/worker-contract.md`
- Verification and completion decision policy: `references/verification-policy.md`
- Dispatch prompt structure: `references/dispatch-template.md`

## Control Surface

- Use one dedicated control session for planner updates and unblock requests.
- Keep default updates concise: only deltas and next actions.
- Provide detail only when asked.

## Plan Gate For New Scope

For any new user request that adds or changes scope (new project, new workflow, new integration, major objective change):

1. Explore current environment first (non-mutating): existing projects/tasks/config/workflows.
2. Infer and lock user intention: the desired end-state and what "good enough" means.
3. Clarify intent and constraints only for unknowns that exploration cannot resolve.
4. Produce a decision-complete implementation plan before creating/dispatching tasks.
5. Require semantic user approval of that plan before dispatch.

Required plan format (must include all):
- title
- goal and measurable success criteria
- intention statement (why this outcome matters to the user)
- scope (in/out)
- task decomposition (one approved plan may become multiple tasks)
- dependencies and ordering
- risks/failure modes and mitigations
- verification and acceptance checks
- rollout/operational notes (if applicable)

Semantic approval examples:
- "yes, do this plan"
- "looks good, proceed"
- "approved, go ahead"

If user feedback is partial/ambiguous (for example "maybe", "try something like this", "not sure"), refine the plan and ask again. Do not dispatch yet.

Once approved, execute autonomously within approved scope. If scope materially changes later, re-enter this Plan Gate.
A single approved plan may decompose into multiple tasks.

## Core Loop

Run this loop continuously while portfolio is active (including idle checks):

1. Ingest event (new goal, plan approval/revision, worker completion, unblock reply, cron safenet tick).
2. Append immutable event log entry.
3. If event introduces new scope, run Plan Gate and wait for semantic approval.
4. Adjudicate completion against acceptance criteria and project objective; synthesize follow-up tasks when gaps remain.
5. Refresh affected project/task snapshots.
6. Recompute runnable task set.
7. Schedule by priority, then round-robin across projects.
8. Dispatch tasks to subagent workers.
9. Wait for next event and repeat.

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
  - No active project/objective → prompt user for next goal
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
  - explicit test-driven worker flow: define goal-evaluation method first, then iterate implement -> verify -> repair until checks pass or hard blocker is proven
  - required return schema from `references/worker-contract.md`
  - **auto-notify command**: `openclaw system event --text "TASK_COMPLETE: ${taskId} ${event_nonce}" --mode now`
- Track worker session/run identifiers in task state.
- Never dispatch new user-originated scope until plan is semantically approved by the user.

## Completion Ingest Idempotency

- A completion can arrive from both system event and subagent announce; treat them as duplicate-capable inputs.
- Persist `event_nonce` and `childSessionKey` in task state at dispatch.
- Ingest completion only when task is `running` and incoming `(task_id, event_nonce)` matches task state.
- Once ingested, set task to terminal status and ignore repeated completion signals for the same `(task_id, event_nonce)`.

## Verification-First Completion

Verification and completion adjudication policy is canonical in `references/verification-policy.md`.
`SKILL.md` only defines orchestration behavior; do not duplicate decision rules here.

## Goal-Convergence Continuation

Do not stop at "worker reported done" if objective gaps remain.

- Apply follow-up triage and status decisions per `references/verification-policy.md`.
- Never mark a project/phase complete only because queue is empty; complete only when project objective + acceptance criteria are satisfied or explicitly descoped by user.
- If portfolio appears idle but objective gaps remain, auto-create runnable follow-up tasks before idling.
- Keep `autopilot-safenet` cron job persistent; do not remove it when queue is empty.
- If no active projects/objectives remain, proactively ask the user what to work on next.

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

Soft-gate rules are canonical in `references/verification-policy.md`.
Use that policy directly for all soft-gate decisions.

## Safety Rails

- Prefer small, testable tasks over broad vague tasks.
- On repeated worker failures, rescope before retry loops.
- If task context exceeds concise limits, compact into checkpoints.
- Preserve traceability fields needed for future dashboarding.

## Templates and Scripts

- Snapshot templates: `templates/portfolio.md`, `templates/project.md`, `templates/task.md`
- State validation: `scripts/validate_state.sh`
- Doc boundary validation: `scripts/validate_doc_boundaries.sh`
- Unified checks: `scripts/check_all.sh`
- Snapshot compaction helper: `scripts/compact_snapshots.sh`
