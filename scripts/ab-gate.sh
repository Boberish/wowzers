#!/usr/bin/env bash
# ab-gate.sh — the NON-NEGOTIABLE byte-identical gate as a script (REFIT-PLAN P2;
# replaces the "cp -r godot/ to scratch and eyeball" folklore).
#
# Runs <sim> with IDENTICAL args on (A) a pristine baseline checkout and (B) your
# working tree, then diffs the full stdout AND the results CSV md5. Any drift =
# FAIL with the diff shown. The baseline is a git worktree pinned to a commit, so
# a concurrent session merging into main mid-gate can NOT false-diff you.
#
#   scripts/ab-gate.sh raid_sim                          # vs merge-base with main
#   scripts/ab-gate.sh raid_sim --seeds=200 --boss=mythos
#   BASE=main scripts/ab-gate.sh twinfang_sim --seeds=300
#
# A change MEANT to shift checksums documents its new baseline instead (see
# REFIT-PLAN §3 acceptance) — this gate is for changes that claim neutrality.
set -uo pipefail
SIM="${1:?usage: ab-gate.sh <sim_name> [sim args...]}"; shift || true
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-$HOME/.local/bin/godot}"
BASE_REF="${BASE:-$(git -C "$ROOT" merge-base HEAD main 2>/dev/null || echo main)}"
BASE_SHA="$(git -C "$ROOT" rev-parse --short "$BASE_REF")"
ABDIR="/tmp/rift-ab-gate"
WT="$ABDIR/base-$BASE_SHA"
OUT="$(mktemp -d /tmp/rift-ab.XXXXXX)"

# ---- (A) pristine baseline worktree, cached per commit ----
mkdir -p "$ABDIR"
if [ ! -d "$WT" ]; then
  git -C "$ROOT" worktree add --detach "$WT" "$BASE_SHA" >/dev/null 2>&1 \
    || { echo "ab-gate: cannot create baseline worktree at $BASE_SHA"; exit 2; }
  "$GODOT" --headless --path "$WT/godot" --import >/dev/null 2>&1 || true
fi

run() {  # run <repo> <tag> [sim args...]
  local repo="$1" tag="$2"; shift 2
  mkdir -p "$repo/godot/out"                 # some sims' csv writers don't mkdir
  touch "$OUT/$tag.start"
  ( cd "$repo" && "$GODOT" --headless --path godot --script "res://sim/$SIM.gd" -- "$@" ) \
    > "$OUT/$tag.stdout" 2>&1
  echo $? > "$OUT/$tag.rc"
  # only a CSV THIS run produced counts (stale results must not false-diff)
  local csv
  csv="$(find "$repo/godot/out" -name '*.csv' -newer "$OUT/$tag.start" 2>/dev/null | head -1)"
  if [ -n "$csv" ]; then md5sum "$csv" | cut -d' ' -f1 > "$OUT/$tag.csvmd5"
  else echo "no-csv" > "$OUT/$tag.csvmd5"; fi
}
# scrub per-run noise: absolute paths + godot boot chatter differ between checkouts
scrub() { grep -vE "^Godot Engine|^ *$" "$1" | sed "s|$WT|WT|g; s|$ROOT|WT|g"; }

echo "ab-gate: $SIM $* — baseline $BASE_SHA (A) vs working tree (B)"
( run "$WT" A "$@" ) & pa=$!
( run "$ROOT" B "$@" ) & pb=$!
wait $pa; wait $pb

# identical GARBAGE must not pass: either side erroring fails the gate outright
for t in A B; do
  if [ "$(cat "$OUT/$t.rc")" != "0" ] \
     || grep -qE "ERROR: Can't load script|SCRIPT ERROR|Parse Error" "$OUT/$t.stdout"; then
    echo "AB-GATE: FAIL — side $t errored (rc=$(cat "$OUT/$t.rc")); a gate can't pass on matching errors"
    grep -m3 -E "ERROR|FAIL" "$OUT/$t.stdout" | sed 's/^/  /'
    echo "  logs: $OUT"
    exit 1
  fi
done

ok=1
if ! diff -u <(scrub "$OUT/A.stdout") <(scrub "$OUT/B.stdout") > "$OUT/stdout.diff"; then ok=0; fi
[ "$(cat "$OUT/A.csvmd5")" = "$(cat "$OUT/B.csvmd5")" ] || ok=0

if [ $ok -eq 1 ]; then
  echo "AB-GATE: BYTE-IDENTICAL PASS  (stdout + csv md5 $(cat "$OUT/B.csvmd5"))"
  exit 0
fi
echo "AB-GATE: FAIL — output drifted vs $BASE_SHA"
echo "  csv A=$(cat "$OUT/A.csvmd5")  B=$(cat "$OUT/B.csvmd5")"
head -40 "$OUT/stdout.diff" | sed 's/^/  /'
echo "  full diff: $OUT/stdout.diff   logs: $OUT"
exit 1
