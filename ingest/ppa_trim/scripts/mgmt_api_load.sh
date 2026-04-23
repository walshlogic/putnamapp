#!/usr/bin/env bash
# Load SQL files to Supabase via Management API.
# Usage: ./mgmt_api_load.sh <sql_file_or_inline_query>
#   If arg ends in .sql, reads file. Otherwise treats arg as inline SQL.
set -euo pipefail

TOKEN=$(python3 -c "import json; print(json.load(open('/Users/walshwill/.claude.json'))['mcpServers']['supabase']['env']['SUPABASE_ACCESS_TOKEN'])")
URL='https://api.supabase.com/v1/projects/uuhftgvyinrgzlhvudxf/database/query'

SQL_INPUT="${1:?need sql file path or inline query}"

TMP_PAYLOAD=$(mktemp)
trap 'rm -f "$TMP_PAYLOAD"' EXIT
if [[ "$SQL_INPUT" == *.sql && -f "$SQL_INPUT" ]]; then
  python3 -c "import json,sys; open(sys.argv[2],'w').write(json.dumps({'query': open(sys.argv[1]).read()}))" "$SQL_INPUT" "$TMP_PAYLOAD"
else
  python3 -c "import json,sys; open(sys.argv[2],'w').write(json.dumps({'query': sys.argv[1]}))" "$SQL_INPUT" "$TMP_PAYLOAD"
fi

RESPONSE=$(curl -s -w "\n__HTTP__%{http_code}" -X POST "$URL" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  --data "@$TMP_PAYLOAD")

HTTP_CODE=$(echo "$RESPONSE" | grep '__HTTP__' | sed 's/__HTTP__//')
BODY=$(echo "$RESPONSE" | sed '/__HTTP__/d')

if [[ "$HTTP_CODE" != "200" && "$HTTP_CODE" != "201" ]]; then
  echo "ERROR http=$HTTP_CODE body=$BODY" >&2
  exit 1
fi
# Print first 200 chars of response for logs
echo "$BODY" | head -c 200
echo
