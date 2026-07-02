#!/usr/bin/env bash
# Project Rift — instant PUBLIC https links via Cloudflare quick tunnels (no account).
# Prereqs running locally:  python3 server/serve-web.py 8000   and   ./server/serve-local.sh
#   ./server/tunnel.sh
# Prints two URLs: the PAGE link you send people, and the WSS address they paste
# into the game's PLAY ONLINE server field.
set -euo pipefail
cd "$(dirname "$0")/.."
CF=./tools/cloudflared
LOGP=$(mktemp) ; LOGW=$(mktemp)
"$CF" tunnel --no-autoupdate --url http://127.0.0.1:8000 > "$LOGP" 2>&1 &
P1=$!
"$CF" tunnel --no-autoupdate --url http://127.0.0.1:9077 > "$LOGW" 2>&1 &
P2=$!
trap 'kill $P1 $P2 2>/dev/null' EXIT
echo "opening tunnels…"
for i in $(seq 1 30); do
	PAGE=$(grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' "$LOGP" | head -1 || true)
	WSS=$(grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' "$LOGW" | head -1 || true)
	[ -n "${PAGE}" ] && [ -n "${WSS}" ] && break
	sleep 1
done
if [ -z "${PAGE:-}" ] || [ -z "${WSS:-}" ]; then
	echo "tunnel URLs did not appear — logs: $LOGP $LOGW" ; exit 1
fi
echo ""
echo "  SEND THIS LINK (the game):   ${PAGE}"
echo "  SERVER FIELD in-game:        wss://${WSS#https://}"
echo ""
echo "both tunnels stay up while this window is open (Ctrl-C stops them)"
wait
