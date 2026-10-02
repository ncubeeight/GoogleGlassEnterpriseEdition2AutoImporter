#!/bin/bash
# Installs (or updates) the Google Glass EE2 auto-import watcher for the current Mac user.
# Files are copied, not symlinked: launchd jobs can't read ~/Documents or ~/Desktop
# (macOS privacy protection), so this folder can live anywhere.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLIST_LABEL="com.glassimport"
PLIST_DEST="$HOME/Library/LaunchAgents/$PLIST_LABEL.plist"

echo "Checking for adb..."
ADB=""
for c in "$HOME/Library/Android/sdk/platform-tools/adb" "/opt/homebrew/bin/adb" "/usr/local/bin/adb"; do
    [ -x "$c" ] && ADB="$c" && break
done
[ -z "$ADB" ] && ADB="$(command -v adb || true)"

if [ -z "$ADB" ]; then
    echo ""
    echo "adb was not found on this Mac."
    echo "Install it with Homebrew, then re-run this installer:"
    echo ""
    echo "    brew install android-platform-tools"
    echo ""
    exit 1
fi
echo "Found adb: $ADB"

mkdir -p "$HOME/bin"

# The progress window is optional: without a Swift compiler the watcher still
# imports and falls back to notifications.
echo "Building progress window..."
if command -v swiftc >/dev/null 2>&1 && xcrun --find swiftc >/dev/null 2>&1; then
    BUILD_DIR="$(mktemp -d)"
    if swiftc -O "$SCRIPT_DIR/progress/GlassImportProgress.swift" -o "$BUILD_DIR/GlassImportProgress"; then
        install -m 755 "$BUILD_DIR/GlassImportProgress" "$HOME/bin/GlassImportProgress"
        echo "Installed progress window to $HOME/bin/GlassImportProgress"
    else
        echo "Warning: progress window failed to build; imports will use notifications only."
    fi
    rm -rf "$BUILD_DIR"
else
    echo "Swift compiler not found, so the progress window was skipped."
    echo "To get it, run 'xcode-select --install', then re-run this installer."
fi

install -m 755 "$SCRIPT_DIR/glass-import.sh" "$HOME/bin/glass-import.sh"
echo "Installed watcher script to $HOME/bin/glass-import.sh"

mkdir -p "$HOME/Library/LaunchAgents"
sed "s#__HOME__#$HOME#g" "$SCRIPT_DIR/com.glassimport.plist.template" > "$PLIST_DEST"
echo "Installed LaunchAgent to $PLIST_DEST"

launchctl unload "$PLIST_DEST" 2>/dev/null || true
launchctl load "$PLIST_DEST"
echo "Loaded and running."
echo ""
echo "Photos import to: $HOME/Pictures/GoogleGlass"
echo "Videos import to: $HOME/Pictures/GoogleGlass/Movies"
echo "Log file: $HOME/Library/Logs/glass-import.log"
echo ""
echo "Plug in the Glass, accept the 'Allow USB debugging' prompt on its display"
echo "the first time, and it will import automatically from then on."
