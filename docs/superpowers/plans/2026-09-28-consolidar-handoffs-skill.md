# consolidar-handoffs (skill) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Criar a skill `consolidar-handoffs`, que transforma N handoffs em 1 consolidado correlacionado, sem perder pendência e com redundância mínima — validada por TDD (baseline sem skill → skill → refactor).

**Architecture:** Skill de conteúdo próprio em `.agents/skills/consolidar-handoffs/SKILL.md` (PT, flat, sem código). O teste vive em `tests/consolidar-handoffs/`: fixtures com verdade-conhecida + `check.mjs` (9 critérios). O RED/GREEN usa subagentes de modelo leve lendo as fixtures, sem e com a skill.

**Tech Stack:** Markdown, Node.js (`node --check`, `check.mjs`), Bash (`validate-repo.sh`), subagentes OpenCode.

**Spec:** [`docs/superpowers/specs/2026-09-28-consolidar-handoffs.md`](../specs/2026-09-28-consolidar-handoffs.md)

## Global Constraints

- Nome só com letras/números/hífen: `consolidar-handoffs`. Sem acento, sem parêntese.
- Frontmatter: `description` começa com "Use when", terceira pessoa, **só gatilhos** (nunca resumir o processo), ≤1024 chars.
- `SKILL.md` alvo: <500 palavras.
- **Igualdade:** toda pendência de entrada aparece na saída (aberta/feita/obsoleta). Zero exclusão silenciosa.
- **Provenance obrigatória:** cada item cita `ses_*`/data/handoff de origem.
- **Resolução vence:** estado mais recente define o status; contradição vira `CONFLITO`.
- Sem segredos. Skill própria ⇒ `CURATION.md` = `sim`, `README.md` lista.
- Teste por subagente é read-only (não altera arquivos).
- Idioma: PT (convenção das skills próprias). Código/commits normais.

## Review Focus

1. Dois handoffs citam a mesma pendência com palavras diferentes → deve **ligar**, não duplicar.
2. Handoff posterior resolve/obsoleta item anterior → **não** carregar como aberto.
3. Status conflitante para o mesmo item → marcar `CONFLITO`, não escolher em silêncio.
4. Correlação entre projetos por causa raiz compartilhada → **surfaçar o vínculo**.
5. Handoff longo com muitas pendências → **não** perder os itens do fim (progresso igualitário).

---

### Task 1: Corpus de fixtures + verdade-conhecida

**Files:**
- Create: `tests/consolidar-handoffs/fixtures/projA/2026-08-01-bootstrap.md`
- Create: `tests/consolidar-handoffs/fixtures/projA/2026-08-10-login-fix.md`
- Create: `tests/consolidar-handoffs/fixtures/projB/2026-08-15-messagefs.md`
- Create: `tests/consolidar-handoffs/fixtures/projB/2026-08-20-outbox.md`
- Create: `tests/consolidar-handoffs/ground-truth.md`

**Interfaces:**
- Produces: os 4 handoffs lidos pela tarefa de teste; `ground-truth.md` só para o humano pontuar.

- [ ] **Step 1: Criar os 4 handoffs**

`fixtures/projA/2026-08-01-bootstrap.md`:
```markdown
# Handoff — projA bootstrap
Sessão: ses_aaa1 · Data: 2026-08-01 · Escopo: repo projA
## Pendências
- P1: corrigir login com JWT (bug no middleware) — aberto
- P2: adicionar testes de integração no auth — aberto
- P3: rotacionar TOKEN_Z (exposto em log) — aberto
- P4: escrever README de deploy — aberto
## Notas
TOKEN_Z bloqueia produção. Nada foi commitado.
```

`fixtures/projA/2026-08-10-login-fix.md`:
```markdown
# Handoff — projA login fix
Sessão: ses_aaa2 · Data: 2026-08-10 · Escopo: repo projA
## Estado
- P1 (login JWT): CONCLUÍDO e no main.
- P2 (testes auth): segue aberto; causa raiz é a lib `srclib 2.3`.
- P3 (TOKEN_Z): ainda aberto.
## Novo
- P5: migrar `srclib 2.3` -> `3.0` (a lib antiga causa o bug de auth).
```

`fixtures/projB/2026-08-15-messagefs.md`:
```markdown
# Handoff — projB (MessageFS)
Sessão: ses_bbb1 · Data: 2026-08-15 · Escopo: repo projB
## Pendências
- Q1: bug de sessão intermitente; MESMA causa raiz da lib `srclib 2.3` (projA).
- Q2: outbox não é idempotente — aberto.
```

`fixtures/projB/2026-08-20-outbox.md`:
```markdown
# Handoff — projB outbox
Sessão: ses_bbb2 · Data: 2026-08-20 · Escopo: repo projB
## Estado
- Q1: CONCLUÍDO (migrou `srclib 3.0`). Logo P5 (migrar srclib) também está feito.
- TOKEN_Z foi rotacionado em 2026-08-18 — P3 (projA) NÃO é mais necessário.
- Q2 (outbox idempotente): aberto.
## Duplicata
A doc de deploy P4 (projA) é a mesma coisa que Q3 daqui; P4 e Q3 são duplicatas.
```

- [ ] **Step 2: Criar a verdade-conhecida (só para pontuação humana)**

`ground-truth.md`:
```markdown
# Verdade esperada do consolidado
Abertas: P2 (projA), Q2 (projB), doc-deploy (P4=Q3, projA/projB, duplicata).
Feitas: P1, P5, Q1.
Obsoletas/legado: P3 (TOKEN_Z rotacionado em 2026-08-18).
Correlações: cluster `srclib 2.3` = {P2, Q1, P5}.
Conflitos: nenhum.
Provenance: ses_aaa1, ses_aaa2, ses_bbb1, ses_bbb2.
Total de itens de entrada: 6 (P1,P2,P3,P4,P5,Q1) + Q2 (projB h1) = 7 → saída: 3 abertas + 3 feitas + 1 obsoleta = 7.
```

- [ ] **Step 3: Verificar**

Run: `ls tests/consolidar-handoffs/fixtures/projA tests/consolidar-handoffs/fixtures/projB`
Expected: 2 arquivos em cada + `ground-truth.md` presente.

- [ ] **Step 4: Commit**

```bash
git add tests/consolidar-handoffs
git commit -m "test(consolidar-handoffs): fixtures e verdade-conhecida"
```

---

### Task 2: Scorer `check.mjs` (TDD do scorer)

**Files:**
- Create: `tests/consolidar-handoffs/check.mjs`
- Test: `tests/consolidar-handoffs/check.test.sh`

**Interfaces:**
- Produces: `node check.mjs <consolidado.md>` → imprime `PASS/FAIL <critério>` e `score N/9`; exit 0 se 9/9.

- [ ] **Step 1: Escrever o teste do scorer (espera falha)**

`check.test.sh`:
```bash
#!/usr/bin/env bash
set -euo pipefail
D="$(cd "$(dirname "$0")" && pwd)"
pass() { printf 'PASS: %s\n' "$*"; }
fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

# Saída "boa" mínima que deve passar.
GOOD="$(mktemp)"; cat > "$GOOD" <<'EOF'
Abertas: P2 (aberto, ses_aaa2); Q2 (aberto, ses_bbb1); doc-deploy (P4=Q3, duplicata, ses_aaa1/ses_bbb2).
Feitas: P1 (concluído, ses_aaa2); P5 (concluído, ses_bbb2); Q1 (concluído, ses_bbb2).
Obsoletas: P3 (TOKEN_Z rotacionado, ses_bbb2).
Correlações: srclib 2.3 = {P2, Q1, P5}.
EOF
node "$D/check.mjs" "$GOOD" >/dev/null || fail 'saída boa deveria passar'

# Saída "ruim": perde P2, carrega P3 como aberto, sem correlação/duplicata/provenance.
BAD="$(mktemp)"; cat > "$BAD" <<'EOF'
Abertas: P1 (aberto); P3 (aberto); P4 (aberto); P5 (aberto); Q2 (aberto).
EOF
if node "$D/check.mjs" "$BAD" >/dev/null 2>&1; then fail 'saída ruim deveria falhar'; fi
pass 'check.mjs aceita boa e rejeita ruim'
printf 'check.test.sh: pass\n'
```

Run: `bash tests/consolidar-handoffs/check.test.sh`
Expected: FAIL (`check.mjs` não existe).

- [ ] **Step 2: Escrever `check.mjs` mínimo**

`check.mjs`:
```js
#!/usr/bin/env node
// Pontua um handoff consolidado contra a verdade do fixture.
// Uso: node check.mjs <consolidado.md>
import { readFileSync } from "node:fs";

const file = process.argv[2];
if (!file) { console.error("uso: node check.mjs <consolidado.md>"); process.exit(2); }
const t = readFileSync(file, "utf8");

const perto = (id, re) => new RegExp(`${id}\\b[^\\n]{0,80}${re}`, "i").test(t);
const criteria = [
  ["P2 aberto",         perto("P2", "(aberto|pendente)")],
  ["Q2 aberto",         perto("Q2", "(aberto|pendente)")],
  ["P1 feito",          perto("P1", "(conclu|feito|resolv|done)")],
  ["P5 feito",          perto("P5", "(conclu|feito|resolv|done)")],
  ["Q1 feito",          perto("Q1", "(conclu|feito|resolv|done)")],
  ["P3 nao-aberto",     /P3\b/.test(t) && !perto("P3", "(aberto|pendente)")],
  ["correlacao srclib", /srclib/i.test(t)],
  ["duplicata P4/Q3",   /(P4|Q3)/.test(t) && /duplicat|mesma|id[eê]ntic|merge/i.test(t)],
  ["provenance",        /ses_(aaa1|aaa2|bbb1|bbb2)/.test(t)],
];

let ok = 0;
for (const [name, pass] of criteria) {
  console.log(`${pass ? "PASS" : "FAIL"} ${name}`);
  if (pass) ok++;
}
console.log(`\nscore ${ok}/${criteria.length}`);
process.exit(ok === criteria.length ? 0 : 1);
```

- [ ] **Step 3: Rodar o teste do scorer**

Run: `bash tests/consolidar-handoffs/check.test.sh`
Expected: `check.test.sh: pass`.

- [ ] **Step 4: Commit**

```bash
git add tests/consolidar-handoffs/check.mjs tests/consolidar-handoffs/check.test.sh
git commit -m "test(consolidar-handoffs): scorer check.mjs + teste do scorer"
```

---

### Task 3: RED — baseline sem skill

**Files:**
- Create: `tests/consolidar-handoffs/prompt.md`
- Produce: `tests/consolidar-handoffs/runs/red-<modelo>.md` (saída do subagente; não versionar)

**Interfaces:**
- Produces: baseline pontuado; lista de falhas verbatim (alimenta a skill).

- [ ] **Step 1: Escrever o prompt neutro**

`prompt.md`:
```markdown
Você recebeu vários handoffs de sessões diferentes (projetos projA e projB) em
`tests/consolidar-handoffs/fixtures/`. Leia TODOS.

Produza UM handoff consolidado que o próximo agente possa seguir sem perder
nenhuma pendência. Correlacione o que for relacionado e minimize a redundância.

Não altere nenhum arquivo. Devolva só o markdown consolidado.
```

- [ ] **Step 2: Despachar subagente SEM a skill**

Despache 1 subagente por modelo leve (ex.: `qwen3.8-flash`, `mimo-v2.5`), read-only. Prompt = conteúdo de `prompt.md` + "os arquivos estão em `<repo>/tests/consolidar-handoffs/fixtures/`". Salve a saída de cada um em `runs/red-<modelo>.md`.

- [ ] **Step 3: Pontuar**

Run: `for f in tests/consolidar-handoffs/runs/red-*.md; do echo "== $f"; node tests/consolidar-handoffs/check.mjs "$f"; done`
Expected: **falha** em ≥1 critério (baseline). Registre quais critérios falharam e as racionalizações (verbatim) em `runs/red-notes.md`.

- [ ] **Step 4: Nenhum commit de runs**

`runs/` é descartável. Adicione `tests/consolidar-handoffs/runs/` ao `.gitignore`.

```bash
printf 'tests/consolidar-handoffs/runs/\n' >> .gitignore
git add .gitignore
git commit -m "chore: ignore runs de teste da skill consolidar-handoffs"
```

---

### Task 4: GREEN — escrever `SKILL.md`

**Files:**
- Create: `.agents/skills/consolidar-handoffs/SKILL.md`

**Interfaces:**
- Consumes: falhas verbatim do Task 3.
- Produces: skill que cobre exatamente essas falhas.

- [ ] **Step 1: Escrever a skill mínima (GREEN)**

`.agents/skills/consolidar-handoffs/SKILL.md`:
```markdown
---
name: consolidar-handoffs
description: Use quando houver múltiplos handoffs (de várias sessões ou projetos) para juntar; quando o usuário pedir "consolidar handoffs", "correlacionar pendências", "o que várias sessões deixaram", "tirar redundância entre handoffs", ou iniciar uma sessão a partir de vários handoffs.
---

# Consolidar handoffs

Transforma N handoffs em 1 consolidado: correlaciona, aplica resoluções anteriores,
marca legado/obsoleto, preserva origem. **Nenhuma pendência some.**

## Invariantes

1. **Igualdade** — toda pendência de entrada aparece na saída (aberta, feita ou obsoleta). Zero exclusão silenciosa.
2. **Origem** — cada item cita o handoff/sessão/data de origem.
3. **Resolução vence** — se um handoff posterior fecha ou torna obsoleto um item, a saída reflete isso; não carrega como aberto.
4. **Correlação explícita** — itens com a mesma causa raiz/assunto viram 1 item com N origens.
5. **Conflito** — status divergente vira `CONFLITO`; não escolha em silêncio.
6. **Redundância mínima** — item repetido aparece 1 vez.

## Procedimento

1. Liste **todos** os handoffs: caminho · sessão · data · projeto.
2. Extraia cada pendência crua: `descrição · status · projeto · origem`.
3. Agrupe por: mesmo projeto · mesma causa raiz · mesma ação.
4. Para cada grupo, o status final vem do handoff **mais recente que cita o item**; se dois se contradizem, marque `CONFLITO`.
5. Produza as seções: **Abertas · Feitas · Obsoletas/legado · Correlações · Conflitos**.
6. **Confira a igualdade:** nº de itens de entrada = soma das linhas de saída (duplicatas mergadas contam 1) + obsoletas.

## Formato

```markdown
# Consolidado — <projetos> (<N> handoffs, <data>)
Abertas:
- <item> — <projeto> — origem <ses>/<data>
Feitas:
- <item> — origem <ses>
Obsoletas/legado:
- <item> — <por que não é mais necessária> — origem <ses>
Correlações:
- <causa raiz> = {<itens>} — origens <ses...>
Conflitos:
- <item> — <status A> (ses_x) vs <status B> (ses_y) — decidir
Igualdade: <N entrada> = <a+b+c saída>
```

## Erros comuns

| Erro | Correção |
|---|---|
| Perder item do fim do handoff | Releia item a item; confira a igualdade |
| Duplicar item entre handoffs | Mesmo assunto → 1 linha com N origens |
| Carregar item já resolvido | O handoff mais recente vence |
| Esconder contradição | `CONFLITO` explícito |
| Não ver causa raiz comum | Bloco "Correlações" |
```

- [ ] **Step 2: Verificar frontmatter e tamanho**

Run: `wc -w .agents/skills/consolidar-handoffs/SKILL.md` e `sed -n '1,4p' .agents/skills/consolidar-handoffs/SKILL.md`
Expected: <500 palavras; `description` começa com "Use quando" e não resume o processo.

---

### Task 5: GREEN — verificar com skill

- [ ] **Step 1: Despachar os MESMOS modelos COM a skill**

Prompt = `prompt.md` + "Siga a skill `consolidar-handoffs` (`.agents/skills/consolidar-handoffs/SKILL.md`)". Salve em `runs/green-<modelo>.md`.

- [ ] **Step 2: Pontuar e comparar**

Run: `for f in tests/consolidar-handoffs/runs/green-*.md; do echo "== $f"; node tests/consolidar-handoffs/check.mjs "$f"; done`
Expected: **PASS 9/9** em todos (ou ≥9/9 com leitura manual confirmando). Compare com o RED em `runs/red-notes.md`.

- [ ] **Step 3: Se falhar, volte ao Task 4**

Cada critério que falhar vira um contador explícito na skill (REFACTOR). Repita até 9/9.

---

### Task 6: REFACTOR — fechar brechas

- [ ] **Step 1: Rodar 1 repetição extra por modelo com a skill**

Salve em `runs/green2-<modelo>.md`. Pontue.

- [ ] **Step 2: Anotar racionalizações novas e adicionar contador**

Se surgir brecha nova (ex.: "agrupei por projeto e perdi a correlação"), adicione linha em "Erros comuns" e re-teste.

- [ ] **Step 3: Registrar o placar**

Crie `tests/consolidar-handoffs/SCORE.md` com: modelo · arm · score · falhas. (Este arquivo é versionado — é a evidência do teste.)

---

### Task 7: Deploy

**Files:**
- Modify: `CURATION.md` (linha da skill → `sim`)
- Modify: `README.md` (lista de conteúdo versionado)
- Modify: `tests/retrospectiva-test.sh`? não. Add: `tests/validate-repo-test.sh` inalterado.

- [ ] **Step 1: Marcar na curadoria**

Em `CURATION.md`, adicione `| consolidar-handoffs | própria | sim |` (ordem alfabética perto de `compress`/`context-engineering`).
Em `README.md`, adicione `- \`consolidar-handoffs\`` à lista de conteúdo versionado.

- [ ] **Step 2: Validar**

Run: `bash scripts/validate-repo.sh && bash tests/consolidar-handoffs/check.test.sh`
Expected: `0 errors`; `check.test.sh: pass`.

- [ ] **Step 3: Expor no runtime**

```bash
cp -r .agents/skills/consolidar-handoffs ~/.agents/skills/
```

- [ ] **Step 4: Commit e push**

```bash
git add .agents/skills/consolidar-handoffs CURATION.md README.md tests/consolidar-handoffs docs/superpowers
git commit -m "feat(consolidar-handoffs): skill de consolidacao de multiplos handoffs

TDD: RED baseline -> skill -> GREEN 9/9 -> REFACTOR.
Evidencia em tests/consolidar-handoffs/SCORE.md."
git push origin main
```

---

## Self-Review

**1. Spec coverage:** igualdade → Task 4 invariante 1 + check `P2/Q2`; resolução vence → invariante 3 + `P1/P5/Q1/P3`; correlação → invariante 4 + `srclib`; redundância → invariante 6 + `duplicata`; provenance → invariante 2 + `ses_*`; conflito → invariante 5 + seção Conflitos. TDD → Tasks 3/5/6. Deploy → Task 7. **Sem lacunas.**

**2. Placeholder scan:** nenhum "TBD/TODO"; todos os arquivos têm conteúdo real.

**3. Type consistency:** os ids `P1..P5`, `Q1..Q3` são idênticos nas fixtures, no ground-truth e no `check.mjs`. `check.mjs` é chamado igual em Tasks 2/5.

**4. Review Focus:** (1) mesma pendência com palavras diferentes → fixture P2 vs descrição; (2) resolução posterior → P3/P5; (3) conflito → seção Conflitos (fixture não tem conflito real; o scorer não testa conflito — **nota:** adicionar conflito à fixture é a próxima iteração, registrada como pendência); (4) causa raiz comum → srclib; (5) não perder o fim → igualdade.

> Nota de cobertura: a fixture atual não contém um item em **conflito de status** real. O critério `Conflitos` da skill fica sem teste direto. Registrar pendência e cobrir na iteração 2 (adicionar `P6` com status contraditório entre `ses_aaa2` e `ses_bbb2`).
