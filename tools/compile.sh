#!/usr/bin/env bash
# Generate parsers from all format specs.
#
# Usage: tools/compile.sh [target ...]     (default: python javascript)
# Targets: any kaitai-struct-compiler target (python, javascript, java, go, ...)
# Output:  build/<target>/
# Env:     KSC — compiler command (default: kaitai-struct-compiler)

set -euo pipefail
cd "$(dirname "$0")/.."

KSC="${KSC:-kaitai-struct-compiler}"
if [ $# -eq 0 ]; then
  set -- python javascript
fi

# formats/_common/ holds shared types; they are compiled via imports.
specs=(formats/[a-z]*/*.ksy)

for target in "$@"; do
  echo "==> $target (${#specs[@]} specs)"
  rm -rf "build/$target"
  mkdir -p "build/$target"
  "$KSC" --target "$target" --outdir "build/$target" --import-path formats "${specs[@]}"
done
