# my-agents

> **Configuração pessoal de agentes** — feita sob medida para as minhas
> máquinas, assinaturas e fluxo. Publicada (privada) para referência e backup.
> Trate como exemplo: peça ao teu próprio LLM para escrever a config das tuas
> necessidades. Evite reusar skills de terceiros verbatim — elas carregam
> pressupostos, paths e layout de credenciais de outra pessoa.

Repositório mestre único: **skills, plugins/tools, instruções e base de MCP**,
compartilhados entre os CLIs de agente desta máquina. O diretório `skills/` de
cada harness continua um **diretório real** cujas entradas são **symlinks por
skill** para cá — uma edição aqui alcança todos.

## Layout

**Flat:** um diretório por skill na raiz, cada um com `SKILL.md`.
Config de harness fica em `opencode/`.

```
<skill-1>/SKILL.md
<skill-2>/SKILL.md
opencode/
  plugins/            # plugins/tools (OpenCode v2)
  instructions/       # instruções modulares
  opencode.json       # base sanitizada (SEM segredos)
AGENTS.md
install.sh            # máquina nova: symlinks por skill
sync.sh               # esta máquina: snapshot vivo -> repo
CURATION.md           # triagem de skills (o que entra/sai)
```

## Consumers

| Harness | Skills directory | Como linka |
| --- | --- | --- |
| OpenCode v2 | `~/.config/opencode/skills` | dir real: symlinks por skill |
| Claude Code | `~/.claude/skills` | symlinks por skill |
| Codex | `~/.codex/skills` | symlinks por skill |
| shared (cross-runtime) | `~/.agents/skills` | symlinks por skill |

Symlink **por skill** (não o diretório inteiro): cada dir de harness também
guarda entradas que **não** vivem aqui.

## Deliberadamente FORA deste repo

- **Segredos / MCP com token** — `opencode.json` daqui é **base**; o MCP
  `daily-digest` (com `DIGEST_API_TOKEN` literal) fica **só na máquina**.
- **Estado local** — `.mind-automation-state.json`, `*.bak`, `.caveman-active`.
- **Pessoal** — `pendentes.md`, `docs/`.
- **Vendor de terceiros** — ver inventário abaixo; não copiar para cá.

## Componentes externos (inventário + atualização)

| Componente | Fonte | Onde vive | Atualizar |
| --- | --- | --- | --- |
| superpowers | git/npm (plugin OpenCode) | `~/.cache/opencode/npm/...` | reinstalar plugin |
| i-have-adhd | [ayghri/i-have-adhd](https://github.com/ayghri/i-have-adhd) | `~/.local/share/opencode/vendor/i-have-adhd` | `git pull` no vendor |
| terminal-browser | app local | `~/.local/share/terminal-browser` | atualizar o app |
| vozes de output (`estilo-*`) | [hesreallyhim/awesome-claude-code-output-styles](https://github.com/hesreallyhim/awesome-claude-code-output-styles) + smixs | **portadas** → neste repo | diff manual quando mudar |

## Rules

`.gitignore` bloqueia forma-de-credencial (`.env`, `*.key`, `*token*`,
`*secret*`), estado local (`*state*.json`, `*.bak`) e ruído. Mesmo privado,
segredo não entra: o `opencode.json` versionado é sanitizado.
