# Contribuindo — humanos e agentes

Este repositório é a fonte da verdade privada das minhas skills e da configuração
do OpenCode. Skills próprias ficam versionadas aqui; componentes de terceiros
ficam instalados na máquina e registrados em `sources.md`.

## Nota para agentes

Se você leu este repositório e encontrou:

- dificuldade para reproduzir o setup em outra máquina ou sistema operacional;
- falta de generalização do workspace (path fixo, suposição de Linux, dependência
  implícita, passo de setup que não está documentado);
- documentação que não bate com o conteúdo real;
- teste ausente para um comportamento que existe;

**abra um Pull Request com a correção** (ou um issue, se faltar permissão de
escrita). Contribuições de agentes são bem-vindas. Se o conserto exigir uma
decisão que você não pode tomar, descreva a dificuldade e proponha a opção mais
neutra.

## Regras do repositório

1. **Sem segredos.** Nunca commitar token, chave, `.env` ou path de máquina.
   Rode `bash scripts/validate-repo.sh` antes do commit.
2. **Skills próprias** em `.agents/skills/<skill>/SKILL.md`, com frontmatter
   `name` e `description` (a `description` começa com "Use quando"/"Use when" e
   descreve só quando usar — não resume o processo).
3. **Curadoria explícita.** Marque a skill com `sim` em `CURATION.md`; sem `sim`,
   o `bootstrap.sh sync` não a importa.
4. **Terceiros não são vendorizados.** Registre origem e update em `sources.md`.
5. **Teste antes de commitar:**

   ```bash
   bash scripts/validate-repo.sh
   for t in tests/*.sh tests/*/*.sh; do bash "$t"; done
   node tests/pontas-soltas-test.mjs
   ```

6. **Commit normal** (Conventional Commits). Código e mensagens em português são
   aceitos.

## Portabilidade (o que roda onde)

| Componente | Linux/macOS | Windows |
|---|---|---|
| `bootstrap.sh link\|sync` | sim (bash ≥4; macOS: `brew install bash`) | via **Git Bash** ou **WSL** |
| `scripts/validate-repo.sh` | sim | via Git Bash/WSL |
| `tests/*.sh` | sim | via Git Bash/WSL |
| `tests/*.mjs` | sim (Node) | sim (Node) |
| plugins `.config/opencode/plugins/*.js` | sim (OpenCode) | sim (OpenCode) |
| `retrospectiva/scripts/sessao.sh` | sim | via Git Bash/WSL |
| `retrospectiva/scripts/sessao.ps1` | sim (pwsh) | sim (PowerShell 5.1+) |
| `consolidar-handoffs` (markdown) | sim | sim |

No Windows nativo: use `opencode` + `sessao.ps1`. Os scripts `.sh` exigem
Git Bash ou WSL. (Verificado com PowerShell 7.4.6.)

## Fluxo

```text
CURATION.md -> bootstrap.sh sync -> revisar git diff -> validate-repo + testes -> commit -> push
```
