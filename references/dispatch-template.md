# Worker Dispatch Template

Use this template when spawning coding workers via `sessions_spawn`.
Before spawn, planner generates and persists `event_nonce` in task state.

## Delegation Boundary

- `autopilot` owns planning, scope boundaries, acceptance criteria, verification requirements, and completion ingest.
- `coding-agent` owns coding-agent execution mechanics (PTY/background process setup, provider command invocation, and session monitoring workflow).
- Do not duplicate or re-specify `coding-agent` shell wrappers in this template. Reference the skill and provide task payload only.

## Planner Inputs (Required)

Populate these fields before dispatch:

- `taskId`
- `projectId`
- `event_nonce`
- `workdir`
- `taskObjective`
- `scopeBoundaries`
- `acceptanceCriteria`
- `verificationRequirements`
- `returnSchemaRef` (`references/worker-contract.md`)

## Subagent Spawn Skeleton

```javascript
sessions_spawn({
  runtime: "subagent",
  mode: "run",
  label: `worker-${taskId}`,
  task: `You are a coding worker for autopilot task: ${taskId}

Use the \`coding-agent\` skill for implementation.

## Task Context
- project_id: ${projectId}
- task_id: ${taskId}
- event_nonce: ${event_nonce}
- workdir: ${workdir}

## Objective
${taskObjective}

## Scope Boundaries
${scopeBoundaries}

## Acceptance Criteria
${acceptanceCriteria}

## Verification Requirements
${verificationRequirements}

## Execution Policy
1. Follow the \`coding-agent\` skill for all coding execution mechanics.
2. Define goal-evaluation method first (criterion -> concrete check).
3. Iterate implement -> verify -> repair until checks pass or hard blocker/verifier limit is explicit.
4. Do not return \`needs_adjustment\` or \`failed\` as a first response to normal test failures; attempt repair loops first.
5. On completion, run:
openclaw system event --text "TASK_COMPLETE: ${taskId} ${event_nonce}" --mode now

## Completion Contract
Return final completion payload that conforms to ${returnSchemaRef}.
\`event_nonce\` is mandatory and must equal ${event_nonce}.
\`task_id\`, \`status\`, \`summary\`, \`evidence\`, and \`verification\` are mandatory core fields.
`
})
```

## Completion Ingest Notes

- Match worker completion to task only when `(task_id, event_nonce)` equals task state.
- Ignore duplicate completion signals for the same `(task_id, event_nonce)` after terminal ingest.
- If acceptance criteria are unmet in evidence, mark `needs_adjustment` and create follow-up task(s).
