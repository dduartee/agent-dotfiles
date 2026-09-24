# Evidência de curadoria — agent-dotfiles

Data da coleta: 2026-09-24. Escopo: skills disponíveis, histórico de prompts e configuração viva do agente. Este documento não contém segredos, tokens ou valores de credencial.

## Método e limites

- `opencode-prompt-analysis/scripts/export_opencode_user_messages.py --summary` reportou 4.599 mensagens de usuário, 1.116 sessões, janela 2026-05-05 → 2026-09-21.
- `analyses/final-report.md` é recorte curado anterior: 3.270 mensagens humanas, 845 sessões, janela até 2026-08-21. Seus percentuais não são combinados com o export novo.
- O export bruto inclui mensagens geradas pelo sistema; o relatório final estima 8% de auto-generated. Contagens abaixo usam o relatório quando há percentual humano; buscas no JSONL são tratadas como pistas, não como prova de autoria.
- Critério: `sim` exige valor observado ou dependência do harness e conteúdo que podemos manter. `não` significa dependência externa/vendorizada. `defer` significa evidência insuficiente ou risco de divergência.

## Evidência de uso que guia curadoria

| Padrão observado | Evidência | Consequência para curadoria |
|---|---|---|
| Orquestração por subagentes | 139 mensagens humanas mencionam subagente; 84% das sessões do relatório têm uma mensagem de dispatch | Incluir ferramentas/skill de contexto, handoff e revisão; não vendorizar packs automaticamente |
| Specs e documentação como contrato | 269 mensagens mencionam documentação; 392 mencionam spec | Incluir `retrospectiva` e artefatos de harness; README deve explicar contrato e recuperação |
| Debug com evidência real | 427 mencionam log, 298 erro, 121 debug | Incluir validação de logs, revisão adversarial e testes; não confiar em relato sem path/linha |
| Saída estruturada | 211 JSON, 206 Markdown, 189 tabela | Skills de estilo devem preservar formato, código e fatos; validador deve ser machine-readable |
| Verificação anti-alucinação | usuário usa subagente para checar alegações contra código | `doubt-driven-development` é terceiro-party valioso, mas não entra como skill própria |
| Recap/continuidade | 256 mensagens no corpus atual carregam termos de contexto/recap/handoff/retrospectiva; histórico mostra Derivatives e compactação | Incluir `retrospectiva`, `sessao-atual`, backlog e pontas soltas como harness |
| Follow-up curto e repetição | 39,9% do corpus atual tem prompt <50 chars; 51 runs idênticos no relatório anterior | Manter estado/recap explícito; não confundir skill de estilo com mecanismo de contexto |
| Sessões sem diretório de projeto | 226 mensagens em `~/Projects` e 63 em `~/` no relatório | Tornar origem/projeto e `CURATION` explícitos; não afirmar determinismo de sessão |

## Matriz de decisão

| Skill | Decisão | Autoria/origem | Evidência/overlap | Portabilidade | Ação |
|---|---|---|---|---|---|
| `retrospectiva` | `sim` | Própria; Reads `session_message` do OpenCode | Fecha pendências, detecta rastros e auto-revisa; overlap baixo com `doubt-driven-development` | Parcial: depende de OpenCode DB/schema | Versionar; documentar limite e teste de execução |
| `estilo-ajudante-haicai` | `sim` | Adaptação própria; origem de estilo em `sources.md` | Output style explícito; uso como modo, não mecanismo de memória | Alta; só `SKILL.md` | Versionar com atribuição |
| `estilo-conciso` | `sim` | Adaptação própria | Preferência recorrente por densidade; não substitui `retrospectiva` | Alta | Versionar |
| `estilo-evangelista-tecnico` | `sim` | Adaptação própria | Modo de saída; baixa dependência externa | Alta | Versionar |
| `estilo-jornalista-tabloid` | `sim` | Adaptação própria | Modo de saída humorístico, fallback de clareza | Alta | Versionar |
| `estilo-mestre-zen` | `sim` | Adaptação própria | Modo de descoberta; auto-clareza em erro | Alta | Versionar |
| `estilo-poeta-existencialista` | `sim` | Adaptação própria | Modo de saída; facts preserved | Alta | Versionar |
| `estilo-vendedor-de-vim` | `sim` | Adaptação própria | Modo humorístico/opt-in | Alta | Versionar |
| `generating-exams` | `sim` | Própria; sem upstream público | Uso direto declarado; overlap baixo | Alta, mas skill depende de PDFs/Chrome quando executada | Versionar; declarar dependências de execução |
| `chrome-devtools-agent` | `sim` | Própria; wrapper local do MCP Chrome DevTools | Browser verification é relevante no histórico (console, screenshots, DOM, rede); valor como ferramenta de harness | OpenCode/MCP-specific | Versionar; documentar que MCP precisa estar instalado |
| `mind-management` | `não` | MIT, upstream em `Projects/mind/src/resources/skill-mind-management.md` | É protocolo do projeto Mind, não autoria própria; setup do Mind o gerencia | Depende de Mind/OpenCode | Não vendorizar; documentar instalação/atualização no `sources.md` |
| `doubt-driven-development` | `não` | MIT, `addyosmani/agent-skills` | Alto valor para revisão adversarial, mas third-party | Externa | Manter symlink/pack; documentar origem |
| `i-have-adhd` | `não` | MIT, vendor `ayghri/i-have-adhd` | Preferência de output; já ativo no ambiente | Externa | Manter vendor; documentar commit/update |
| `terminal-browser` | `não` | App local | Dependência de aplicação local | Externa | Manter fora; documentar caminho |
| `brainstorming` + visual companion | `não` | `obra/superpowers`, MIT | Forte valor de discovery/design, mas fornecido pelo plugin | Externa | Manter plugin; documentar reinstalação |
| Demais skills sem `sim` | `não` — evidência insuficiente | Variadas; origem individual precisa de auditoria | Não há evidência suficiente para versionar como próprias | Variada | Não importar implicitamente; reavaliar quando houver uso próprio |

## Regra de manutenção

- `CURATION.md` decide inclusão; não é inventário de tudo que está instalado.
- `sources.md` é a fonte de origem/update de terceiros.
- Não copiar vendor para `.agents/skills` do repo.
- Se `incluir=sim` e source não existir, `bootstrap.sh sync` deve falhar claramente.
- Se uma skill marcada não for encontrada em nenhum source permitido, registrar pendência antes de adiar.
- Não afirmar portabilidade completa enquanto `opencode.json` depender de paths/IP locais ou enquanto plugin depender de harness específico.

## Evidência de limitações atuais

- `bootstrap.sh` atualmente sincroniza arquivos tracked individually e não instala packs externos.
- `opencode.json` sanitizado ainda contém paths absolutos e endereço de rede local; merge manual permanece obrigatório.
- `sources.md` documenta um clone de `addyosmani/agent-skills` que não existe no path local atual; o comando precisa ser revalidado antes de ser tratado como instalação concluída.
- O histórico de prompts é forte evidência de necessidade, mas não prova autoria, licença ou manutenção de cada skill.
- OpenCode v2 documenta `~/.agents/skills` como compatibility source global, `SKILL.md` como entrada de diretório e IDs derivados do path: <https://opencode.ai/v2/docs/skills/>.
