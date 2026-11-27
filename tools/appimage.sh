#!/usr/bin/env bash
# Package the existing Linux export; never run against personal campaign data.
set -euo pipefail
cd "$(dirname "$0")/.."

out="$PWD/dist"
cache="${XDG_CACHE_HOME:-$HOME/.cache}/pattaya-after-hours/appimage"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
mkdir -p "$cache"
test -x "$out/linux/PattayaAfterHours.x86_64"

download() {
  local name="$1" url="$2" checksum="$3"
  if ! printf '%s  %s\n' "$checksum" "$cache/$name" | sha256sum --check --status 2>/dev/null; then
    curl --fail --location --retry 3 --output "$scratch/$name" "$url"
    printf '%s  %s\n' "$checksum" "$scratch/$name" | sha256sum --check
    mv "$scratch/$name" "$cache/$name"
  fi
}

# Pin both components: appimagetool otherwise fetches a moving runtime at build time.
download appimagetool-1.9.1-x86_64.AppImage \
  https://github.com/AppImage/appimagetool/releases/download/1.9.1/appimagetool-x86_64.AppImage \
  ed4ce84f0d9caff66f50bcca6ff6f35aae54ce8135408b3fa33abfc3cb384eb0
download runtime-20251108-x86_64 \
  https://github.com/AppImage/type2-runtime/releases/download/20251108/runtime-x86_64 \
  2fca8b443c92510f1483a883f60061ad09b46b978b2631c807cd873a47ec260d
chmod +x "$cache/appimagetool-1.9.1-x86_64.AppImage"

appdir="$scratch/PattayaAfterHours.AppDir"
mkdir -p "$appdir/usr/bin" "$appdir/usr/share/licenses/pattaya-after-hours"
cp "$out/linux/PattayaAfterHours.x86_64" "$appdir/usr/bin/"
cp LICENSE GODOT-LICENSE.txt assets/DejaVu-LICENSE.txt "$appdir/usr/share/licenses/pattaya-after-hours/"
cp assets/art/icon.png "$appdir/pattaya-after-hours.png"
cp tools/linux/pattaya-after-hours.desktop "$appdir/"
cp tools/linux/AppRun "$appdir/"
chmod +x "$appdir/AppRun" "$appdir/usr/bin/PattayaAfterHours.x86_64"
ARCH=x86_64 APPIMAGE_EXTRACT_AND_RUN=1 "$cache/appimagetool-1.9.1-x86_64.AppImage" \
  --no-appstream --runtime-file "$cache/runtime-20251108-x86_64" \
  "$appdir" "$out/PattayaAfterHours-linux-x86_64.AppImage"

# Extraction mode works on CI and on machines without FUSE. Isolate all save paths.
mkdir -p "$scratch/data" "$scratch/config"
XDG_DATA_HOME="$scratch/data" XDG_CONFIG_HOME="$scratch/config" \
  APPIMAGE_EXTRACT_AND_RUN=1 "$out/PattayaAfterHours-linux-x86_64.AppImage" \
  --headless --quit-after 3 2>&1 | tee "$scratch/smoke.log"
if grep -Eq 'SCRIPT ERROR:|^ERROR:|Parse Error:|Compile Error:' "$scratch/smoke.log"; then
  echo "AppImage startup failed." >&2
  exit 1
fi
