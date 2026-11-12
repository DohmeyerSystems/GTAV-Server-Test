#!/usr/bin/env bash
# =====================================================================
# backup-db.sh – Datenbank-Dump nach ./backups (gitignored)
#   ./scripts/backup-db.sh            # behält die letzten 14 Dumps
#   KEEP=30 ./scripts/backup-db.sh
# Für tägliche Backups per cron (als root):
#   15 4 * * * /opt/gtav-server/scripts/backup-db.sh >/dev/null 2>&1
# =====================================================================
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DB_NAME="${DB_NAME:-qbox}"
KEEP="${KEEP:-14}"
OUT="$ROOT/backups"
mkdir -p "$OUT"

DUMP=(mariadb-dump); command -v mariadb-dump >/dev/null || DUMP=(mysqldump)
file="$OUT/${DB_NAME}_$(date +%Y-%m-%d_%H-%M).sql.gz"
"${DUMP[@]}" --single-transaction --routines --triggers "$DB_NAME" | gzip > "$file"
echo "Backup: $file"

ls -1t "$OUT"/"${DB_NAME}"_*.sql.gz | tail -n +"$((KEEP + 1))" | xargs -r rm --
