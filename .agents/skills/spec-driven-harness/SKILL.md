---
name: spec-driven-harness
description: |
  MANDATORY for ANY multi-file project with 3+ independent modules. Applies
  spec-driven development with harness engineering: creates modular specs with
  dependency graphs, dispatches subagents in parallel, enforces quality gates
  at every phase, and builds recovery mechanisms into the project structure.
  TRIGGER when user says "build", "create project", "implement", "spec",
  "workflow", "orchestrate", "dispatch agents", "homelab", "harness", "recovery",
  "spec-driven", "module specs", or describes multi-step implementation tasks.
  Also trigger when user asks to "document the process", "create a skill from
  our workflow", or wants to replicate a previous project structure. If the
  user mentions specs, modules, phases, or subagent parallelism, this skill
  DEFINITELY applies. Do NOT skip this skill for any multi-module project.
---

# Spec-Driven Development with Harness Engineering

Build projects through modular specifications executed by parallel AI agents,
with quality gates at every phase and built-in recovery mechanisms.

This skill captures the complete workflow refined across building the A31
Homelab — a 14-module Flask + MQTT + vanilla JS project orchestrated through
7 parallel phases with 5.5% defect rate (14/26 findings confirmed, all fixed
before implementation).

## When This Skill Applies

You MUST use this skill when ALL of the following are true:
1. The project has 3+ independent modules or services
2. Modules have clear dependency boundaries (can be built by separate agents)
3. The user wants production-quality output with automated verification
4. The project benefits from persistent specs as recovery mechanisms

You SHOULD use this skill when:
- The project spans multiple languages/frameworks (Python + JS + shell)
- You need to fan out parallel subagents for speed
- You want automated quality gates (not just human review)
- The project will be maintained or extended by AI agents in future sessions

Do NOT use this skill for:
- Single-file changes or bug fixes
- Projects with no module boundaries
- Quick prototypes where specs would be overhead

## The Complete Workflow

### Phase 0: Brainstorming → Design

Before ANY spec is written, follow the brainstorming skill:
1. Explore project context (hardware, constraints, existing code)
2. Ask clarifying questions ONE at a time
3. Propose 2-3 approaches with trade-offs
4. Present design in sections, get approval after each
5. Write design doc to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`
6. Self-review for placeholders, contradictions, ambiguity
7. User reviews written spec → approve → transition

### Phase 1: Spec Architecture

Design the module decomposition BEFORE writing individual specs:

**1a. Identify module boundaries:**
- Each module = one atomic unit of work for one subagent
- Modules at the same dependency level touch DIFFERENT files
- Contract: module X produces artifacts that module Y consumes

**1b. Draw the dependency graph:**
```
Nivel 0 (sem deps):     foundation
                          │
          ┌───────────────┼───────────────┐
Nivel 1:  module-a     module-b     module-c    ← parallel
          │               │
Nivel 2:  module-d     module-e                 ← parallel
          │
Nivel 3:  module-f                              ← sequential
```

**1c. Create the orchestrator** (`specs/executar_todas.md`):
- Recovery section (top): how to resume if context is lost
- Dependency graph (ASCII art)
- Execution phases with agent labels
- Interview gate: pause before dispatching agents
- Contract table: producer → consumer → artifact
- Quality Left Pipeline stages
- Session recovery instructions

**1d. Classify every module by parallelism level:**
- Level 0: no dependencies
- Level N: depends on modules from level N-1 or N-2
- Same level + different files = parallel dispatch

### Phase 2: Module Spec Creation

For EVERY module, create `specs/modules/NN-module-name.md` following this
EXACT structure. No section is optional.

#### Required Sections (in order)

```markdown
# Módulo NN — Module Name

**Dependências:** <module-ids>
**Nível de paralelismo:** <level> (<phase description>)
**Agente:** `<agent-label>`

## Recovery Note

> This spec is the recovery pin for module NN. If session context is lost
> (reset, compaction, crash), an agent can rebuild this module from this
> document alone. Read, implement, verify. No prior context needed.

## Objetivo

2-3 sentences on what this module builds and why.

## Completion Criteria

Checklist with checkboxes — the agent KNOWS when it's done:
- [ ] File X created at path/Y
- [ ] Function Z exports correctly
- [ ] Verification commands pass
- [ ] Harness check passes

## Artefatos Produzidos

File tree of everything this module creates:
```
path/
├── file1.py       # Description
└── file2.js       # Description
```

## Implementação

Step-by-step with COMPLETE code blocks. The agent copies, doesn't invent.
Each step produces one file. Code must be exact — no pseudocode, no "..."
abbreviations, no "// similar to above".

### 1. path/file1.py

```python
# Complete, runnable code
```

### 2. path/file2.js

```javascript
// Complete, runnable code
```

## Guides (Feedforward)

| Guide | Type | What it prevents |
|-------|------|-----------------|
| CLAUDE.md hard limits | Computational | Wrong stack choices |
| Contract: function X(a, b) -> dict | Computational | Interface mismatch |
| Pattern: shebang Termux | Computational | Platform incompatibility |

## Sensors (Feedback)

| Sensor | Type | Trigger | What it catches |
|--------|------|---------|-----------------|
| bash -n syntax check | Computational | Post-create | Shell syntax errors |
| Python import check | Computational | Post-create | Broken imports |
| Flask test_client | Computational | Post-create | Route errors |

## Verificação

```bash
# Commands the agent runs to verify its work
# Every command should produce ✓ or ✗
test -f path/file1.py && echo "✓ file1.py" || echo "✗ missing"
python3 -c "from module import function; print('✓ import OK')"
```

## Outputs/Contracts

- **`path/file1.py`:** `function_name(params) -> return_type` — what it does
- **`path/file2.js`:** `export class ClassName` — constructor signature, methods
- Contract: consumer modules reference these EXACT names and paths

## Recovery

If this module fails during rebuild:
1. Check harness-check.sh for pre-existing breakage
2. Re-read this spec from top
3. Verify prior module outputs exist (dependencies)
4. Re-implement from "Implementação" section
5. Run "Verificação" commands
6. If still failing, check `docs/changelog.md` for recent changes that
   might affect this module
```

### Phase 3: Spec Review (Before ANY Code)

Run the code review fan-out BEFORE implementing:

```
9 finder angles in parallel:
  A. Cross-module consistency (contracts match)
  B. Missing requirements (every user story has a module)
  C. Interface contracts (signatures, types, edge cases)
  D. Dependency graph correctness (no circular deps, no false deps)
  E. Python bug scan (Flask pitfalls, concurrency, path traversal)
  F. JavaScript bug scan (MQTT leaks, DOM injection, race conditions)
  G. Shell bug scan (shebangs, error handling, signal handling)
  H. End-to-end gaps (unhandled states, missing config, bootstrapping)
  I. Test coverage (what's not tested)

↓

Verification (1-vote, 3-state):
  CONFIRMED: can name inputs → wrong output, quote the line
  PLAUSIBLE: mechanism real, trigger uncertain
  REFUTED: factually wrong or guarded elsewhere

↓

Sweep: fresh reviewer finds what 9 finders missed
```

**Fix ALL CONFIRMED + PLAUSIBLE findings before implementation.**
Each finding is a spec bug that would cause agent failure at runtime.

### Phase 4: Implementation (Subagent-Driven Development)

Execute using the subagent-driven-development skill pattern:

```
For each phase in executar_todas.md:
  1. Interview gate: confirm with user before dispatching
  2. Dispatch implementer subagents (parallel for same level)
  3. Each subagent: read spec → implement → verify → commit
  4. Spec compliance review: did agent build what spec asked?
  5. Code quality review: is the implementation well-built?
  6. Fix issues (same subagent) → re-review → approve
  7. Mark module complete
```

**Commit discipline:** Every module gets one atomic commit:
```
module(03): api endpoints — /api/health, /api/torch, /api/photo, /api/exec, /api/say
```

**Backpressure:** harness-check.sh runs before every commit. If it fails,
the commit is rejected and the agent sees the error output.

### Phase 5: Integration Test

After ALL modules are implemented, run the integration test suite:
- File structure check (all dirs exist)
- Python import check (all modules importable)
- Flask routes check (all endpoints respond)
- JS file check (all frontend files present)
- Shell syntax check (bash -n on all .sh)
- Smoke test (one-liner via SSH to device)

### Phase 6: Harness Refinement

After the project is built, apply harness engineering:

1. **Create harness-check.sh** — fast computational sensor (<5s)
   - Shell syntax (bash -n)
   - Shebang convention
   - Python imports
   - Flask routes smoke test
   - Required files existence
   - Executable permissions

2. **Classify all controls** into guides (feedforward) and sensors (feedback),
   computational vs inferential

3. **Build Quality Left Pipeline:**
   | Stage | When | What |
   |-------|------|------|
   | Pre-commit | Before git commit | harness-check.sh |
   | Post-module | After each module | Spec verification commands |
   | Post-integration | After all modules | Integration test suite |
   | Pre-merge | Before PR/merge | Code review (9 finder angles) |

4. **Document the steering loop:**
   - Issue found → Fix → Strengthen guide → Add sensor → Verify
   - Every bug becomes a new sensor

5. **Add ADR-006** documenting harness engineering as architectural decision

6. **Assess harnessability:** what ambient affordances make this project
   tractable to agents? (typed languages, clear module boundaries,
   framework conventions)

## The Orchestrator Template

Create `specs/executar_todas.md` with this structure:

```markdown
# Project Name — Orchestrator

## Recovery

> This spec is the recovery mechanism. If context is lost, read from here.

### Session Recovery (dead session)
1. Open new session
2. Read this file to rebuild the plan
3. Check git log for last module commit
4. Read docs/features.md for current state
5. Run harness-check.sh to validate existing code
6. Resume from next uncommitted phase

## Execution Strategy

Subagent-driven development with dependency-aware parallelism.
Each module = one atomic task by one subagent with fresh context.
Main agent orchestrates; never implements directly.

## Dependency Graph
[ASCII art showing N levels with parallel groups]

## Execution Phases

### Fase 1 — Foundation (1 agent)
| Order | Module | Spec | Agent |

### Interview Gate
Before dispatching implementation agents:
1. Confirm with user
2. Surface ambiguities via AskUserQuestion
3. Do NOT proceed without explicit confirmation

### Fase 2 — Parallel (N agents)
[Same table format]

[...]

## Contracts Between Modules
| Producer | Consumer | Contract |

## Quality Left Pipeline
| Stage | When | What |

## Agent Instructions
[Numbered steps for the orchestrator agent]
```

## Recovery Engineering

Every spec must enable recovery. This is NOT optional.

### Recovery Pin Pattern

At the top of every spec file:
```markdown
> **Recovery pin.** If context is lost, an agent can rebuild this module
> from this document alone. Read, implement, verify. No prior context needed.
```

### Session Recovery Flow

When a session crashes or context is lost:
1. Read `specs/executar_todas.md` (the orchestrator)
2. Run `git log --oneline` to find the last module commit
3. Check `docs/features.md` for feature completion status
4. Run `scripts/harness-check.sh` to validate existing code
5. Resume from the NEXT phase after the last commit

### Recovery Verification

After recovery, verify:
- `harness-check.sh` passes
- Integration test (module 12) passes
- All contracts from the orchestrator's contract table hold

## Harness Engineering Principles

### Guides (Feedforward Controls)

Steer the agent BEFORE it acts. Anticipate unwanted outputs.

| Category | Examples |
|----------|----------|
| **Runtime constraints** | CLAUDE.md hard limits (RAM, no Docker, aarch64) |
| **Structural constraints** | Module specs with exact code, contracts, dependencies |
| **Stylistic constraints** | Shebang convention, coding patterns, naming |
| **Architectural constraints** | ADRs documenting decisions and why alternatives rejected |
| **State awareness** | docs/features.md showing what's built vs planned |

### Sensors (Feedback Controls)

Observe outputs AFTER the agent acts. Enable self-correction.

| Category | Computational (<5s, deterministic) | Inferential (slower, probabilistic) |
|----------|-----------------------------------|-------------------------------------|
| **Syntax** | bash -n, Python import check | — |
| **Structure** | File existence, executable perms | Code quality review |
| **Behavior** | Flask test_client, whitelist bypass test | Spec compliance review |
| **Integration** | Integration test suite (29 assertions) | Cross-module consistency finder |
| **Coverage** | Required files checklist | Sweep agent (gapscan) |

### Backpressure

Quality gates that REJECT bad output before it propagates:

1. **Pre-commit hook:** harness-check.sh linked as .git/hooks/pre-commit
   - Fails → commit rejected → agent sees error → agent fixes → retries
   - Quote: "When a subagent commits, the hook runs immediately. If tests fail,
     the commit is rejected and the agent sees the error output"

2. **Post-module verification:** Spec's own verification commands
   - Fails → agent hasn't finished → don't mark module complete

3. **Spec compliance review:** Independent agent verifies against spec
   - Fails → implementer fixes → re-review → repeat until approved

### Steering Loop

```
Issue found → Fix → Strengthen guide → Add sensor → Verify
     ↑                                              │
     └──────────────────────────────────────────────┘
```

Every defect becomes a stronger harness:
- Agent used wrong shebang? → Add to CLAUDE.md + shebang check in harness-check.sh
- Module contract broken? → Add to contract table + integration test assertion
- Race condition in parallel agents? → Fix dependency graph + add to orchestrator

## Strict Conditions for New Modules

When adding a new module to an existing project:

1. **Identify dependency level:** What existing modules does it consume?
2. **Check for file conflicts:** Does it write files that other modules also write?
   If yes, it CANNOT run in parallel with them.
3. **Write spec following the template:** All 12 sections required
4. **Add to orchestrator:** New phase or extend existing phase
5. **Update contract table:** New producer → consumer relationships
6. **Update docs/features.md:** Add feature with status 🚧
7. **Update docs/changelog.md:** Add entry
8. **Update harness-check.sh:** Add new required files
9. **Run code review:** At minimum, cross-module consistency + contract check
10. **Implement + verify + commit:** Follow the subagent-driven dev cycle

## Key Principles

- **Spec is the contract.** Subagents reference it for consistency
- **Spec enables recovery.** Survives session crashes, context resets
- **Spec enables parallelism.** Clear boundaries let agents work concurrently
- **Spec creates completion criteria.** Checklist with checkboxes
- **Harness prevents regression.** Every bug becomes a sensor
- **Quality left.** Checks run as early as possible
- **Atomic commits.** One module = one commit = one subagent
- **Fresh context per task.** Main agent only orchestrates

## Reference Files

- `references/module-template.md` — Complete module spec template
- `references/orchestrator-template.md` — Complete orchestrator template
- `references/harness-checklist.md` — Harness engineering verification checklist

Read these when creating new specs or applying harness to an existing project.
