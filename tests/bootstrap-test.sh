#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/bootstrap-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
pass() { printf 'PASS: %s\n' "$*"; }

make_fixture() {
  local name="$1"
  local repo="$TMP/$name/repo"
  local home="$TMP/$name/home"
  mkdir -p "$repo/.config/opencode" "$repo/.agents/skills" "$repo/docs" \
    "$home/.agents/skills/present-skill" "$home/.agents/skills/omitted-skill" \
    "$home/.config/opencode"
  cp "$ROOT/bootstrap.sh" "$repo/bootstrap.sh"
  chmod +x "$repo/bootstrap.sh"
  printf 'name: present-skill\n' > "$home/.agents/skills/present-skill/SKILL.md"
  printf 'name: omitted-skill\n' > "$home/.agents/skills/omitted-skill/SKILL.md"
  printf '{"base":true}\n' > "$repo/.config/opencode/opencode.json"
  printf '{"secret":"fixture-only"}\n' > "$home/.config/opencode/opencode.json"
  printf 'home agents\n' > "$home/.config/opencode/AGENTS.md"
  printf 'repo docs\n' > "$repo/docs/not-config.md"
  printf 'repo sources\n' > "$repo/sources.md"
  printf '.agents/skills/.gitkeep\n' > "$repo/.agents/skills/.gitkeep"
  cat > "$repo/CURATION.md" <<'EOF'
| skill | tipo | incluir |
|---|---|---|
| present-skill | própria | sim |
| missing-skill | própria | sim |
| omitted-skill | própria |  |
EOF
  printf '%s\n' "$repo" "$home"
}

mapfile -t fixture_paths < <(make_fixture sync)
REPO="${fixture_paths[0]}"
HOME_DIR="${fixture_paths[1]}"
if HOME="$HOME_DIR" bash "$REPO/bootstrap.sh" sync >"$TMP/sync.log" 2>&1; then
  fail 'sync should fail when a marked skill source is missing'
fi
grep -q 'skill source ausente: missing-skill' "$TMP/sync.log" || {
  cat "$TMP/sync.log" >&2
  fail 'sync should name missing source'
}
[ "$(cat "$REPO/.config/opencode/opencode.json")" = '{"base":true}' ] || fail 'sync changed repo opencode.json'
[ "$(cat "$HOME_DIR/.config/opencode/opencode.json")" = '{"secret":"fixture-only"}' ] || fail 'sync changed home opencode.json'
[ -f "$REPO/.agents/skills/present-skill/SKILL.md" ] || fail 'sync did not import present marked skill'
[ ! -e "$REPO/.agents/skills/omitted-skill" ] || fail 'sync imported unmarked skill'
pass 'sync allowlist and config boundary'

mapfile -t fixture_paths < <(make_fixture link)
REPO="${fixture_paths[0]}"
HOME_DIR="${fixture_paths[1]}"
printf 'existing local data\n' > "$HOME_DIR/.config/opencode/AGENTS.md"
printf '{\"base\":true}\n' > "$REPO/.config/opencode/AGENTS.md"
if HOME="$HOME_DIR" bash "$REPO/bootstrap.sh" link >"$TMP/link.log" 2>&1; then
  fail 'link should refuse to replace an existing local file without FORCE=1'
fi
[ "$(cat "$HOME_DIR/.config/opencode/AGENTS.md")" = 'existing local data' ] || fail 'link changed existing local file'
HOME="$HOME_DIR" FORCE=1 bash "$REPO/bootstrap.sh" link >"$TMP/link-force.log" 2>&1
[ -L "$HOME_DIR/docs/not-config.md" ] && fail 'link installed untracked docs file'
[ -L "$HOME_DIR/sources.md" ] && fail 'link installed repo-level sources.md'
[ "$(cat "$HOME_DIR/.config/opencode/opencode.json")" = '{"secret":"fixture-only"}' ] || fail 'link changed opencode.json'
pass 'link boundary and explicit replacement'

printf 'bootstrap-test: pass\n'
