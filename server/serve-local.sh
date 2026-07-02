#!/usr/bin/env bash
# Run the Rift server straight from this checkout — no Docker, instant iteration.
#   ./server/serve-local.sh [port]
set -euo pipefail
cd "$(dirname "$0")/.."
PORT="${1:-9077}"
GODOT="${GODOT:-$HOME/.local/bin/godot}"
exec "$GODOT" --headless --path godot --script res://net/server_main.gd -- --port="$PORT"
