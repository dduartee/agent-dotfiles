# Fontes externas e componentes não vendorizados

Este repo versiona apenas conteúdo próprio ou derivado explicitamente aprovado em `CURATION.md`. Packs externos continuam instalados/gerenciados na máquina e são registrados aqui para reprodução.

## Política

- `bootstrap.sh` não instala packs externos e não copia `~/.agents` inteiro.
- `~/.agents/skills` é source de compatibilidade; `~/.config/opencode/skills` e `~/.claude/skills` são sources de fallback para skills locais ainda não migradas.
- `CURATION.md` é allowlist de conteúdo versionado. `sim` exige source local; `não` mantém dependência fora.
- Atualizar um pack exige atualizar sua origem, preservar atribuição/licença e revisar diff; não fazer `git add -A` cegamente.
- Secrets, tokens, paths de conta e estado de runtime não entram neste arquivo.

## Inventário de origem

| Fonte | Skills/uso | Licença/proveniência | Atualização |
|---|---|---|---|
| `obra/superpowers` | `brainstorming`, visual-companion e skills de processo | MIT; plugin OpenCode | Fixar tag/commit no cache; config local declara plugin |
| `mattpocock/skills` | `ask-matt`, `handoff`, `writing-for-agents`, `tdd`, `to-spec`, `to-tickets` e outras de engenharia | Upstream público; confirmar `LICENSE` por commit antes de redistribuir | Usar instalador do pack; `~/.agents/.skill-lock.json` é lock local |
| `JuliusBrussee/caveman` | `caveman*`, `compress` e `caveman-commit` | Upstream público; confirmar `LICENSE` por commit | Atualizar pelo instalador; não copiar para repo |
| `addyosmani/agent-skills` | `doubt-driven-development` | MIT; `skills/doubt-driven-development/` | Clone/symlink do diretório completo; preservar `references/` e `agents/` |
| `vercel-labs/skills` + `vercel-labs/agent-skills` | `find-skills`, `vercel-react-best-practices`, `web-design-guidelines` | Upstream público; confirmar licença por commit | Reinstalar pelo pack; manter em `~/.agents/skills` |
| `ayghri/i-have-adhd` | Vendor de output ADHD | MIT; commit de referência `839872f` | `git pull` no checkout; symlink por diretório |
| `terminal-browser` | Skill do app local | Código do app local | Atualizar junto com app; symlink por diretório |
| `dduartee/mind` | MCP, protocolo e `mind-management` gerado | MIT; source canônica no projeto Mind | `mind setup opencode`/refresh; nunca vendorizar `mind-management` aqui |
| `hesreallyhim/awesome-claude-code-output-styles` + `smixs` | Origem dos estilos adapted/ported | MIT; créditos devem acompanhar cada arquivo | Diff manual; não há sync automático |
| `github/awesome-copilot` | Skill Chrome DevTools local; cópia derivada, API desatualizada | MIT; reconciliar antes de promover | `defer`; atualizar para `isolatedContext` e remover overlap |
| `nenhum upstream` | `generating-exams` | Própria; licença local não declarada | Alterar somente neste repo |
| `origem local` | `retrospectiva`, `spec-driven-harness` | Própria/derivada; atribuição registrada em `docs/curation-evidence.md` | Alterar neste repo; dependências declaradas no README |

## Comandos de referência

### Superpowers

```json
{
  "plugin": ["superpowers@git+https://github.com/obra/superpowers.git"]
}
```

A tag/commit deve ser fixado no cache local quando a versão for promovida. O bootstrap não faz esse refresh.

### Addy Osmani

```bash
mkdir -p ~/.local/share/agent-packs ~/.agents/skills
git clone --depth 1 https://github.com/addyosmani/agent-skills \
  ~/.local/share/agent-packs/addyosmani-agent-skills
ln -sfn ~/.local/share/agent-packs/addyosmani-agent-skills/skills/doubt-driven-development \
  ~/.agents/skills/doubt-driven-development
```

Atualizar: `git -C ~/.local/share/agent-packs/addyosmani-agent-skills pull --ff-only`.
O symlink preserva referências relativas do pack.

### i-have-adhd

```bash
git clone --depth 1 https://github.com/ayghri/i-have-adhd \
  ~/.local/share/opencode/vendor/i-have-adhd
ln -sfn ~/.local/share/opencode/vendor/i-have-adhd/skills/i-have-adhd \
  ~/.agents/skills/i-have-adhd
```

Atualizar: `git -C ~/.local/share/opencode/vendor/i-have-adhd pull --ff-only`.
O commit de referência atual é `839872f`; trocar versão exige revisar regras de output.

### Mind

```bash
git clone --depth 1 https://github.com/dduartee/mind.git ~/.local/share/mind
cd ~/.local/share/mind
bun install
./mind setup opencode
```

`mind setup` pode gerenciar `mind-management` e `mind-automation.js`; tratar ambos como componentes gerados. Não linkar o skill gerado para dentro deste repo.

### Others

- `github/awesome-copilot` — skill Chrome DevTools: cópia local é derivada, não canônica. Fonte: <https://github.com/github/awesome-copilot/blob/main/skills/chrome-devtools/SKILL.md>. Não importar até atualizar API (`isolatedContext`) e resolver overlap.
- `JuliusBrussee/caveman`, `mattpocock/skills` e `vercel-labs/*`: usar instalador oficial e manter `.skill-lock.json`/commit como provenance.
- `terminal-browser`: atualizar app local; não há comando de instalação neste repo.
- `estilo-*`: comparar upstream manualmente; alterações de comportamento exigem pressure-test antes de promover.

## Limites conhecidos

- `opencode.json` é base portátil (sem paths de máquina nem IP local); a config real (MCPs, tokens, paths) fica fora do repo e exige merge manual.
- `chrome-devtools-agent` depende do MCP Chrome DevTools instalado.
- `retrospectiva` descobre o OpenCode em runtime (`opencode debug paths`, `opencode session export`) e cai para SQLite (`session_message`) quando o export não existe. Helpers `sessao.sh` (POSIX) e `sessao.ps1` (Windows); o PS foi validado em PowerShell 7.4.6 (parse + execução); o Windows PowerShell 5.1 não foi testado.
- `spec-driven-harness` é conteúdo local; não possui upstream declarado.
- O lock de skills cobre parte do ambiente; não substitui um SBOM/licença por skill.

## Regra de mudança

1. Atualizar fonte/commit.
2. Rodar testes/pressure-test do componente.
3. Atualizar esta tabela e `CURATION.md` somente se a decisão de ownership mudou.
4. Rodar `bash scripts/validate-repo.sh` e revisar `git diff`.
