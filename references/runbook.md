# Runbook

## Start New Portfolio

1. Ensure `.openclaw-autopilot/` exists.
2. Initialize required event files:
   - `mkdir -p .openclaw-autopilot/events`
   - `touch .openclaw-autopilot/events/events.jsonl`
   - `touch .openclaw-autopilot/events/checkpoints.jsonl`
3. Create/update `portfolio.md` from template.
4. Add initial projects and seed tasks.
5. Emit `project_created` and `task_created` events.
6. **Set up wake mechanisms** (see below — this is MANDATORY).
7. Ensure cron safenet exists at 15-minute interval.

### First-Use Setup Trigger

If user asks "setup autopilot", "initialize autopilot", or "start autopilot":

1. Run this "Start New Portfolio" section immediately.
2. Confirm cron safenet is created at 15-minute cadence.
3. Report created files and first runnable tasks.

## Plan Gate For New User Requests

Use this section as operational execution for the Plan Gate policy in `SKILL.md`.
For approval semantics, required plan format, and scope-change rules, follow `SKILL.md` as canonical.

Before dispatching tasks for a new request/scope:
1. Perform non-mutating exploration first (existing tasks/projects/workflows/config).
2. Infer and write an intention statement (desired end-state and success definition behind explicit task wording).
3. Clarify only high-impact unknowns not resolvable from environment.
4. Produce a decision-complete plan (scope, acceptance criteria, dependencies, risks, rollout, verification).
5. Get semantic user approval before dispatch.

After plan approval:
- create/update project/task state
- dispatch according to policy
- remain autonomous within approved scope
A single approved plan may decompose into multiple tasks.

## Wake Mechanisms (EVENT-DRIVEN)

Workers use **subagent runtime + coding-agent skill** with auto-notify, providing event-driven completion callbacks (best-effort if gateway restarts mid-run).

### 1. Create Cron Safenet (15m)

Create or update cron job (exactly every 15 minutes) to run autopilot safenet tick.

Recommended job name: `autopilot-safenet`

Set/update cadence to exactly every 15 minutes:

```bash
# Resolve existing autopilot-safenet job id by name
JOB_ID=$(openclaw cron list --json | jq -r '.jobs[] | select(.name=="autopilot-safenet") | .id' | head -n1)

# Create when missing
if [ -z "$JOB_ID" ]; then
  openclaw cron add --name autopilot-safenet --every 15m --system-event "Autopilot safenet tick: read .openclaw-autopilot/portfolio.md, check stale workers via subagents+sessions_history, ingest completions idempotently, dispatch queued runnable tasks, and report brief portfolio progress."
else
  # Update by resolved id (cron edit requires id, not name)
  openclaw cron edit "$JOB_ID" --name autopilot-safenet --every 15m --system-event "Autopilot safenet tick: read .openclaw-autopilot/portfolio.md, check stale workers via subagents+sessions_history, ingest completions idempotently, dispatch queued runnable tasks, and report brief portfolio progress."
fi
```

If `jq` is unavailable, run `openclaw cron list --json`, find the job with name `autopilot-safenet`, and use its `id` with `openclaw cron edit <id> ...`.

Cron task payload should:
- Check `.openclaw-autopilot/portfolio.md` for portfolio status
- **Stale worker detection**: For tasks running >2h, check if worker is stale via `subagents` tool (`action: "list"`)
  - If stale/crashed: mark `needs_adjustment`, create recovery task
- **Idle dispatch check**: If no workers running but runnable tasks exist:
  - Recompute priority and dispatch next batch
  - Report status to user with task queue summary
- **Progress reporting**: On each cron tick, report brief portfolio status:
  - Active workers count and what they're working on
  - Tasks in queue (count by priority)
  - Recent completions since last report
- If no active projects/objectives remain, ask user for next goal and keep safenet running

### 2. Record Worker Session Keys

When dispatching, save the `childSessionKey` from `sessions_spawn` into the task file.

### 3. Record Completion Correlation Nonce

When dispatching, generate and save an `event_nonce` for the task.

### 4. Worker Auto-Notify Pattern

Every worker task must start by invoking `coding-agent` skill, and include auto-notify command:

```bash
Use the coding-agent skill for this task.

Inside the coding-agent execution plan, include:
bash pty:true background:true command:"codex exec --full-auto 'Build feature X.

When completely finished, run: openclaw system event --text \"TASK_COMPLETE: task-feature-x-abc123 nonce-9f17\" --mode now'"
```

### On Each Wake (System Event or Cron Tick)

**Primary trigger: System event from worker completion**

1. Parse event text for `TASK_COMPLETE: ${taskId} ${event_nonce}`
2. Verify `(task_id, event_nonce)` matches a `running` task in state
3. Read subagent announce via `subagents` tool (`action: "list"`) + `sessions_history` for `childSessionKey`
4. Adjudicate completion:
   - validate payload schema against `references/worker-contract.md`
   - adjudicate completion/status and follow-up triage using `references/verification-policy.md`
5. Ingest worker result exactly once, update task/project/portfolio state
6. Dispatch next runnable task

**Fallback trigger: Cron tick (safenet + idle dispatch + progress)**

1. Read `portfolio.md` for full portfolio state
2. **Stale worker check**: For tasks running >2h with no update, check worker status via `subagents` tool (`action: "list"`)
   - If stale/crashed: mark `needs_adjustment`, create recovery task
3. **Idle dispatch check**: If no workers running but runnable tasks exist:
   - Recompute runnable task set and priority
   - Dispatch next task batch (respecting concurrency limits)
   - Report to user: "Dispatching ${taskId}: ${taskTitle}"
4. **Objective gap check**: If no workers and no runnable tasks, but unresolved project objective/intention gaps exist in latest completions:
   - Create follow-up tasks to close gaps
   - Recompute queue and dispatch
5. **Progress report**: Every cron tick, report brief status to user:
   - "Portfolio: ${activeWorkerCount} active workers, ${queuedTaskCount} tasks queued, ${recentCompletionCount} completed since last update"
   - List active worker tasks (title + estimated progress if available)
6. **No-project prompt**: If no active project/objective exists, ask user for next goal and keep `autopilot-safenet` enabled

### Completion Message Flow

```
Worker (Codex) completes
  → runs: openclaw system event --text "TASK_COMPLETE: task-id event_nonce" --mode now
  → system event wakes planner immediately
Subagent auto-announces to planner session
  → planner reads announce, extracts result
  → planner idempotency-checks `(task_id, event_nonce)` then updates state, dispatches next task
```

Event-driven primary path with cron safenet checks.

## Event-Driven Operation

Primary trigger sources:

- **system event from worker** (primary — `TASK_COMPLETE: ${taskId} ${event_nonce}`)
- **subagent announce** (automatic — completion callback to planner)
- **cron tick** (safenet — detects stale workers, idle dispatch, progress reporting)
- **plan approval/revision** (user approves or edits proposed plan for new scope)
- human unblock responses
- new project/task intake from user

On each trigger:

1. append event(s),
2. if new scope, run Plan Gate and require semantic approval before dispatch,
3. idempotency-check completion events against `(task_id, event_nonce)`,
4. adjudicate completion evidence against acceptance criteria/objective and synthesize follow-up tasks from objective gaps and meaningful risk/suggestion inputs,
5. refresh affected snapshots,
6. recompute runnable task set,
7. dispatch tasks if workers available and tasks ready.

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
4. **check for existing cron safenet** (`openclaw cron list`), create/update at 15-minute interval if missing/mismatched,
5. resume scheduler.
