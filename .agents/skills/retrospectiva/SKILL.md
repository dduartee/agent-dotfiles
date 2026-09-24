---
name: retrospectiva
description: Use quando o usuário pedir retrospectiva, recap, "o que ficou pendente", "o que esquecemos", resumo da sessão, ou perto de encerrar, compactar ou commitar uma sessão.
---

# Retrospectiva

Duas responsabilidades:

- **A) Fechar a sessão** — achar pendências, esquecimentos e pontos sem desfecho.
- **B) Auto-revisar o comportamento** e propor melhorias de **ambiente** para runs futuras.

O agente esquece e deixa pendências para trás. Pior: a compactação de contexto (e a gestão de KV cache) descarta informação sem avisar. Retrospectiva que só olha a memória do agente herda a mesma perda.

**Ground truth = a sessão real gravada pelo OpenCode** (`session_message` no `opencode.db`), re-consultada em runtime. Nunca a tua memória do contexto.

## Passo 0 — obrigatório, antes de qualquer análise

Roda o script e lê a saída inteira:

```bash
SKILL_DIR="${SKILL_DIR:-$HOME/.agents/skills/retrospectiva}"
bash "$SKILL_DIR/scripts/sessao.sh"            # sessão atual (auto)
bash "$SKILL_DIR/scripts/sessao.sh" ses_xxx    # sessão específica
```

Use o caminho absoluto do skill; execução a partir de outro diretório não muda ground truth. `OPENCODE_DB` e `RETRO_MAX` podem sobrescrever DB e limite de caracteres.

O ID é resolvido sozinho: `$OPENCODE_SESSION_ID` → `GET /api/session/active` → casa `location.directory` com o cwd. Com **2+ sessões no mesmo diretório** (ex.: outro agente rodando em paralelo), o script **não adivinha** — lista os candidatos e pede o id. Se falhar, passe `ses_xxx`.

A saída traz, nesta ordem: cabeçalho (contagens + compactação), **RASTROS DE PENDÊNCIA** e o **TRANSCRIPT** real. Só depois analisa.

Se o script falhar, diz isso explicitamente. Não finjas ter analisado.

## Quando usar

- "retrospectiva", "recap", "resumo", "o que fizemos"
- "o que ficou pendente", "o que esquecemos", "o que faltou"
- fim de sessão, antes de compactar, commitar ou passar a outro agente

## A) Fechar a sessão

1. Parte dos **RASTROS** (leads), mas confirma cada um no transcript. Rastro é pista, não conclusão.
2. Extrai, com referência ao ponto do transcript:
   - **Concluído** — o que passou a funcionar (concreto).
   - **Decisões** — escolhas feitas e o porquê.
   - **Pendências** — TODO dito e não feito; promessa do agente não cumprida; item adiado; oferta do agente sem resposta do usuário; pergunta sem resposta.
   - **Riscos** — o que pode quebrar, não testado, não commitado.
3. **Rastro forte sem desfecho = pendência**, mesmo que o item principal já funcione. Ex.: o agente achou dois erros, aprofundou um, e o outro ficou com `warning` vivo → vira item.
   - `warning`/`aviso`, `TODO`/`FIXME`, "não testei"/"não validei", "por enquanto", `workaround`, erro de tool (`status=error`) sem correção.
4. Distingue "disse que ia fazer" de "feito". Promessa ≠ entrega.

## B) Auto-revisar o comportamento (candidatos)

Procura no transcript onde o **agente** poderia ter ido melhor e traduz em melhoria de **ambiente**:

- **Navegação** — demorou a achar arquivo/skill → falta um ponteiro.
- **Checagem automática** — erro que lint/typecheck/teste/hook pegaria. Ambiente **sem guardrail** já é achado.
  - *Mecânico* (padrão fixo, API proibida, local de arquivo) → **propõe a checagem** (lint rule / pre-commit / CI / hook), não texto. Mecânico pede checagem, full stop.
  - *Julgamento* (consistência entre arquivos, "segue o estilo do entorno") → regra escrita.
  - Antes, lê a checagem que **já existe** — uma checagem desligada/morta é o achado, não uma reinvenção.
- **Regras / AGENTS.md / skills** — instrução que não muda comportamento (no-op); `description` que não disparou; regra ambígua.
- **Economia de tools** — chamada caríssima em token.
- **Acesso à informação** — log, DB ou serviço que faltou.

Regras de B:

- **≤3 candidatos**, ordenados por severidade. Se não houver, escreve "nada encontrado".
- **Só apresenta. Nunca aplica** — quem decide é o usuário.
- Cada candidato: **onde** · **o que mudar** · **por quê**.

## Rigor (vale para A e B)

- **Coverage statement** no topo: quantas mensagens/compactações foram lidas. Honestidade de escopo.
- Cada item com **confiança** (alta/média/baixa) e **prioridade**.
- Causa só com **mecanismo + evidência discriminante + counterfactual**. Atribuição post-hoc não basta.
- *Não fabriques certeza nem lição.* Análise vazia/inconclusiva é válida; recomenda não mudar quando for o caso.
- **Não inventa.** Se um item não está no transcript, não está feito. Cita a mensagem ou o arquivo.
- Ordena por urgência, mostra ≤5 itens; retém o resto internamente e mostra se pedirem.
- Se houver **COMPACTAÇÃO**, trata o trecho anterior como suspeito e reconfere o que foi descartado.
- Sessão curta (< 3 turnos): diz que não há o que retomar.

## Formato

```
Retrospectiva — [título curto]
Cobertura: [N msgs lidas · K compactações · confiança geral]
Feito: [1-3 linhas concretas]
Pendências (não fechado):
1. [item] — [por que importa] — [confiança]
Melhorias de ambiente (candidatos — você decide):
1. [onde] — [o que mudar] — [por quê]
Pergunta aberta: [a única que mais trava]
Risco: [se houver]
Próximo passo: [UMA ação < 2 min]
```

## Futuro (não implementado)

- **Auditoria de retros anteriores** — persistir os findings e, no próximo run, marcar **Verified / Drifted / Missing** e re-surface dos skipped. Fonte: `claude-improve`.
- **Learnings persistentes + métricas entre sessões** — promotion após ~N runs (vira config, sai do learnings); tokens/cache por sessão. Fonte: `claude-improve`, `session-report`.

Referências da pesquisa de concorrentes: `reference/pesquisa-concorrentes.md`.
