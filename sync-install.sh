#!/bin/bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "$0")" && pwd)"
ID="$(jq -r .id "$ROOT/manifest.json")"
DEST="$HOME/.config/omarchy/plugins/$ID"
mkdir -p "$(dirname "$DEST")"
rm -rf "$DEST"
cp -a "$ROOT" "$DEST"
rm -f "$DEST/sync-install.sh"
omarchy plugin validate "$DEST"
omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
# Disable/remove old short id if present
omarchy plugin disable cleanlock >/dev/null 2>&1 || true
omarchy plugin remove cleanlock --yes >/dev/null 2>&1 || true
omarchy plugin enable "$ID" --section right >/dev/null
ln -sfn "$DEST/bin/cleanlock" "$HOME/.local/bin/cleanlock"
# Rewrite shell.json old id if needed
python3 - <<PY
import json
from pathlib import Path
p=Path.home()/".config"/"omarchy"/"shell.json"
data=json.loads(p.read_text())
changed=False
def walk(o):
  global changed
  if isinstance(o, dict):
    if o.get("id")=="cleanlock":
      o["id"]="$ID"
      changed=True
    for v in o.values(): walk(v)
  elif isinstance(o, list):
    for v in o: walk(v)
walk(data)
if changed:
  p.write_text(json.dumps(data, indent=2)+"\n")
PY
omarchy restart shell
echo "Installed $ID from $ROOT -> $DEST"
