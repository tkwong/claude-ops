# Skills

`claude-ops` ships a small set of operating *skills* — markdown checklists
that encode the dev-ops mindset for a long-lived project agent. Each one
is grounded in actual production patterns (not theory).

## Why skills exist

A long-running agent needs more than tools — it needs *discipline*. Without
discipline, agents:

- Make 5 changes in an hour, none verified, then can't debug what broke.
- Reinvent wheels because they didn't check 30 minutes for prior art.
- Tune parameters without baselines, declare success based on vibes.
- Forget to log decisions, so 3 months later they re-run the same failed experiment.
- Drift into pure ops (status reports) and stop *improving* the project.

Skills are the operator's playbook, written down so the agent runs it
consistently and the human doesn't have to remember to remind them.

## The five starter skills

| Skill | When to invoke |
|---|---|
| [`after-change-monitor`](../skills/after-change-monitor.md) | After ANY non-trivial change (config, code, restart) |
| [`parameter-tuning`](../skills/parameter-tuning.md) | When adjusting a config knob — treat it as a controlled experiment |
| [`daily-review`](../skills/daily-review.md) | Once per day — surface 1-3 ranked improvements |
| [`ship-it`](../skills/ship-it.md) | For code changes — full scope→test→commit→review→deploy→verify cycle |
| [`validate-before-build`](../skills/validate-before-build.md) | Before building anything non-trivial — 30-min "does this exist?" check |

## How to wire them into your project

**Option A: Reference them from CLAUDE.md (simplest).**

Your project's `CLAUDE.md` lists the skills. Claude Code reads CLAUDE.md
on every session start and follows the conventions you describe. The skills
themselves can live in your repo's `./skills/` dir or referenced from this
template repo. See `CLAUDE.md.template` for the section to copy.

**Option B: Install as Claude Code Skills.**

Claude Code supports user-invocable skills at `~/.claude/skills/<name>.md`
or per-project `./skills/<name>.md`. Symlink or copy from this repo:

```bash
mkdir -p ~/.claude/skills
ln -s $(pwd)/skills/*.md ~/.claude/skills/
```

Now you (or the agent) can invoke them as `/after-change-monitor`,
`/daily-review`, etc.

## Decisions log convention

Skills frequently say "log this to `memory/decisions/`". The convention:

```
~/.claude/projects/<sanitized-cwd>/memory/decisions/
├── 2026-04-17-btc5m-live.md
├── 2026-04-17-tick-pad-bump.md
└── 2026-04-18-revert-tick-pad.md
```

One file per decision. Filename: `YYYY-MM-DD-<short-slug>.md`.

Recommended body:

```markdown
---
date: 2026-04-17
type: parameter-tune | code-change | config | infra
status: kept | reverted | iterating
---

## Hypothesis
What you thought would happen and why.

## Change
What you actually changed (file, line, value, commit hash).

## Baseline
The metric value before. Be specific.

## Verification window
When you'll check / when you checked.

## Result
The metric value after, and what you concluded.
```

This is heavier-weight than feedback memory — only use it for things you
want to be able to look up later. Daily-review reads this dir.

## Cadence: daily review via cron

For the daily-review skill to be reliable, it needs a trigger. Two options:

**Cron + Telegram MCP scheduling:**

If your Telegram MCP supports message scheduling, queue a daily message at
the agent's chat:

```bash
# At 09:00 every morning, send the agent a "do your daily review" message.
0 9 * * * /your/script-that-sends-telegram-message "Run /daily-review for the last 24h."
```

**Sentinel file watched by a separate script:**

Have a cron `touch /tmp/daily-review-trigger`, and a small wrapper that
detects the file and sends an instruction to the agent's tmux session.

Either way, the trigger should be external — don't expect the agent to
remember on its own.

## Adding your own skills

Skills are just markdown. Drop a new `<name>.md` in `skills/` with:

```markdown
---
name: skill-name
description: One-line hook for relevance scoring
---

# skill-name

The mindset (1 paragraph).

## The procedure
Numbered checklist.

## What this prevents
The failure mode.

## Real example
A grounded example, not theory.
```

The `Real example` section matters — abstract advice doesn't stick.
Update via PR if it generalizes; keep project-specific ones in your own
project's `./skills/`.
