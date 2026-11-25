#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
export XDG_DATA_HOME="$scratch"
export XDG_CONFIG_HOME="$scratch/config"
godot_bin="${GODOT_BIN:-godot}"
"$godot_bin" --headless --editor --import --path . --quit 2>&1 | tee "$scratch/import.log"
"$godot_bin" --headless --path . --script tests/check.gd 2>&1 | tee "$scratch/test.log"
"$godot_bin" --headless --path . --script tests/economy_balance.gd 2>&1 | tee "$scratch/balance.log"
if grep -Eq 'SCRIPT ERROR:|^ERROR:|Parse Error:|Compile Error:' "$scratch/import.log" "$scratch/test.log" "$scratch/balance.log"; then
  echo "Godot reported an error; checks failed." >&2
  exit 1
fi
