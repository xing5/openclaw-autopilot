# Dashboard Readiness

V1 does not build a dashboard, but must emit data that supports one later.

## Required Views to Enable Later

- portfolio health
- per-project progress
- task funnel and throughput
- blocked queue and unblock latency
- verification completeness and confidence

## Required Data Dimensions

- time: created/started/completed timestamps
- scope: portfolio, project, task
- ownership: worker backend/agent/session
- quality: verification completeness/confidence
- risk: failure/needs-adjustment reasons

## Suggested Metrics

- `tasks_created_total`
- `tasks_completed_total`
- `tasks_failed_total`
- `tasks_needs_adjustment_total`
- `tasks_blocked_human_total`
- `verification_incomplete_total`
- `mean_task_cycle_time_ms`
- `mean_block_resolution_time_ms`

## Event Mapping

These event types should always be present for dashboard derivation:

- `task_created`
- `task_dispatched`
- `task_status_changed`
- `worker_result_ingested`
- `block_opened`
- `block_resolved`

## Snapshot Compatibility

Dashboard should be able to render from either:

- live snapshots (`portfolio.md`, `projects/*.md`, `tasks/*.md`), or
- event replay from JSONL logs.
