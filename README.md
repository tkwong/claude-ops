# claude-ops

> **Opinionated glue for keeping a Claude Code agent alive on a server, doing ops work.**

Claude Code is great at one-off tasks. But what if you want it to *live* on a
box — monitoring a service, triaging alerts on Telegram, restarting itself when
it crashes, remembering context across days of conversations?

`claude-ops` is the thinnest possible scaffolding to do that. No new framework,
no daemon written from scratch — just `tmux + cron + a Telegram MCP bridge +
file-based memory`, packaged so you can stand up a new always-on agent in under
five minutes.

## What's in the box

```
claude-ops/
├── bin/agops              # CLI: list / start / stop / restart / logs / attach
├── lib/
│   ├── watchdog.sh        # Cron job — restart any DOWN agent
│   ├── backup-to-s3.sh    # Cron job — hourly tar+gzip → S3
│   └── memory-init.sh     # Bootstrap ~/.claude/projects/<X>/memory/
├── systemd/               # Optional systemd units (alternative to cron)
├── examples/trading-bot/  # Sanitized real-world example (HFT bot operator)
├── docs/                  # Architecture, memory pattern, telegram-mcp setup
├── CLAUDE.md.template     # Fill-in-the-blanks for your own CLAUDE.md
└── install.sh             # One-shot installer (idempotent)
```

## When to use this

- You have a service running on a server and want a live operator that reads
  logs, answers Telegram questions, and reboots things at 3am.
- You want Claude to *remember* across sessions (yesterday's incident, last
  week's tuning) without rebuilding context every time.
- You don't want to learn LangGraph or pay for a SaaS to do something a
  shell script can do.

## When **not** to use this

- You need multi-tenant SaaS hosting → use Devin or LangGraph Platform.
- You want a UI dashboard → roll your own, or wait for v2.
- You're building autonomous coding agents → use Claude Code or Aider directly,
  no supervisor needed.

## Quickstart (5 minutes)

```bash
# 1. Clone
git clone https://github.com/tkwong/claude-ops.git
cd claude-ops

# 2. Install (symlinks bin/agops to ~/.local/bin)
./install.sh

# 3. Configure your first agent
mkdir -p ~/.claude-ops/agents
cp examples/trading-bot/agent.conf ~/.claude-ops/agents/myagent.conf
$EDITOR ~/.claude-ops/agents/myagent.conf
#   Set PROJECT_DIR= to wherever your CLAUDE.md lives.

# 4. Drop a CLAUDE.md in your project
cp CLAUDE.md.template /path/to/your/project/CLAUDE.md
$EDITOR /path/to/your/project/CLAUDE.md

# 5. Start it
agops start myagent
agops logs myagent -f         # watch it boot
agops attach myagent          # interact via tmux (Ctrl-b d to detach)

# 6. Auto-restart on crash (cron, runs every 2min)
(crontab -l 2>/dev/null; echo "*/2 * * * * $PWD/lib/watchdog.sh") | crontab -
```

## Telegram bridge (recommended)

`claude-ops` doesn't ship a Telegram client — instead it works with any MCP
server that exposes a chat surface. The setup the author uses:

- [`claude-telegram-supercharged`](https://github.com/...) — Telegram MCP server
  with multi-chat routing, voice transcription, and message scheduling.

See [`docs/TELEGRAM-MCP.md`](docs/TELEGRAM-MCP.md) for setup.

## S3 backup

```bash
cp examples/trading-bot/backup.conf ~/myagent.backup.conf
$EDITOR ~/myagent.backup.conf      # set BUCKET, SOURCE_DIR, PATTERNS
(crontab -l; echo "0 * * * * BACKUP_CONF=$HOME/myagent.backup.conf $PWD/lib/backup-to-s3.sh") | crontab -
```

Set a 30-day lifecycle rule on the bucket to auto-expire old backups.
On EC2, an attached IAM instance role removes the need for credentials.

## Why this exists

There are agent *frameworks* (LangGraph, OpenHands, Goose) and there are agent
*runtimes* (Claude Code, Devin). What's missing is the boring middle layer:
how do you keep one alive on a Linux box for a week, give it persistent memory,
and let your phone talk to it.

This repo answers that with the smallest amount of code that works.

## Status

Used in production by [polyhft](https://github.com/tkwong/polyhft) — an
8-bot HFT operation on Polymarket. Battle-tested for ~24/7 uptime over weeks.

## License

MIT — see [LICENSE](LICENSE).
