#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$ROOT/.agents/skills/retrospectiva/scripts/sessao.sh"
TMP="$(mktemp -d /tmp/opencode/retrospectiva-test.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
pass() { printf 'PASS: %s\n' "$*"; }
command -v sqlite3 >/dev/null || fail 'sqlite3 missing'
command -v jq >/dev/null || fail 'jq missing'

SID='ses_fixture_aaaaaaaaaaaaaaaaaaaaaaaa'
BAD_SID="ses_bad' OR 1=1 --"
DB="$TMP/opencode.db"
mkdir -p "$TMP/bin"
RAW_TOKEN="xvl-$(printf 'B%.0s' {1..32})"

cat > "$TMP/bin/opencode" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
case "$*" in
  "session list --format json") printf '%s\n' '[{"id":"ses_fixture_aaaaaaaaaaaaaaaaaaaaaaaa","title":"fixture"}]' ;;
  "api get /api/session/active") printf '%s\n' '{"data":{}}' ;;
  "api get /api/session/"*) printf '%s\n' '{"data":{"title":"fixture"}}' ;;
  *) exit 0 ;;
esac
EOF
chmod +x "$TMP/bin/opencode"

sqlite3 "$DB" <<SQL
CREATE TABLE session_message (seq INTEGER, session_id TEXT, type TEXT, data TEXT);
INSERT INTO session_message VALUES (1, '$SID', 'user', '{"text":"token de fixture $RAW_TOKEN"}');
INSERT INTO session_message VALUES (2, '$SID', 'assistant', '{"content":[{"type":"text","text":"resposta"}]}');
SQL

output=$(cd /tmp && PATH="$TMP/bin:$PATH" OPENCODE_DB="$DB" RETRO_MAX=500 bash "$SCRIPT" "$SID")
printf '%s\n' "$output" | grep -q 'fixture' || fail 'title/session output missing'
printf '%s\n' "$output" | grep -q 'resposta' || fail 'assistant transcript missing'
printf '%s\n' "$output" | grep -q 'xvl-\[REDACTED\]' || {
  printf '%s\n' "$output" >&2
  fail 'credential not redacted'
}
if printf '%s\n' "$output" | grep -q "$RAW_TOKEN"; then
  fail 'raw credential leaked'
fi
pass 'SID fixture, cwd-independent invocation, redaction'

if (cd /tmp && PATH="$TMP/bin:$PATH" OPENCODE_DB="$DB" bash "$SCRIPT" "$BAD_SID" >"$TMP/bad.log" 2>&1); then
  fail 'malformed SID should be rejected'
fi
grep -Eqi 'sid.*inválido|session.*inválido' "$TMP/bad.log" || {
  cat "$TMP/bad.log" >&2
  fail 'malformed SID error not explicit'
}
pass 'SID validation'

if OPENCODE_DB="$TMP/missing.db" PATH="$TMP/bin:$PATH" bash "$SCRIPT" "$SID" >"$TMP/missing.log" 2>&1; then
  fail 'missing DB should fail'
fi
grep -q 'banco não encontrado' "$TMP/missing.log" || fail 'missing DB message unclear'
pass 'missing DB failure'

SKILL="$ROOT/.agents/skills/retrospectiva/SKILL.md"
grep -q 'SKILL_DIR' "$SKILL" || fail 'skill lacks cwd-independent script path guidance'
pass 'skill path guidance'

printf 'retrospectiva-test: pass\n'
