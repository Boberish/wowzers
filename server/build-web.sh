#!/usr/bin/env bash
# Build the browser (WASM) client into dist/web — the "send a link" pipeline.
#   ./server/build-web.sh
# Rebuild any time the game changes; players just refresh the page.
# One-time setup: Godot 4.7 export templates must be installed
# (~/.local/share/godot/export_templates/4.7.stable/) — see server/README.md.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-$HOME/.local/bin/godot}"
mkdir -p dist/web
"$GODOT" --headless --path godot --export-release "Web" ../dist/web/index.html
echo ""
echo "built dist/web — serve it with:  python3 server/serve-web.py [port]"
ls -la dist/web
