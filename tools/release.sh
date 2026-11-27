#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

godot_bin="${GODOT_BIN:-godot}"
out="$PWD/dist"
mkdir -p "$out/linux" "$out/windows"
"$godot_bin" --headless --editor --import --path . --quit

if [ -n "${ANDROID_HOME:-}" ] && [ -n "${JAVA_HOME:-}" ]; then
  : "${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:?Set the Android release keystore path}"
  : "${GODOT_ANDROID_KEYSTORE_RELEASE_USER:?Set the Android release key alias}"
  : "${GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD:?Set the Android release key password}"
  prefs="$(mktemp -d)"
  trap 'rm -rf "$prefs"' EXIT
  mkdir -p "$prefs/godot"
  cat > "$prefs/godot/editor_settings-4.7.tres" <<CONFIG
[gd_resource type="EditorSettings" format=3]

[resource]
export/android/java_sdk_path = "$JAVA_HOME"
export/android/android_sdk_path = "$ANDROID_HOME"
CONFIG
  XDG_CONFIG_HOME="$prefs" "$godot_bin" --headless --path . --export-release Android "$out/PattayaAfterHours.apk"
fi

"$godot_bin" --headless --path . --export-release Linux "$out/linux/PattayaAfterHours.x86_64"
"$godot_bin" --headless --path . --export-release Windows "$out/windows/PattayaAfterHours.exe"
"$godot_bin" --headless --path . --export-release macOS "$out/PattayaAfterHours-macOS.zip"
for os in linux windows; do
  cp GODOT-LICENSE.txt LICENSE "$out/$os/"
  (
    cd "$out/$os"
    zip -q -FS "../PattayaAfterHours-$os-x86_64.zip" ./*
  )
done
tools/appimage.sh
smoke_data="$(mktemp -d)"
XDG_DATA_HOME="$smoke_data" XDG_CONFIG_HOME="$smoke_data/config" "$out/linux/PattayaAfterHours.x86_64" --headless --quit-after 3
rm -rf "$smoke_data"
(
  cd "$out"
  releases=(PattayaAfterHours-*-x86_64.zip PattayaAfterHours-macOS.zip PattayaAfterHours-linux-x86_64.AppImage)
  if [ -f PattayaAfterHours.apk ]; then releases+=(PattayaAfterHours.apk); fi
  sha256sum "${releases[@]}" > SHA256SUMS.txt
)
