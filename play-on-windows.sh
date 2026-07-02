#!/usr/bin/env bash
# Mirror the Godot project to the Windows filesystem for native-GPU playtesting.
# WSLg only gives Godot software GL (llvmpipe), so play sessions should run in
# Windows Godot against this copy. Re-run after any changes you want to test —
# it's incremental (rsync), so subsequent syncs take a second.
#
#   ./play-on-windows.sh
#   then open  C:\Users\Bill\RiftPlay\godot\project.godot  in Windows Godot 4.7
#   (first open runs the asset import once; after that it's instant)
#
# The Linux-side .godot import cache is deliberately NOT synced: the Windows
# editor builds its own, so it never fights the WSL agents/sims over cache files.
set -euo pipefail
SRC="$(cd "$(dirname "$0")/godot" && pwd)/"
DST="/mnt/c/Users/Bill/RiftPlay/godot/"
mkdir -p "$DST"
rsync -a --delete --exclude '.godot/' --exclude 'out/' "$SRC" "$DST"
echo "synced -> C:\\Users\\Bill\\RiftPlay\\godot"

# Game-mode launches (the Play*.bat files) never import assets — without this
# step a fresh/changed copy shows a BLACK SCREEN. Runs the Windows Godot
# headless via WSL interop; incremental, so it's fast after the first time.
WINGODOT="/mnt/c/Users/Bill/RiftPlay/Godot_v4.7-stable_win64_console.exe"
if [ -x "$WINGODOT" ]; then
	echo "importing assets on the Windows side..."
	(cd /mnt/c/Users/Bill/RiftPlay && timeout 300 ./Godot_v4.7-stable_win64_console.exe \
		--headless --path "C:/Users/Bill/RiftPlay/godot" --import >/dev/null 2>&1) || true
fi
echo "ready — double-click  C:\\Users\\Bill\\RiftPlay\\Play Rift.bat"
