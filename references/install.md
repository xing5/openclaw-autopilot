# Autopilot — Installation Guide

## Quick Install

### 1. Add skill to OpenClaw

**Option A — Symlink (recommended for development):**
```bash
mkdir -p ~/.openclaw/workspace/skills
ln -s /path/to/openclaw-autopilot ~/.openclaw/workspace/skills/autopilot
```

**Option B — Clone directly:**
```bash
mkdir -p ~/.openclaw/workspace/skills
cd ~/.openclaw/workspace/skills
git clone <repo-url> autopilot
cd autopilot && git checkout v3
```

**Option C — Use `skills.load.extraDirs` in `openclaw.json`:**
```json
{
  "skills": {
    "load": {
      "extraDirs": ["/path/to/openclaw-autopilot"]
    }
  }
}
```

### 2. Create runtime state directory

```bash
cd ~/.openclaw/workspace
mkdir -p autopilot-state/outcomes
echo '{"projects":[]}' > autopilot-state/portfolio.json
```

State lives in `autopilot-state/` (workspace root), separate from the skill code.

### 3. Add AGENTS.md trigger hook

Append this block to your `AGENTS.md`:

```markdown
## 🤖 Autopilot (always active)

When a subagent completion announcement arrives with label starting with `autopilot:`,
read the autopilot skill and follow its instructions to evaluate the outcome,
update portfolio state, and spawn follow-up workers.

When the user says `autopilot add project:`, `autopilot status`, `autopilot pause`,
`autopilot resume`, or `autopilot drop`, read the autopilot skill and handle the command.
```

This is necessary because Autopilot needs to react on **every turn** where a worker
announces back — not just when the user explicitly triggers it. Skills are normally
lazy-loaded by description matching, but the AGENTS.md hook ensures the agent always
recognizes autopilot events.

### 4. Set up watchdog cron

Create a safety-net cron job (catches stuck/orphaned workers):

```
cron add job:{
  "name": "autopilot-watchdog",
  "schedule": { "kind": "every", "everyMs": 14400000 },
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "Autopilot watchdog sweep. Read autopilot-state/portfolio.json. Check for: (1) tasks stuck in 'running' status for >30 minutes with no active session, (2) projects with all tasks done but project still 'active' — evaluate if goal is met, (3) any stale state. Fix what you find. If the portfolio is empty or nothing needs attention, reply with exactly NO_REPLY and do nothing else."
  },
  "delivery": { "mode": "announce" },
  "enabled": true
}
```

### 5. Verify

Say `autopilot status` — you should see "No active projects."

---

## How It Works

```
User: "autopilot add project: Build a landing page"
  │
  ▼
Agent reads SKILL.md (via AGENTS.md hook or skill description match)
  │
  ▼
Decomposes goal → Creates portfolio entry → Spawns worker via sessions_spawn
  │
  ▼
Worker runs in isolated session, completes task
  │
  ▼
Result announced back to main session (sessions_spawn announce mechanism)
  │
  ▼
AGENTS.md hook fires → Agent reads SKILL.md → Evaluates outcome
  │
  ├─ Goal not met → Spawn next worker (chain continues)
  └─ Goal met → Mark complete, notify user
```

The watchdog cron (every 4h) is only a safety net — not the primary driver.

---

## Uninstalling

1. Remove the `## 🤖 Autopilot` section from AGENTS.md
2. Remove the `autopilot-watchdog` cron job
3. Remove the skill: `rm -rf ~/.openclaw/workspace/skills/autopilot` (or remove symlink)
4. Optionally remove state: `rm -rf ~/.openclaw/workspace/autopilot-state/`
