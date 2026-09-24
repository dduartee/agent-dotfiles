# Module Spec Template

Copy this template for every new module. Fill in ALL `[PLACEHOLDERS]`.
Delete no sections. Every section is required.

---

# Módulo [NN] — [Module Name]

**Dependências:** [module-ids, comma-separated]
**Nível de paralelismo:** [level] ([description: "paralelo com X, Y" or "sequencial após Z"])
**Agente:** `[agent-label]`

## Recovery Note

> **Recovery pin.** This spec is the persistent source of truth for module [NN].
> If session context is lost (reset, compaction, crash), an agent can rebuild
> this module from this document alone. Read, implement, verify. No prior
> session context needed.

## Objetivo

[2-3 sentences on what this module builds and why it exists.]

## Completion Criteria

Before this module is marked done, ALL of the following must be verified:

- [ ] [File/artifact 1 created]
- [ ] [File/artifact 2 created]
- [ ] [Verification condition 1]
- [ ] [Verification condition 2]
- [ ] harness-check.sh passes after module completion

## Artefatos Produzidos

```
[path/]
├── [file1.ext]       # [Description]
├── [file2.ext]       # [Description]
└── [subdir/]
    └── [file3.ext]   # [Description]
```

## Implementação

### 1. [path/file1.ext]

[Brief instruction. Then complete, runnable code.]

```[language]
# Complete implementation
```

### 2. [path/file2.ext]

```[language]
# Complete implementation
```

[Repeat for each file.]

## Guides (Feedforward)

What steers the agent BEFORE it acts on this module:

| Guide | Type | What it prevents |
|-------|------|-----------------|
| [CLAUDE.md section X] | [Computational/Inferential] | [Wrong choice prevented] |
| [Contract from module Y] | [Computational/Inferential] | [Interface mismatch] |
| [Pattern/convention] | [Computational/Inferential] | [Inconsistency] |

## Sensors (Feedback)

What validates the agent AFTER it acts on this module:

| Sensor | Type | Trigger | What it catches |
|--------|------|---------|-----------------|
| [Command or check] | [Computational/Inferential] | [When it runs] | [What defect] |
| [Command or check] | [Computational/Inferential] | [When it runs] | [What defect] |

## Verificação

```bash
# Commands the agent runs to self-verify.
# Every command must produce explicit pass/fail output.

# [Check description]
[command] && echo "✓ [what passed]" || echo "✗ [what failed]"

# [Check description]
[command] && echo "✓ [what passed]" || echo "✗ [what failed]"
```

## Outputs/Contracts

What other modules consume from this module:

- **`[path/file1.ext]`:** `[function/class name]([params]) -> [return type]` — [what it does, when to call it]
- **`[path/file2.ext]`:** `[export name]` — [constructor signature or usage]
- **[Contract name]:** [Interface description that consumers depend on]

## Recovery

If this module fails during rebuild:

1. Run `scripts/harness-check.sh` to check for pre-existing breakage
2. Re-read this spec from the top
3. Verify prior module outputs exist (check dependencies section):
   ```bash
   [commands to verify dependencies are in place]
   ```
4. Re-implement from "Implementação" section, file by file
5. Run "Verificação" commands after each file
6. If still failing, check `docs/changelog.md` for recent changes
   that might affect this module's contracts
