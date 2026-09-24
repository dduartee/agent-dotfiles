# Harness Engineering Verification Checklist

Use this checklist when applying harness engineering to a project.
Every item must be verified before claiming the harness is complete.

## Guides (Feedforward) — Before Agents Act

- [ ] **CLAUDE.md exists** with: hardware constraints, stack, hard limits, connection info, coding patterns, harness section
- [ ] **Module specs exist** for every module with: objective, completion criteria, exact code, verification commands, contracts
- [ ] **Orchestrator exists** (`specs/executar_todas.md`) with: dependency graph, phases, contract table, recovery instructions
- [ ] **ADRs exist** (`docs/architecture.md`) documenting every architectural decision and why alternatives were rejected
- [ ] **Features map exists** (`docs/features.md`) with status emojis (✅/🚧/📝/💡) for every feature
- [ ] **Changelog exists** (`docs/changelog.md`) in Keep a Changelog format with template for future entries
- [ ] **Hard limits documented** in CLAUDE.md: RAM constraints, forbidden technologies, platform-specific restrictions
- [ ] **Contract table complete** in orchestrator: every producer-consumer pair listed with exact artifact names

## Sensors (Feedback) — After Agents Act

- [ ] **harness-check.sh exists** and is executable (<5s, deterministic)
- [ ] **bash -n** runs on all .sh files
- [ ] **Shebang check** verifies Termux convention (or project convention)
- [ ] **Python import check** verifies all modules importable
- [ ] **Flask/test_client smoke test** verifies all routes respond
- [ ] **Required files check** verifies critical files exist
- [ ] **Executable permissions check** verifies scripts are +x
- [ ] **Integration test suite exists** with ≥20 assertions across ≥5 test groups
- [ ] **Spec compliance review process** defined (spec reviewer agent)
- [ ] **Code quality review process** defined (code quality reviewer agent)
- [ ] **Code review fan-out** defined (9 finder angles)

## Quality Left Pipeline

- [ ] **Pre-commit stage:** harness-check.sh runs before git commit
- [ ] **Post-module stage:** spec verification commands run after each module
- [ ] **Post-integration stage:** integration test suite runs after all modules
- [ ] **Pre-merge stage:** code review (finder agents) runs before PR/merge
- [ ] **Backpressure:** pre-commit hook rejects commits that fail harness-check.sh

## Recovery Engineering

- [ ] **Recovery pin** at top of every spec file
- [ ] **Session recovery** documented in orchestrator
- [ ] **Git log** provides module completion markers (commit format: `module(NN): description`)
- [ ] **features.md** provides ground truth for current project state
- [ ] **changelog.md** provides historical context for changes
- [ ] **harness-check.sh** can validate existing code before resuming

## Steering Loop

- [ ] Process documented: Issue → Fix → Strengthen guide → Add sensor → Verify
- [ ] Example provided (real steering loop from project history)
- [ ] Every past bug has a corresponding sensor preventing recurrence

## Cross-Cutting

- [ ] **No TODOs** in specs — all implementation is complete
- [ ] **No placeholders** in code blocks — all code is runnable
- [ ] **No "obvious" omissions** — edge cases are handled
- [ ] **Version pinning** — dependencies have version constraints
- [ ] **Platform conventions** — shebangs, paths, service manager are project-appropriate

## Harnessability Assessment

Rate the project on these ambient affordances:

| Affordance | Score (1-5) | Notes |
|------------|-------------|-------|
| Typed language (Python type hints, TypeScript) | | |
| Clear module boundaries | | |
| Framework conventions (Flask blueprints, runsv) | | |
| Deterministic build (no external deps at build time) | | |
| Testable in isolation (mockable dependencies) | | |
| Documented interfaces (contracts, API specs) | | |

**Total: __/30** — higher = more harnessable = fewer agent errors.
