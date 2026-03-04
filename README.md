# Autopilot

🧭 Continuous goal-driven project manager for [OpenClaw](https://github.com/nichochar/openclaw) agents.

Autopilot decomposes user goals into tasks, dispatches subagent workers, evaluates outcomes against success criteria, and chains follow-up work automatically — driving projects to completion with minimal human escalation.

## Architecture

**Event-driven, not polling.** Uses OpenClaw's `sessions_spawn` announce mechanism as the primary loop:

```
User adds project
  → Decompose goal → Spawn Worker
    → Worker completes → Announces back to main session
      → Evaluate outcome → Spawn next worker → ...
        → Goal met → Notify user
```

A lightweight watchdog cron (every 4h) catches stuck/orphaned workers as a safety net.

### Three Layers

| Layer | What | How |
|-------|------|-----|
| **Portfolio State** | `autopilot-state/portfolio.json` | Projects, tasks, success criteria, status |
| **Event Loop** | AGENTS.md trigger hook | Reacts to `autopilot:*` worker completions |
| **Worker Dispatch** | `sessions_spawn` | Isolated subagent sessions per task |

## Install

```bash
# Add to your OpenClaw workspace
mkdir -p ~/.openclaw/workspace/skills
ln -s /path/to/openclaw-autopilot ~/.openclaw/workspace/skills/autopilot

# Create runtime state
cd ~/.openclaw/workspace
mkdir -p autopilot-state/outcomes
echo '{"projects":[]}' > autopilot-state/portfolio.json
```

Then add the AGENTS.md hook and watchdog cron — see [`references/install.md`](references/install.md) for full steps.

Or just say `autopilot status` and the agent will self-install on first use.

## Usage

```
autopilot add project: Build a landing page for my SaaS
autopilot status
autopilot pause <project>
autopilot resume <project>
autopilot drop <project>
```

## Design Principles

- **Goal leadership** — Autopilot owns forward progress, not just task coordination
- **Intention preservation** — Every task traces back to the user's original goal
- **Outcome evaluation** — Judge actual output against success criteria, not just task completion
- **Minimal escalation** — Only escalate for product/policy/access decisions
- **Event-driven** — React to worker completions, don't poll

## Repo Structure

```
SKILL.md              ← Skill definition (frontmatter + instructions)
README.md             ← This file
LICENSE               ← MIT
references/
  install.md          ← Full installation guide
```

Runtime state (created during install, not in repo):
```
<workspace>/
  autopilot-state/
    portfolio.json    ← Project state
    outcomes/         ← Worker result files
```

## Version History

- **v3** — Event-driven architecture using `sessions_spawn` announce chain reaction. JSON portfolio state. Simplified from v1/v2.
- **v1/v2** — ACP/Codex-based workers, markdown state files, verification-heavy. Deprecated.

## License

MIT
