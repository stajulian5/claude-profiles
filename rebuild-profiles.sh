#!/bin/bash
# Rebuilds separate Claude desktop copies (one per account) from /Applications/Claude.app.
# Re-run after every Claude update. Usage: ./rebuild-profiles.sh
set -euo pipefail
cd "$(dirname "$0")"
REPO="$(pwd)"
SRC="/Applications/Claude.app"
OUT="$HOME/Applications/Claude Profiles"
DATA="$HOME/Library/Application Support/ClaudeProfiles"
TOOLS="$REPO/tools"
mkdir -p "$OUT"
[ -d "$SRC" ] || { echo "Install Claude into /Applications first"; exit 1; }
LSREG=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

[ -x "$TOOLS/hue" ] || swiftc -O "$TOOLS/hue.swift" -o "$TOOLS/hue"

build() { # name slug hue-radians
  local name="$1" slug="$2" hue="$3"
  local app="$OUT/$name.app" plist="$OUT/$name.app/Contents/Info.plist"
  rm -rf "$app"
  cp -cR "$SRC" "$app"
  mkdir -p "$DATA/$slug"

  # CFBundleName must stay "Claude": Electron derives its helper app names from it
  /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $name" "$plist" 2>/dev/null \
    || /usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string $name" "$plist"
  /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier com.claudeprofiles.$slug" "$plist"
  # don't compete with the main Claude for claude:// links
  /usr/libexec/PlistBuddy -c "Delete :CFBundleURLTypes" "$plist" 2>/dev/null || true

  # the profile's data dir is passed through LaunchServices, so the executable stays untouched
  /usr/libexec/PlistBuddy -c "Delete :LSEnvironment" "$plist" 2>/dev/null || true
  /usr/libexec/PlistBuddy -c "Add :LSEnvironment dict" "$plist"
  /usr/libexec/PlistBuddy -c "Add :LSEnvironment:CLAUDE_USER_DATA_DIR string $DATA/$slug" "$plist"

  # Claude ignores CLAUDE_USER_DATA_DIR, so start it through a small compiled
  # launcher that passes --user-data-dir (the flag Claude does honor).
  # macOS won't launch an app whose main executable is a shell script.
  local w; w="$(mktemp -d)"
  cat > "$w/launcher.c" <<EOF
#include <mach-o/dyld.h>
#include <libgen.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
int main(int argc, char **argv) {
  char self[4096]; uint32_t n = sizeof self;
  if (_NSGetExecutablePath(self, &n) != 0) return 1;
  char bin[4096]; snprintf(bin, sizeof bin, "%s/Claude", dirname(self));
  char **a = calloc(argc + 2, sizeof *a);
  a[0] = bin; a[1] = "--user-data-dir=$DATA/$slug";
  for (int i = 1; i < argc; i++) a[i + 1] = argv[i];
  execv(bin, a);
  perror("execv"); return 1;
}
EOF
  clang -O2 -arch arm64 -arch x86_64 -o "$app/Contents/MacOS/ClaudeProfile" "$w/launcher.c"
  rm -rf "$w"
  /usr/libexec/PlistBuddy -c "Set :CFBundleExecutable ClaudeProfile" "$plist"

  # the asset-catalog icon would override the recolored .icns
  /usr/libexec/PlistBuddy -c "Delete :CFBundleIconName" "$plist" 2>/dev/null || true

  # recolored icon
  local t; t="$(mktemp -d)"
  iconutil -c iconset "$SRC/Contents/Resources/electron.icns" -o "$t/in.iconset"
  mkdir "$t/out.iconset"
  for p in "$t"/in.iconset/*.png; do "$TOOLS/hue" "$p" "$t/out.iconset/$(basename "$p")" "$hue"; done
  iconutil -c icns "$t/out.iconset" -o "$app/Contents/Resources/electron.icns"
  rm -rf "$t"

  xattr -cr "$app"
  codesign --force --deep --sign - "$app" >/dev/null 2>&1
  codesign -v "$app"
  "$LSREG" -f "$app"
  echo "built $app"
}

# ---- Profiles: edit this list to add/rename accounts ----
# build <App name> <data-folder slug> <icon hue: radians, or "gray">
build Mica     mica     0     # original orange
build Personal personal gray  # black and white
