# Placar — `consolidar-handoffs` (TDD)

Fixture: `fixtures/` (4 handoffs, projA + projB). Scorer: `check.mjs` (**11 critérios**).
Modelos leves. `runs/` é descartável (git-ignored); este arquivo é a evidência versionada.

> Endurecido após review independente (2026-09-28): correlação exige o cluster `srclib` com ≥2 ids na mesma linha; duplicata não-mergeada reprova; quebra de seção em heading não-status; item ≠ rótulo. Regressões em `check.test.sh` (A/B/C/D/F).

| modelo | arm | run | score | falhas |
|---|---|---|---|---|
| mimo-v2.5 | RED (sem skill) | red-mimo | **9/10** | `P2 aberto` — marcou aberto como concluído (inferiu resolução) |
| qwen3.8-flash | RED (sem skill) | red-qwen | 10/10 | — |
| mimo-v2.5 | GREEN (com skill) | green-mimo | 10/10 | — |
| qwen3.8-flash | GREEN (com skill) | green-qwen | 10/10 | — |
| mimo-v2.5 | GREEN rep2 | green2-mimo | **9/10** | `P5 nao-aberto` — super-aplicou a invariante 4 (recusou declaração explícita) |
| qwen3.8-flash | GREEN rep2 | green2-qwen | 10/10 | — |
| mimo-v2.5 | GREEN rep3 (pós-refactor) | green3-mimo | 10/10 | — |

## Leitura

- **RED:** baseline inconsistente — `mimo` perde uma pendência aberta (P2) ao inferir resolução a partir da migração da lib.
- **GREEN:** com a skill, ambos 10/10.
- **REFACTOR:** a repetição expôs variância — a invariante 4 ("não infira") foi super-aplicada e reabriu P5 mesmo com o handoff declarando "logo P5 também está feito". A skill foi ajustada (declaração explícita = fechar; inferência própria = não fechar) → `green3` 10/10.

## Limites

- n pequeno (1–3 reps por modelo).
- A fixture não tem item em **conflito de status** real → o critério "Conflitos" fica sem teste direto (ponta `ps_62c2d88fc0554e9ea8368ec49941fdac`; iteração 2).
- Scorer é heurístico (seção-aware); toda saída foi lida manualmente.
