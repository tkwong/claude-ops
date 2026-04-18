---
name: parameter-tuning
description: Tune one knob at a time with a hypothesis, baseline, and revert plan. Log the result so future-you doesn't repeat the experiment.
---

# parameter-tuning

You're going to change a config value (a threshold, a multiplier, a flag) to
improve some outcome. **Treat it as a controlled experiment, not a guess.**

## The mindset

> "Let me try 0.70" is a guess. "I think 0.70 is right because at 0.72 our
> hit rate dropped 8pp on bucket [0.70-0.75], suggesting the AS overhead
> there outweighs edge. I'll switch to 0.70 and check fill economics in 24h
> against the saved baseline." is an experiment.

## The procedure

**1. State the hypothesis explicitly.**

Format: "Changing X from A to B should cause M to move from M0 to ~M1, because
[mechanism]." Write this down before you touch anything. If you can't articulate
the mechanism, you don't yet know what you're doing — read more first.

**2. Tune ONE knob at a time.**

If you change two things and PnL moves, you can't attribute the cause. The
discipline costs latency but saves wasted experiments. Exception: when knobs
are coupled by definition (e.g. min/max of a range), change them together
and treat the pair as one knob.

**3. Pick a meaningful baseline window.**

If the metric is noisy (PnL, win rate), the baseline window must be long
enough to show signal above noise. Rule of thumb: at least as many samples
in baseline as you expect post-change before deciding.

**4. Apply the change. Use `after-change-monitor`.**

Schedule a follow-up. Don't promise yourself you'll remember.

**5. Decide — keep, revert, or iterate.**

- **Keep**: result matches hypothesis with adequate sample size. Log to
  `memory/decisions/`.
- **Revert**: result is opposite or significantly worse. Revert *now*, then
  log the failed experiment so you don't try the same thing in 3 months.
- **Iterate**: result was directionally right but smaller than hoped. Refine
  hypothesis (smaller step, different range) and repeat. Don't stack multiple
  iterations as separate "successful" changes — that compounds noise.

**6. Bigger lesson?**

If a parameter consistently drifts toward a value, the value should probably
become the default in code/config, not just the env override. Surface this
to the operator: "I've tuned MAX_BUY_PRICE to 0.70 three times across
different bots. Should this be the default in CLAUDE.md / config?"

## What this prevents

- Tuning fatigue — changing knobs constantly without learning anything.
- Forgetting failed experiments and re-running them next quarter.
- "I think it's better now" reports with no evidence.

## Real example

> Tonight: DIRECTIONAL_MAX_BUY_PRICE 0.72 → 0.70 on btc:5m.
> Hypothesis: bucket-EV analysis (memory: project_bucket_ev_pattern) shows
> the directional bot is +EV at $0.60-0.70 and -EV above. The 0.72 cap
> still allows -EV trades in the [0.70, 0.72] band where AS+fees > edge.
> Expected effect: 5-10% drop in trade count, slight positive shift in
> per-trade PnL.
> Verification: 24h fill economics, target ≥0 cents/trade lift.
