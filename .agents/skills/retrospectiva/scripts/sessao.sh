#!/usr/bin/env bash
# Re-consulta a sessão REAL do OpenCode direto do SQLite (opencode.db).
# Fonte ground truth -> imune a compactação de contexto e à gestão de KV cache.
#
# Resolução da sessão (em ordem):
#   1) $1
#   2) $OPENCODE_SESSION_ID
#   3) GET /api/session/active  (a sessão em execução)
#   4) sessão mais recente do diretório atual
#
# Uso:
#   bash scripts/sessao.sh              # sessão atual (auto)
#   bash scripts/sessao.sh ses_xxx      # sessão específica
#
# Env:
#   RETRO_MAX=1200   # máx. de chars por mensagem
set -euo pipefail

DB="${OPENCODE_DB:-$HOME/.local/share/opencode/opencode.db}"
MAX="${RETRO_MAX:-1200}"

resolve_sid() {
  [ -n "${1:-}" ] && { printf '%s\n' "$1"; return 0; }
  [ -n "${OPENCODE_SESSION_ID:-}" ] && { printf '%s\n' "$OPENCODE_SESSION_ID"; return 0; }

  # Sessões em execução (foreground) — a fonte correta do "agora".
  local active n id dir matches
  active=$(opencode api get /api/session/active 2>/dev/null | jq -r '.data | keys[]?' 2>/dev/null || true)
  n=$(printf '%s\n' "$active" | grep -c . || true)
  [ "${n:-0}" -eq 1 ] && { printf '%s\n' "$active"; return 0; }

  # Várias ativas: casa pelo diretório da sessão.
  if [ "${n:-0}" -gt 1 ]; then
    matches=0
    SID_MATCHES=""
    for id in $active; do
      dir=$(opencode api get "/api/session/$id" 2>/dev/null | jq -r '.data.location.directory // empty' 2>/dev/null)
      [ -n "$dir" ] || continue
      if [ "$PWD" = "$dir" ] || [ "${PWD#"$dir"/}" != "$PWD" ]; then
        matches=$((matches + 1)); SID_MATCHES="$SID_MATCHES $id"
      fi
    done
    [ "$matches" -eq 1 ] && { printf '%s\n' $SID_MATCHES; return 0; }

    # Mesmo diretório: NÃO adivinha. Com outro agente rodando em paralelo, o
    # desempate por recência escolhe a sessão errada (já falhou ao vivo).
    if [ "$matches" -gt 1 ]; then
      echo "AVISO: $matches sessões ativas no mesmo diretório ($PWD). Não adivinho — passe o id explícito:" >&2
      for id in $SID_MATCHES; do
        info=$(opencode api get "/api/session/$id" 2>/dev/null | jq -r '.data.title // "?"' 2>/dev/null)
        echo "  - $id  $info" >&2
      done
      return 1
    fi

    echo "AVISO: $n sessões ativas; nenhuma do diretório atual. Passe o id explícito:" >&2
    for id in $active; do
      info=$(opencode api get "/api/session/$id" 2>/dev/null | jq -r '"\(.data.location.directory // "?")  \(.data.title // "?")"' 2>/dev/null)
      echo "  - $id  $info" >&2
    done
    return 1
  fi

  # Sem servidor: mais recente do cwd.
  id=$(opencode session list --format json 2>/dev/null | jq -r '.[0].id?' 2>/dev/null)
  [ -n "$id" ] && { printf '%s\n' "$id"; return 0; }
  return 1
}

SID=$(resolve_sid "${1:-}") || {
  echo "ERRO: não achei a sessão. Passe o id: bash scripts/sessao.sh ses_xxx"
  exit 1
}
[ -f "$DB" ] || { echo "ERRO: banco não encontrado: $DB"; exit 1; }

TITLE=$(opencode session list --format json 2>/dev/null \
  | jq -r --arg s "$SID" '.[] | select(.id==$s) | .title' 2>/dev/null | head -1)
if [ -z "${TITLE:-}" ]; then
  TITLE=$(opencode api get "/api/session/$SID" 2>/dev/null \
    | jq -r '.data.title // .title // empty' 2>/dev/null | head -1)
fi

# Rastros: sinais textuais que costumam marcar pendência/desfecho ausente.
FORTE='TODO|FIXME|XXX|warning|aviso|não testei|nao testei|não validei|nao validei|não testado|nao testado|não consegui|nao consegui|pendente|pendência|pende[nç]cia|fica (pra|para) depois|ficou (pra|para)|deixei (pra|para)|por enquanto|workaround|gambiarra|não implementei|nao implementei|falta (testar|validar|fazer)'
FRACO='\bdepois\b|temporári|temporari|por ora|futuramente|idealmente|ideal seria|assum(indo|o|imos)|eventualmente|pretendo|planejo|se quiser|posso |quer que eu|sugiro|recomendo'

sqlite3 -json "$DB" \
  "select seq, type, data from session_message where session_id='$SID' order by seq;" 2>/dev/null \
| jq -r --arg sid "$SID" --arg title "${TITLE:-?}" --argjson max "$MAX" \
    --arg forte "$FORTE" --arg fraco "$FRACO" '
  def excerpt($re):
    (. as $t
     | (try ($t | match($re; "i")) catch null) as $m
     | if $m == null then $t[0:160]
       else $t[([$m.offset - 40, 0] | max) : $m.offset + 140] end);
  def norm: gsub("\\s+"; " ");
  . as $rows
  | ($rows | map(.type)) as $types
  | ($rows | map(
      { seq: .seq, type: .type,
        text: ((.data | fromjson) as $m
               | if (.type=="user" or .type=="system" or .type=="synthetic") then ($m.text // "")
                 else ([$m.content[]? | select(.type=="text") | .text] | join(" ")) end),
        tools: (if .type=="assistant"
                then [((.data|fromjson).content[]? | select(.type=="tool")
                       | { name: .name, status: (.state.status // "?"),
                           err: (((.state.error.message // .state.metadata.error // "") | tostring)) })]
                else [] end) })) as $msgs
  | ([$msgs[] | .seq as $s | (.tools // [])[] | select(.status=="error")
      | "[erro ] seq \($s) · tool \(.name): \(.err | norm | .[0:120])"]) as $erros
  | ([$msgs[] | select(.type=="user" or .type=="assistant") | select(.text | test($forte; "i"))
      | "[forte] seq \(.seq) (\(.type)): \(.text | norm | excerpt($forte))"]) as $fortes
  | ([$msgs[] | select(.type=="user" or .type=="assistant")
      | select(.text | test($fraco; "i"))
      | select((.text | test($forte; "i")) | not)
      | "[fraco] seq \(.seq) (\(.type)): \(.text | norm | excerpt($fraco))"]) as $fracos
  | "=== SESSÃO \($sid) — \($title) ===",
    "mensagens: \($rows | length)  |  user:\($types | map(select(.=="user")) | length)  assistant:\($types | map(select(.=="assistant")) | length)  compaction:\($types | map(select(.=="compaction")) | length)  |  rastros: \($fortes|length) fortes, \($fracos|length) fracos, \($erros|length) erros",
    (if ($types | index("compaction")) != null
     then "AVISO: houve COMPACTAÇÃO — parte do contexto foi descartada (marcada abaixo). Trechos antes dela são suspeitos."
     else "Sem compactação de contexto." end),
    "",
    "=== RASTROS DE PENDÊNCIA (leads — confirme no transcript) ===",
    (if ($erros|length)==0 then "  (nenhum erro de tool)" else $erros[] end),
    (if ($fortes|length)==0 then "  (nenhum rastro forte)" else $fortes[0:40][] end),
    (if ($fracos|length)==0 then "  (nenhum rastro fraco)" else $fracos[0:15][] end),
    "",
    "=== TRANSCRIPT ===",
    ( $msgs[]
      | if (.type == "user" or .type == "system" or .type == "synthetic") then
          "[\(.type | ascii_upcase)] " + (.text[0:$max])
        elif .type == "assistant" then
          "[ASSIST] " + (.text[0:$max])
          + (([.tools[].name] | unique) as $tl
             | if ($tl | length) > 0 then "  ⟨tools: \($tl | join(","))⟩" else "" end)
        elif .type == "compaction" then
          "--- [COMPACTAÇÃO] o contexto acima foi resumido/descartado aqui ---"
        else empty end )
'
