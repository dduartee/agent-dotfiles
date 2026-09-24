#!/usr/bin/env bash
# bootstrap.sh — dotfiles de agentes (espelha $HOME).
#
#   ./bootstrap.sh link   (default)  repo -> $HOME   (symlink por arquivo; backup .prelink.bak)
#   ./bootstrap.sh sync              $HOME -> repo   (snapshot do que mudou)
#
# Exceções (merge MANUAL, nunca linkadas/copiadas):
#   .config/opencode/opencode.json  — a versão da máquina tem MCP/token local
#                                     (ex.: daily-digest); a do repo é base sanitizada.
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
HOME_DIR="${HOME:?}"
DRY="${DRY_RUN:-0}"
CMD="${1:-link}"

SKIP_RE='^\.config/opencode/opencode\.json$'

# arquivos gerenciados (relativos ao repo = relativos ao $HOME)
mapfile -t ITEMS < <(
  cd "$REPO" && find . -type f \
    -not -path './.git/*' \
    -not -name 'README.md' -not -name '.gitignore' \
    -not -name 'CURATION.md' -not -name 'bootstrap.sh' \
    | sed 's#^\./##' | grep -vE "$SKIP_RE"
)

if [ "$CMD" = "sync" ]; then
  for r in "${ITEMS[@]}"; do
    src="$HOME_DIR/$r"; [ -e "$src" ] || { echo "skip (sem ~/$r)"; continue; }
    mkdir -p "$REPO/$(dirname "$r")"; cp -f "$src" "$REPO/$r"; echo "sync $r"
  done
  # importa skills marcadas "sim" na CURATION.md (de ~/.agents ou ~/.config/opencode/skills)
  if [ -f "$REPO/CURATION.md" ]; then
    grep -E '^\|[^|]+\|[^|]+\|[[:space:]]*sim[[:space:]]*\|' "$REPO/CURATION.md" \
      | awk -F'|' '{gsub(/^ +| +$/,"",$2); print $2}' | while read -r name; do
        for base in "$HOME_DIR/.agents/skills" "$HOME_DIR/.config/opencode/skills"; do
          if [ -d "$base/$name" ]; then
            mkdir -p "$REPO/.agents/skills/$name"; cp -fR "$base/$name/." "$REPO/.agents/skills/$name/"
            echo "skill: $name"; break
          fi
        done
      done
  fi
  echo "snapshot pronto. Revise: git -C \"$REPO\" status"
  exit 0
fi

for r in "${ITEMS[@]}"; do
  dst="$HOME_DIR/$r"
  if [ "$DRY" = 1 ]; then echo "would link ~/$r -> $REPO/$r"; continue; fi
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then mv "$dst" "$dst.prelink.bak"; fi
  ln -sfn "$REPO/$r" "$dst"; echo "link ~/$r"
done

echo
echo "NOTA: ~/.config/opencode/opencode.json NÃO foi tocado."
echo "      Merge manual: compare com $REPO/.config/opencode/opencode.json"
