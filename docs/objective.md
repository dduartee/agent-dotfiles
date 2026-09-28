# Objetivo — agent-dotfiles

> Documento de visão do repositório. Consolida o objetivo das **skills próprias** e
> do **harness de memória e revisão** (retrospectiva, pontas soltas, backlog, mind).
> Revisado em 2026-09-28. Ground truth do "hoje" = o conteúdo real deste repo.

## 1. Propósito

Uma **fonte da verdade única, portável e sem segredos** para a configuração dos meus
agentes de código — skills, plugins/harness, instruções e base de MCP — reproduzível
numa máquina nova com um comando, **harness-agnostic** onde der (skills), e
**adapter-specific** onde precisa (config/plugins do OpenCode).

## 2. Princípios

1. **Dotfiles.** O repo espelha caminhos gerenciados de `$HOME`; `bootstrap.sh link`
   symlinka de volta, `bootstrap.sh sync` faz snapshot. Editar aqui = valer no harness.
2. **Harness-agnostic qualificado.** Skills flat (`<skill>/SKILL.md`) expostas por
   `~/.agents/skills` (alias cross-runtime). Config/plugins do OpenCode são adapter.
3. **Próprias versionadas; terceiros documentados.** Só o meu conteúdo entra;
   packs de terceiros vão em `sources.md` (origem + update), nunca vendorizados.
4. **Segredos nunca entram.** `.gitignore` + scan do validador; `opencode.json` é
   base portátil; MCPs/tokens/paths reais ficam fora do repo (merge manual).
5. **Sem cópia divergente.** `sync` puxa o vivo; `link` restaura. Nada editado em dois lugares.
6. **Guardrail de máquina.** `scripts/validate-repo.sh` + `.githooks/pre-commit`
   barram sintaxe, JSON inválido, credencial, symlink e placeholder antes do commit.

## 3. Camadas contempladas

### A. Skills próprias
`retrospectiva` · `generating-exams` · `spec-driven-harness` ·
`estilo-{ajudante-haicai,conciso,evangelista-tecnico,jornalista-tabloid,mestre-zen,poeta-existencialista,vendedor-de-vim}`.

### B. Harness de memória e revisão
- **`retrospectiva`** — fecha a sessão e auto-revisa o ambiente. Ground truth =
  sessão real do OpenCode, re-consultada em runtime. **Cross-platform**: descobre o
  OpenCode (`opencode debug paths`), extrai via `opencode session export` (Linux,
  macOS, Windows) com fallback SQLite; helpers `sessao.sh` (POSIX) e `sessao.ps1` (Windows).
- **`pontas_soltas`** (`pontas-soltas.js`) — pontas soltas do **projeto** (raiz git),
  append-only, tool + hooks `context`/`compaction`.
- **`backlog`** (`backlog.js` + `pendentes.md`) — ideias/pendências do usuário, injetadas todo turno.
- **`sessao-atual`** (`sessao-atual.js`) — id da sessão no contexto (base da retrospectiva).
- **`mind`** (MCP externo) — memória de longo prazo; versionamos só o protocolo e a base.

### C. Externos (documentados, não copiados)
Superpowers, `addyosmani/agent-skills`, `ayghri/i-have-adhd`, `terminal-browser`,
MCPs (`chrome-devtools`, `playwright`, `exa`, `mind`) — ver `sources.md`.

## 4. Alvo — capacidades do "ideal"

1. **Reprodutível:** clone + `bootstrap.sh link` numa máquina limpa deixa skills e
   config iguais (fora o merge manual do `opencode.json`).
2. **Sem segredo no histórico:** scan automático provando (0 forma-de-credencial).
3. **Portátil de verdade:** nenhum path absoluto de máquina no conteúdo versionado.
4. **Harness versionado como código**, com testes (`tests/`) e validador.
5. **Promoção de learnings:** o que a `retrospectiva` descobre recorrente vira
   regra/skill **no repo**.
6. **Cross-platform:** o harness roda em Linux, macOS e Windows (OpenCode).

## 5. Não-objetivos

- Vendorizar terceiros (vão por `sources.md`).
- Guardar segredos ou estado de runtime (`*state*.json`, `.env`, backups).
- Ser multi-usuário/time ou sincronizar máquinas automaticamente.
- Duplicar a memória de longo prazo do `mind`.

## 6. Estado atual

- Repo privado `dduartee/agent-dotfiles` (`main`), layout dotfiles, allowlist em `CURATION.md`.
- `bootstrap.sh link|sync` (falha fechado; não toca `opencode.json`).
- Skills próprias versionadas (retrospectiva, generating-exams, spec-driven-harness, 7 `estilo-*`).
- Harness: plugins + `sessao-atual` + `backlog` + `pontas-soltas`.
- `scripts/validate-repo.sh` + `.githooks/pre-commit` + `tests/`.
- `docs/{objective,curation-evidence,ATTRIBUTIONS}.md` + `sources.md`.

## 7. Roadmap

- **Fase 1:** fechar curadoria pendente; testar `validate-repo.sh`/testes no CI local.
- **Fase 2:** guardrails adicionais (link integrity, pin de versões de MCP).
- **Fase 3:** promoção de learnings da `retrospectiva` v3 (auditoria de retros + friction ranking).

## 8. Critérios de aceite

- Clone + `bootstrap.sh link` reproduz skills + config (fora merge do `opencode.json`).
- 0 forma-de-credencial no conteúdo; 0 path absoluto de máquina no versionado.
- Todas as skills próprias versionadas; terceiros só em `sources.md`.
- `retrospectiva` funcional em Linux/macOS/Windows.
