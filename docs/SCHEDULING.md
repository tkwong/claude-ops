# Scheduling

Three mechanisms, three jobs. Pick the right one or you will ship silent failures.

## The three mechanisms

| Tool | What fires | Where it lands | Use for |
|---|---|---|---|
| **`CronCreate`** (Claude Code built-in) | Prompt text | Into the **live Claude session** as user input | Triggering the agent to *do work* (review, analyze, decide) |
| **Telegram MCP `/schedule`** | Reminder message | `bot.api.sendMessage` → Telegram chat | Human-facing reminders |
| **System `cron` + shell script** | Arbitrary shell | stdout / Telegram API / files | Deterministic health checks, stat rollups, backups |

## The trap

Both Telegram `/schedule` *and* a shell `curl ... /sendMessage` call post to the chat. It looks like the agent will see it and respond. **It will not.**

Telegram's bot API does not route a bot's own outgoing messages back as incoming updates. Messages the bot sends appear in the user's chat but never re-enter the bot's webhook/poll loop. So scheduling the bot to "prompt itself" this way produces text the human sees, with zero agent action behind it.

We learned this the hard way — 7 hours of hourly "audit please" messages that never triggered a single audit. Check `messages.db` if you want to reproduce: `SELECT is_outgoing, count(*) FROM messages WHERE ts > ? GROUP BY is_outgoing` — 0 incoming.

Only `CronCreate` injects into the session as if the user typed it.

## Decision flow

```
Need the agent to do work?        → CronCreate
Need the human to get a ping?     → Telegram /schedule
Need deterministic shell output?  → system cron
```

## Example: the polyhft setup

```cron
# Deterministic shell — stats, no LLM
0 * * * * ~/polyhft/scripts/dynamic_review.sh      # hourly one-liner to Telegram
3 9 * * * ~/polyhft/scripts/daily_review.sh         # 24h rollup to Telegram
*/2 * * * * ~/claude-ops/lib/watchdog.sh            # restart dead agents
```

```js
// CronCreate — fires into Claude session
CronCreate({ cron: "0 * * * *", prompt: "/hourly-review" })          // LLM audit + proposal
CronCreate({ cron: "23 10 * * 1", prompt: "/memory-review" })         // weekly memory pruning
```

`CronCreate` jobs are session-scoped — they die if the Claude session dies. Keep the session alive with a watchdog (see `lib/watchdog.sh`) or re-register on startup.

## Writing the prompt

A `CronCreate` prompt is user input. Write it exactly as you would type it:

- ✅ `"/daily-review — focus on btc:5m fill rate vs paper expectation"`
- ❌ `"Please run the daily review and post results to Telegram"`  (vague, no slash command, no success criterion)

If the prompt references data that may not exist yet (e.g. a log file from a not-yet-completed run), include a fallback: *"if no fills yet, report 0-fill cause and skip verdict"*.
