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
mkdir -p autopilot-state/outcomes autopilot-state/archive
echo '{"projects":[]}' > autopilot-state/portfolio.json
```

State lives in `autopilot-state/` (workspace root), separate from the skill code.

### 3. Add AGENTS.md trigger hook

Append this block to your `AGENTS.md`:

```markdown
## 🧭 Autopilot (worker completion hook)

When a subagent completion announcement arrives with label starting with `autopilot:`,
read the autopilot skill and follow its instructions to evaluate the outcome,
update portfolio state, and spawn follow-up workers. Work silently — do not notify
the user unless the project is complete, blocked, or requires a significant pivot.
```

This hook is necessary because worker completions arrive as announce messages that
trigger a new agent turn. The hook ensures the agent recognizes `autopilot:*` labels
and loads the skill to continue the chain reaction.

User-facing interactions (starting projects, checking status, pausing) are handled
naturally through the skill's description matching — no hook needed for those.

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

Ask something like "do I have any autopilot projects running?" — the agent should
naturally load the skill and report no active projects.

---

## How It Works

```
User: "I need to build a landing page for my SaaS, can you handle it?"
  │
  ▼
Agent matches skill description → reads SKILL.md → activates Autopilot
  │
  ▼
Presents plan: inferred goal, success criteria, initial tasks
  │
  ▼
User confirms → Creates portfolio entry → Spawns first worker(s)
  │
  ▼
Worker runs in isolated session, completes task
  │
  ▼
Result announced back to main session (sessions_spawn announce mechanism)
  │
  ▼
AGENTS.md hook fires → Agent reads SKILL.md → Verifies outcome against criteria
  │
  ├─ Goal not met → Spawn next worker (chain continues silently)
  └─ Goal met → Notify user with completion summary
```

The watchdog cron (every 4h) is only a safety net — not the primary driver.

---

## Uninstalling

1. Remove the `## 🧭 Autopilot` section from AGENTS.md
2. Remove the `autopilot-watchdog` cron job
3. Remove the skill: `rm -rf ~/.openclaw/workspace/skills/autopilot` (or remove symlink)
4. Optionally remove state: `rm -rf ~/.openclaw/workspace/autopilot-state/`
