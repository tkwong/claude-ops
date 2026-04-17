#!/bin/bash
# Generic S3 backup — tar+gzip configured paths and upload, hourly via cron.
#
# Cron:
#   0 * * * * BACKUP_CONF=/path/to/myproject.backup.conf /path/to/claude-ops/lib/backup-to-s3.sh
#
# Config file format (sourced as bash):
#   BUCKET=s3://my-bucket            # required
#   SOURCE_DIR=/home/me/project      # required (cwd before tar)
#   PATTERNS=("*.json" "state.json") # required, bash array of globs relative to SOURCE_DIR
#   PREFIX=myproject                 # optional, default: basename(SOURCE_DIR)
#   LOG=/tmp/backup.log              # optional
#
# Relies on the EC2 IAM instance role for credentials, or AWS_PROFILE.
# Set a 30-day lifecycle rule on the bucket to auto-expire old backups.

set -euo pipefail
shopt -s nullglob   # non-matching globs expand to empty

BACKUP_CONF="${BACKUP_CONF:?set BACKUP_CONF=/path/to/conf}"
[ -f "$BACKUP_CONF" ] || { echo "missing conf: $BACKUP_CONF" >&2; exit 1; }
# shellcheck source=/dev/null
source "$BACKUP_CONF"

: "${BUCKET:?config missing BUCKET}"
: "${SOURCE_DIR:?config missing SOURCE_DIR}"
declare -p PATTERNS >/dev/null 2>&1 || { echo "config missing PATTERNS array" >&2; exit 1; }
[ "${#PATTERNS[@]}" -gt 0 ] || { echo "config PATTERNS array is empty" >&2; exit 1; }

PREFIX="${PREFIX:-$(basename "$SOURCE_DIR")}"
LOG="${LOG:-/tmp/backup.log}"

ts() { date -u '+%Y-%m-%dT%H:%M:%SZ'; }
cd "$SOURCE_DIR"

TARBALL="/tmp/${PREFIX}-backup-$(date -u +%Y%m%d-%H%M).tar.gz"
S3_KEY="${PREFIX}/$(date -u +%Y-%m-%d-%H)/backup.tar.gz"

# Expand patterns to actual files (skip missing)
FILES=()
for pat in "${PATTERNS[@]}"; do
    for f in $pat; do
        [ -f "$f" ] && FILES+=("$f")
    done
done

if [ ${#FILES[@]} -eq 0 ]; then
    echo "[$(ts)] [$PREFIX] no files matched" >> "$LOG"
    exit 0
fi

if ! tar czf "$TARBALL" "${FILES[@]}" 2>>"$LOG"; then
    echo "[$(ts)] [$PREFIX] tar FAILED — see $LOG" >> "$LOG"
    rm -f "$TARBALL"
    exit 1
fi
SIZE=$(du -h "$TARBALL" | cut -f1)

if aws s3 cp "$TARBALL" "$BUCKET/$S3_KEY" --only-show-errors; then
    echo "[$(ts)] [$PREFIX] uploaded $S3_KEY ($SIZE, ${#FILES[@]} files)" >> "$LOG"
else
    echo "[$(ts)] [$PREFIX] upload FAILED for $S3_KEY" >> "$LOG"
    rm -f "$TARBALL"
    exit 1
fi

rm -f "$TARBALL"
