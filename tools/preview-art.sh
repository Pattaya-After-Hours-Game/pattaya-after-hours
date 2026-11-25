#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
output="${1:-/tmp/pattaya-art-preview}"
preview_data="$(mktemp -d)"
trap 'rm -rf "$preview_data"' EXIT
XDG_DATA_HOME="$preview_data" XDG_CONFIG_HOME="$preview_data/config" PATTAYA_PREVIEW_DIR="$output" \
  "${GODOT_BIN:-godot}" --path . --script tests/preview_street.gd --resolution 960x540
