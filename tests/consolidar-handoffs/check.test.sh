#!/usr/bin/env bash
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
pass() { printf 'PASS: %s\n' "$*"; }
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

# Saída "boa" mínima que deve passar (um item por linha).
GOOD="$(mktemp)"; cat > "$GOOD" <<'EOF'
Abertas:
- P2 (aberto, ses_aaa2)
- Q2 (aberto, ses_bbb1)
- doc-deploy P4=Q3 (duplicata, aberto, ses_aaa1/ses_bbb2)
Feitas:
- P1 (concluído, ses_aaa2)
- P5 (concluído, ses_bbb2)
- Q1 (concluído, ses_bbb2)
Obsoletas:
- P3 (TOKEN_Z rotacionado, ses_bbb2)
Correlações:
- srclib 2.3 = {P2, Q1, P5}
EOF
node "$D/check.mjs" "$GOOD" >/dev/null || fail 'saída boa deveria passar'

# Saída "ruim": tudo aberto, sem correlação/duplicata/provenance.
BAD="$(mktemp)"; cat > "$BAD" <<'EOF'
Abertas:
- P1 (aberto)
- P2 (aberto)
- P3 (aberto)
- P4 (aberto)
- P5 (aberto)
- Q1 (aberto)
- Q2 (aberto)
EOF
if node "$D/check.mjs" "$BAD" >/dev/null 2>&1; then fail 'saída ruim deveria falhar'; fi
pass 'check.mjs aceita boa e rejeita ruim'
printf 'check.test.sh: pass\n'
