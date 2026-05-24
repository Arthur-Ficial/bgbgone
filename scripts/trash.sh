#!/bin/bash
# Shared safe cleanup helper. Project policy is to move paths to Trash rather
# than deleting them with rm.

trash_init() {
    if [ -z "${BGBGONE_TRASH_DIR:-}" ]; then
        BGBGONE_TRASH_DIR="$HOME/.Trash/bgbgone-$(date +%Y%m%d-%H%M%S)-$$"
        mkdir -p "$BGBGONE_TRASH_DIR"
    fi
}

trash_path() {
    local target base dest n
    for target in "$@"; do
        [ -e "$target" ] || continue
        trash_init
        base="$(basename "$target")"
        dest="$BGBGONE_TRASH_DIR/$base"
        n=1
        while [ -e "$dest" ]; do
            dest="$BGBGONE_TRASH_DIR/$base.$n"
            n=$((n + 1))
        done
        mv "$target" "$dest"
    done
}
