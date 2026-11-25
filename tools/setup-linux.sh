#!/usr/bin/env bash
# Install the pinned standard Godot build without sudo or changing shell profiles.
set -euo pipefail
cd "$(dirname "$0")/.."

templates=false
case "${1:-}" in
  --templates) templates=true ;;
  --help|-h)
    echo "Usage: tools/setup-linux.sh [--templates]"
    echo "Installs Godot for Linux x86-64 into ~/.local; optionally installs export templates."
    exit 0 ;;
  "") ;;
  *) echo "Unknown option: $1" >&2; exit 1 ;;
esac
if [[ "$#" -gt 1 || "$(uname -s)" != Linux || "$(uname -m)" != x86_64 ]]; then
  echo "This installer supports Linux x86-64 and at most one option." >&2
  exit 1
fi
for tool in curl unzip sha256sum awk; do
  command -v "$tool" >/dev/null || { echo "Install $tool first." >&2; exit 1; }
done

version="$(cat .godot-version)"
cache="${XDG_CACHE_HOME:-$HOME/.cache}/pattaya-after-hours/setup"
data="${XDG_DATA_HOME:-$HOME/.local/share}"
install_dir="$HOME/.local/opt/godot/$version"
bin_dir="$HOME/.local/bin"
base="https://github.com/godotengine/godot-builds/releases/download/$version-stable"
mkdir -p "$cache" "$install_dir" "$bin_dir"

verify() {
  printf '%s  %s\n' "$2" "$1" | sha256sum --check --status
}

download() {
  local name="$1" expected
  expected="$(awk -v name="$name" '$2 == name {print $1}' tools/godot-checksums.sha256)"
  if [[ ! "$expected" =~ ^[a-f0-9]{64}$ ]]; then
    echo "No pinned SHA-256 for $name. Update tools/godot-checksums.sha256 first." >&2
    exit 1
  fi
  if [[ ! -f "$cache/$name" ]] || ! verify "$cache/$name" "$expected"; then
    echo "Downloading $name"
    curl --fail --location --retry 3 --output "$cache/$name.part" "$base/$name"
    verify "$cache/$name.part" "$expected" || { echo "Checksum mismatch: $name" >&2; exit 1; }
    mv "$cache/$name.part" "$cache/$name"
  fi
  echo "Verified $name"
}

editor="Godot_v$version-stable_linux.x86_64"
download "$editor.zip"
unzip -qo "$cache/$editor.zip" -d "$install_dir"
chmod +x "$install_dir/$editor"
ln -sfn "$install_dir/$editor" "$bin_dir/godot-$version"
if [[ ! -e "$bin_dir/godot" && ! -L "$bin_dir/godot" ]]; then
  ln -s "godot-$version" "$bin_dir/godot"
fi

if "$templates"; then
  archive="Godot_v$version-stable_export_templates.tpz"
  download "$archive"
  scratch="$(mktemp -d "$cache/templates.XXXXXX")"
  trap 'rm -rf "$scratch"' EXIT
  unzip -q "$cache/$archive" -d "$scratch"
  template_version="$(cat "$scratch/templates/version.txt")"
  if [[ "$template_version" != "$version.stable" ]]; then
    echo "Unexpected template version: $template_version" >&2
    exit 1
  fi
  mkdir -p "$data/godot/export_templates/$template_version"
  cp -a "$scratch/templates/." "$data/godot/export_templates/$template_version/"
  echo "Templates installed: $data/godot/export_templates/$template_version"
fi

"$bin_dir/godot-$version" --version
echo "Editor: $bin_dir/godot-$version"
echo "Run: GODOT_BIN=\"$bin_dir/godot-$version\" tools/test.sh"
echo "Open: \"$bin_dir/godot-$version\" --editor --path \"$PWD\""
