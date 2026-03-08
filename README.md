# Autopilot

🧭 Autonomous goal-driven project manager for [OpenClaw](https://github.com/nichochar/openclaw) agents.

Autopilot decomposes user goals into tasks, dispatches subagent workers, verifies outcomes against acceptance criteria, and chains follow-up work automatically — driving projects to completion with minimal human interruption.

## Architecture

**Event-driven, not polling.** Uses OpenClaw's `sessions_spawn` announce mechanism:

```
User describes project → Plan gate (confirm goal + criteria) → Spawn workers
  → Worker completes → Verify outcome → Spawn next → ...
    → All criteria met → Notify user
```

A lightweight watchdog cron (every 4h) catches stuck/orphaned workers as a safety net.

### Three Layers

| Layer | What | How |
|-------|------|-----|
| **Portfolio State** | `autopilot-state/portfolio.json` | Projects, tasks, acceptance criteria, status |
| **Event Loop** | AGENTS.md hook + skill description | Reacts to `autopilot:*` worker completions |
| **Worker Dispatch** | `sessions_spawn` | Isolated subagent sessions per task |

### Key Features

- **Plan Gate** — Presents inferred goal, success criteria, and initial tasks for user confirmation before starting
- **Verification-First** — Worker outcomes evaluated against acceptance criteria with evidence, not narratives
- **Worker Context Inheritance** — Each worker receives a condensed brief of prior outcomes and learnings
- **Silent Operation** — No user notifications except on completion, blocks, or significant pivots
- **Portfolio Archival** — Completed projects archived to keep active state lean
- **Structured Escalation** — Blocks include what was tried, what's needed, impact, and suggested options

## Install

```bash
# Add to your OpenClaw workspace
mkdir -p ~/.openclaw/workspace/skills
ln -s /path/to/openclaw-autopilot ~/.openclaw/workspace/skills/autopilot

# Create runtime state
cd ~/.openclaw/workspace
mkdir -p autopilot-state/outcomes autopilot-state/archive
echo '{"projects":[]}' > autopilot-state/portfolio.json
```

Then add the AGENTS.md hook and watchdog cron — see [`references/install.md`](references/install.md).

Or just mention "autopilot" to the agent — it will self-install on first use.

## Usage

Autopilot activates naturally through conversation. No rigid commands needed:

- *"Build a REST API for user management, handle it autonomously"*
- *"What's the status on my projects?"*
- *"Pause work on the API project"*
- *"Drop the landing page project"*

## Design Principles

- **Goal leadership** — Autopilot owns forward progress, not just task coordination
- **Verification-first** — Evidence against acceptance criteria, not "it should work"
- **Silent operation** — Work quietly, notify only on completion or blocks
- **Intention preservation** — Every task traces back to the user's original goal
- **Minimal escalation** — Only escalate for product/policy/access decisions

## Repo Structure

```
SKILL.md              ← Skill definition (frontmatter + full instructions)
README.md             ← This file
LICENSE               ← MIT
references/
  install.md          ← Installation guide
```

Runtime state (created during install, not in repo):
```
<workspace>/
  autopilot-state/
    portfolio.json    ← Active project state
    outcomes/         ← Worker result files
    archive/          ← Completed/dropped project records
```

## Version History

- **v3** — Event-driven architecture, plan gate, verification-first completion, worker context inheritance, portfolio archival, natural skill invocation (no rigid commands), structured escalation protocol.
- **v1/v2** — ACP/Codex-based workers, markdown state files. Deprecated.

## License

MIT
