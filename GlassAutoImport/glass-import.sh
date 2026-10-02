#!/bin/bash
# Watches for Google Glass EE2 over USB (adb) and auto-imports new photos/videos.
# Successfully-imported files are moved into a hidden .imported/ folder on the
# device (not deleted) so the camera roll clears out without destroying data.
# Installed to ~/bin by install.sh; edit the copy in the repo and re-run install.sh.

# Locate adb: check common install locations, then fall back to PATH.
ADB=""
for c in "$HOME/Library/Android/sdk/platform-tools/adb" "/opt/homebrew/bin/adb" "/usr/local/bin/adb"; do
    if [ -x "$c" ]; then ADB="$c"; break; fi
done
[ -z "$ADB" ] && ADB="$(command -v adb || true)"
if [ -z "$ADB" ]; then
    echo "adb not found. Install Android platform-tools (e.g. 'brew install android-platform-tools') and re-run." >&2
    exit 1
fi

DEST="$HOME/Pictures/GoogleGlass"
DEST_MOVIES="$DEST/Movies"
REMOTE_PICTURES="/sdcard/Pictures"
REMOTE_MOVIES="/sdcard/Movies"
TARGET_MODEL="Glass Enterprise Edition 2"
LOG="$HOME/Library/Logs/glass-import.log"
STATUS_DIR="$HOME/Library/Caches/GlassImporter"
STATUS="$STATUS_DIR/status"
PROGRESS_APP="$HOME/bin/GlassImportProgress"

mkdir -p "$DEST" "$DEST_MOVIES" "$STATUS_DIR"
log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG"; }

notify() {
    osascript -e "display notification \"$1\" with title \"Google Glass Import\"" >/dev/null 2>&1
}

human_size() { awk -v b="$1" 'BEGIN { split("B KB MB GB TB", u); i = 1; while (b >= 1000 && i < 5) { b /= 1000; i++ } printf (i == 1 ? "%d %s" : "%.1f %s"), b, u[i] }'; }

# Status file read by the GlassImportProgress window. Written atomically so the
# window never sees a half-written file.
write_status() {
    cat > "$STATUS.tmp" <<EOF
state=$1
started=$STARTED
total_files=$TOTAL_FILES
total_bytes=$TOTAL_BYTES
done_files=$DONE_FILES
done_bytes=$DONE_BYTES
failed=$FAILED
current_file=$CUR_NAME
current_local=$CUR_LOCAL
current_size=$CUR_SIZE
dest=$DEST
dest_movies=$DEST_MOVIES
EOF
    mv -f "$STATUS.tmp" "$STATUS"
}

show_progress_window() {
    pkill -f "$PROGRESS_APP" 2>/dev/null
    [ -x "$PROGRESS_APP" ] || return 1
    "$PROGRESS_APP" "$STATUS" >/dev/null 2>&1 &
}

# Queue every file in $1 that isn't already in $2. Each adb call gets
# </dev/null so it can't swallow the loop's input (the old one-file-per-run bug).
scan_dir() {
    local remote="$1" local_dest="$2" size path name
    while read -r size path <&3; do
        [ -z "$path" ] && continue
        name="${path##*/}"
        [ -f "$local_dest/$name" ] && continue
        Q_REMOTE+=("$path"); Q_LOCAL+=("$local_dest/$name"); Q_SIZE+=("$size")
        TOTAL_BYTES=$((TOTAL_BYTES + size))
    done 3< <("$ADB" shell "find '$remote' -maxdepth 1 -type f ! -name '.*' -exec stat -c '%s %n' {} +" </dev/null 2>>"$LOG" | tr -d '\r')
}

log "Watcher started (adb: $ADB)"

while true; do
    "$ADB" wait-for-usb-device 2>>"$LOG"

    # Give the device a moment and confirm it's actually the Glass (not some other Android device)
    sleep 2
    MODEL=$("$ADB" shell getprop ro.product.model </dev/null 2>/dev/null | tr -d '\r')

    if [ "$MODEL" != "$TARGET_MODEL" ]; then
        log "Connected device is '$MODEL', not Glass — ignoring"
        "$ADB" wait-for-disconnect 2>>"$LOG"
        continue
    fi

    log "Glass connected, checking for new photos/videos"

    Q_REMOTE=(); Q_LOCAL=(); Q_SIZE=()
    STARTED=$(date +%s); TOTAL_BYTES=0; DONE_FILES=0; DONE_BYTES=0; FAILED=0
    CUR_NAME=""; CUR_LOCAL=""; CUR_SIZE=0; DISCONNECTED=0

    scan_dir "$REMOTE_PICTURES" "$DEST"
    scan_dir "$REMOTE_MOVIES" "$DEST_MOVIES"
    TOTAL_FILES=${#Q_REMOTE[@]}

    if [ "$TOTAL_FILES" -eq 0 ]; then
        log "No new photos/videos"
        notify "Glass connected — no new photos or videos."
    else
        log "Found $TOTAL_FILES new file(s), $(human_size "$TOTAL_BYTES")"
        write_status importing
        show_progress_window || notify "Importing $TOTAL_FILES file(s) ($(human_size "$TOTAL_BYTES")) to Pictures/GoogleGlass — keep Glass plugged in."

        "$ADB" shell "mkdir -p '$REMOTE_PICTURES/.imported' '$REMOTE_MOVIES/.imported'" </dev/null >>"$LOG" 2>&1

        for i in "${!Q_REMOTE[@]}"; do
            remote="${Q_REMOTE[$i]}"; CUR_LOCAL="${Q_LOCAL[$i]}"; CUR_SIZE="${Q_SIZE[$i]}"
            CUR_NAME="${remote##*/}"
            write_status importing

            if "$ADB" pull -a "$remote" "$CUR_LOCAL" </dev/null >>"$LOG" 2>&1 \
                && [ "$(stat -f%z "$CUR_LOCAL" 2>/dev/null)" = "$CUR_SIZE" ]; then
                "$ADB" shell "mv '$remote' '${remote%/*}/.imported/'" </dev/null >>"$LOG" 2>&1
                DONE_FILES=$((DONE_FILES + 1))
                DONE_BYTES=$((DONE_BYTES + CUR_SIZE))
            else
                # Remove the partial copy, otherwise the next run would see it and skip the file forever.
                rm -f "$CUR_LOCAL"
                if [ "$("$ADB" get-state 2>/dev/null)" != "device" ]; then
                    DISCONNECTED=1
                    log "Glass disconnected mid-import at $CUR_NAME"
                    break
                fi
                FAILED=$((FAILED + 1))
                log "Size mismatch or pull failure for $CUR_NAME — leaving on device, not archiving"
            fi
        done

        CUR_NAME=""; CUR_LOCAL=""; CUR_SIZE=0
        if [ "$DISCONNECTED" -eq 1 ]; then
            write_status disconnected
            notify "Glass was unplugged — copied $DONE_FILES of $TOTAL_FILES. Reconnect to import the rest."
        else
            write_status done
            log "Imported $DONE_FILES new file(s) to $DEST"
            if [ "$FAILED" -gt 0 ]; then
                notify "Imported $DONE_FILES file(s); $FAILED failed and were left on Glass."
            else
                notify "Imported $DONE_FILES file(s) to Pictures/GoogleGlass."
            fi
        fi
    fi

    [ "$DISCONNECTED" -eq 1 ] || "$ADB" wait-for-disconnect 2>>"$LOG"
    log "Glass disconnected"
done
