# agent-dotfiles

Fonte da verdade privada para skills e configuração pessoal de agentes. Repo espelha caminhos gerenciados de `$HOME`; não tenta transformar toda configuração local em dotfiles.

## Escopo real

- **Shared skills:** `.agents/skills/<skill>/SKILL.md`, com allowlist em `CURATION.md`.
- **Adaptador OpenCode:** `.config/opencode/{AGENTS.md,instructions,plugins}` e base sanitizada de `opencode.json`.
- **Externos:** packs, vendor e MCPs continuam instalados na máquina; `sources.md` registra origem e update.
- **Harness-agnostic é qualificado:** skills têm paths cross-runtime; config/plugins OpenCode são adapter-specific. Não prometer que um comando instala qualquer MCP/binário externo.

## Layout

```text
.config/opencode/
  opencode.json            # base sanitizada; nunca editada pela máquina via link
  AGENTS.md
  plugins/*.js             # harness OpenCode v2
  instructions/*.md
.agents/skills/<skill>/SKILL.md
bootstrap.sh               # link | sync
CURATION.md                # allowlist e decisões de ownership
sources.md                 # terceiros, vendor e dependências locais
scripts/validate-repo.sh   # guardas locais
.githooks/pre-commit       # hook opt-in
```

## Uso

```bash
./bootstrap.sh sync                 # $HOME -> repo; falha se source sim ausente
DRY_RUN=1 ./bootstrap.sh link        # prévia repo -> $HOME
./bootstrap.sh link                  # só caminhos gerenciados; não move arquivos
FORCE=1 ./bootstrap.sh link           # move existente para .prelink.bak
bash scripts/validate-repo.sh
```

Fluxo de curadoria:

```text
CURATION.md -> bootstrap sync -> revisar git diff -> testes/validator -> commit
```

`sync` lê `~/.agents/skills`, `~/.config/opencode/skills` e `~/.claude/skills` nessa ordem para skills marcadas. `link` não instala packs externos, não instala `opencode.json` e não deve tocar arquivos locais sem `FORCE=1`.

## Conteúdo versionado

Allowlist atual inclui:

- `retrospectiva` — cross-platform (Linux/macOS/Windows); descobre o OpenCode em runtime
- `consolidar-handoffs` — junta N handoffs em 1 consolidado correlacionado, sem perder pendência
- `generating-exams`
- `spec-driven-harness`
- sete `estilo-*` adapted/ported, com atribuição em `sources.md`

Decisão `defer`: `chrome-devtools-agent` deriva de `github/awesome-copilot` e precisa de reconciliação de API antes de entrar.

`mind-management` não é vendorizado: é gerado pelo projeto Mind. `doubt-driven-development`, `i-have-adhd`, `terminal-browser`, Superpowers e demais packs externos ficam em `sources.md`.

## OpenCode/MCP

`.config/opencode/opencode.json` no repo é base sem segredo e não é instalado por `link`. A máquina pode conter MCPs, tokens, paths e modelos locais. Em máquina nova, revisar e mesclar manualmente a base; nunca copiar arquivo local para dentro do repo.

Plugins locais versionados:

- `pontas-soltas.js` — storage append-only por projeto, tool e hooks `context`/`compaction`.
- `backlog.js` — injeta allowlist do backlog compartilhado.
- `sessao-atual.js` — injeta id de sessão.
- `mind-automation.js` — componente gerenciado/read-only; `mind setup` pode regenerá-lo. Tratar como derived, não como fonte autoritativa do Mind.

## Segurança e manutenção

- `CURATION.md` é allowlist estrita. `sim` exige `SKILL.md` disponível; `não` impede cópia de terceiros.
- `.gitignore` bloqueia segredos, keys, tokens e estado; validador faz scan adicional.
- Rodar `./scripts/validate-repo.sh` antes de commit.
- Ativar hook local somente com:

```bash
git config core.hooksPath .githooks
```

- `mind-management` e `mind-automation.js` têm ownership externo; evitar symlink para output gerado.
- `retrospectiva` descobre o OpenCode em runtime (`opencode debug paths` + `opencode session export`), com fallback SQLite (`session_message`). Helpers: `sessao.sh` (Linux/macOS/WSL/Git Bash, requer `jq`) e `sessao.ps1` (Windows, PowerShell 5.1+).
- `opencode.json` é base portátil (sem paths de máquina nem IP local); MCPs, tokens e paths reais ficam fora do repo e exigem merge manual.

## Para agentes

Se você encontrou dificuldade de reprodução ou **falta de generalização do workspace** (path fixo, suposição de Linux, setup não documentado), **abra um Pull Request**. Regras e portabilidade por SO: [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Referências

- Objetivo: [`docs/objective.md`](docs/objective.md)
- Evidência de curadoria: [`docs/curation-evidence.md`](docs/curation-evidence.md)
- Atribuições: [`docs/ATTRIBUTIONS.md`](docs/ATTRIBUTIONS.md)
- Fontes externas: [`sources.md`](sources.md)
- Ecossistema (repos de skills para complementar): [`docs/ecosystem.md`](docs/ecosystem.md)
- OpenCode v2 skills: <https://opencode.ai/v2/docs/skills/>
- Repositório: <https://github.com/dduartee/agent-dotfiles> (privado)
