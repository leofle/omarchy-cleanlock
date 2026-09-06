#!/bin/bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "$0")" && pwd)"
DEST="$HOME/.config/omarchy/plugins/cleanlock"
mkdir -p "$(dirname "$DEST")"
rm -rf "$DEST"
cp -a "$ROOT" "$DEST"
# Don't ship the sync helper as part of the installed plugin tree name confusion — it's fine inside
omarchy plugin validate "$DEST"
omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
omarchy plugin enable cleanlock --section right >/dev/null
omarchy restart shell
echo "Installed cleanlock from $ROOT -> $DEST"
