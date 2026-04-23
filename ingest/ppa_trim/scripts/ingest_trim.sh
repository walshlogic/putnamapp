#!/usr/bin/env bash
# =====================================================================
# Putnam+Life  |  TRIM ingest driver
# Usage:  ./ingest_trim.sh path/to/TRIM_Data_Package2025.zip
# Env:    SUPABASE_DB_URL (preferred)  OR  PGHOST/PGUSER/PGPASSWORD/PGDATABASE/PGPORT
# =====================================================================
set -euo pipefail

ZIP="${1:-}"
[[ -z "$ZIP" ]] && { echo "usage: $0 <TRIM_Data_Package.zip>"; exit 1; }
[[ -z "${SUPABASE_DB_URL:-}" ]] && { echo "SUPABASE_DB_URL is not set (use the Postgres connection string from Supabase → Project Settings → Database → Connection string → URI, session pooler or direct)"; exit 1; }

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$ROOT/work"
OUT="$WORK/out"
SQL="$ROOT/scripts/upsert_trim.sql"
PARSE="$ROOT/parse_trim.py"

rm -rf "$WORK" && mkdir -p "$OUT"
echo "→ Extracting $ZIP"
unzip -q "$ZIP" -d "$WORK"

TXT="$(find "$WORK" -name 'RE_Trim_Notice_Export.txt' | head -1)"
[[ -z "$TXT" ]] && { echo "RE_Trim_Notice_Export.txt not found in zip"; exit 1; }

echo "→ Parsing $(basename "$TXT")"
python3 "$PARSE" "$TXT" "$OUT"

echo "→ Loading into Supabase"
cd "$WORK"
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f "$SQL"

echo "✓ Done"
