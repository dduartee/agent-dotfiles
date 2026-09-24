# agent-dotfiles

> **Configuração pessoal de agentes de código**, tratada como **dotfiles**: o
> repo espelha o `$HOME` e um `bootstrap.sh` linka de volta. Skills, plugins/
> tools, instruções e base de MCP — **harness-agnostic**.

Feito sob medida para as minhas máquinas. Publicado (privado) para referência e
backup. Peça ao teu próprio LLM para escrever a config das tuas necessidades.

## Layout (espelho do `$HOME`)

```
.config/opencode/
  opencode.json            # base SANITIZADA (sem segredos)
  AGENTS.md
  plugins/*.js             # plugins/tools (OpenCode v2)
  instructions/*.md
.agents/skills/<skill>/SKILL.md   # skills (flat, dir por skill)
bootstrap.sh               # link | sync
CURATION.md                # triagem de skills
```

## Uso

```bash
./bootstrap.sh link     # máquina nova: repo -> $HOME (backup .prelink.bak)
./bootstrap.sh sync     # esta máquina: $HOME -> repo (snapshot; revise com git diff)
DRY_RUN=1 ./bootstrap.sh link   # prévia
```

## Consumidores (skills)

`~/.agents/skills` é o alias cross-runtime. Os harnesses linkam **por skill**:

| Harness | Skills directory |
| --- | --- |
| shared (cross-runtime) | `~/.agents/skills` |
| OpenCode v2 | `~/.config/opencode/skills` |
| Claude Code | `~/.claude/skills` |
| Codex | `~/.codex/skills` |

## Deliberadamente FORA do repo

- **`opencode.json` da máquina** — tem MCP/token local (`daily-digest`); a
  versão daqui é **base**. `bootstrap.sh` **não** toca nele → merge manual.
- **Estado local** — `.mind-automation-state.json`, `*.bak`, `.caveman-active`.
- **Pessoal** — `pendentes.md`, `docs/`.
- **Vendor de terceiros** — ver inventário abaixo; não copiar para cá.

## Componentes externos (origem GitHub + atualização)

| Componente | Origem (GitHub) | Onde vive | Atualizar |
| --- | --- | --- | --- |
| superpowers (`brainstorming` + visual-companion, ...) | [obra/superpowers](https://github.com/obra/superpowers) — MIT, v6.4.1 | plugin OpenCode `superpowers@git+https://github.com/obra/superpowers.git` → `~/.cache/opencode/npm/…` | reinstalar o plugin |
| doubt-driven-development | [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) — MIT (`skills/doubt-driven-development/`) | copiada em `~/.agents/skills/` | re-baixar do pack |
| i-have-adhd | [ayghri/i-have-adhd](https://github.com/ayghri/i-have-adhd) — MIT | `~/.local/share/opencode/vendor/i-have-adhd` (symlink em `~/.agents/skills/`) | `git pull` |
| terminal-browser | app local | `~/.local/share/terminal-browser` | atualizar o app |
| vozes de output (`estilo-*`) | [hesreallyhim/awesome-claude-code-output-styles](https://github.com/hesreallyhim/awesome-claude-code-output-styles) + smixs | **portadas** → neste repo | diff manual |
| generating-exams | **sem upstream público** (local) | **neste repo**, `.agents/skills/` | — |

**Favoritas em uso:** `doubt-driven-development` · `brainstorming` (+ visual-companion)
· `i-have-adhd` · `generating-exams` (própria, versionada).

## Rules

`.gitignore` bloqueia forma-de-credencial (`.env`, `*.key`, `*token*`,
`*secret*`), estado local (`*state*.json`, `*.bak`) e ruído. Mesmo privado,
segredo não entra: a base `opencode.json` é sanitizada.
