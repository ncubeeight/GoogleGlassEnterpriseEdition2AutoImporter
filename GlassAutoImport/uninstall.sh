#!/bin/bash
# Removes the Google Glass EE2 auto-import watcher for the current Mac user.
PLIST="$HOME/Library/LaunchAgents/com.glassimport.plist"

launchctl unload "$PLIST" 2>/dev/null || true
pkill -f "$HOME/bin/GlassImportProgress" 2>/dev/null || true
rm -f "$PLIST"
rm -f "$HOME/bin/glass-import.sh" "$HOME/bin/GlassImportProgress"
rm -rf "$HOME/Library/Caches/GlassImporter"

echo "Watcher stopped and removed."
echo "Note: your imported photos/videos in $HOME/Pictures/GoogleGlass were left in place."
