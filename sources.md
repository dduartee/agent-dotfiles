# Fontes externas — instalação reproduzível

Packs ficam em `~/.local/share/agent-packs` (clone) e são expostos por **symlink
do diretório da skill** em `~/.agents/skills/` — não cópia. Isso preserva os
caminhos relativos internos do pack (ex.: `SKILL.md` usa `../../references/`).

## superpowers — `brainstorming` (+ visual-companion)

Plugin do OpenCode. Em `~/.config/opencode/opencode.json`:

```json
{ "plugin": ["superpowers@git+https://github.com/obra/superpowers.git"] }
```

Instala no cache ao iniciar/recarregar. Reparar cache:
`rm -rf ~/.cache/opencode/npm/git-superpowers-*` e reiniciar.

## addyosmani/agent-skills — `doubt-driven-development`

```bash
mkdir -p ~/.local/share/agent-packs ~/.agents/skills
git clone --depth 1 https://github.com/addyosmani/agent-skills \
  ~/.local/share/agent-packs/addyosmani-agent-skills
ln -sfn ~/.local/share/agent-packs/addyosmani-agent-skills/skills/doubt-driven-development \
  ~/.agents/skills/doubt-driven-development
```

Atualizar: `git -C ~/.local/share/agent-packs/addyosmani-agent-skills pull`.
(O pack traz `references/` e `agents/` usados pela skill — por isso symlink do dir, não cópia solta.)

## ayghri/i-have-adhd

```bash
git clone --depth 1 https://github.com/ayghri/i-have-adhd \
  ~/.local/share/opencode/vendor/i-have-adhd
ln -sfn ~/.local/share/opencode/vendor/i-have-adhd/skills/i-have-adhd \
  ~/.agents/skills/i-have-adhd
```

Atualizar: `git -C ~/.local/share/opencode/vendor/i-have-adhd pull` (commit de referência: `839872f`).

## terminal-browser

Skill do app local em `~/.local/share/terminal-browser` → symlink do dir da skill
em `~/.agents/skills/`. Atualiza junto com o app.

## `estilo-*` (portadas)

Origem: [hesreallyhim/awesome-claude-code-output-styles](https://github.com/hesreallyhim/awesome-claude-code-output-styles)
(+ smixs). **Portadas e versionadas neste repo** — sem sync automático; diff manual quando o upstream mudar.

## `generating-exams`

**Sem upstream público.** Própria, versionada em `.agents/skills/generating-exams/`.

---
Reproduzir tudo numa máquina nova: rodar os blocos acima e depois `./bootstrap.sh link`.
