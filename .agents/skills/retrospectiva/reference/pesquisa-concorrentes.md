# Pesquisa — skills de retrospectiva: concorrentes, alternativas e o que adotar

Levantamento em 2026-09-24. Fontes primárias (SKILL.md no GitHub) citadas.
Comparação com a nossa skill local `retrospectiva` (v1).

## 1. Concorrentes diretos

### 1.1 mattpocock/skills — `retro` (o mais influente)

- https://github.com/mattpocock/skills/blob/main/skills/in-progress/retro/SKILL.md · https://www.skills.sh/mattpocock/skills/retro (128,9K installs) · ainda em `skills/in-progress/`.
- Gatilho user-invoked; Passo 1 chama `writing-for-agents`.
- **Escopo: só comportamento/ambiente — NÃO fecha pendências.** 7 categorias: Navigation, Automated checks, Coding standards, Global AGENTS.md, Tool economy, No-ops, Information access.
- Técnicas (quote):
  - `"Default to building the check over writing the rule."` — violação mecânica → linter/pre-commit/CI; só judgement call vai para `CODING_STANDARDS.md`.
  - `"A repo with no guardrail ... is itself a finding: an un-linted repo is a standing missed opportunity, not a neutral default."`
  - `"a check that already exists but sits unwired or silently broken is the finding, not a reinvention."`

### 1.2 TerenceBristol/claude-improve — `/improve` (o mais completo)

- https://github.com/TerenceBristol/claude-improve/blob/main/improve.md (45 KB, v4.0.0)
- 6 fases, 3 escopos. Learnings persistentes que ajustam runs futuros; history scan determinístico com `jq`, removendo `tool_result` (ruído); **auditoria de runs anteriores: Verified Implemented / Drifted / Missing**; coverage statement; confidence (High/Medium/Low); *"Never truncate silently."*
- `"hooks are deterministic enforcement, while CLAUDE.md instructions are probabilistic (~80% compliance)"`.

### 1.3 bokan/claude-skill-self-improvement — `/self-improvement`

- https://github.com/bokan/claude-skill-self-improvement/blob/master/SKILL.md
- Task agents em paralelo (1 por arquivo .jsonl), ranking de **fricção por frequência**, quotes cruas. `"Generalize aggressively. Look for the meta-pattern behind specific issues."` Cross-ref com CLAUDE.md: Already fixed / Still missing. *"Do not apply changes - create the file for user review."*

### 1.4 accidentalrebel/claude-skill-session-retrospective

- https://github.com/accidentalrebel/claude-skill-session-retrospective (SKILL.md + `scripts/get-session.sh`)
- **Arquitetura quase igual à nossa**: script pega o JSONL da sessão, agente parseia `type:user`/`type:assistant`, `tool_result is_error:true` e correções do usuário. Output narrativo; não extrai pendências nem propõe mudança de ambiente.

### 1.5 sionic-ai `/retrospective` (HuggingFace)

- https://huggingface.co/blog/sionic-ai/claude-code-skills-training
- Transforma a sessão em artefato: gera `SKILL.md` + `plugin.json` + `references/` + `scripts/`, branch, commit e **PR**. *"Claude writes the skill while everything is still in context."* A prioridade é documentar falha: *"'I tried X and it broke because Y' turns out to be the most useful sentence in the whole system"* — tabela "Failed Attempts".

### 1.6 boshu2/agentops — `postmortem`

- https://github.com/boshu2/agentops/blob/main/skills/postmortem/SKILL.md
- Rigor causal explícito: `"Treat causal statements as hypotheses until the mechanism is demonstrated."` Promover correlação→causa exige **mecanismo + evidência discriminante + counterfactual**. `"Post-hoc fix attribution ... satisfies none of these alone."` `"Empty or inconclusive analysis is valid; recommend no change when warranted. Manufacture neither certainty nor a lesson."` Não promove regra sozinho; sugestões ≤3.

### 1.7 Outros

- **mcpmarket "Retro" (JeremyDev87)** — ciclo `PLAN → ACT → EVAL`, evidência dos logs → regra de projeto / memória / issue do GitHub. SKILL.md primário não encontrado.

## 2. Alternativas adjacentes

| Fonte | O que faz | Técnica notável |
|---|---|---|
| **claude-reflect** (https://github.com/BayramAnnakov/claude-reflect) | Captura correções em tempo real via hooks + `/reflect` | Regex de correção (`"no, use X"`, `"don't"`, `"remember:"`) + confidence 0.60–0.95; fila humana; `/reflect-skills` minera padrões entre 68 sessões → `/commands` |
| **session-report** (plugin oficial Claude) | Relatório HTML de uso entre sessões | tokens, cache-hit `<85%`, `top_prompts >2%`, subagents >1M tokens; anomalias como % do total |
| **handoff** (local) | Compacta a conversa em doc p/ outro agente | "suggested skills", não duplicar artefatos, redigir segredos |
| **claude-handoff** (local) | Idem, + lança agente em background | `claude --bg --name` |
| **session-handoff** | Handoff estruturado | git state, staleness, secret leak, resume command |
| **claude-codex-handoff** | Handoff entre agentes diferentes | `HANDOFF.md` git-friendly + sanity-check vs git |
| **mind MCP** (skill local) | Memória persistente em grafo | checkpoints sobrevivem a compactação; tiers; links |
| **superpowers** | — | `handoff`/`retrospectiva` NÃO encontrados no tree main (só `diagnosing-superpowers`) |
| **EvoSkill / hermes-agent-self-evolution** | Loop evolutivo de skills | otimiza SKILL.md via DSPy+GEPA a partir de trajetórias falhas |
| **alirezarezvani self-improving-agent** | Auto-memory | promotion lifecycle (2–3× → promove); hook `error-capture` PostToolUse |

## 3. Inventário de técnicas

| Técnica | Fonte |
|---|---|
| Ground truth em transcript re-lido por script | accidentalrebel, nós |
| Marcar compactação como trecho suspeito | **só nós** |
| Extração de correções por regex + confidence | claude-reflect |
| Auditoria de runs anteriores (Verified/Drifted/Missing) | claude-improve |
| Coverage statement | claude-improve |
| Enforcement → hook/lint/pre-commit/CI | mattpocock, claude-improve |
| Rank de fricção por frequência + quotes cruas | bokan |
| Documentar falhas ("Failed Attempts") | sionic |
| Causalidade com counterfactual | boshu2 |
| Learnings persistentes + promotion após ~5 runs | claude-improve, alirezarevs |
| Métricas entre sessões (tokens/cache/skills) | session-report |
| Mineração de padrões repetidos → novo skill | claude-reflect, EvoSkill |
| Aplicar mudança automaticamente | claude-improve, EvoSkill |
| Integração com tracker/PR | mattpocock, sionic |
| Handoff entre agentes | claude-codex-handoff, claude-handoff |

## 4. Lacunas vs. nossa skill

| Técnica | Temos? | Adotável? |
|---|---|---|
| Ground truth re-consultado em runtime (SQLite) | ✅ | — |
| Marca de compactação como "suspeito" | ✅ | — |
| Fechar pendências / promessa≠entrega | ✅ (resp. A) | — |
| **Rastros de pendência por regex/sinais** | ✅ v2 | feito |
| Auto-revisão de ambiente (7 categorias) | ✅ (resp. B) | — |
| **Enforcement mecânico → lint/hook/CI** | ✅ v2 | feito |
| **Auditoria de retros anteriores** | ❌ | roadmap |
| **Coverage statement** | ✅ v2 | feito |
| **Learnings persistentes + promotion** | ❌ | roadmap |
| **Métricas e tendência entre sessões** | ❌ | roadmap |
| **Confidence + tier de prioridade** | ✅ v2 | feito |
| **Rigor causal (counterfactual)** | ✅ v2 | feito |
| Aplicação automática | ❌ (intencional: só apresenta) | — |
| Integração com tracker/PR | ❌ | roadmap |

**Diferencial real nosso:** (a) SQLite re-consultado em runtime (imune a compactação/KV cache) e (b) marcar o ponto de compactação. **Não encontrado em nenhum concorrente.**

## 5. Top 5 recomendações

1. **Extração de rastros de pendência por sinais** (alto/baixo) — feita na v2.
2. **Auditoria de retrospectivas anteriores** Verified/Drifted/Missing (alto/médio) — roadmap.
3. **Persistência de learnings + métricas entre sessões** (alto/médio) — roadmap.
4. **Mecânico → checagem determinística** (alto/médio) — feito na v2 (regra).
5. **Confidence + tier + counterfactual + coverage statement** (médio/baixo) — feito na v2.
