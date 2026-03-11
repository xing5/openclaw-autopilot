# Autopilot — Installation Guide

## Deployment Options

### Option A: Dedicated Autopilot Agent (Recommended)

A standalone agent whose sole job is autopilot — receives projects, dispatches workers,
drives to completion. No distractions from general-purpose agent behavior.

### Option B: Skill on a General Agent

Add autopilot as one capability on an existing agent. The agent can chat, do ad-hoc
tasks, AND run autopilot projects. Requires an AGENTS.md hook for worker completions.

---

## Option A: Dedicated Agent Setup

### 1. Create the agent

```bash
openclaw agents add --id autopilot-agent --name "Autopilot"
```

Or use an existing agent dedicated to this purpose.

### 2. Replace AGENTS.md

Copy the dedicated AGENTS.md into the agent's workspace:

```bash
cp /path/to/openclaw-autopilot/references/AGENTS.md <agent-workspace>/AGENTS.md
```

This AGENTS.md is purpose-built for autopilot — it includes the setup gate, dispatch
protocol, and references back to the skill for full instructions.

### 3. Add skill to the agent's workspace

```bash
mkdir -p <agent-workspace>/skills
ln -s /path/to/openclaw-autopilot <agent-workspace>/skills/autopilot
```

### 4. Create runtime state directory

```bash
cd <agent-workspace>
mkdir -p autopilot-state/outcomes autopilot-state/archive
echo '{"projects":[]}' > autopilot-state/portfolio.json
```

### 5. Set up watchdog cron

Create a safety-net cron job (catches stuck/orphaned workers):

```
cron add job:{
  "name": "autopilot-watchdog",
  "schedule": { "kind": "every", "everyMs": 14400000 },
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "Autopilot watchdog sweep. Read autopilot-state/portfolio.json. Check for: (1) tasks stuck in 'running' status for >30 minutes with no active session, (2) projects with all tasks verified but project still 'active' — evaluate if goal is met, (3) any stale state. Fix what you find. If the portfolio is empty or nothing needs attention, reply with exactly NO_REPLY and do nothing else."
  },
  "delivery": { "mode": "announce" },
  "enabled": true
}
```

### 6. Configure main agent to delegate

Your main (conversational) agent can delegate projects to the autopilot agent.
Add the autopilot agent to your main agent's subagent allowlist in `openclaw.json`:

```json
{
  "agents": {
    "list": [
      {
        "id": "main",
        "subagents": { "allowAgents": ["autopilot-agent"] }
      },
      {
        "id": "autopilot-agent",
        "workspace": "<agent-workspace>",
        "agentDir": "<agent-dir>"
      }
    ]
  }
}
```

Or use `sessions_send` from your main agent to communicate with the autopilot agent.

### 7. Verify

Send a message to the autopilot agent — it should check setup, complete any missing
steps automatically, and report ready.

---

## Option B: Skill on General Agent

### 1. Add skill

```bash
mkdir -p ~/.openclaw/workspace/skills
ln -s /path/to/openclaw-autopilot ~/.openclaw/workspace/skills/autopilot
```

### 2. Create runtime state directory

```bash
cd ~/.openclaw/workspace
mkdir -p autopilot-state/outcomes autopilot-state/archive
echo '{"projects":[]}' > autopilot-state/portfolio.json
```

### 3. Add AGENTS.md hook

Append this block to your `AGENTS.md`:

```markdown
## 🧭 Autopilot (worker completion hook)

When a subagent completion announcement arrives with label starting with `autopilot:`,
read the autopilot skill and follow its instructions to evaluate the outcome,
update portfolio state, and spawn follow-up workers. Work silently — do not notify
the user unless the project is complete, blocked, or requires a significant pivot.
```

### 4. Set up watchdog cron

Same as Option A, step 5.

### 5. Verify

Ask "do I have any autopilot projects running?" — the agent should naturally load
the skill and report no active projects.

---

## How It Works

```
User: "Build a landing page for my SaaS, handle it autonomously"
  │
  ▼
Agent activates Autopilot (skill match or AGENTS.md hook)
  │
  ▼
Presents plan: inferred goal, success criteria, initial tasks
  │
  ▼
User confirms → Creates portfolio entry → Spawns worker subagent(s)
  │
  ▼
Worker subagent spawns coding agent → implements → self-verifies
  │
  ▼
Worker reports VERIFIED or BLOCKED → announces back to autopilot session
  │
  ▼
Autopilot evaluates goal progress
  │
  ├─ More work needed → Spawn next worker (chain continues silently)
  ├─ Blocked → Escalate to user with specifics
  └─ Goal met → Notify user with completion summary
```

The watchdog cron (every 4h) is only a safety net — not the primary driver.

---

## Uninstalling

**Dedicated agent:**
1. Remove the watchdog cron job
2. Optionally remove the agent: `openclaw agents remove --id autopilot-agent`
3. Remove workspace/state if no longer needed

**Skill on general agent:**
1. Remove the `## 🧭 Autopilot` section from AGENTS.md
2. Remove the watchdog cron job
3. Remove the skill: `rm -rf ~/.openclaw/workspace/skills/autopilot`
4. Optionally remove state: `rm -rf ~/.openclaw/workspace/autopilot-state/`
