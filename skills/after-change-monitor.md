---
name: after-change-monitor
description: After making any non-trivial change, define a verification window and check back. Don't fire-and-forget.
---

# after-change-monitor

You just changed something — config, code, restart, parameter. **Now you need
to verify it actually had the effect you intended.** Don't move on to the next
task until you've checked back at least once.

## The mindset

A change is a *hypothesis*: "I think doing X will cause Y." You verify by
measuring Y before and after. Without that loop, you're just thrashing the
system and hoping.

## The procedure

**1. Before changing — record baseline.**

Write down (or save to memory) the current value of the metric you expect to
move. Be specific. "PnL last 24h", "fill rate last 100 orders", "log error
count per hour". Vague baselines = vague verification.

**2. Make the change.**

Apply it. Note the timestamp. Note exactly what you changed (the diff, the
new env value, the commit hash).

**3. Schedule a check-in.**

Decide the verification window:
- Restart / process change → 1-5 minutes
- Config tweak with immediate effect → 15-60 minutes
- Strategy / parameter change → 4-24 hours
- Anything affecting noisy metrics (PnL, win rate) → at least 24h, often longer

If you can `schedule` a wake-up via the Telegram MCP (or equivalent), do it
now — don't trust yourself to remember. If you can't, at minimum tell the
operator: "I'll check back in N hours."

**4. At check-in — measure post-change.**

Re-read the same metric. Compare to baseline. Note sample size — a 1-trade
sample after a strategy change tells you nothing.

**5. Decide:**

- **Effect as expected** → log to `memory/decisions/` as a confirmed change. Move on.
- **No effect / mixed** → either wait longer (sample size) or revert.
- **Adverse effect** → revert immediately, report to operator, log root cause.

**6. Tell the operator.**

Even if the change worked, surface it. "btc:5m live ran 24h since enabling,
+$23 PnL, 28 trades, fill rate 31% (vs paper 100% — adverse selection as
expected). Recommendation: keep running, monitor for another 24h before
sizing up." This is what makes you a useful operator and not a black box.

## What this prevents

- Making 5 changes in an hour, none verified, then trying to debug
  why the system feels worse — you have no idea which one broke it.
- Reporting "done" on a config change that didn't take effect because
  the service wasn't reloaded.
- Quietly leaving a parameter that is actively losing money because
  nobody scheduled a follow-up.

## Real example

> Tonight: enabled `TRADING_ENABLED=true` on btc:5m bot at 22:08 UTC.
> Baseline: 0 live trades, paper backtest +$2150/30d for this config.
> Verification window: 24-48h, looking for >50 trades and live PnL not
> diverging more than -30% from paper expectation. Will check at next
> daily-review.
