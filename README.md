# claude-ops

> **Turn any project into a chatable, self-improving service running on your
> own server. Claude Code lives on the box, talks to you over Telegram (or
> any chat), follows a real dev-ops discipline, and remembers context across
> sessions.**

You already have an always-on server somewhere. You already use Claude Code
for short bursts on your laptop. `claude-ops` puts Claude Code on the server
and gives it the discipline and infra to *stay* there — so every project
you run becomes a thing you can talk to from your phone, that watches
itself, and that proposes its own improvements.

Three things in one package:

1. **Always-on supervision** — `tmux + cron + watchdog + S3 backup + memory
   bootstrap`, so the agent survives crashes, reboots, and SSH disconnects.
2. **Chatable surface** — wire up any chat MCP (Telegram is the default
   recommendation, but Slack/Discord/custom all work) so you give instructions
   from wherever you are, not from a terminal.
3. **A starter set of skills** — markdown checklists that encode the dev-ops
   mindset: verify changes, tune parameters as experiments, daily-review,
   ship-it discipline, validate before building.

Together: stand up a new "live agent for a project" in under five minutes.
The agent then operates, improves, and reports — without you babysitting it.

## What's in the box

```
claude-ops/
├── bin/agops              # CLI: list / start / stop / restart / logs / attach
├── lib/
│   ├── watchdog.sh        # Cron job — restart any DOWN agent (with backoff)
│   ├── backup-to-s3.sh    # Cron job — hourly tar+gzip → S3
│   └── memory-init.sh     # Bootstrap ~/.claude/projects/<X>/memory/
├── skills/                # 5 starter skills (after-change-monitor,
│                          #   parameter-tuning, daily-review, ship-it,
│                          #   validate-before-build)
├── systemd/               # Optional systemd units (alternative to cron)
├── examples/trading-bot/  # Sanitized real-world example
├── docs/                  # ARCHITECTURE, MEMORY, SKILLS, TELEGRAM-MCP, BACKUP
├── CLAUDE.md.template     # Fill-in-the-blanks for your own CLAUDE.md
└── install.sh             # Idempotent installer
```

## When to use this

- You run **multiple projects on a server** (trading bots, scrapers,
  automation, ML pipelines) and want one chatable agent per project,
  reachable from your phone wherever you are.
- You're tired of `ssh` + `tmux attach` every time you want to check on
  something — you'd rather text the project a question and get an answer.
- You want the agent to *remember* across sessions (yesterday's incident,
  last week's parameter tune, which experiments already failed) instead of
  re-explaining context every conversation.
- You want each agent to follow a real *discipline* — controlled parameter
  tunes, post-change verification, decisions logged for future-you, daily
  improvement proposals — not improvise.
- You don't want to learn LangGraph or pay for a SaaS to do what a shell
  script + a few markdown files can do.

## When **not** to use this

- You need multi-tenant SaaS hosting for other people's agents → use Devin
  or LangGraph Platform.
- You want a polished web dashboard → roll your own, or wait for v2.
- You're building autonomous coding agents that finish in hours, not run
  for weeks → use Claude Code or Aider directly, no supervisor needed.
- You don't have a server (or comfortable SSH/cron access to one) → this
  isn't for you.

## Prerequisites

- Linux (or macOS — caveat: a couple of scripts use `readlink -f`, install
  `coreutils` via Homebrew if needed)
- `tmux` (`apt install tmux` / `brew install tmux`)
- [Claude Code](https://www.anthropic.com/claude-code) installed and `claude`
  on `$PATH` — this repo doesn't ship Claude itself
- (Optional) `aws` CLI for S3 backup
- (Optional) A Telegram MCP bridge if you want phone access — see
  [`docs/TELEGRAM-MCP.md`](docs/TELEGRAM-MCP.md)

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

# 7. (Optional but recommended) Wire up the skills
mkdir -p ~/.claude/skills
ln -s "$PWD/skills/"*.md ~/.claude/skills/
#   Now /after-change-monitor, /daily-review, etc. are invocable in chat.
```

## Skills (the part that makes this not just a supervisor)

Five starter skills shipping in `skills/`:

| Skill | When |
|---|---|
| **after-change-monitor** | After ANY non-trivial change — schedule a check |
| **parameter-tuning** | Adjusting a knob — treat it as a controlled experiment |
| **daily-review** | Once per day — surface 1-3 ranked improvements |
| **ship-it** | Code change — full scope→test→commit→review→deploy→verify cycle |
| **validate-before-build** | About to build something — 30-min "does this exist?" check |

Each skill is a markdown checklist with a real-world example. See
[`docs/SKILLS.md`](docs/SKILLS.md) for the full philosophy and how to add
your own.

## Telegram bridge (recommended)

`claude-ops` doesn't ship a Telegram client. It works with any MCP server that
exposes chat tools to Claude Code. See [`docs/TELEGRAM-MCP.md`](docs/TELEGRAM-MCP.md)
for setup options.

## S3 backup

```bash
cp examples/trading-bot/backup.conf ~/myagent.backup.conf
$EDITOR ~/myagent.backup.conf      # set BUCKET, SOURCE_DIR, PATTERNS
(crontab -l; echo "0 * * * * BACKUP_CONF=$HOME/myagent.backup.conf $PWD/lib/backup-to-s3.sh") | crontab -
```

Set a 30-day lifecycle rule on the bucket to auto-expire old backups.
On EC2, an attached IAM instance role removes the need for credentials.

## Why this exists

The author runs several projects on one always-on server (trading bots,
scrapers, paper-trade trackers). For each project, you'd ideally want
*one* persistent agent that:

- watches the project's logs and state,
- restarts it when it crashes,
- answers questions about it from your phone,
- proposes improvements based on what it sees,
- and remembers the context, the decisions, and the failed experiments.

There are agent *frameworks* (LangGraph, OpenHands, Goose) and there are
agent *runtimes* (Claude Code, Devin). What's missing is the boring middle
layer: how do you keep one alive on a Linux box for weeks, give it persistent
memory, give it a chat surface, and teach it the discipline to *improve* the
project rather than just *operate* it.

This repo answers that with the smallest amount of code that works — and
five markdown files that encode the discipline.

## Status

Early — runs 24/7 on the author's box supervising a multi-bot trading
operation. Public release; expect rough edges. Issues and PRs welcome.

## License

MIT — see [LICENSE](LICENSE).
