#!/usr/bin/env bash
# Testa o helper POSIX da retrospectiva: descoberta, export, fallback SQLite,
# validação de SID e redação de credencial.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$ROOT/.agents/skills/retrospectiva/scripts/sessao.sh"
TMP="$(mktemp -d /tmp/opencode/retrospectiva-test.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
pass() { printf 'PASS: %s\n' "$*"; }
command -v jq >/dev/null || fail 'jq missing'

SID='ses_fixture_aaaaaaaaaaaaaaaaaaaaaaaa'
BAD_SID="ses_bad' OR 1=1 --"
RAW_TOKEN="xvl-$(printf 'B%.0s' {1..32})"
DB="$TMP/opencode.db"
EXPORT_JSON="$TMP/export.json"
mkdir -p "$TMP/bin"

# Mock do opencode: cobre list, active, item, debug paths e session export.
cat > "$TMP/bin/opencode" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cmd="$*"
case "$cmd" in
  "session list --format json") printf '%s\n' '[{"id":"ses_fixture_aaaaaaaaaaaaaaaaaaaaaaaa","title":"fixture"}]' ;;
  "api get /api/session/active") printf '%s\n' '{"data":{}}' ;;
  "api get /api/session/"*) printf '%s\n' '{"data":{"title":"fixture"}}' ;;
  "debug paths") [ -n "${MOCK_DB:-}" ] && printf 'db %s\n' "$MOCK_DB" ;;
  "session export "*) [ "${MOCK_EXPORT_FAIL:-0}" = 1 ] && exit 1; cat "${MOCK_EXPORT_JSON:?}";;
  *) exit 0 ;;
esac
EOF
chmod +x "$TMP/bin/opencode"

cat > "$EXPORT_JSON" <<EOF
{"info":{"title":"fixture"},
 "messages":[
   {"type":"user","text":"token de fixture $RAW_TOKEN"},
   {"type":"assistant","content":[{"type":"text","text":"resposta"}]},
   {"type":"assistant","content":[{"type":"tool","name":"edit","state":{"status":"error","error":{"message":"boom"}}}]},
   {"type":"compaction","summary":"resumo"}
 ]}
EOF

if command -v sqlite3 >/dev/null 2>&1; then
  sqlite3 "$DB" <<SQL
CREATE TABLE session_message (seq INTEGER, session_id TEXT, type TEXT, data TEXT);
INSERT INTO session_message VALUES (1, '$SID', 'user', '{"text":"token de fixture $RAW_TOKEN"}');
INSERT INTO session_message VALUES (2, '$SID', 'assistant', '{"content":[{"type":"text","text":"resposta"}]}');
SQL
fi

# 1) Caminho export (portátil, sem sqlite3).
output=$(cd /tmp && PATH="$TMP/bin:$PATH" MOCK_EXPORT_JSON="$EXPORT_JSON" RETRO_MAX=500 bash "$SCRIPT" "$SID")
printf '%s\n' "$output" | grep -q 'fixture' || fail 'title/session output missing'
printf '%s\n' "$output" | grep -q 'resposta' || fail 'assistant transcript missing'
printf '%s\n' "$output" | grep -q 'fonte: export' || fail 'export source not reported'
printf '%s\n' "$output" | grep -q 'COMPACTAÇÃO' || fail 'compaction not surfaced'
printf '%s\n' "$output" | grep -q 'boom' || fail 'tool error lead missing'
printf '%s\n' "$output" | grep -q 'xvl-\[REDACTED\]' || { printf '%s\n' "$output" >&2; fail 'credential not redacted'; }
if printf '%s\n' "$output" | grep -q "$RAW_TOKEN"; then fail 'raw credential leaked'; fi
pass 'export path, cwd-independent invocation, redaction, leads'

# 2) SID malformado é rejeitado.
if (cd /tmp && PATH="$TMP/bin:$PATH" MOCK_EXPORT_JSON="$EXPORT_JSON" bash "$SCRIPT" "$BAD_SID" >"$TMP/bad.log" 2>&1); then
  fail 'malformed SID should be rejected'
fi
grep -Eqi 'sid.*inválido' "$TMP/bad.log" || { cat "$TMP/bad.log" >&2; fail 'malformed SID error not explicit'; }
pass 'SID validation'

# 3) Export falha + banco ausente => erro claro.
if (cd /tmp && PATH="$TMP/bin:$PATH" MOCK_EXPORT_FAIL=1 OPENCODE_DB="$TMP/missing.db" bash "$SCRIPT" "$SID" >"$TMP/missing.log" 2>&1); then
  fail 'missing source should fail'
fi
grep -Eqi 'banco não encontrado|sem fonte' "$TMP/missing.log" || { cat "$TMP/missing.log" >&2; fail 'missing source message unclear'; }
pass 'missing source failure'

# 4) Fallback SQLite quando o export falha.
if command -v sqlite3 >/dev/null 2>&1; then
  fb=$(cd /tmp && PATH="$TMP/bin:$PATH" MOCK_EXPORT_FAIL=1 OPENCODE_DB="$DB" bash "$SCRIPT" "$SID")
  printf '%s\n' "$fb" | grep -q 'fonte: sqlite3:' || { printf '%s\n' "$fb" >&2; fail 'sqlite fallback not used'; }
  printf '%s\n' "$fb" | grep -q 'resposta' || fail 'sqlite fallback transcript missing'
  printf '%s\n' "$fb" | grep -q 'xvl-\[REDACTED\]' || fail 'sqlite fallback not redacted'
  pass 'sqlite fallback path'
fi

# 5) Descoberta e caminho independente documentados no script/skill.
grep -q 'debug paths' "$SCRIPT" || fail 'script does not discover paths via opencode debug paths'
grep -q 'session export' "$SCRIPT" || fail 'script does not use portable session export'
SKILL="$ROOT/.agents/skills/retrospectiva/SKILL.md"
grep -q 'SKILL_DIR' "$SKILL" || fail 'skill lacks cwd-independent script path guidance'
grep -qi 'windows' "$SKILL" || fail 'skill lacks Windows guidance'
[ -f "$ROOT/.agents/skills/retrospectiva/scripts/sessao.ps1" ] || fail 'PowerShell helper missing'
pass 'discovery + Windows helper present'

printf 'retrospectiva-test: pass\n'
