# Autopilot — Installation Guide

Follow these steps to set up Autopilot on this OpenClaw agent.

## Step 1: Create directories

```bash
mkdir -p autopilot/outcomes
```

## Step 2: Initialize portfolio state

Create `autopilot/portfolio.json`:

```json
{
  "projects": []
}
```

## Step 3: Add trigger hook to AGENTS.md

Append the following block to the end of `AGENTS.md` (before any closing section like "Make It Yours"):

```markdown
## 🤖 Autopilot (always active)

When a subagent completion announcement arrives with label starting with `autopilot:`,
read `autopilot/SKILL.md` and follow its instructions to evaluate the outcome,
update portfolio state, and spawn follow-up workers.

When the user says `autopilot add project:`, `autopilot status`, `autopilot pause`,
`autopilot resume`, or `autopilot drop`, read `autopilot/SKILL.md` and handle the command.
```

This hook ensures the main session agent recognizes Autopilot events on every turn.
AGENTS.md is loaded into the system prompt on every turn — the hook is always active.

## Step 4: Set up watchdog cron

Create a safety-net cron job that catches stuck/orphaned workers (runs every 4 hours):

```
cron add job:{
  "name": "autopilot-watchdog",
  "schedule": { "kind": "every", "everyMs": 14400000 },
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "Autopilot watchdog sweep. Read autopilot/portfolio.json. Check for: (1) tasks stuck in 'running' status for >30 minutes with no active session, (2) projects with all tasks done but project still 'active' — evaluate if goal is met, (3) any stale state. Fix what you find. If the portfolio is empty or nothing needs attention, reply with exactly NO_REPLY and do nothing else."
  },
  "delivery": { "mode": "announce" },
  "enabled": true
}
```

## Step 5: Verify

Say `autopilot status` — you should see "No active projects."

## How It Works

Autopilot uses an **event-driven chain reaction**, not polling:

1. User says `autopilot add project: <goal>`
2. Agent decomposes goal → spawns worker via `sessions_spawn` with `autopilot:*` label
3. Worker runs in isolated session, finishes, result announced back to main session
4. AGENTS.md hook fires → agent reads SKILL.md → evaluates outcome → spawns next worker
5. Chain continues until goal is met or escalation is needed

The watchdog cron is only a safety net for stuck workers — not the primary driver.

## Uninstalling

1. Remove the Autopilot section from AGENTS.md
2. Remove the `autopilot-watchdog` cron job
3. Delete `autopilot/` directory
