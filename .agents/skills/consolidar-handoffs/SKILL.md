---
name: consolidar-handoffs
description: Use quando houver múltiplos handoffs (de várias sessões ou projetos) para juntar; quando o usuário pedir "consolidar handoffs", "correlacionar pendências", "o que várias sessões deixaram", "tirar redundância entre handoffs", ou iniciar uma sessão a partir de vários handoffs.
---

# Consolidar handoffs

Transforma N handoffs em 1 consolidado: correlaciona, aplica resoluções anteriores,
marca legado/obsoleto, preserva origem. **Nenhuma pendência some.**

## Invariantes

1. **Igualdade** — toda pendência de entrada aparece na saída (aberta, feita ou obsoleta). Zero exclusão silenciosa.
2. **Origem** — cada item cita o handoff/sessão/data de origem.
3. **Resolução declarada vence** — se um handoff **nomeia** o item e diz o desfecho (feito/obsoleto), a saída reflete isso — mesmo numa frase curta: "logo P5 também está feito", "TOKEN_Z foi rotacionado — P3 não é mais necessário".
4. **Não infira sozinho** — não deduza **você mesmo** que um item está feito só porque a causa raiz dele foi resolvida. Declaração é do handoff (invariante 3); inferência é sua. Se o handoff cita o item e diz o desfecho → feche. Se você teria que presumir → deixe aberto, com nota. Na dúvida, deixe aberto e sinalize.
5. **Correlação explícita** — itens com a mesma causa raiz/assunto viram 1 item com N origens.
6. **Conflito** — status divergente entre handoffs vira `CONFLITO`; não escolha em silêncio.
7. **Redundância mínima** — item repetido aparece 1 vez.

## Procedimento

1. Liste **todos** os handoffs: caminho · sessão · data · projeto.
2. Extraia cada pendência crua: `id · descrição · status declarado · projeto · origem`.
3. Agrupe por: mesmo projeto · mesma causa raiz · mesma ação.
4. Para cada item, o status vem do handoff **mais recente que declara aquele item**; aplique a invariante 4.
5. Produza as seções: **Abertas · Feitas · Obsoletas/legado · Correlações · Conflitos**.
6. **Confira a igualdade:** nº de itens de entrada = soma das linhas de saída (duplicatas mergadas contam 1) + obsoletas. Se não bater, ache o item perdido.

## Formato

```markdown
# Consolidado — <projetos> (<N> handoffs, <data>)
Abertas:
- <item> — <projeto> — origem <ses>/<data>
Feitas:
- <item> — origem <ses>
Obsoletas/legado:
- <item> — <por que não é mais necessária> — origem <ses>
Correlações:
- <causa raiz> = {<itens>} — origens <ses...>
Conflitos:
- <item> — <status A> (ses_x) vs <status B> (ses_y) — decidir
Igualdade: <N entrada> = <a+b+c saída>
```

## Erros comuns

| Erro | Correção |
|---|---|
| Fechar item porque a causa raiz foi resolvida | Só feche se o handoff citar **aquele** item (invariante 4) |
| Recusar declaração explícita curta ("logo P5 também está feito") | Isso é declaração → feche (invariante 3) |
| Perder item do fim do handoff | Releia item a item; confira a igualdade |
| Duplicar item entre handoffs | Mesmo assunto → 1 linha com N origens |
| Carregar item já declarado feito | O handoff mais recente que declara o item vence |
| Esconder contradição | `CONFLITO` explícito |
| Não ver causa raiz comum | Bloco "Correlações" |
