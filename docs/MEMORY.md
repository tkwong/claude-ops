# Memory pattern

Claude Code can persist arbitrary memory across sessions per-project.
`claude-ops` doesn't reinvent this — it just uses the built-in convention.

## Where memory lives

```
~/.claude/projects/<sanitized-cwd>/memory/
├── MEMORY.md               # Index — loaded into every session's context
├── feedback_<topic>.md     # User corrections / preferences
├── project_<topic>.md      # Project facts that aren't in code/git
├── reference_<topic>.md    # Pointers to external systems
└── user_<topic>.md         # Who the user is
```

`<sanitized-cwd>` = the absolute project path with `/` replaced by `-` and
prefixed with `-`. E.g. `/home/me/myproject` → `-home-me-myproject`.

`memory-init.sh` does the path-mangling for you:

```bash
./lib/memory-init.sh /home/me/myproject
# → creates ~/.claude/projects/-home-me-myproject/memory/MEMORY.md
```

## What goes in each type

| Type | Save when… | Example |
|---|---|---|
| **user** | You learn the user's role, expertise, or preferences | "Senior Rust dev, new to React in this repo" |
| **feedback** | User corrects or confirms an approach | "Don't mock the DB in tests — got burned in Q3" |
| **project** | You learn a fact about the work that isn't in code | "Auth rewrite is driven by legal, not tech debt" |
| **reference** | You learn where info lives in external systems | "Bug tracker is in Linear project INGEST" |

## What NOT to save

- Code patterns, architecture, file paths → derivable from the repo
- Recent commits, who-changed-what → `git log` is authoritative
- Bug fixes → the diff and commit message capture them
- Anything in CLAUDE.md → already loaded

## File format

> Claude Code itself doesn't parse the frontmatter below — it just reads
> the markdown. The frontmatter is a *convention* this repo recommends so
> the agent can reason about which memories are relevant to a task. Drop it
> if you prefer plain markdown; everything still works.

```markdown
---
name: Short title
description: One-line hook for relevance scoring
type: user|feedback|project|reference
---

The actual fact / rule / preference.

**Why:** The reason behind it (user's quote, past incident, deadline).

**How to apply:** When and where to use this guidance.
```

## Index format (`MEMORY.md`)

One line per memory, no frontmatter:

```markdown
- [Title](file.md) — one-line hook
- [Title](file.md) — one-line hook
```

`MEMORY.md` is loaded into context every session, so keep it under ~150 lines.

## Why this works

Claude Code reads `MEMORY.md` automatically. The index is short enough to
fit in context. When a memory is relevant to the current task, Claude opens
the linked file.

This is dumber than a vector DB and that's the point — debug-able, version-able,
zero infra.
