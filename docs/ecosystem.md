# Ecossistema — repositórios de skills

Lista factual de repositórios públicos que podem **complementar** este repo.
Nenhum é vendorizado aqui: a instalação/aprovação passa por `CURATION.md` e a
origem fica em `sources.md`.

Coleta: 2026-09-28, via GitHub API + READMEs (fonte primária). Metadados podem
mudar; revalidar antes de promover.

## Especificação e formato

| Fonte | URL | Uso |
|---|---|---|
| Agent Skills spec | <https://agentskills.io> | especificação canônica de `SKILL.md`/frontmatter |
| OpenCode skills | <https://opencode.ai/docs/skills> | como o OpenCode descobre skills |

## Catálogos e coleções

| Repo | URL | Licença | Último push | Formato | O que oferece |
|---|---|---|---|---|---|
| anthropics/skills | <https://github.com/anthropics/skills> | README: "many skills Apache 2.0"; sem `LICENSE` de topo | 2026-09-24 | `SKILL.md` + `spec/` + `template/` | skills de documento (docx/pdf/pptx/xlsx) + template oficial |
| VoltAgent/awesome-agent-skills | <https://github.com/VoltAgent/awesome-agent-skills> | MIT | 2026-09-28 | catálogo `SKILL.md`, 1000+, multi-runtime | descoberta por domínio |
| wshobson/agents | <https://github.com/wshobson/agents> | MIT | 2026-09-28 | fonte única → 6 harnesses (inclui OpenCode) | matriz de portabilidade entre harnesses + `plugin-eval`/`make validate` |
| vercel-labs/skills | <https://github.com/vercel-labs/skills> | MIT | 2026-09-18 | CLI `npx skills` (add/find/list/update/init) | tooling de instalação/registro + lockfile |
| sickn33/agentic-awesome-skills | <https://github.com/sickn33/agentic-awesome-skills> | MIT | 2026-09-28 | catálogo gerado (`CATALOG.md`, `skills_index.json`) + CI | índice machine-readable + validação/CI |
| b-mendoza/agent-skills | <https://github.com/b-mendoza/agent-skills> | sem `LICENSE` declarada | 2026-09-20 | `skills/` + `.agents/skills/` + `skills-lock.json` | convenção de lockfile por repo + matriz de portabilidade |
| iTzFaisal/agency-agents | <https://github.com/iTzFaisal/agency-agents> | MIT | 2026-08-09 | `.claude/` + `.agents/skills/` | frontmatter estendido (`license`/`compatibility`/`metadata`) |
| karanb192/awesome-claude-skills | <https://github.com/karanb192/awesome-claude-skills> | MIT | 2026-09-01 | lista curada 50+ `SKILL.md` | descoberta de skills de processo |
| JayRHa/AgentSkills | <https://github.com/JayRHa/AgentSkills> | MIT | 2026-07-28 | `SKILL.md` + `scripts/install-skill.sh` | instalador/catálogo |

## Já usados por este repo

| Repo | URL | Como entra |
|---|---|---|
| obra/superpowers | <https://github.com/obra/superpowers> | plugin em `.config/opencode/opencode.json` |
| addyosmani/agent-skills | <https://github.com/addyosmani/agent-skills> | pack externo (`sources.md`) |
| mattpocock/skills | <https://github.com/mattpocock/skills> | pack externo (`sources.md`) |
| ayghri/i-have-adhd | <https://github.com/ayghri/i-have-adhd> | vendor + symlink (`sources.md`) |
| JuliusBrussee/caveman | <https://github.com/JuliusBrussee/caveman> | pack externo (`sources.md`) |
| vercel-labs/* | <https://github.com/vercel-labs/skills> | pack externo (`sources.md`) |

## Como avaliar um candidato antes de adicionar

1. **Licença** explícita (arquivo `LICENSE`), não só o README.
2. **Formato** compatível (`SKILL.md` flat, frontmatter `name`+`description`).
3. **Atividade** recente (`pushed_at`).
4. **Overlap** com o que já existe (evitar duplicar skill).
5. Se entrar: registrar em `CURATION.md` (`sim`) e em `sources.md` (origem/update);
   **não** copiar vendor para `.agents/skills/` do repo.
