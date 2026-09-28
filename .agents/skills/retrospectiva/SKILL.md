---
name: retrospectiva
description: Use quando o usuário pedir retrospectiva, recap, "o que ficou pendente", "o que esquecemos", resumo da sessão, ou perto de encerrar, compactar ou commitar uma sessão. Funciona em Linux, macOS e Windows (OpenCode).
---

# Retrospectiva

Duas responsabilidades:

- **A) Fechar a sessão** — achar pendências, esquecimentos e pontos sem desfecho.
- **B) Auto-revisar o comportamento** e propor melhorias de **ambiente** para runs futuras.

O agente esquece e deixa pendências para trás. Pior: a compactação de contexto (e a gestão de KV cache) descarta informação sem avisar. Retrospectiva que só olha a memória do agente herda a mesma perda.

**Ground truth = a sessão real gravada pelo OpenCode**, re-consultada em runtime. Nunca a tua memória do contexto.

Foco: **OpenCode** (o harness que grava a sessão). Paths, comando e SO variam — **descubra, não assuma**.

## Passo 0 — descobrir o ambiente e a sessão (obrigatório)

### 0.1 Achar o OpenCode

- POSIX (Linux/macOS/WSL/Git Bash): `command -v opencode`
- Windows (PowerShell/cmd): `where.exe opencode`
- Versão: `opencode --version`
- Override do binário: `OPENCODE_BIN`

Se não achar no PATH, procure nos locais de instalação comuns antes de desistir: instalador shell (`~/.local/bin`, `~/.opencode/bin`), npm global (`npm prefix -g`), Bun (`~/.bun/bin`), Homebrew no macOS (`/opt/homebrew/bin`, `/usr/local/bin`), Windows **Scoop** (`~\scoop\shims`), **Chocolatey** (`%ProgramData%\chocolatey\bin`), `mise`. Sem `opencode`, **não há sessão gravada**: pare e diga isso — não invente transcript.

### 0.2 Achar os dados (autoridade = `opencode debug paths`)

Rode e leia as chaves: `home, data, config, cache, state, log, tmp, bin, repos, db`.

- `db` = caminho do `opencode.db` (a fonte do ground truth).
- **Nunca hardcode** `~/.local/share/opencode` — muda por SO e por tipo de instalação.
- Overrides possíveis: `OPENCODE_DATA_DIR`, `OPENCODE_CONFIG`, `OPENCODE_CONFIG_DIR`, `OPENCODE_DB`.

Fallback só se `debug paths` não existir (versão antiga):

| SO | data | config | db |
|----|------|--------|----|
| Linux | `$XDG_DATA_HOME/opencode` ou `~/.local/share/opencode` | `~/.config/opencode` | `<data>/opencode.db` |
| macOS | `~/.local/share/opencode` | `~/.config/opencode` | `<data>/opencode.db` |
| Windows | `%USERPROFILE%\.local\share\opencode` | `%USERPROFILE%\.config\opencode` | `<data>\opencode.db` |

(App Desktop no Windows usa `%LOCALAPPDATA%\opencode\data`.) O export do passo 0.4 **dispensa o banco**.

### 0.3 Resolver a sessão

Em ordem: `$1`/`-SessionId` → `$OPENCODE_SESSION_ID` → `opencode api get /api/session/active` → casa `location.directory` com o diretório atual → `opencode session list --format json`.

Com **2+ sessões no mesmo diretório** (ex.: outro agente rodando em paralelo), **não adivinhe** — liste os candidatos e peça o id explícito.

### 0.4 Extrair o ground truth (export = caminho portátil)

```
opencode session export <ses_xxx> > <tmp>/retro-<id>.json     # --sanitize redige segredos
```

O JSON traz `info` (título, tokens, custo) e `messages[]` (`type`, `text`, `content[]`). Funciona em **Linux, macOS e Windows**, sem `sqlite3` nem `jq`.

Fallback (versão antiga/offline) → SQLite em `<db>`:

```
sqlite3 <db> "select seq,type,data from session_message where session_id='<id>' order by seq;"
```

Alternativa via API: `opencode api get /api/session/<id>/message`.

### 0.5 Helper (opcional — acelera; não é obrigatório)

- POSIX (Linux/macOS/WSL/Git Bash): `bash "$SKILL_DIR/scripts/sessao.sh" [ses_xxx]`
- Windows (PowerShell): `pwsh -File "$env:USERPROFILE\.agents\skills\retrospectiva\scripts\sessao.ps1" [-SessionId ses_xxx]`

Onde `SKILL_DIR="${SKILL_DIR:-$HOME/.agents/skills/retrospectiva}"` — use o caminho absoluto do skill; rodar de outro diretório não muda o ground truth.

Dependências: `opencode`; `jq` no helper POSIX (o PowerShell usa JSON nativo). **Sem helper, faça 0.1–0.4 à mão** e leia o JSON exportado com as tuas tools (`read`/`grep`) — é válido.

A saída traz, nesta ordem: cabeçalho (contagens + compactação), **RASTROS DE PENDÊNCIA** e o **TRANSCRIPT** real. Só depois analisa. Se o helper falhar, diz isso explicitamente. Não finjas ter analisado.

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

## Compatibilidade (resumo)

| Ambiente | Como extrair o ground truth | Dependências |
|----------|------------------------------|--------------|
| Linux/macOS/WSL/Git Bash | `sessao.sh` (export) ou export manual | `opencode`, `jq` |
| Windows nativo (PowerShell) | `sessao.ps1` ou `opencode session export` + `read` | `opencode`, PowerShell 5.1+ |
| Sem `opencode`/DB | inacessível — diga e pare | — |

O OpenCode no Windows grava em `%USERPROFILE%\.local\share\opencode`; o comando que importa (`session export`) é o mesmo em todos os SOs.

## Futuro (não implementado)

- **Auditoria de retros anteriores** — persistir os findings e, no próximo run, marcar **Verified / Drifted / Missing** e re-surface dos skipped. Fonte: `claude-improve`.
- **Learnings persistentes + métricas entre sessões** — promotion após ~N runs (vira config, sai do learnings); tokens/cache por sessão. Fonte: `claude-improve`, `session-report`.

Referências da pesquisa de concorrentes: `reference/pesquisa-concorrentes.md`.
