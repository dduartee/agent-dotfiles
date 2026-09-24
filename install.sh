#!/usr/bin/env bash
# install.sh — máquina NOVA: symlinka as skills (raiz) e a config opencode.
# Idempotente. Backup do que existir (.prelink.bak). NÃO toca em opencode.json.
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
OPENCODE="${OPENCODE_HOME:-$HOME/.config/opencode}"
DRY="${DRY_RUN:-0}"

# dirs de skills por harness (cross-runtime)
SKILL_DIRS=(
  "${AGENT_SKILLS_DIR:-$HOME/.agents/skills}"
  "$OPENCODE/skills"
  "$HOME/.claude/skills"
  "$HOME/.codex/skills"
)

link() { # src dst
  local src="$1" dst="$2"
  [ -e "$src" ] || { echo "skip (não existe): $src"; return; }
  if [ "$DRY" = 1 ]; then echo "would link $dst -> $src"; return; fi
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then mv "$dst" "$dst.prelink.bak"; fi
  ln -sfn "$src" "$dst"; echo "linked $dst -> $src"
}

# skills flat: todo dir na raiz com SKILL.md
for d in "$REPO"/*/; do
  [ -f "$d/SKILL.md" ] || continue
  name="$(basename "${d%/}")"
  for sk in "${SKILL_DIRS[@]}"; do
    [ -d "$(dirname "$sk")" ] || continue   # só harness presente
    link "${d%/}" "$sk/$name"
  done
done

# OpenCode: por arquivo (permite extras locais)
link "$REPO/AGENTS.md" "$OPENCODE/AGENTS.md"
for f in "$REPO"/opencode/plugins/*.js; do [ -e "$f" ] && link "$f" "$OPENCODE/plugins/$(basename "$f")"; done
for f in "$REPO"/opencode/instructions/*.md; do [ -e "$f" ] && link "$f" "$OPENCODE/instructions/$(basename "$f")"; done

echo
echo "NOTA: opencode.json NÃO foi tocado (o teu tem MCP/token local)."
echo "      Compare com opencode/opencode.json e faça merge manual."
