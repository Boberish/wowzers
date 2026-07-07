#!/usr/bin/env bash
# preflight.sh — deploy sanity gate (REFIT-PLAN P2). The protocol is versioned and
# the handshake HARD-REJECTS mismatches by design (CLAUDE.md §run), so server and
# clients must ship from the SAME commit. This asserts that story before a deploy:
#
#   server/preflight.sh          # check + print the deploy line
#
# Fails if the game tree has uncommitted changes (a deploy must be reproducible)
# or the protocol version can't be read. Prints commit + protocol version — put
# that line in the deploy log; when a player reports "version mismatch", this is
# the line you compare against.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

VER="$(grep -oE 'const VERSION := [0-9]+' "$ROOT/godot/net/net_protocol.gd" | grep -oE '[0-9]+')"
[ -n "$VER" ] || { echo "PREFLIGHT: FAIL — cannot read NetProtocol.VERSION"; exit 1; }

DIRTY="$(git -C "$ROOT" status --porcelain -- godot/ server/ | wc -l)"
COMMIT="$(git -C "$ROOT" rev-parse --short HEAD)"
BRANCH="$(git -C "$ROOT" rev-parse --abbrev-ref HEAD)"

if [ "$DIRTY" -ne 0 ]; then
  echo "PREFLIGHT: FAIL — $DIRTY uncommitted change(s) under godot/ or server/."
  echo "  A deployed server must build from a committed state (clients must be able"
  echo "  to check out the exact same tree). Commit or stash first."
  git -C "$ROOT" status --short -- godot/ server/ | head -10 | sed 's/^/  /'
  exit 1
fi

echo "PREFLIGHT: OK"
echo "  deploy line:  commit=$COMMIT branch=$BRANCH protocol=v$VER"
echo "  remember: rebuild + redeploy server AND web client together (old versions"
echo "  are rejected at handshake by design) — server/build-web.sh, then the Docker"
echo "  image; verify with a PLAY ONLINE smoke against the new box."
