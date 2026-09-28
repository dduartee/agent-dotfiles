#!/usr/bin/env bash
# sessao.sh — ground truth da sessão OpenCode (POSIX: Linux, macOS, WSL, Git Bash).
#
# Descobre o ambiente em runtime; NÃO assume path nem SO:
#   1. binário: $OPENCODE_BIN -> `opencode` no PATH
#   2. banco:   $OPENCODE_DB  -> `opencode debug paths` (chave `db`)
#   3. sessão:  $1 -> $OPENCODE_SESSION_ID -> /api/session/active -> diretório -> list
#   4. fonte:   `opencode session export` (JSON portátil) -> fallback SQLite
#
# Uso:
#   bash scripts/sessao.sh [ses_xxx]
#
# Env:
#   OPENCODE_BIN          binário do opencode (default: opencode)
#   OPENCODE_DB           caminho do opencode.db (fallback)
#   OPENCODE_SESSION_JSON JSON de sessão já exportado (pula o export)
#   OPENCODE_SESSION_ID   id da sessão
#   RETRO_MAX             máx. de chars por mensagem (default 1200)
set -euo pipefail

MAX="${RETRO_MAX:-1200}"
[[ "$MAX" =~ ^[0-9]+$ ]] || { echo "ERRO: RETRO_MAX deve ser inteiro" >&2; exit 2; }

need_jq() {
  command -v jq >/dev/null 2>&1 && return 0
  echo "ERRO: jq não encontrado. Instale jq, ou exporte manualmente e leia o JSON com suas tools." >&2
  exit 1
}
need_jq

# --- 1. binário -----------------------------------------------------------
OC_BIN="${OPENCODE_BIN:-opencode}"
have_oc=0
if command -v "$OC_BIN" >/dev/null 2>&1; then have_oc=1; fi
oc() { [ "$have_oc" = 1 ] && command "$OC_BIN" "$@" 2>/dev/null || return 127; }

# --- 2. banco (descoberta; nunca hardcode de SO) --------------------------
DB="${OPENCODE_DB:-}"
if [ -z "$DB" ] && [ "$have_oc" = 1 ]; then
  DB="$(oc debug paths 2>/dev/null | awk '$1=="db"{print $2}')" || true
fi

# --- 3. sessão ------------------------------------------------------------
resolve_sid() {
  [ -n "${1:-}" ] && { printf '%s\n' "$1"; return 0; }
  [ -n "${OPENCODE_SESSION_ID:-}" ] && { printf '%s\n' "$OPENCODE_SESSION_ID"; return 0; }
  [ "$have_oc" = 1 ] || return 1

  local active n id dir matches
  active=$(oc api get /api/session/active | jq -r '.data | keys[]?' 2>/dev/null || true)
  n=$(printf '%s\n' "$active" | grep -c . || true)
  [ "${n:-0}" -eq 1 ] && { printf '%s\n' "$active"; return 0; }

  if [ "${n:-0}" -gt 1 ]; then
    matches=0; SID_MATCHES=""
    for id in $active; do
      dir=$(oc api get "/api/session/$id" | jq -r '.data.location.directory // empty' 2>/dev/null || true)
      [ -n "$dir" ] || continue
      if [ "$PWD" = "$dir" ] || [ "${PWD#"$dir"/}" != "$PWD" ]; then
        matches=$((matches + 1)); SID_MATCHES="$SID_MATCHES $id"
      fi
    done
    [ "$matches" -eq 1 ] && { printf '%s\n' $SID_MATCHES; return 0; }

    # Mesmo diretório: NÃO adivinha. Com outro agente rodando em paralelo, o
    # desempate por recência escolhe a sessão errada.
    if [ "$matches" -gt 1 ]; then
      echo "AVISO: $matches sessões ativas no mesmo diretório ($PWD). Não adivinho — passe o id explícito:" >&2
      for id in $SID_MATCHES; do
        info=$(oc api get "/api/session/$id" | jq -r '.data.title // "?"' 2>/dev/null || true)
        echo "  - $id  $info" >&2
      done
      return 1
    fi

    echo "AVISO: $n sessões ativas; nenhuma do diretório atual. Passe o id explícito:" >&2
    for id in $active; do
      info=$(oc api get "/api/session/$id" | jq -r '"\(.data.location.directory // "?")  \(.data.title // "?")"' 2>/dev/null || true)
      echo "  - $id  $info" >&2
    done
    return 1
  fi

  id=$(oc session list --format json | jq -r '.[0].id?' 2>/dev/null || true)
  [ -n "$id" ] && { printf '%s\n' "$id"; return 0; }
  return 1
}

SID=$(resolve_sid "${1:-}") || {
  echo "ERRO: não achei a sessão. Passe o id: bash scripts/sessao.sh ses_xxx" >&2
  exit 1
}
[[ "$SID" =~ ^ses_[A-Za-z0-9_-]+$ ]] || { echo "ERRO: SID inválido: $SID" >&2; exit 2; }

TITLE=$(oc session list --format json | jq -r --arg s "$SID" '.[] | select(.id==$s) | .title' 2>/dev/null | head -1 || true)
if [ -z "${TITLE:-}" ]; then
  TITLE=$(oc api get "/api/session/$SID" | jq -r '.data.title // .title // empty' 2>/dev/null | head -1 || true)
fi

# --- 4. fonte de ground truth --------------------------------------------
TMPJSON=""
cleanup() { [ -n "$TMPJSON" ] && rm -f "$TMPJSON" || true; }
trap cleanup EXIT

EXP="${OPENCODE_SESSION_JSON:-}"
if [ -z "$EXP" ] && [ "$have_oc" = 1 ]; then
  TMPJSON="$(mktemp "${TMPDIR:-/tmp}/retro-XXXXXX.json")"
  if oc session export "$SID" > "$TMPJSON" && [ -s "$TMPJSON" ] && jq -e . "$TMPJSON" >/dev/null 2>&1; then
    EXP="$TMPJSON"
  else
    EXP=""
  fi
fi

SRC=""
ROWS=""
if [ -n "$EXP" ] && [ -f "$EXP" ]; then
  ROWS=$(jq -c '[.messages | to_entries[] | {seq:(.key+1), type:(.value.type // "?"), data:.value}]' "$EXP" 2>/dev/null) || ROWS=""
  [ -n "$ROWS" ] && SRC="export"
fi

if [ -z "$SRC" ]; then
  if ! command -v sqlite3 >/dev/null 2>&1; then
    echo "ERRO: sem fonte da sessão. 'opencode session export' falhou e sqlite3 está ausente." >&2
    echo "      Alternativa: exporte manualmente e use OPENCODE_SESSION_JSON=<arquivo>." >&2
    exit 1
  fi
  if [ -z "$DB" ] || [ ! -f "$DB" ]; then
    echo "ERRO: banco não encontrado: ${DB:-<não descoberto; use OPENCODE_DB>}" >&2
    exit 1
  fi
  ROWS=$(sqlite3 -json "$DB" "select seq,type,data from session_message where session_id='$SID' order by seq;" 2>/dev/null \
    | jq -c '[.[] | (.type) as $rt | (.data|fromjson) as $d
              | {seq:.seq, type:$rt, data:($d + {type:($d.type // $rt)})}]' 2>/dev/null) || ROWS=""
  [ -n "$ROWS" ] || { echo "ERRO: sessão vazia ou inacessível em $DB" >&2; exit 1; }
  SRC="sqlite3:$DB"
fi

# --- 5. relatório ---------------------------------------------------------
FORTE='TODO|FIXME|XXX|warning|aviso|não testei|nao testei|não validei|nao validei|não testado|nao testado|não consegui|nao consegui|pendente|pendência|pende[nç]cia|fica (pra|para) depois|ficou (pra|para)|deixei (pra|para)|por enquanto|workaround|gambiarra|não implementei|nao implementei|falta (testar|validar|fazer)'
FRACO='\bdepois\b|temporári|temporari|por ora|futuramente|idealmente|ideal seria|assum(indo|o|imos)|eventualmente|pretendo|planejo|se quiser|posso |quer que eu|sugiro|recomendo'

printf '%s' "$ROWS" | jq -r \
  --arg sid "$SID" --arg title "${TITLE:-?}" --arg src "$SRC" --argjson max "$MAX" \
  --arg forte "$FORTE" --arg fraco "$FRACO" '
  def redact:
    gsub("sk-[A-Za-z0-9]{20,}"; "sk-[REDACTED]")
    | gsub("xvl-[A-Za-z0-9]{20,}"; "xvl-[REDACTED]")
    | gsub("gh[pousr]_[A-Za-z0-9]{20,}"; "gh_[REDACTED]")
    | gsub("AKIA[0-9A-Z]{16}"; "AKIA[REDACTED]")
    | gsub("-----BEGIN ([A-Z ]+)?PRIVATE KEY-----"; "[PRIVATE KEY REDACTED]");
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
        text: ((.data
                | if (.type=="user" or .type=="system" or .type=="synthetic") then (.text // "")
                  else ([ (.content // [])[]? | select(.type=="text") | .text ] | join(" ")) end) | redact),
        tools: (if .type=="assistant"
                then [ (.data.content // [])[]? | select(.type=="tool")
                       | { name: (.name // "?"),
                           status: ((.state.status // .status) // "?"),
                           err: (((.state.error.message // .state.metadata.error // .error // "") | tostring) | redact) } ]
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
    "fonte: \($src)",
    "mensagens: \($rows | length)  |  user:\($types | map(select(.=="user")) | length)  assistant:\($types | map(select(.=="assistant")) | length)  compaction:\($types | map(select(.=="compaction")) | length)  |  rastros: \($fortes|length) fortes, \($fracos|length) fracos, \($erros|length) erros",
    (if ($types | index("compaction")) != null
     then "AVISO: houve COMPACTAÇÃO — parte do contexto foi descartada. Trechos antes dela são suspeitos."
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
