# State Model

This file defines the persisted state for `autopilot`.

## Directory Layout

```text
.openclaw-autopilot/
  portfolio.md
  projects/
    <project_id>.md
  tasks/
    <task_id>.md
  events/
    events.jsonl
    checkpoints.jsonl
```

## ID Conventions

- `project_id`: `proj-<slug>`
- `task_id`: `task-<slug>-<shortid>`
- `block_id`: `block-<timestamp>-<shortid>`

Use stable IDs once created.

## Task Status Enum

- `proposed`
- `ready`
- `running`
- `blocked_human`
- `needs_adjustment`
- `failed`
- `done`
- `canceled`

## `portfolio.md` Contract

Keep this concise and always current. Include:

- active projects summary table
- high-priority runnable tasks
- blocked items requiring human input
- recently completed items
- latest planner heartbeat timestamp

## `projects/<project_id>.md` Contract

Each project snapshot includes:

- metadata: name, priority, objective, current phase
- status counters by task state
- active branches/workstreams
- next recommended planner actions
- links to key task IDs

## `tasks/<task_id>.md` Contract

Each task snapshot includes:

- task identity and project link
- objective and acceptance criteria
- dependencies (task IDs or "none")
- worker assignment metadata
- status, confidence, verification summary
- evidence pointers (artifacts, logs, outputs)
- follow-up suggestions

## Event Log: `events/events.jsonl`

Append-only JSON object per line.

Required fields:

- `ts` (ISO timestamp)
- `event_type`
- `project_id` (nullable for portfolio events)
- `task_id` (nullable)
- `block_id` (nullable)
- `from_status` (nullable)
- `to_status` (nullable)
- `actor` (`planner|worker|human|system`)
- `summary`
- `evidence` (array)
- `meta` (object, optional)

Common `event_type` values:

- `project_created`
- `task_created`
- `task_dispatched`
- `task_status_changed`
- `worker_result_ingested`
- `block_opened`
- `block_resolved`
- `checkpoint_compacted`
- `planner_tick`

## Checkpoint Log: `events/checkpoints.jsonl`

Used for compact rollups without losing full history.

Required fields:

- `ts`
- `scope` (`portfolio|project`)
- `scope_id` (`portfolio` or `project_id`)
- `window_start`
- `window_end`
- `summary`
- `key_metrics`

## Dashboard-Ready Fields (Persist Now)

Every task snapshot and relevant event should capture:

- `priority`
- `parent_task_id` (nullable)
- `worker_backend` (`acp`)
- `worker_agent_id` (`codex` by default)
- `worker_session_key`
- `run_id`
- `started_at`
- `ended_at`
- `verification_confidence`
- `verification_complete` (`true|false`)
- `blocked_duration_ms` (for resolved blocks when known)
