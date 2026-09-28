# Spec — skill `consolidar-handoffs`

Data: 2026-09-28 · Origem: pedido do usuário nesta sessão (`ses_f2c8b1230ffeiOlK4yitpcaqa5`).

## Problema

Vários handoffs (de sessões e projetos distintos ou relacionados) ficam espalhados.
O agente que os lê deixa pendências para trás, duplica itens, ignora que um handoff
posterior já resolveu/obsoletou um item, e não vê correlações entre projetos.
Resultado: progresso desigual — um ponto é desfalecido.

## Resultado esperado

Um **handoff consolidado** a partir de N handoffs:
- **Igualdade:** toda pendência de entrada aparece na saída (aberta, feita ou obsoleta).
- **Provenance:** cada item cita handoff/sessão/data de origem.
- **Resolução vence:** o estado mais recente que cita o item define o status.
- **Correlação explícita:** itens com a mesma causa raiz/assunto viram 1 item com N origens.
- **Conflito explícito:** status divergente vira `CONFLITO`; não se escolhe em silêncio.
- **Redundância mínima:** item repetido aparece 1 vez.

Serve para: o usuário abrir novas sessões com handoffs correlacionados e o próximo
agente continuar **sem desfalcar nenhum ponto**.

## Não-objetivos

- Não é a skill `retrospectiva` (essa olha 1 sessão do OpenCode; esta olha N handoffs).
- Não escreve no `mind` nem em storage de projetos.
- Não decide pendências de negócio; consolida e sinaliza.

## Entradas / saídas

- Entrada: 2+ arquivos de handoff (markdown), com sessão/data/projeto.
- Saída: 1 markdown com seções: Abertas · Feitas · Obsoletas/legado · Correlações · Conflitos.

## Abordagem de teste (TDD)

1. **RED:** subagente (modelo leve) recebe os handoffs-fixture e a tarefa, **sem** a skill.
   Pontuação contra a verdade-conhecida → espera-se falha (itens perdidos/duplicados/sem correlação).
2. **GREEN:** escreve `SKILL.md` mínima que cobre as falhas observadas; repete a tarefa **com** a skill → pontuação cheia.
3. **REFACTOR:** fecha brechas novas; repete até estabilizar.

Pontuação automática por `tests/consolidar-handoffs/check.mjs` (9 critérios), com leitura manual de cada match.

## Invariantes de deploy

- `consolidar-handoffs` é skill própria → `CURATION.md` = `sim`, versionada em `agent-dotfiles`.
- `SKILL.md` com frontmatter válido (`name`, `description` "Use when…", ≤1024 chars, sem resumo de workflow).
- Sem segredos; roda `bash scripts/validate-repo.sh` e a suíte antes do commit.
