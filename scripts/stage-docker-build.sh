#!/usr/bin/env bash
# Stage runtime-common for hermes standalone Docker build.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CLEAN=0

for arg in "$@"; do
  case "$arg" in
    --clean) CLEAN=1 ;;
  esac
done

if [[ "$CLEAN" -eq 1 ]]; then
  rm -rf "$ROOT/packages/common"
  echo "removed staged packages/common"
  exit 0
fi

SRC="${RUNTIME_COMMON_SRC:-$ROOT/../../works/agents-runtime/packages/common}"
if [[ ! -d "$SRC" ]]; then
  echo "error: runtime-common not found at $SRC" >&2
  echo "hint: export RUNTIME_COMMON_SRC=/path/to/agents-runtime/packages/common" >&2
  exit 1
fi

rm -rf "$ROOT/packages/common"
mkdir -p "$ROOT/packages"
cp -a "$SRC" "$ROOT/packages/common"
echo "staged runtime-common from $SRC"
