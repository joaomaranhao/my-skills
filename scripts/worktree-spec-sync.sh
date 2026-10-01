#!/usr/bin/env bash
set -euo pipefail

# Sincroniza o memory bank .spec/ entre a árvore principal (orquestrador) e uma
# git worktree de worker. O .spec/ é local (gitignored): não viaja em worktree e
# NÃO faz merge. Use este helper para reconciliar em vez de copiar à mão.
#
# Uso:
#   worktree-spec-sync.sh push <worktree> <path...>          # principal -> worktree
#   worktree-spec-sync.sh pull <worktree> <path...>          # worktree -> principal
#   worktree-spec-sync.sh pull --force <worktree> <path...>
#
# <path> é relativo a $SPEC_DIR (ex.: features/PBI-01.md). Sem '/', assume
# features/<path> e acrescenta .md se faltar. Vários paths são aceitos.
#
# Variáveis: SPEC_DIR (default .spec), MAIN_ROOT (default $PWD).
# pull não sobrescreve a árvore principal se ela for mais nova (use --force).

SPEC_DIR="${SPEC_DIR:-.spec}"
MAIN_ROOT="${MAIN_ROOT:-$PWD}"
FORCE=0

usage() {
  cat <<EOF
Uso:
  worktree-spec-sync.sh push <worktree> <path...>   # principal -> worktree
  worktree-spec-sync.sh pull <worktree> <path...>   # worktree -> principal
  worktree-spec-sync.sh pull --force <worktree> <path...>

Sincroniza arquivos de \$SPEC_DIR entre a árvore principal (\$MAIN_ROOT) e uma
worktree. <path> é relativo a \$SPEC_DIR; sem '/', vira features/<path> (.md).

Variáveis: SPEC_DIR (default .spec), MAIN_ROOT (default \$PWD).
EOF
}

normalize() {
  local p="$1"
  [[ "$p" == */* ]] || p="features/$p"
  [[ "$p" == *.md ]] || p="$p.md"
  printf '%s' "$p"
}

args=()
for a in "$@"; do
  case "$a" in
    -h|--help) usage; exit 0 ;;
    --force) FORCE=1 ;;
    -*) echo "flag desconhecida: $a" >&2; usage; exit 1 ;;
    *) args+=("$a") ;;
  esac
done

mode="${args[0]:-}"
worktree="${args[1]:-}"
rels=("${args[@]:2}")

if [[ "$mode" != "push" && "$mode" != "pull" ]]; then
  usage
  exit 1
fi
if [[ -z "$worktree" || ${#rels[@]} -eq 0 ]]; then
  usage
  exit 1
fi
if [[ ! -d "$worktree" ]]; then
  echo "worktree não encontrada: $worktree" >&2
  exit 1
fi
if [[ ! -d "$MAIN_ROOT/$SPEC_DIR" ]]; then
  echo "memory bank não encontrado: $MAIN_ROOT/$SPEC_DIR" >&2
  exit 1
fi

for raw in "${rels[@]}"; do
  rel=$(normalize "$raw")

  if [[ "$mode" == "push" ]]; then
    src="$MAIN_ROOT/$SPEC_DIR/$rel"
    dst="$worktree/$SPEC_DIR/$rel"
    if [[ ! -f "$src" ]]; then
      echo "não existe na principal: $SPEC_DIR/$rel" >&2
      exit 1
    fi
    mkdir -p "$(dirname "$dst")"
    cp -f "$src" "$dst"
    echo "push $SPEC_DIR/$rel -> $worktree"
  else
    src="$worktree/$SPEC_DIR/$rel"
    dst="$MAIN_ROOT/$SPEC_DIR/$rel"
    if [[ ! -f "$src" ]]; then
      echo "não existe na worktree: $SPEC_DIR/$rel" >&2
      exit 1
    fi
    if [[ -f "$dst" && "$dst" -nt "$src" && "$FORCE" -ne 1 ]]; then
      echo "SKIP (principal mais nova): $SPEC_DIR/$rel — use --force para sobrescrever" >&2
      continue
    fi
    mkdir -p "$(dirname "$dst")"
    cp -f "$src" "$dst"
    echo "pull $SPEC_DIR/$rel <- $worktree"
  fi
done
