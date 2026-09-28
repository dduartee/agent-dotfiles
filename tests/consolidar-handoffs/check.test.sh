#!/usr/bin/env bash
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
T="$(mktemp -d "${TMPDIR:-/tmp}/chk.XXXXXX")"
trap 'rm -rf "$T"' EXIT
pass() { printf 'PASS: %s\n' "$*"; }
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }
w() { cat > "$1"; }

# GOOD (multilinha) — deve passar.
w "$T/good.md" <<'EOF'
# Consolidado
Abertas:
- P2 (aberto, ses_aaa2)
- Q2 (aberto, ses_bbb1)
- doc-deploy P4=Q3 (duplicata, aberto, ses_aaa1/ses_bbb2)
Feitas:
- P1 (concluído, ses_aaa2)
- P5 (concluído, ses_bbb2)
- Q1 (concluído, ses_bbb2)
Obsoletas:
- P3 (rotacionado, ses_bbb2)
Correlações:
- srclib 2.3 = {P2, Q1, P5}
EOF
node "$D/check.mjs" "$T/good.md" >/dev/null || { node "$D/check.mjs" "$T/good.md"; fail 'GOOD deveria passar'; }

# BAD — tudo aberto.
w "$T/bad.md" <<'EOF'
Abertas:
- P1 (aberto)
- P2 (aberto)
- P3 (aberto)
- P4 (aberto)
- P5 (aberto)
- Q1 (aberto)
- Q2 (aberto)
- Q3 (aberto)
EOF
node "$D/check.mjs" "$T/bad.md" >/dev/null 2>&1 && fail 'BAD deveria falhar'

# A — srclib citado sem cluster (Review Focus 4 não surfaçado).
sed 's|^- srclib 2.3 = {P2, Q1, P5}|- srclib 2.3 causou bugs|' "$T/good.md" > "$T/a.md"
node "$D/check.mjs" "$T/a.md" >/dev/null 2>&1 && fail 'A (sem correlação) deveria falhar'

# B — duplicata não-mergeada: P4 e Q3 em linhas abertas separadas.
w "$T/b.md" <<'EOF'
Abertas:
- P2 (aberto, ses_aaa2)
- Q2 (aberto, ses_bbb1)
- P4 (aberto, ses_aaa1)
- Q3 (aberto, ses_bbb2)
Feitas:
- P1 (concluído, ses_aaa2)
- P5 (concluído, ses_bbb2)
- Q1 (concluído, ses_bbb2)
Obsoletas:
- P3 (rotacionado, ses_bbb2)
Correlações:
- srclib 2.3 = {P2, Q1, P5} (P4/Q3 duplicata)
EOF
node "$D/check.mjs" "$T/b.md" >/dev/null 2>&1 && fail 'B (duplicata não-mergeada) deveria falhar'

# C — P2 só na correlação, fora de Abertas (drops uma pendência aberta).
w "$T/c.md" <<'EOF'
Abertas:
- Q2 (aberto, ses_bbb1)
- doc-deploy P4=Q3 (duplicata, aberto)
Feitas:
- P1 (concluído, ses_aaa2)
- P5 (concluído, ses_bbb2)
- Q1 (concluído, ses_bbb2)
Obsoletas:
- P3 (rotacionado, ses_bbb2)
Correlações:
- srclib 2.3 = {P2, Q1, P5}
EOF
node "$D/check.mjs" "$T/c.md" >/dev/null 2>&1 && fail 'C (P2 perdido) deveria falhar'

# D — formato compacto (igual ao ground-truth) deve passar.
w "$T/d.md" <<'EOF'
Abertas: P2 (aberto, ses_aaa2); Q2 (aberto, ses_bbb1); doc-deploy P4=Q3 (duplicata, aberto, ses_aaa1/ses_bbb2)
Feitas: P1 (concluído, ses_aaa2); P5 (concluído, ses_bbb2); Q1 (concluído, ses_bbb2)
Obsoletas: P3 (rotacionado, ses_bbb2)
Correlações: srclib 2.3 = {P2, Q1, P5}
EOF
node "$D/check.mjs" "$T/d.md" >/dev/null || { node "$D/check.mjs" "$T/d.md"; fail 'D (compacto) deveria passar'; }

# F — heading "Pendências concluídas" é seção done, não open.
w "$T/f.md" <<'EOF'
Abertas: P2 (aberto, ses_aaa2); Q2 (aberto, ses_bbb1); doc P4=Q3 (duplicata, aberto)
Pendências concluídas: P1 (ses_aaa2); P5 (ses_bbb2); Q1 (ses_bbb2)
Obsoletas: P3 (rotacionado, ses_bbb2)
Correlações: srclib 2.3 = {P2, Q1, P5}
EOF
node "$D/check.mjs" "$T/f.md" >/dev/null || { node "$D/check.mjs" "$T/f.md"; fail 'F (pendências concluídas) deveria passar'; }

pass 'check.mjs: good/bad + regressões A,B,C,D,F'
printf 'check.test.sh: pass\n'
