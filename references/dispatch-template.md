# Worker Dispatch Template

Use this template when spawning coding workers via `sessions_spawn`.
Before spawn, planner generates and persists `event_nonce` in task state.

## Subagent + Coding Agent Pattern

Non-negotiable rule: worker uses `coding-agent` skill for coding execution.

```javascript
sessions_spawn({
  runtime: "subagent",
  mode: "run",
  label: `worker-${taskId}`,
  task: `You are a coding worker for autopilot task: ${taskId}

## Task Objective
${taskObjective}

## Acceptance Criteria
${acceptanceCriteria}

## Verification Requirements
${verificationCommands}

## Implementation Instructions

1. Mandatory: invoke the `coding-agent` skill first. Do not directly execute coding work outside that skill unless explicitly requested for recovery/debug.
2. Use the coding-agent skill to run the appropriate coding agent:
   - For building/creating: Use Codex with --full-auto flag
   - For reviewing: Use vanilla Codex (no special flags)
   - For frontend work: Include Playwright e2e tests

3. Run in background with PTY and auto-notify:

\`\`\`bash
bash pty:true workdir:${workdir} background:true command:"codex exec --full-auto '
  ${detailedTaskInstructions}

  Verification steps:
  ${verificationCommands}

  When completely finished, run:
  openclaw system event --text \"TASK_COMPLETE: ${taskId} ${event_nonce}\" --mode now
'"
\`\`\`

4. Monitor the coding agent via:
   - \`subagents\` tool with \`action: "list"\` - check running subagents
   - \`sessions_history\` with \`sessionKey: childSessionKey\` - read progress and final output

5. When the system event fires, construct your completion report using the worker-contract schema:

## Required Return Format

\`\`\`
task_id: ${taskId}
status: done|failed|needs_adjustment
summary:
- [concise summary of what was accomplished]
evidence:
- cmd: [verification command]
  output: [actual output]
- artifact: [file path or commit hash]
verification:
  checks_attempted: [list of checks]
  checks_passed: [list of passed checks]
  checks_failed: [list of failed checks]
  why_not_fully_verifiable: null
  confidence: high|medium|low
next_suggestions:
- title: [follow-up task title]
  rationale: [why this matters]
risks_or_unknowns:
- [any concerns or unknowns]
\`\`\`

6. Return this report in your final response. The planner will ingest it when your subagent session completes.
`
})
```

## Example: Frontend Feature Task

```javascript
sessions_spawn({
  runtime: "subagent",
  mode: "run",
  label: "worker-task-dark-mode-ui-abc123",
  task: `You are a coding worker for autopilot task: task-dark-mode-ui-abc123

## Task Objective
Implement dark mode toggle in the Settings page with theme persistence

## Acceptance Criteria
- Toggle switch in Settings UI
- Theme persists across sessions (localStorage)
- All components support dark/light themes
- Smooth transition animations
- Tests pass (unit + integration + e2e)

## Verification Requirements
- npm test (unit + integration tests pass)
- npm run e2e (Playwright tests pass)

## Implementation Instructions

1. Use `coding-agent` skill, then run Codex with auto-notify:

\`\`\`bash
bash pty:true workdir:~/Projects/myapp background:true command:"codex exec --full-auto '
  Implement dark mode toggle in Settings page:

  1. Create DarkModeToggle component in src/components/Settings/
  2. Add dark theme CSS variables to src/styles/themes.css
  3. Implement theme context provider in src/contexts/ThemeContext.tsx
  4. Add localStorage persistence for theme preference
  5. Update all major components to respect theme
  6. Write unit tests for ThemeContext
  7. Write Playwright e2e test: toggle → reload → verify persistence

  Verification:
  - npm test (all tests pass)
  - npm run e2e (Playwright tests pass)

  When completely finished, run:
  openclaw system event --text \"TASK_COMPLETE: task-dark-mode-ui-abc123 nonce-2b41\" --mode now
'"
\`\`\`

2. Monitor progress with \`sessions_history\` for the worker \`childSessionKey\`

3. When system event fires and Codex finishes, return completion report:

\`\`\`
task_id: task-dark-mode-ui-abc123
status: done
summary:
- Implemented DarkModeToggle component with smooth transitions
- Added theme context with localStorage persistence
- Updated 12 components to support dark theme
- All tests passing (unit + integration + e2e)
evidence:
- cmd: npm test
  output: Test Suites: 24 passed, 24 total
- cmd: npm run e2e
  output: 8 passed (dark mode toggle, persistence, theme switching)
- artifact: src/components/Settings/DarkModeToggle.tsx
- artifact: src/contexts/ThemeContext.tsx
- commit: abc123def (feat: Add dark mode support)
verification:
  checks_attempted: ["npm test", "npm run e2e"]
  checks_passed: ["npm test", "npm run e2e"]
  checks_failed: []
  why_not_fully_verifiable: null
  confidence: high
next_suggestions:
- title: Add dark mode to admin panel
  rationale: Settings page has dark mode, admin panel should match
risks_or_unknowns: []
\`\`\`
`
})
```

## Git Worktree Pattern for Parallel Tasks

For running multiple coding agents in parallel:

```bash
# Planner creates worktrees
git worktree add -b fix/issue-78 /tmp/autopilot-task-78 main
git worktree add -b fix/issue-99 /tmp/autopilot-task-99 main

# Dispatch workers in parallel
sessions_spawn({ runtime: "subagent", task: worker_task_for_78 })
sessions_spawn({ runtime: "subagent", task: worker_task_for_99 })

# Each worker runs Codex in its own worktree:
bash pty:true workdir:/tmp/autopilot-task-78 background:true command:"codex exec --full-auto '...'"
bash pty:true workdir:/tmp/autopilot-task-99 background:true command:"codex exec --full-auto '...'"

# Workers auto-notify on completion
# Planner receives system events, reads announces, ingests results
```

## Recovery from Stale Workers

If cron safenet tick detects a worker running >2h with no progress:

1. Check active workers: `subagents` with `action: "list"`
2. Read latest logs/output: `sessions_history` with `sessionKey: childSessionKey`
3. If hung/crashed: `subagents` with `action: "kill"` and `target: childSessionKey`
4. Mark task `needs_adjustment`
5. Create follow-up task with narrower scope or different approach
