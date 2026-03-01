# Task: {{title}}

task_id: {{task_id}}
project_id: {{project_id}}
parent_task_id: {{parent_task_id}}
priority: {{priority}}
status: {{status}}
created_at: {{created_at}}
updated_at: {{updated_at}}

## Objective

{{objective}}

## Acceptance Criteria

1. {{criterion_one}}
2. {{criterion_two}}

## Dependencies

- {{dependency_or_none}}

## Worker Assignment

- worker_backend: {{worker_backend}}
- worker_agent_id: {{worker_agent_id}}
- worker_session_key: {{worker_session_key}}
- run_id: {{run_id}}
- event_nonce: {{event_nonce}}
- started_at: {{started_at_or_null}}
- ended_at: {{ended_at_or_null}}

## Verification Summary

- verification_complete: {{verification_complete}}
- verification_confidence: {{verification_confidence}}
- checks_passed: {{checks_passed}}
- checks_failed: {{checks_failed}}
- why_not_fully_verifiable: {{why_not_fully_verifiable}}
- blocked_duration_ms: {{blocked_duration_ms_or_null}}
- objective_gaps: {{objective_gaps_or_empty}}
- gap_triage_decision: {{gap_triage_decision_or_none}}

## Evidence

- {{evidence_item}}

## Risks and Unknowns

- {{risk_item}}

## Next Suggestions

- {{suggestion_item}}
