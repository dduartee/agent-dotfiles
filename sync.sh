#!/usr/bin/env bash
# sync.sh — esta máquina: snapshot vivo -> repo. NÃO commita.
# Skills: só as marcadas "sim" em CURATION.md.
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
OPENCODE="${OPENCODE_HOME:-$HOME/.config/opencode}"
SKILLS_DIR="${AGENT_SKILLS_DIR:-$HOME/.agents/skills}"

mkdir -p "$REPO/opencode/plugins" "$REPO/opencode/instructions"
cp -f "$OPENCODE/AGENTS.md" "$REPO/AGENTS.md"
for f in backlog.js pontas-soltas.js sessao-atual.js mind-automation.js; do
  cp -f "$OPENCODE/plugins/$f" "$REPO/opencode/plugins/$f"
done
cp -f "$OPENCODE/instructions/"*.md "$REPO/opencode/instructions/"

# skills marcadas: | nome | ... | sim |
if [ -f "$REPO/CURATION.md" ]; then
  grep -E '^\|[^|]+\|[^|]+\|[[:space:]]*sim[[:space:]]*\|' "$REPO/CURATION.md" \
    | awk -F'|' '{gsub(/^ +| +$/,"",$2); print $2}' | while read -r name; do
      [ -d "$SKILLS_DIR/$name" ] || { echo "aviso: skill ausente $name"; continue; }
      mkdir -p "$REPO/$name"; cp -fR "$SKILLS_DIR/$name/." "$REPO/$name/"
      echo "copiada: $name"
    done
fi

echo "snapshot pronto. Revise: git -C \"$REPO\" status"
