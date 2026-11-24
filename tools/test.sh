#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
export XDG_DATA_HOME="$scratch"
godot_bin="${GODOT_BIN:-godot}"
"$godot_bin" --headless --editor --import --path . --quit
"$godot_bin" --headless --path . --script tests/check.gd
