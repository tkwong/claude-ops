#!/bin/bash
# claude-ops watchdog — restart any DOWN agent listed in $CLAUDE_OPS_HOME/agents/.
# Run via cron every 1-2 minutes:
#   */2 * * * * /path/to/claude-ops/lib/watchdog.sh

set -euo pipefail

export PATH="$HOME/.cargo/bin:$HOME/.bun/bin:/usr/local/bin:/usr/bin:/bin"

CLAUDE_OPS_HOME="${CLAUDE_OPS_HOME:-$HOME/.claude-ops}"
AGENTS_DIR="$CLAUDE_OPS_HOME/agents"
LOG="${WATCHDOG_LOG:-/tmp/claude-ops-watchdog.log}"
AGOPS_BIN="$(dirname "$(readlink -f "$0")")/../bin/agops"

ts() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }

[ -d "$AGENTS_DIR" ] || { echo "[$(ts)] no agents dir at $AGENTS_DIR" >> "$LOG"; exit 0; }

for conf in "$AGENTS_DIR"/*.conf; do
    [ -f "$conf" ] || continue
    name=$(basename "$conf" .conf)
    if ! tmux has-session -t "$name" 2>/dev/null; then
        echo "[$(ts)] $name DOWN — restarting" >> "$LOG"
        "$AGOPS_BIN" start "$name" >> "$LOG" 2>&1 || \
            echo "[$(ts)] $name restart FAILED" >> "$LOG"
    fi
done
