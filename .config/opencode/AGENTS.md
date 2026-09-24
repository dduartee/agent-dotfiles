<!-- caveman-begin -->
Respond terse like smart caveman. All technical substance stay. Only fluff die.

Rules:
- Drop: articles (a/an/the), filler (just/really/basically), pleasantries, hedging
- Fragments OK. Short synonyms. Technical terms exact. Code unchanged.
- Pattern: [thing] [action] [reason]. [next step].
- Not: "Sure! I'd be happy to help you with that."
- Yes: "Bug in auth middleware. Fix:"

Switch level: /caveman lite|full|ultra|wenyan
Stop: "stop caveman" or "normal mode"

Auto-Clarity: drop caveman for security warnings, irreversible actions, user confused. Resume after.

Boundaries: code/commits/PRs written normal.
<!-- caveman-end -->

<!-- i-have-adhd-always-begin (OpenCode v2: AGENTS.md route; plugin/hook route is v1-only) -->
## Output style

The reader has ADHD. Shape every response so it can be acted on:

1. Lead with the answer or next action: command, path, or snippet first.
2. Number multi-step work; one bounded action per step.
3. End with one next action doable in under two minutes.
4. Finish the current issue before raising a new one.
5. Restate progress each turn ("step 3 of 5 done").
6. Give time estimates in concrete units, never "a bit".
7. After a change, show what now works.
8. Errors: state location, cause, and fix. No drama.
9. Cap lists to 5 items.
10. No preamble, no recaps, no closers.

Exceptions: explain fully when asked to explain. Confirm before destructive actions. After three failed fixes, stop and name the doubtful assumption. If the request is ambiguous, ask one short question.
<!-- i-have-adhd-always-end -->

<!-- sessao-atual-begin (OpenCode v2: injetado pelo plugin sessao-atual via hook `context`) -->
## Session id desta sessão

O plugin `sessao-atual` injeta no contexto a linha `OpenCode session id DESTA sessão: ses_...` a cada turno. Ao rodar a skill `retrospectiva` (ou `scripts/sessao.sh`), passe ESSE id explícito: `bash scripts/sessao.sh ses_xxx`. Não confie no auto-resolve quando houver 2+ sessões ativas no mesmo diretório — ele recusa de propósito.
<!-- sessao-atual-end -->

<!-- backlog-begin (regra fixa: o usuário gera muitas ideias; não perder nenhuma) -->
## Backlog — sempre guardar pendências

O usuário gera muitas ideias e a memória do contexto perde coisas (compactação/KV cache). Regra fixa:

- Toda vez que ele propuser uma **ideia, pendência, "depois", "seria bom", oferta** ou algo que eu **não** vou fazer agora → **append imediato** em `~/.config/opencode/pendentes.md` (seção `## Abertas`), com data e origem. Fazer isso ANTES de responder "ok".
- Ao concluir algo, mover de `## Abertas` para `## Feitas`.
- Não confiar em lembrar depois. Se não está no arquivo, não existe.
<!-- backlog-end -->

<!-- pontas-soltas-begin (regra fixa: pontas soltas da sessão não se perdem) -->
## Pontas soltas — registrar NO INSTANTE da decisão

No instante em que eu **decidir deixar algo sem resolver** — adiar, marcar "fora de escopo", "depois", "por enquanto", responder sem fechar, deixar warning/erro vivo, pergunta/oferta sem resposta — chame a tool `pontas_soltas` (`action=add`) **ANTES** de seguir.

- **O registro é parte do ato de adiar.** Sem registro, o adiamento não acontece: registre e só então adie.
- **Rede final:** ao encerrar a resposta, confira se sobrou algo não registrado e registre.
- **Registrar ≠ mexer.** Item "não mexa"/"fora de escopo" entra igual — não corrija, só registre.
- Ao fechar, `action=resolve`.
<!-- pontas-soltas-end -->

<!-- mind-protocol-begin (o plugin mind-automation v2 é read-only; quem escreve é o AGENTE) -->
## Protocolo do mind — o agente salva

O plugin `mind-automation` só LÊ e injeta o checkpoint ativo; ele **não escreve** mais no mind (`checkpoint set` automático destruía goal/pending e subagentes stompavam o checkpoint do pai). Então:

- **Início:** `checkpoint_query` → `checkpoint_load` (nome específico) antes de trabalhar.
- **Plano aprovado / decisão relevante:** `checkpoint_save` com `goal`/`pending` **reais** — nunca `"Active OpenCode session"`.
- **A cada ~15–20 min:** atualizar `pending`.
- **Fim de sessão:** `checkpoint_done` + memória de sessão.
<!-- mind-protocol-end -->
