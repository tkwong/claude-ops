#!/bin/bash
# claude-ops watchdog — restart any DOWN agent listed in $CLAUDE_OPS_HOME/agents/.
# Run via cron every 1-2 minutes:
#   */2 * * * * /path/to/claude-ops/lib/watchdog.sh

set -euo pipefail

# Cron has minimal PATH. Cover common locations where `claude`, `tmux`,
# `aws`, `bun`, `node`, `npm` may live. Override with WATCHDOG_PATH.
export PATH="${WATCHDOG_PATH:-$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.bun/bin:$HOME/.npm-global/bin:$HOME/.nvm/versions/node/$(ls -1 $HOME/.nvm/versions/node 2>/dev/null | tail -1)/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin}"

export CLAUDE_OPS_HOME="${CLAUDE_OPS_HOME:-$HOME/.claude-ops}"
AGENTS_DIR="$CLAUDE_OPS_HOME/agents"
LOG="${WATCHDOG_LOG:-/tmp/claude-ops-watchdog.log}"
AGOPS_BIN="$(dirname "$(readlink -f "$0")")/../bin/agops"

ts() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }

[ -d "$AGENTS_DIR" ] || { echo "[$(ts)] no agents dir at $AGENTS_DIR" >> "$LOG"; exit 0; }

# Crash-loop backoff: track restarts in a state file. If an agent has
# restarted >= MAX_RESTARTS times within BACKOFF_WINDOW seconds, skip it
# until BACKOFF_WINDOW elapses. Override via env.
STATE_DIR="${WATCHDOG_STATE_DIR:-$CLAUDE_OPS_HOME/state}"
mkdir -p "$STATE_DIR"
MAX_RESTARTS="${WATCHDOG_MAX_RESTARTS:-3}"
BACKOFF_WINDOW="${WATCHDOG_BACKOFF_WINDOW:-1800}"   # 30 min

now_epoch() { date -u +%s; }

for conf in "$AGENTS_DIR"/*.conf; do
    [ -f "$conf" ] || continue
    name=$(basename "$conf" .conf)
    tmux has-session -t "$name" 2>/dev/null && continue

    # Read recent restart timestamps (one per line)
    state_file="$STATE_DIR/$name.restarts"
    now=$(now_epoch)
    cutoff=$((now - BACKOFF_WINDOW))
    recent=()
    if [ -f "$state_file" ]; then
        while IFS= read -r t; do
            [ "$t" -ge "$cutoff" ] 2>/dev/null && recent+=("$t")
        done < "$state_file"
    fi

    if [ "${#recent[@]}" -ge "$MAX_RESTARTS" ]; then
        echo "[$(ts)] $name in BACKOFF (${#recent[@]} restarts in last ${BACKOFF_WINDOW}s) — skipping" >> "$LOG"
        continue
    fi

    echo "[$(ts)] $name DOWN — restarting (attempt ${#recent[@]}/${MAX_RESTARTS})" >> "$LOG"
    if "$AGOPS_BIN" start "$name" >> "$LOG" 2>&1; then
        recent+=("$now")
        printf '%s\n' "${recent[@]}" > "$state_file"
    else
        echo "[$(ts)] $name restart FAILED" >> "$LOG"
    fi
done
