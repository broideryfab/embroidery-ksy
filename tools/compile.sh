#!/usr/bin/env bash
# Generate parsers from all format specs.
#
# Usage: tools/compile.sh [target ...]     (default: python javascript)
# Targets: any kaitai-struct-compiler target (python, javascript, java, go, ...)
# Output:  build/<target>/
# Env:     KSC — compiler command (default: node tools/ksc.js, the npm
#          compiler; run `npm install` first). The JVM compiler works too:
#          KSC=kaitai-struct-compiler tools/compile.sh

set -euo pipefail
cd "$(dirname "$0")/.."

read -r -a ksc <<< "${KSC:-node tools/ksc.js}"
if [ $# -eq 0 ]; then
  set -- python javascript
fi

# formats/_common/ holds shared types; they are compiled via imports.
specs=(formats/[a-z]*/*.ksy)

for target in "$@"; do
  echo "==> $target (${#specs[@]} specs)"
  rm -rf "build/$target"
  mkdir -p "build/$target"
  "${ksc[@]}" --target "$target" --outdir "build/$target" --import-path formats "${specs[@]}"
done
