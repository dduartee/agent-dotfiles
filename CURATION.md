# Curadoria de skills

Allowlist explícita. `sim` significa conteúdo local/derivado que este repo
versiona; `não` significa terceiro/vendor gerenciado fora. Rode
`./bootstrap.sh sync`; source `sim` ausente falha em vez de ser ignorado.

Fontes permitidas para sync: `~/.agents/skills`,
`~/.config/opencode/skills` e `~/.claude/skills` (preferência na ordem).
Terceiros nunca são copiados para este repo; veja `sources.md`.

| skill | tipo | incluir |
|---|---|---|
| api-and-interface-design | externo |  |
| ask-matt | externo |  |
| browser-testing-with-devtools | externo |  |
| caveman | externo |  |
| caveman-commit | externo |  |
| caveman-compress | externo |  |
| caveman-help | externo |  |
| caveman-review | externo |  |
| ci-cd-and-automation | externo |  |
| claude-handoff | externo |  |
| codebase-design | externo |  |
| code-review | externo |  |
| code-review-and-quality | externo |  |
| code-simplification | externo |  |
| compress | externo |  |
| context-engineering | externo |  |
| cross-model-review | externo |  |
| debugging-and-error-recovery | externo |  |
| deprecation-and-migration | externo |  |
| diagnosing-bugs | externo |  |
| display-guided-debug | externo |  |
| documentation-and-adrs | externo |  |
| domain-modeling | externo |  |
| doubt-driven-development | externo |  |
| estilo-ajudante-haicai | própria/adaptada | sim |
| estilo-conciso | própria/adaptada | sim |
| estilo-evangelista-tecnico | própria/adaptada | sim |
| estilo-jornalista-tabloid | própria/adaptada | sim |
| estilo-mestre-zen | própria/adaptada | sim |
| estilo-poeta-existencialista | própria/adaptada | sim |
| estilo-vendedor-de-vim | própria/adaptada | sim |
| find-skills | externo |  |
| frontend-ui-engineering | externo |  |
| git-guardrails-claude-code | externo |  |
| git-workflow-and-versioning | externo |  |
| grilling | externo |  |
| grill-me | externo |  |
| grill-with-docs | externo |  |
| handoff | externo |  |
| human-in-the-loop-debug | externo |  |
| idea-refine | externo |  |
| i-have-adhd | vendor (symlink → ~/.local/share/opencode/vendor/i-have-adhd/skills/i-have-adhd) ⭐ | não |
| implement | externo |  |
| implement-spec | externo |  |
| improve-codebase-architecture | externo |  |
| incremental-hw-test-layers | externo |  |
| incremental-implementation | externo |  |
| interview-me | externo |  |
| loop-me | externo |  |
| migrate-to-shoehorn | externo |  |
| performance-optimization | externo |  |
| planning-and-task-breakdown | externo |  |
| prototype | externo |  |
| resolving-merge-conflicts | externo |  |
| retrospectiva | própria | sim |
| scaffold-exercises | externo |  |
| security-and-hardening | externo |  |
| setup-matt-pocock-skills | externo |  |
| setup-pre-commit | externo |  |
| setup-ts-deep-modules | externo |  |
| shipping-and-launch | externo |  |
| source-driven-development | externo |  |
| spec-driven-development | externo |  |
| spec-driven-harness | própria (harness) | sim |
| structured-log-parsing | externo |  |
| subagent-context-negotiation | externo |  |
| tdd | externo |  |
| teach | externo |  |
| terminal-browser | vendor (symlink → ~/.local/share/terminal-browser/app/skills/default/terminal-browser) | não |
| test-driven-development | externo |  |
| to-questionnaire | externo |  |
| to-spec | externo |  |
| to-tickets | externo |  |
| triage | externo |  |
| using-agent-skills | externo |  |
| vercel-react-best-practices | externo |  |
| wait-what | externo |  |
| wayfinder | externo |  |
| web-design-guidelines | externo |  |
| wizard | externo |  |
| writing-beats | externo |  |
| writing-for-agents | externo |  |
| writing-fragments | externo |  |
| writing-shape | externo |  |
| chrome-devtools-agent | externo/derived (awesome-copilot) | defer |
| generating-exams | própria | sim |
| mind-management | externo (gerado pelo Mind) | não |
