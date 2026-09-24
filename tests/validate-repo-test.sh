#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d /tmp/opencode/validate-test.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
pass() { printf 'PASS: %s\n' "$*"; }
fixture() {
  local name="$1"
  local dir="$TMP/$name"
  mkdir -p "$dir"
  cp -a "$ROOT"/. "$dir"/
  rm -rf "$dir/.git" "$dir/.superpowers"
  printf '%s\n' "$dir"
}
expect_failure() {
  local label="$1" dir="$2"
  if bash "$dir/scripts/validate-repo.sh" >"$dir/result.log" 2>&1; then
    cat "$dir/result.log" >&2
    fail "$label should fail"
  fi
  pass "$label rejected"
}

base="$(fixture base)"
bash "$base/scripts/validate-repo.sh" >"$base/result.log" 2>&1 || {
  cat "$base/result.log" >&2
  fail 'baseline fixture should pass'
}
pass 'baseline fixture'

bad_js="$(fixture bad-js)"
printf '\nexport default {\n' >> "$bad_js/.config/opencode/plugins/pontas-soltas.js"
expect_failure 'invalid JavaScript' "$bad_js"

bad_json="$(fixture bad-json)"
printf '{invalid\n' > "$bad_json/.config/opencode/opencode.json"
expect_failure 'invalid JSON' "$bad_json"

token_case="$(fixture token-case)"
token="sk-$(printf 'A%.0s' {1..32})"
printf '\ncredential fixture %s\n' "$token" >> "$token_case/README.md"
expect_failure 'credential shape' "$token_case"

bad_link="$(fixture bad-link)"
ln -s /definitely/not/a/real/target "$bad_link/.agents/skills/broken-link"
expect_failure 'broken symlink' "$bad_link"

printf 'validate-repo-test: pass\n'
