---
name: daily-review
description: Once per day, read the last 24h of state and propose 1-3 concrete improvements. Don't just report — recommend.
---

# daily-review

Once per day (suggested: morning), do a structured review of the last 24
hours and surface 1-3 concrete improvements to the operator.

## The mindset

You are not a status dashboard. You are an analyst with skin in the game.
The operator's time is limited; your output should respect that by being:
- **Bounded**: 1-3 items, not 12.
- **Concrete**: each item names a file/param/action, not "consider X".
- **Prioritized**: rank by expected impact × confidence.
- **Honest about what you don't know**.

## The procedure

**1. Pull the data.**

Read what's relevant for the last 24h:
- Logs: `tail -N /tmp/<service>.log` (or last 24h windowed)
- State files: trades, PnL, positions, error counts
- Memory `decisions/` dir — what changes were applied recently and how did
  they pan out?

**2. Count and characterize.**

Concrete numbers:
- "X trades, Y wins, Z PnL"
- "K errors, primarily of type [...]"
- "Service uptime A% (B restarts)"
- "Outstanding TODO items in memory: ..."

If a number is meaningfully different from yesterday, flag it.

**3. Form 1-3 concrete proposals.**

Each one should have:
- **What**: the specific change (file, line, value, command)
- **Why**: the observation that motivated it (with the number)
- **Risk**: what could go wrong, what you're uncertain about
- **Verify**: how you'll know if it worked (which fits `after-change-monitor`)

**4. Rank them.**

Order by `(expected impact) × (confidence) / (risk)`. The top item should be
the one you'd recommend if the operator only had time for one.

**5. Send to operator. Don't auto-apply unless explicitly authorized.**

Use the channel the operator reads (Telegram, etc.). Format:
```
== Daily review YYYY-MM-DD ==

Numbers: [...]

Proposals (ranked):
1. [What]
   Why: [observation]
   Risk: [...]
   Verify: [...]

2. ...

Awaiting your call.
```

**6. After the operator approves, apply via `parameter-tuning` /
`after-change-monitor`.**

## What this prevents

- Drift: small bugs / suboptimal params accumulate because nobody is
  systematically asking "is this still the right setting?"
- Surprise: operator finds out about a problem from a stranger (or P&L
  loss) instead of the agent.
- Stale memory: decisions log gets out of date because nothing forces
  a periodic re-read.

## Cadence options

- **Cron-triggered**: simplest. A cron entry sends a "daily-review now"
  trigger to the agent (via Telegram MCP scheduling, or a sentinel file
  the agent watches).
- **Event-triggered**: end of trading day, end of US/EU session, etc.
- **Operator-triggered**: `/daily-review` from chat. Less reliable but
  zero infra.

Pick one and stick to it for at least a week so the rhythm forms.

## Real example

> Daily review 2026-04-17:
>
> Numbers: 8 crypto bots, 2 in live mode (eth:5m, btc:5m). Last 24h:
> eth:5m 12 trades, +$4.20 PnL, 33% fill rate. btc:5m 0 trades (just
> went live 2h ago, too early).
>
> Proposals:
> 1. eth:5m fill rate 33% vs paper 100% — adverse selection ~30pp as
>    documented (memory: adverse_selection_ioc). Consider raising
>    DIRECTIONAL_TICK_PAD from 0.05 to 0.07 to widen edge buffer.
>    Risk: fewer fills. Verify: 24h trade count + PnL/trade.
> 2. paper_trades_btc_4h.json grew 800KB overnight, never read. Likely
>    safe to gzip + archive. Risk: nil. Verify: backup size next cycle.
> 3. (none)
