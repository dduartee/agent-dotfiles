# Agent Dotfiles Curation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fechar curadoria de skills, alinhar `agent-dotfiles` ao objetivo final e deixar clone, sync, validação e documentação reproduzíveis sem segredos nem vendorização de terceiros.

**Architecture:** `CURATION.md` será manifesto explícito de decisão. `bootstrap.sh sync` importará somente skills marcadas e `link` restaurará arquivos versionados sem tocar no `opencode.json` local. Um validador separado verificará sintaxe, JSON, curadoria, symlinks, ausência de segredos e reproducibility em `HOME` temporário; documentação explicará o que é portátil e o que exige merge manual.

**Tech Stack:** Bash, Node.js (`node --check`/JSON), Markdown, symlinks POSIX, Git hooks locais.

**Spec:** `/tmp/opencode/agent-dotfiles-objetivo-final.md`

## Global Constraints

- Incluir apenas skills próprias; packs de terceiros permanecem em `sources.md`.
- Nunca versionar segredos, `.env`, tokens, chaves, estado de runtime ou backups.
- Preservar `opencode.json` da máquina; merge permanece manual.
- Não vendorizar `obra/superpowers`, `addyosmani/agent-skills`, `ayghri/i-have-adhd` ou `terminal-browser`.
- Não afirmar portabilidade de código ausente do repo; qualificar paths absolutos e dependências locais.
- Toda decisão de curadoria precisa de evidência: autoria/licença, overlap, valor observado ou dependência.
- Toda pendência não resolvida deve aparecer em `~/.config/opencode/pendentes.md` e/ou `pontas_soltas`.

## Review Focus

1. Skill marcada `sim` mas ausente do diretório de origem — sync deve reportar e falhar explicitamente.
2. Skill sem `sim` sendo vendorizada — sync não deve copiá-la.
3. `HOME` temporário contaminado por `opencode.json`, token ou paths da máquina — link/sync não deve tocar nem vazar config local.
4. Symlink quebrado ou link de arquivo apresentado como link de diretório — validação deve detectar e documentação deve refletir o comportamento real.
5. Mudança de conteúdo local sem revisão — validação deve exigir diff explícito antes de commit.

---

### Task 1: Coleta de evidência e matriz de curadoria

**Files:**
- Create: `docs/curation-evidence.md`
- Read: `/tmp/opencode/agent-dotfiles-objetivo-final.md`
- Read: `/home/gabrielkduarte/Projects/opencode-prompt-analysis/{README.md,analyses/final-report.md,data/*.jsonl}`
- Read: `CURATION.md`, `sources.md`, `README.md`

**Interfaces:**
- Produces: matriz por skill com `include`, `source`, `rationale`, `overlap`, `license`, `portability`, `evidence`.

- [ ] **Step 1: Exportar resumo do projeto de análise sem alterar o projeto**

Run:

```bash
cd /home/gabrielkduarte/Projects/opencode-prompt-analysis
python3 scripts/export_opencode_user_messages.py --summary
```

Expected: resumo com fonte, datas, sessões e mensagens; nenhum arquivo em `agent-dotfiles` alterado.

- [ ] **Step 2: Minerar padrões de uso**

Buscar termos `retro`, `handoff`, `test`, `security`, `context`, `concis`, `ADHD`, `mind`, `dotfiles` e `skill` nos JSONL. Registrar somente padrões repetidos ou evidência forte; separar contagem de exemplos anonimizados.

- [ ] **Step 3: Auditar origem e status de cada skill candidata**

Para cada `sim` atual e cada decisão aberta (`chrome-devtools-agent`, `mind-management`), registrar path local, symlink/cópia, upstream, licença e overlap. Não incluir segredo nem valor de token no documento.

- [ ] **Step 4: Escrever `docs/curation-evidence.md`**

Usar tabela com colunas: `skill`, `decisão`, `autoria`, `upstream/licença`, `evidência de uso`, `overlap`, `portabilidade`, `ação`. Registrar a regra: “sem evidência suficiente = `defer`, não `sim` implícito”.

- [ ] **Step 5: Validar documento**

Run:

```bash
rg -n 'TBD|TODO|<[^>]+>' docs/curation-evidence.md || true
git diff --check -- docs/curation-evidence.md
```

Expected: nenhum placeholder; nenhum erro de whitespace.

### Task 2: Corrigir curadoria e contrato do bootstrap

**Files:**
- Modify: `CURATION.md:1-93`
- Modify: `bootstrap.sh:1-59`
- Test: `tests/bootstrap-test.sh`

**Interfaces:**
- `bootstrap.sh sync`: importa exatamente linhas com `incluir=sim`; falha com mensagem clara se source não existir.
- `bootstrap.sh link`: symlinka arquivos versionados exceto `opencode.json`; não instala packs externos.
- `bootstrap-test.sh`: roda em `HOME` temporário e retorna 0 somente quando todos os checks passam.

- [ ] **Step 1: Escrever teste RED para curadoria e sync**

Criar fixture com uma skill `sim` presente, uma skill `sim` ausente, uma skill não marcada presente e `opencode.json` fora do conjunto sincronizado.

Expected: implementação atual falha ao não distinguir source ausente ou ao tratar arquivo como diretório.

- [ ] **Step 2: Rodar teste RED**

Run:

```bash
bash tests/bootstrap-test.sh
```

Expected: FAIL com pelo menos uma asserção sobre o contrato novo.

- [ ] **Step 3: Implementar parser e mensagens fail-fast em `bootstrap.sh`**

Manter Bash existente; validar coluna `incluir` com regex, reportar `skill source ausente: <nome>` e sair 1 antes de anunciar snapshot completo. Preservar `opencode.json` na exclusão e não copiar skills não marcadas.

- [ ] **Step 4: Rodar teste GREEN**

Run:

```bash
bash tests/bootstrap-test.sh
```

Expected: PASS; fixture não contém skill não marcada e `opencode.json` permanece intacto.

- [ ] **Step 5: Validar shell**

Run:

```bash
bash -n bootstrap.sh tests/bootstrap-test.sh
```

Expected: exit 0.

### Task 3: Importar skills próprias e versionar fontes externas

**Files:**
- Modify: `CURATION.md`
- Create/update: `.agents/skills/<própria>/SKILL.md` via `bootstrap.sh sync`
- Modify: `sources.md`
- Modify: `README.md`

**Interfaces:**
- `CURATION.md` será a única decisão de inclusão.
- `sources.md` será a única fonte de instalação/update de terceiros.
- README distinguirá skills próprias, vendor externo e dependências locais.

- [ ] **Step 1: Aplicar decisões de `docs/curation-evidence.md`**

Marcar `sim` apenas para skills próprias confirmadas. Para `chrome-devtools-agent` e `mind-management`, usar `sim`, `não` ou `defer` conforme evidência; não deixar decisão implícita.

- [ ] **Step 2: Rodar sync no repo real**

Run:

```bash
cd /home/gabrielkduarte/agent-dotfiles
bash bootstrap.sh sync
git status --short
git diff --stat
```

Expected: somente skills marcadas e arquivos gerenciados explicitamente aparecem no diff; revisar antes de stage.

- [ ] **Step 3: Corrigir `sources.md`**

Remover paths absolutos específicos da máquina, documentar dependências locais, registrar versões/commits quando existirem e declarar que packs externos não são instalados por `bootstrap.sh`.

- [ ] **Step 4: Corrigir README e objetivo operacional**

Adicionar estado atual, escopo real, comando de validação, limite de portabilidade, regra de segredo e relação `CURATION → sync → commit`.

### Task 4: Adicionar guardas de integridade e documentação de uso

**Files:**
- Create: `scripts/validate-repo.sh`
- Create: `.githooks/pre-commit`
- Modify: `README.md`
- Modify: `bootstrap.sh`
- Test: `tests/validate-repo-test.sh`

**Interfaces:**
- `scripts/validate-repo.sh`: retorna 0 somente se sintaxe, JSON, CURATION, links e secret scan passarem.
- `.githooks/pre-commit`: executa validador e bloqueia commit em erro.

- [ ] **Step 1: Escrever testes RED do validador**

Criar fixture com JS inválido, JSON inválido, forma de token e link quebrado. Expected: validador deve falhar em cada caso.

- [ ] **Step 2: Implementar validador mínimo**

Executar `node --check` nos `.js`, `node -e 'JSON.parse(...)'` no `opencode.json`, shell syntax, contagem de `sim`/skills presentes, scan de formas de credencial e check de symlinks. Não imprimir valores encontrados; imprimir path e classe do padrão.

- [ ] **Step 3: Adicionar hook e instruções de ativação**

Adicionar `.githooks/pre-commit` executável e README com `git config core.hooksPath .githooks`; não alterar hooks do usuário sem instrução explícita.

- [ ] **Step 4: Rodar testes GREEN e validação real**

Run:

```bash
bash tests/validate-repo-test.sh
bash scripts/validate-repo.sh
```

Expected: ambos exit 0 no repo real.

### Task 5: Revisão em loop e fechamento

**Files:**
- Modify: `docs/curation-evidence.md`, `CURATION.md`, `README.md`, `sources.md`, scripts/tests conforme findings
- Create/update: `~/.config/opencode/pendentes.md` somente para pendências reais

- [ ] **Step 1: Loop local de consistência**

Rodar `git diff --check`, `bash -n`, testes, `node --check`, JSON parse, secret scan e comparar `CURATION` contra filesystem.

- [ ] **Step 2: Revisão adversarial fresh-context**

Pedir ao revisor que procure: claim de portabilidade sem asset, sync que perde arquivos, hook que não executa, vendorização não intencional, segredo em histórico, docs que mentem sobre estado.

- [ ] **Step 3: Registrar pendências não resolvidas**

Para cada finding que não puder ser fechado nesta execução, chamar `pontas_soltas(action=add)` antes de adiar; mover para `pendentes.md` se for ideia/pendência do usuário.

- [ ] **Step 4: Repetir até nenhuma finding substantivo novo ou limite de três loops**

Executar no máximo três rodadas de revisão; após a terceira, reportar findings restantes sem grind.

- [ ] **Step 5: Verificação final e relatório**

Rodar comandos completos, mostrar HEAD/status, listar skills incluídas, reportar loops e findings restantes. Só declarar concluído com evidência fresca.
