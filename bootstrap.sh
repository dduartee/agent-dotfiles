#!/usr/bin/env bash
# bootstrap.sh — dotfiles de agentes (espelha apenas caminhos gerenciados).
#
#   ./bootstrap.sh link   repo -> $HOME
#   ./bootstrap.sh sync   $HOME -> repo
#
# O link é explícito: nunca move arquivo local sem FORCE=1. O sync nunca toca
# opencode.json porque a configuração da máquina pode conter MCPs/segredos.
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
HOME_DIR="${HOME:?}"
DRY="${DRY_RUN:-0}"
FORCE="${FORCE:-0}"
CMD="${1:-link}"

case "$CMD" in
  link|sync) ;;
  *) echo "uso: $0 [link|sync]" >&2; exit 2 ;;
esac

fail() { echo "erro: $*" >&2; exit 1; }

# Arquivos que pertencem ao espelho da máquina. Documentação, testes e
# metadados do repo não são dotfiles de $HOME.
managed_items() {
  cd "$REPO"
  find . -type f \
    -not -path './.git/*' \
    -not -name '.gitkeep' \
    -not -path './.config/opencode/opencode.json' \
    -print0 |
  while IFS= read -r -d '' path; do
    rel="${path#./}"
    case "$rel" in
      .config/opencode/*|.agents/skills/*) printf '%s\n' "$rel" ;;
    esac
  done
}

mapfile -t ITEMS < <(managed_items)

# Retorna source permitido para uma skill. ~/.agents é preferencial; os outros
# roots são compatibilidade para skills locais ainda não migradas.
find_skill_source() {
  local name="$1" base
  for base in \
    "$HOME_DIR/.agents/skills" \
    "$HOME_DIR/.config/opencode/skills" \
    "$HOME_DIR/.claude/skills"; do
    if [ -f "$base/$name/SKILL.md" ]; then
      printf '%s\n' "$base/$name"
      return 0
    fi
  done
  return 1
}

if [ "$CMD" = sync ]; then
  for rel in "${ITEMS[@]}"; do
    # Skills have a source precedence and are imported by the allowlist below.
    case "$rel" in .agents/skills/*) continue ;; esac
    src="$HOME_DIR/$rel"
    [ -e "$src" ] || fail "source ausente: ~/$rel"
    mkdir -p "$REPO/$(dirname "$rel")"
    cp -f "$src" "$REPO/$rel"
    echo "sync $rel"
  done

  [ -f "$REPO/CURATION.md" ] || fail "CURATION.md ausente"
  # Valida coluna incluir e devolve somente o allowlist explícito.
  marked="$(awk -F'|' '
    function trim(s) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return s }
    /^\|/ {
      skill=trim($2); include=trim($4)
      if (skill == "" || skill == "skill" || skill == "---") next
      if (include == "sim") print skill
      else if (include != "" && include != "nao" && include != "não") {
        printf "incluir inválido para %s: %s\n", skill, include > "/dev/stderr"
        exit 2
      }
    }
  ' "$REPO/CURATION.md")" || fail "CURATION.md inválido"

  while IFS= read -r name; do
    [ -n "$name" ] || continue
    if ! source="$(find_skill_source "$name")"; then
      fail "skill source ausente: $name"
    fi
    mkdir -p "$REPO/.agents/skills/$name"
    cp -fR "$source/." "$REPO/.agents/skills/$name/"
    echo "skill: $name"
  done <<< "$marked"

  echo "snapshot pronto. Revise: git -C \"$REPO\" status"
  exit 0
fi

for rel in "${ITEMS[@]}"; do
  dst="$HOME_DIR/$rel"
  if [ "$DRY" = 1 ]; then
    echo "would link ~/$rel -> $REPO/$rel"
    continue
  fi
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    if [ "$FORCE" != 1 ]; then
      fail "destino existe: ~/$rel (use FORCE=1 para mover para .prelink.bak)"
    fi
    mv "$dst" "$dst.prelink.bak"
  fi
  ln -sfn "$REPO/$rel" "$dst"
  echo "link ~/$rel"
done

echo
echo "NOTA: ~/.config/opencode/opencode.json NÃO foi tocado."
echo "      Merge manual: compare com $REPO/.config/opencode/opencode.json"
