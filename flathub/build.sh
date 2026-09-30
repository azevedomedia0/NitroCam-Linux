#!/usr/bin/env bash
# Local Flatpak package for com.azevedomedia.NitroCam (Flathub-oriented layout).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_ID=com.azevedomedia.NitroCam
export PATH="/home/am-linux/flutter/bin:/home/am-linux/.local/bin:${PATH:-}"

cd "$ROOT"
# Align binary name with Flathub command
sed -i 's/set(BINARY_NAME ".*")/set(BINARY_NAME "nitrocam")/' linux/CMakeLists.txt || true

flutter pub get
dart run tool/generate_flathub_assets.dart
flutter build linux --release

BUNDLE="$ROOT/build/linux/x64/release/bundle"
# flutter may still emit project name binary
BIN="$BUNDLE/nitrocam"
if [[ ! -x "$BIN" && -x "$BUNDLE/nitrocam_se" ]]; then BIN="$BUNDLE/nitrocam_se"; fi
if [[ ! -x "$BIN" ]]; then
  # default flutter create name
  for c in "$BUNDLE"/*; do
    [[ -x "$c" && -f "$c" ]] && BIN="$c" && break
  done
fi
test -x "$BIN"

APPDIR="$ROOT/flathub/appdir"
REPO="$ROOT/flathub/repo"
rm -rf "$APPDIR" "$REPO"
mkdir -p "$REPO"

flatpak build-init --arch=x86_64 "$APPDIR" "$APP_ID" org.freedesktop.Sdk org.freedesktop.Platform 25.08
mkdir -p "$APPDIR/files/bin" \
  "$APPDIR/files/share/applications" \
  "$APPDIR/files/share/metainfo" \
  "$APPDIR/files/share/icons/hicolor/256x256/apps"

install -D "$BIN" "$APPDIR/files/nitrocam"
cp -a "$BUNDLE/lib" "$APPDIR/files/"
cp -a "$BUNDLE/data" "$APPDIR/files/"
install -D "$ROOT/flathub/${APP_ID}.desktop" "$APPDIR/files/share/applications/${APP_ID}.desktop"
install -D "$ROOT/flathub/${APP_ID}.metainfo.xml" "$APPDIR/files/share/metainfo/${APP_ID}.metainfo.xml"
install -D "$ROOT/flathub/icons/hicolor/256x256/apps/${APP_ID}.png" \
  "$APPDIR/files/share/icons/hicolor/256x256/apps/${APP_ID}.png"
printf '%s\n' '#!/bin/sh' 'exec /app/nitrocam "$@"' > "$APPDIR/files/bin/nitrocam"
chmod 755 "$APPDIR/files/bin/nitrocam"

flatpak build-finish "$APPDIR" \
  --command=nitrocam \
  --share=network --share=ipc \
  --socket=fallback-x11 --socket=wayland --socket=pulseaudio \
  --device=all \
  --filesystem=xdg-download \
  --filesystem=xdg-run/pipewire-0 \
  --filesystem=/var/run/usbmuxd:ro \
  --talk-name=org.freedesktop.Avahi

flatpak build-export "$REPO" "$APPDIR"
flatpak build-bundle "$REPO" "$ROOT/flathub/${APP_ID}.flatpak" "$APP_ID"
flatpak --user remote-delete --force nitrocam-local 2>/dev/null || true
flatpak --user remote-add --no-gpg-verify nitrocam-local "file://$REPO"
flatpak --user uninstall -y "$APP_ID" 2>/dev/null || true
flatpak --user install -y nitrocam-local "$APP_ID"

echo "Installed $APP_ID"
echo "  flatpak run $APP_ID"
echo "  Bundle: $ROOT/flathub/${APP_ID}.flatpak"
