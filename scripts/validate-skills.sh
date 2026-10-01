#!/usr/bin/env bash
set -euo pipefail

# Valida o pacote de skills (não valida o .spec/ do consumidor):
#   - cada pasta em skills/ tem SKILL.md
#   - frontmatter YAML mínimo (name, description)
#   - name == nome da pasta
#   - links relativos ](../<skill>/...) resolvem para arquivo existente
#   - avisa se faltar disable-model-invocation: true
#
# Uso: scripts/validate-skills.sh

ROOT=$(cd "$(dirname "$0")/.." && pwd)
SKILLS_DIR="$ROOT/skills"

# Skills always-on (auto-invocadas por design): não exigem disable-model-invocation.
AUTO_SKILLS=" sdd-context "

errors=0
warnings=0
skill_count=0

err()  { printf 'ERRO   %s\n' "$1" >&2; errors=$((errors + 1)); }
warn() { printf 'AVISO  %s\n' "$1" >&2; warnings=$((warnings + 1)); }

if [[ ! -d "$SKILLS_DIR" ]]; then
  echo "skills/ não encontrado em $ROOT" >&2
  exit 1
fi

shopt -s nullglob
for dir in "$SKILLS_DIR"/*/; do
  name=$(basename "$dir")
  file="$dir/SKILL.md"
  skill_count=$((skill_count + 1))

  if [[ ! -f "$file" ]]; then
    err "$name: falta SKILL.md"
    continue
  fi

  if [[ "$(head -n 1 "$file")" != "---" ]]; then
    err "$name: SKILL.md não começa com frontmatter YAML (---)"
  fi

  fm_name=$(awk '/^name:/{sub(/^name:[[:space:]]*/, ""); print; exit}' "$file")
  if [[ -z "$fm_name" ]]; then
    err "$name: frontmatter sem 'name'"
  elif [[ "$fm_name" != "$name" ]]; then
    err "$name: 'name' ($fm_name) difere da pasta ($name)"
  fi

  if ! grep -qE '^description:' "$file"; then
    err "$name: frontmatter sem 'description'"
  fi

  if ! grep -qE '^disable-model-invocation:[[:space:]]*true' "$file"; then
    if [[ "$AUTO_SKILLS" != *" $name "* ]]; then
      warn "$name: sem 'disable-model-invocation: true'"
    fi
  fi

  while IFS= read -r target; do
    [[ -z "$target" ]] && continue
    target="${target%%#*}"
    if [[ ! -f "$dir/$target" ]]; then
      err "$name: link relativo quebrado -> $target"
    fi
  done < <(grep -oE '\]\(\.\./[^)]+\)' "$file" | sed -E 's/^\]\(//; s/\)$//' || true)
done

printf '\n%d skill(s) verificada(s).\n' "$skill_count"
if [[ "$warnings" -gt 0 ]]; then
  printf '%d aviso(s).\n' "$warnings"
fi

if [[ "$errors" -gt 0 ]]; then
  printf '%d erro(s).\n' "$errors" >&2
  exit 1
fi
printf 'OK.\n'
