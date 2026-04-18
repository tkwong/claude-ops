---
name: ship-it
description: The full code-change cycle: scope → write → smoke test → commit → review checkpoint → deploy → after-change-monitor → log decision.
---

# ship-it

You're not just editing files. You're shipping a change to a system that's
currently doing real work. Treat every change like a deploy.

## The mindset

Code lands in production the moment you `git push` (or restart the bot, or
write the config). Everything before that point is the chance to be careful;
everything after is recovery. Bias the work toward the careful side.

## The procedure

**1. Scope and sanity-check.**

- Is this change actually needed *now*, or is it premature?
- Is it the smallest change that solves the user's stated problem?
- Did you push back if the request felt larger than the goal needed?

If the diff is going to be > ~200 lines, pause and ask the operator if they
want to break it up.

**2. Write the change. Surgical edits only.**

- Touch only what the goal requires.
- Match existing style.
- Don't refactor adjacent code unless the operator asked.
- Don't invent abstractions for one-time use.
- Don't add error handling for impossible cases.

**3. Smoke test before committing.**

- Syntax check: `bash -n script.sh`, `cargo check`, `python -c "import x"`,
  type checker, etc.
- Run the smallest invocation that proves the change is wired up
  (`agops doctor`, `agops list`, etc.).
- If a unit test exists for the changed area, run it.

**4. Self-review the diff.**

`git diff` and read every line. Look for:
- Debug prints / commented-out code
- Hardcoded values that should be config
- Secrets / paths that leak personal info
- Obvious typos

**5. (For non-trivial changes) deep-review.**

For anything ≥ 50 lines or anything user-facing, dispatch an independent
reviewer (subagent or another tool instance) and read its findings. You
will miss things you wrote 10 minutes ago. They won't.

**6. Commit with a useful message.**

Subject line: imperative, < 70 chars, describes the *why*.
Body: what changed, why, what to verify post-deploy. Reference issue numbers.
Don't skip hooks (`--no-verify`) without explicit approval.

**7. Review checkpoint with the operator (for risky changes).**

Public-facing repos, irreversible changes (force-push, prod deploy, sending
funds, dropping data), or anything that affects shared state — pause and
report what you're about to do. Wait for "go".

**8. Deploy.**

`git push`, restart service, apply config — whatever "deploy" means for this
repo. Note the timestamp.

**9. `after-change-monitor`.**

Schedule the verification window. Don't move to the next task until you've
checked back at least once.

**10. Log to `memory/decisions/`.**

Date-stamped file with: hypothesis, what changed, baseline metric,
verification result, decision (kept/reverted/iterated). This is what makes
future-you not repeat tonight's experiment in 2 months.

## What this prevents

- Pushing 5 commits of "wip", "fix", "actually fix", "typo" to a public repo
  in your first hour — looks unprofessional, can't be undone.
- Shipping a change that breaks the running service because you forgot to
  smoke-test the syntax.
- Refactoring adjacent code "while you're in there" and ballooning the diff.
- Forgetting to verify after deploy and not noticing for days that the
  change had no effect / negative effect.

## Real example

> Tonight: shipped `claude-ops` initial commit + review-fix commit.
> 1. Scoped Medium tier with operator (rejected Ambitious as premature).
> 2. Wrote 19 files, ran `agops doctor` to smoke-test before commit.
> 3. Committed locally, did NOT push.
> 4. Dispatched independent reviewer agent — found 32 issues across 4
>    severity levels.
> 5. Fixed 11 blockers/bugs autonomously, surfaced 1 judgment call
>    (whether to publicly link polyhft) to operator.
> 6. Committed fixes (76f21ce), waited for operator OK before pushing.
> 7. Pushed both commits to github.com/tkwong/claude-ops.
> 8. Logged: this very file.
