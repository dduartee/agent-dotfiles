# Orchestrator Template

Copy this to `specs/executar_todas.md` for every new project.

---

# [Project Name] — Orquestrador de Implementação

## Recovery

> Este spec é o mecanismo de recuperação. Se o contexto for perdido (reset,
> compaction, falha de sessão), o fluxo de retomada está documentado aqui.

### Session Recovery (sessão morta)

Se a sessão do agente morrer completamente:
1. Abra uma nova sessão Claude Code
2. Leia este arquivo para reconstruir o plano
3. Execute `git log --oneline` para identificar o último commit de módulo
4. Leia `docs/features.md` para saber o estado atual de cada feature
5. Execute `scripts/harness-check.sh` para validar o código existente
6. Retome da fase seguinte ao último módulo commitado

O contrato de recuperação: se o commit `module(NN): description` existe,
os módulos até NN estão completos. Não reimplementar nada que já tenha commit.

## Estratégia de Execução

Use subagent-driven development: dispache um agente especializado por módulo.
Agentes no mesmo nível de dependência rodam em paralelo.

Cada módulo é uma task atômica executada por um subagente com contexto fresco.
O agente principal (orquestrador) preserva seu contexto distribuindo tarefas
individuais — nunca implementa diretamente.

## Grafo de Dependências

```
Nível 0 (sem deps):    [foundation-module]
                           │
           ┌───────────────┼───────────────┐
Nível 1:   [module-a]  [module-b]  [module-c]    ← parallel
           │               │
Nível 2:   [module-d]  [module-e]               ← parallel
           │
Nível 3:   [module-f]                            ← sequential
```

## Ordem de Execução

### Fase 1 — Fundação (sequencial, 1 agente)

| Ordem | Módulo | Arquivo | Agente |
|-------|--------|---------|--------|
| 1 | [Module Name] | `modules/00-[name].md` | `[agent-label]` |

### Interview Gate

Antes de disparar os agentes de implementação:
1. Confirme com o usuário: "O módulo de fundação foi executado. Posso prosseguir?"
2. Se houver novas informações, ajuste os specs antes de continuar
3. Use AskUserQuestion para cada ambiguidade — não presuma nada
4. Só dispache agentes após confirmação explícita do usuário

### Fase 2 — [Description] (N agentes simultâneos)

| Ordem | Módulo | Arquivo | Agente |
|-------|--------|---------|--------|
| 2a | [Module] | `modules/[NN]-[name].md` | `[label]` |
| 2b | [Module] | `modules/[NN]-[name].md` | `[label]` |

[... repeat for all phases ...]

### Fase N — [Final phase]

## Contratos entre Módulos

| Produtor | Consumidor | Contrato |
|----------|------------|----------|
| [NN]-[name] | [MM]-[name] | `[file path]`, `[function/class name]` |

## Quality Left Pipeline

| Estágio | Onde ocorre | O que verifica |
|---------|-------------|----------------|
| Pre-commit | Antes de cada commit | `harness-check.sh` (backpressure) |
| Pós-módulo | Após cada módulo | Spec do módulo (seção Verificação) |
| Pós-integração | Após todas as fases | Integration test (módulo NN) |
| Pre-merge | Antes de merge/PR | Code review (9 finder angles) |

## Instruções para o Agente Orquestrador

1. Leia este arquivo completamente
2. Execute a Fase 1 com 1 agente
3. Rode `harness-check.sh` e faça commit: `module(00): [description]`
4. Interview Gate: confirme com o usuário antes de continuar
5. Ao concluir, dispache a Fase 2 em paralelo (N agentes)
6. Para cada módulo: spec compliance review → code quality review → commit
7. [Continue para cada fase]
8. Execute o integration test como verificação final
9. Rode `harness-check.sh` uma última vez
