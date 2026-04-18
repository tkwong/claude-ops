#!/bin/bash
# claude-ops installer.
# Usage: ./install.sh [--prefix /usr/local]
#
# Installs:
#   - bin/agops          → $PREFIX/bin/agops (symlink)
#   - lib/*              → kept in repo, referenced by absolute path
#   - $CLAUDE_OPS_HOME   → ~/.claude-ops/agents/  (empty, user populates)
#   - cron               → suggests crontab entry, doesn't install
# Note: examples/ stays in the repo (not copied) — they're reference, not config.
#
# Idempotent — safe to re-run.

set -euo pipefail

PREFIX="${PREFIX:-$HOME/.local}"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_OPS_HOME="${CLAUDE_OPS_HOME:-$HOME/.claude-ops}"

echo "==> repo: $REPO_DIR"
echo "==> prefix: $PREFIX"
echo "==> claude-ops home: $CLAUDE_OPS_HOME"

# 1. dirs
mkdir -p "$PREFIX/bin" "$CLAUDE_OPS_HOME/agents"
chmod +x "$REPO_DIR/bin/"* "$REPO_DIR/lib/"*.sh

# 2. symlink agops
ln -sf "$REPO_DIR/bin/agops" "$PREFIX/bin/agops"
echo "==> linked $PREFIX/bin/agops"

# 3. dep check
echo ""
echo "==> dep check:"
for bin in tmux aws; do
    if command -v "$bin" >/dev/null 2>&1; then
        echo "    OK   $bin"
    else
        echo "    MISS $bin (some features need it — see docs/)"
    fi
done

# 4. PATH advice
case ":$PATH:" in
    *":$PREFIX/bin:"*) ;;
    *) echo ""
       echo "==> $PREFIX/bin not in PATH. Add to your shell:"
       echo "    export PATH=\"\$PATH:$PREFIX/bin\"" ;;
esac

# 5. Optional: link skills into ~/.claude/skills/ so /skill-name works in Claude Code
# Default to YES for non-interactive installs; honor SKIP_SKILLS=1 to opt out.
echo ""
do_skills="y"
if [ -t 0 ] && [ "${SKIP_SKILLS:-}" != "1" ]; then
    read -rp "Link claude-ops skills into ~/.claude/skills/ ? [Y/n] " yn || yn=""
    case "${yn:-Y}" in [Nn]*) do_skills="n" ;; esac
elif [ "${SKIP_SKILLS:-}" = "1" ]; then
    do_skills="n"
fi
if [ "$do_skills" = "y" ]; then
    mkdir -p "$HOME/.claude/skills"
    for skill in "$REPO_DIR/skills/"*.md; do
        [ -f "$skill" ] || continue
        ln -sf "$skill" "$HOME/.claude/skills/$(basename "$skill")"
    done
    echo "==> linked $(ls -1 "$HOME/.claude/skills/" 2>/dev/null | wc -l) skills"
else
    echo "==> skipped skills linking (set SKIP_SKILLS=0 or run interactively to enable)"
fi

cat <<EOF

==> Next steps:
    1. Create an agent config:
         cp $REPO_DIR/examples/trading-bot/agent.conf $CLAUDE_OPS_HOME/agents/myagent.conf
         \$EDITOR $CLAUDE_OPS_HOME/agents/myagent.conf
    2. Start it:
         agops start myagent
    3. (Recommended) Install the watchdog cron:
         (crontab -l 2>/dev/null; echo "*/2 * * * * $REPO_DIR/lib/watchdog.sh") | crontab -
    4. (Optional) Set up S3 backup — see docs/BACKUP.md
    5. (Optional) Set up daily-review cadence — see docs/SKILLS.md
       e.g. cron a 09:00 "/daily-review for last 24h" message via your Telegram MCP
EOF
