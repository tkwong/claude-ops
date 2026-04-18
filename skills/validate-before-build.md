---
name: validate-before-build
description: Before committing time to build a non-trivial thing, spend 30 minutes checking it doesn't already exist. Reinventing wheels is the most expensive failure mode.
---

# validate-before-build

You're about to spend 1+ hours building something. Before you do, spend
30 minutes confirming you're not reinventing a wheel.

## The mindset

The cost of building the wrong thing is the time to build it PLUS the time
to maintain it PLUS the opportunity cost of not building the right thing.
The cost of validating first is 30 minutes.

This is doubly true for OSS work — you're publishing, so the embarrassment
of "this already exists, called X, with 5k stars" is permanent.

## The procedure

**1. Articulate what you're about to build, in 1-2 sentences.**

If you can't, you're not ready to build it. Write the README first
(`README-driven development`).

**2. Search for it.**

- GitHub search for the obvious names and adjacent terms
- HN/Reddit/Twitter for "anyone using X for Y?"
- Vendor docs (e.g. is there an official feature you missed?)
- Adjacent ecosystems — if you're building for tool A, look at how tool B
  solves the same problem

**3. Read 2-5 of the closest matches. Honestly.**

For each one ask:
- Does it solve the problem you have, or just sound similar?
- What's the gap (if any) between what it does and what you need?
- Could you contribute the gap upstream instead of starting fresh?

**4. Decide one of three things:**

- **It exists, use it.** Save your time. Document why you picked it.
- **It exists but doesn't fit.** Be specific about *why* — "needs SaaS",
  "wrong language", "abandoned 2 years", "missing feature X". This becomes
  the README's "Why this exists" section.
- **Doesn't exist.** Now you can build, with the validation in your back
  pocket for skeptics.

**5. (For OSS) capture the validation in the README.**

Future visitors ask "why didn't you use X?" before reading. Pre-empt them.
The "When NOT to use this" section is as valuable as "When to use this".

## Anti-pattern: motivated reasoning

It is *very* tempting to skim the existing options, find a small gap, and
declare yourself justified to build. Push against this — assume the existing
thing is fine until you can articulate the gap precisely. If the gap is "I'd
prefer different naming", you don't have a real gap.

## What this prevents

- Spending a week building, then discovering Devin / LangGraph / Goose /
  whatever already does it.
- OSS readers immediately leaving a "have you seen X?" issue and you have
  no answer.
- Maintaining yet another half-finished tool in the long tail.

## Real example

> Tonight: operator suggested templating the polyhft Claude-monitor setup.
> Before scaffolding, dispatched two parallel research agents:
> 1. claude-code-guide → checked Claude Agent SDK / Claude Code official
>    support for long-running daemon mode.
> 2. general-purpose → surveyed Devin, Goose, OpenHands, LangGraph,
>    AutoGen/MAF, langgraph-supervisor, n8n/Zapier.
>
> Findings: no built-in Claude daemon mode; no open-source supervisord-for-
> LLM-agents; closest matches were SaaS (Devin) or framework-coupled
> (LangGraph Platform). Gap confirmed real.
>
> Recommendation from research: position as "opinionated glue" not "new
> framework category" — this language went directly into the README.
>
> Total validation time: ~10 min of dispatching + 5 min reading findings.
> Saved: a week of building something already done, OR an embarrassing
> first issue from an HN reader.
