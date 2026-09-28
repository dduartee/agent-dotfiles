#!/usr/bin/env bash
# validate-repo.sh — fast deterministic guards for agent-dotfiles.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
errors=0
warnings=0

error() { printf 'ERROR: %s\n' "$*" >&2; errors=$((errors + 1)); }
warn() { printf 'WARN: %s\n' "$*" >&2; warnings=$((warnings + 1)); }

# Syntax checks.
for file in "$ROOT"/bootstrap.sh "$ROOT"/scripts/validate-repo.sh; do
  [ -f "$file" ] || { error "missing ${file#$ROOT/}"; continue; }
  bash -n "$file" || error "bash syntax: ${file#$ROOT/}"
done
if [ -f "$ROOT/.githooks/pre-commit" ]; then
  bash -n "$ROOT/.githooks/pre-commit" || error "bash syntax: .githooks/pre-commit"
fi

# Plugin JavaScript syntax.
while IFS= read -r -d '' file; do
  node --check "$file" >/dev/null 2>&1 || error "JavaScript syntax: ${file#$ROOT/}"
done < <(find "$ROOT/.config/opencode/plugins" -type f -name '*.js' -print0 2>/dev/null)

# JSON config.
if [ -f "$ROOT/.config/opencode/opencode.json" ]; then
  node -e 'JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"))' \
    "$ROOT/.config/opencode/opencode.json" >/dev/null 2>&1 || error 'JSON: .config/opencode/opencode.json'
fi

# CURATION allowlist and filesystem coverage.
if [ ! -f "$ROOT/CURATION.md" ]; then
  error 'missing CURATION.md'
else
  if ! marked="$(awk -F'|' '
    function trim(s) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return s }
    /^\|/ {
      skill=trim($2); include=trim($4)
      if (skill == "" || skill == "skill" || skill == "---") next
      if (include == "sim") print skill
      else if (include != "" && include != "nao" && include != "não" && include != "defer") {
        printf "invalid include for %s: %s\n", skill, include > "/dev/stderr"
        exit 2
      }
    }
  ' "$ROOT/CURATION.md")"; then
    error 'CURATION include values'
  fi
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    [ -f "$ROOT/.agents/skills/$name/SKILL.md" ] || error "marked skill missing SKILL.md: $name"
  done <<< "$marked"
fi

# No symlinks in the versioned dotfiles tree. External packs stay outside repo.
while IFS= read -r -d '' link; do
  error "symlink not allowed: ${link#$ROOT/}"
done < <(find "$ROOT/.agents" "$ROOT/.config" -type l -print0 2>/dev/null)

# Credential-shape scan. Names in docs are allowed; only value-shaped patterns fail.
secret_re='sk-[A-Za-z0-9]{20,}|xvl-[A-Za-z0-9]{20,}|gh[pousr]_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----'
while IFS= read -r -d '' file; do
  case "$file" in
    "$ROOT/.git"/*|"$ROOT/.superpowers"/*) continue ;;
  esac
  if grep -Eq "$secret_re" "$file"; then
    error "credential-shaped value: ${file#$ROOT/}"
  fi
done < <(find "$ROOT" -type f -not -path '*/.git/*' -not -path '*/.superpowers/*' -print0)

# Documentation placeholders outside the implementation plan.
for file in "$ROOT/README.md" "$ROOT/sources.md" "$ROOT/docs/curation-evidence.md"; do
  [ -f "$file" ] || continue
  if grep -nE 'TBD|TODO' "$file" >/dev/null 2>&1; then
    error "placeholder in ${file#$ROOT/}"
  fi
done

# Portability guard: the versioned base must not carry machine-local paths/addresses.
if [ -f "$ROOT/.config/opencode/opencode.json" ]; then
  if grep -nE '/home/|/Users/|C:\\\\Users|[0-9]{1,3}(\.[0-9]{1,3}){3}' "$ROOT/.config/opencode/opencode.json" >/dev/null 2>&1; then
    error 'opencode.json contains machine-local path/address; keep only the portable base'
  fi
  if grep -nE '@latest' "$ROOT/.config/opencode/opencode.json" >/dev/null 2>&1; then
    warn 'opencode.json contains @latest; pin after compatibility review'
  fi
fi

if [ "$errors" -ne 0 ]; then
  printf 'validate-repo: %d error(s), %d warning(s)\n' "$errors" "$warnings" >&2
  exit 1
fi
printf 'validate-repo: 0 errors, %d warning(s)\n' "$warnings"
