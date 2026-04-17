#!/bin/bash
# Initialize Claude Code project-scoped memory directory.
# Claude Code resolves memory at: ~/.claude/projects/<sanitized-cwd>/memory/MEMORY.md
# (see CLAUDE.md "auto memory" section for details).
#
# Usage: memory-init.sh /path/to/project

set -euo pipefail

PROJECT_DIR="${1:?usage: memory-init.sh <project-dir>}"
PROJECT_DIR="$(readlink -f "$PROJECT_DIR")"

# Claude Code's path mangling: replace / with - and prepend "-"
SANITIZED="-$(echo "${PROJECT_DIR#/}" | tr '/' '-')"
MEMDIR="$HOME/.claude/projects/$SANITIZED/memory"

mkdir -p "$MEMDIR"

if [ ! -f "$MEMDIR/MEMORY.md" ]; then
    cat > "$MEMDIR/MEMORY.md" <<'EOF'
<!-- claude-ops memory index. Loaded into every Claude Code session.
     One line per memory file, format:
     - [Title](filename.md) — one-line hook
     Keep this file under ~150 lines; lines past 200 may be truncated. -->
EOF
    echo "Initialized MEMORY.md at $MEMDIR/MEMORY.md"
else
    echo "MEMORY.md already exists at $MEMDIR/MEMORY.md"
fi

echo ""
echo "Memory dir: $MEMDIR"
echo "Add memories as <topic>.md files here, then index them in MEMORY.md."
