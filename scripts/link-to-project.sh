#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
CONF="$ROOT/scripts/harnesses.conf"
SKILLS_DIR="$ROOT/skills"
MDC_SRC="$ROOT/rules/sdd-when-spec.mdc"
AGENTS_SRC="$ROOT/rules/sdd-when-spec.agents.md"
AGENTS_START="<!-- sdd-when-spec:start -->"
AGENTS_END="<!-- sdd-when-spec:end -->"

usage() {
  cat <<EOF
Uso: link-to-project.sh [--harness a,b,...] <projeto> [skill...]

Symlink das skills canônicas (\$ROOT/skills) para cada harness.
Hooks always-on: cópia da rule Cursor (.mdc) e bloco em AGENTS.md.

Harnesses conhecidos (scripts/harnesses.conf):
$(list_harness_ids | sed 's/^/  /')

Aliases: claude, claudecode → claude-code.

Sem --harness, instala todos. Sem lista de skills, linka todas.

Exemplos:
  ./scripts/link-to-project.sh /caminho/do/projeto
  ./scripts/link-to-project.sh --harness cursor,opencode /caminho/do/projeto
  ./scripts/link-to-project.sh --harness antigravity /caminho/do/projeto plan-task exec-step
EOF
}

list_harness_ids() {
  awk -F'\t' '/^[^#]/ && NF>=4 {print $1}' "$CONF"
}

harness_line() {
  local id="$1"
  awk -F'\t' -v id="$id" '/^[^#]/ && $1==id {print; exit}' "$CONF"
}

upsert_agents_md() {
  local dest="$1"
  local body
  body=$(cat "$AGENTS_SRC")
  local block
  block=$(printf '%s\n%s\n%s\n' "$AGENTS_START" "$body" "$AGENTS_END")

  mkdir -p "$(dirname "$dest")"
  if [[ ! -f "$dest" ]]; then
    printf '%s\n' "$block" >"$dest"
    echo "wrote $dest"
    return
  fi

  if grep -qF "$AGENTS_START" "$dest"; then
    python3 - "$dest" "$AGENTS_START" "$AGENTS_END" "$block" <<'PY'
import pathlib, sys
path, start, end, block = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
text = pathlib.Path(path).read_text()
pre = text.split(start, 1)[0]
post = text.split(end, 1)[1] if end in text else ""
pathlib.Path(path).write_text(pre.rstrip() + "\n\n" + block + "\n" + post.lstrip("\n"))
PY
    echo "updated block in $dest"
  else
    printf '\n%s\n' "$block" >>"$dest"
    echo "appended block to $dest"
  fi
}

if [[ ! -f "$CONF" ]]; then
  echo "harnesses.conf não encontrado: $CONF" >&2
  exit 1
fi

HARNESS_IDS=()
PROJECT=""
SKILL_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --list-harnesses)
      list_harness_ids
      exit 0
      ;;
    --harness)
      shift
      [[ $# -ge 1 ]] || { echo "--harness exige uma lista" >&2; exit 1; }
      IFS=',' read -r -a HARNESS_IDS <<<"$1"
      shift
      ;;
    --harness=*)
      IFS=',' read -r -a HARNESS_IDS <<<"${1#*=}"
      shift
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "flag desconhecida: $1" >&2
      usage
      exit 1
      ;;
    *)
      if [[ -z "$PROJECT" ]]; then
        PROJECT="$1"
      else
        SKILL_ARGS+=("$1")
      fi
      shift
      ;;
  esac
done

if [[ -z "${PROJECT:-}" ]]; then
  usage
  exit 1
fi

PROJECT=$(cd "$PROJECT" && pwd)

if [[ ${#HARNESS_IDS[@]} -eq 0 ]]; then
  mapfile -t HARNESS_IDS < <(list_harness_ids)
fi

if [[ ! -d "$SKILLS_DIR" ]]; then
  echo "skills/ não encontrado em $ROOT" >&2
  exit 1
fi

names=()
if [[ ${#SKILL_ARGS[@]} -gt 0 ]]; then
  names=("${SKILL_ARGS[@]}")
else
  for d in "$SKILLS_DIR"/*/SKILL.md; do
    names+=("$(basename "$(dirname "$d")")")
  done
fi

declare -A LINKED_SKILL_DIRS=()
need_agents=0

for hid in "${HARNESS_IDS[@]}"; do
  hid="${hid// /}"
  case "$hid" in
    claude|claudecode) hid="claude-code" ;;
  esac
  line=$(harness_line "$hid")
  if [[ -z "$line" ]]; then
    echo "harness desconhecido: $hid (veja --list-harnesses)" >&2
    exit 1
  fi
  IFS=$'\t' read -r _id skills_rel hook_kind hook_rel <<<"$line"

  if [[ -z "${LINKED_SKILL_DIRS[$skills_rel]:-}" ]]; then
    dest="$PROJECT/$skills_rel"
    mkdir -p "$dest"
    for name in "${names[@]}"; do
      src="$SKILLS_DIR/$name"
      if [[ ! -f "$src/SKILL.md" ]]; then
        echo "skill inexistente: $name ($src)" >&2
        exit 1
      fi
      ln -sfn "$src" "$dest/$name"
      echo "linked $hid $dest/$name -> $src"
    done
    LINKED_SKILL_DIRS[$skills_rel]=1
  else
    echo "skip skills dir already linked: $skills_rel ($hid)"
  fi

  case "$hook_kind" in
    cursor-mdc)
      if [[ ! -f "$MDC_SRC" ]]; then
        echo "rule canônica não encontrada: $MDC_SRC" >&2
        exit 1
      fi
      hook_dest="$PROJECT/$hook_rel"
      mkdir -p "$(dirname "$hook_dest")"
      cp -f "$MDC_SRC" "$hook_dest"
      echo "copied $hook_dest"
      ;;
    agents-md)
      need_agents=1
      ;;
    none) ;;
    *)
      echo "hook_kind desconhecido em $hid: $hook_kind" >&2
      exit 1
      ;;
  esac
done

if [[ "$need_agents" -eq 1 ]]; then
  if [[ ! -f "$AGENTS_SRC" ]]; then
    echo "bloco AGENTS.md não encontrado: $AGENTS_SRC" >&2
    exit 1
  fi
  upsert_agents_md "$PROJECT/AGENTS.md"
fi
