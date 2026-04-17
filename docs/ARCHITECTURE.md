# Architecture

## Why tmux + cron and not Kubernetes / supervisord / systemd-only

| Concern | Choice | Why |
|---|---|---|
| Process supervision | tmux | Survives SSH disconnect; lets you `attach` and watch the agent live; zero daemon to install |
| Restart on crash | cron + `agops` CLI | A cron entry every 2 min restarts any DOWN session. ~120s worst-case downtime is fine for ops work; trading bots restart in seconds |
| Cron alternative | systemd timer (in `systemd/`) | Use if you don't want cron; same semantics |
| Memory | Plain markdown files | Claude Code already reads `~/.claude/projects/<X>/memory/MEMORY.md` on session start. No DB needed. |
| Inter-agent comms | None (yet) | Each agent is its own tmux session. If you need cross-agent state, share files in S3 or use a small message bus |
| Network reachability | Telegram MCP | Phone-friendly, no inbound port needed, free for personal use |

## What we deliberately do not do

- **No Kubernetes** — one box, one operator, one set of agents. Adding k8s
  would 10x the moving parts for no benefit at this scale.
- **No custom daemon** — `tmux` already supervises long-running processes.
  Writing yet another `pm2`/`supervisord` clone solves nothing.
- **No web dashboard** — `agops list` + `agops logs -f` cover 95% of what
  you'd build a dashboard for, with 1% of the code.
- **No agent orchestration framework** — if you need DAGs of agents, use
  LangGraph. If you need one persistent agent, you don't.

## The model

```
                 ┌──────────────────┐
   You (phone) ──┤ Telegram MCP     ├──┐
                 └──────────────────┘  │
                                       ▼
   ┌───────────────────────────────────────┐
   │  tmux session "myagent"               │
   │   ┌─────────────────────────────────┐ │
   │   │  claude  (Claude Code CLI)      │ │
   │   │   ↳ reads CLAUDE.md             │ │
   │   │   ↳ reads/writes memory/*.md    │ │
   │   │   ↳ runs tools (bash, edit...)  │ │
   │   └─────────────────────────────────┘ │
   └───────────────────────────────────────┘
                       ▲
                       │  restart if DOWN
   ┌──────────────────┴──────────────────┐
   │  cron */2: lib/watchdog.sh          │
   └─────────────────────────────────────┘
                       ▲
                       │
   ┌──────────────────┴──────────────────┐
   │  cron 0 *: lib/backup-to-s3.sh      │
   │   ↳ tar paper_trades_*.json etc.    │
   │   ↳ upload to s3://bucket/...       │
   └─────────────────────────────────────┘
```

## What an "agent" is here

Just a tmux session running `claude` (or any long-running process) in a
specified working directory. The CLAUDE.md in that dir tells Claude what
its role is. The memory dir gives it long-term recall.

Configs live in `~/.claude-ops/agents/<name>.conf` — one shell file per
agent. The `agops` CLI and `watchdog.sh` both iterate over that dir.
