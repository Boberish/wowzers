#!/usr/bin/env bash
# psim.sh — run a balance sim in PARALLEL by sharding its seeds across CPU cores.
# Each fight is independent and deterministic per seed, so N shards over disjoint seed
# ranges produce the SAME aggregate bands as one run — just ~N× faster on a multi-core
# box (the sims are otherwise single-threaded). Uses the sims' --seed0 offset.
#
#   scripts/psim.sh <sim> [total_seeds] [jobs] [-- extra sim args]
#   e.g.  scripts/psim.sh twinfang_sim 300
#         scripts/psim.sh raid_sim 300 8 --boss=mythos      # one Seal, sharded
# Supported: the ACTIVE sim surface (2026-07-06 fresh slate) — twinfang_sim (Tempo pilot)
# + raid_sim (the 4 Seals). The old class/boss sims were deleted; recover one from git
# history and re-add it to the case below if a rework wants its harness back.
set -euo pipefail
SIM="${1:?usage: psim.sh <sim_name> [seeds] [jobs] [-- extra args]}"
case "$SIM" in
  twinfang_sim|raid_sim|alchemist_sim|forge_sim|well_sim) ;;
  *) echo "psim.sh supports: twinfang_sim raid_sim alchemist_sim well_sim (they carry --seed0 + a per-seed CSV)."
     echo "Old class sims were deleted 2026-07-06 (git history has them).  Got: '$SIM'"
     exit 2 ;;
esac
TOTAL="${2:-200}"
NC="$(nproc)"
JOBS="${3:-$(( NC > 8 ? 8 : NC ))}"      # default up to 8 shards (headroom on a 12-thread box)
EXTRA=("${@:4}")                          # forwarded verbatim to each shard (e.g. --boss=mythos)
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-$HOME/.local/bin/godot}"
OUT="$ROOT/godot/out"; mkdir -p "$OUT"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

chunk=$(( (TOTAL + JOBS - 1) / JOBS ))
start=$(date +%s.%N)
i=0; s0=1; pids=()
while [ "$s0" -le "$TOTAL" ]; do
  cnt=$(( TOTAL - s0 + 1 )); [ "$cnt" -gt "$chunk" ] && cnt=$chunk
  "$GODOT" --headless --path "$ROOT/godot" --script "res://sim/$SIM.gd" -- \
    --seed0="$s0" --seeds="$cnt" --out="res://out/${SIM}.shard${i}.csv" \
    ${EXTRA[@]+"${EXTRA[@]}"} > "$TMP/shard${i}.log" 2>&1 &
  pids+=($!); i=$((i+1)); s0=$(( s0 + chunk ))
done
fail=0
for pid in "${pids[@]}"; do wait "$pid" || fail=1; done
end=$(date +%s.%N)
[ "$fail" = 0 ] || { echo "!! a shard errored — logs in $TMP:"; cat "$TMP"/shard*.log | grep -iE "error|fail" | head; }

# merge shard CSVs (header once) into the sim's normal results path
combined="$OUT/${SIM}_results.csv"
head -1 "$OUT/${SIM}.shard0.csv" > "$combined"
for f in "$OUT/${SIM}.shard"*.csv; do tail -n +2 "$f" >> "$combined"; rm -f "$f" "$f.uid" 2>/dev/null || true; done
rows=$(( $(wc -l < "$combined") - 1 ))

# win-rate bands, merged — HEADER-DRIVEN so it works for any per-seed schema: the group
# key is every column BEFORE `seed` (class: enc,aspect,skill · raid: boss,skill); win% and
# avg TTK come from the `won` / `ttk_sec` columns found by name.
awk -F, '
  NR==1 { for (c=1;c<=NF;c++){ if($c=="seed")sidx=c; if($c=="won")widx=c; if($c=="ttk_sec")tidx=c } next }
  widx && $widx ~ /^[01]$/ {
    key=""; for (c=1;c<sidx;c++) key = key (c>1?" ":"") $c;
    n[key]++; w[key]+=$widx; if($widx==1) tt[key]+=$tidx;
    if(!(key in seen)){order[++m]=key; seen[key]=1}
  }
  END {
    printf "%-30s %8s %10s %6s\n","cell","win%","avgTTK","n";
    printf "%s\n","----------------------------------------------------------------";
    for(j=1;j<=m;j++){k=order[j];
      printf "%-30s %7.1f%% %9.1fs %6d\n", k, 100*w[k]/n[k], (w[k]>0?tt[k]/w[k]:0), n[k]}
  }' "$combined"

awk -v s="$start" -v e="$end" -v sim="$SIM" -v t="$TOTAL" -v j="$JOBS" -v r="$rows" -v c="$combined" \
  'BEGIN{printf "\n%s: %d seeds/cell, %d shards, %.1fs  (%d rows) -> %s\n", sim, t, j, e-s, r, c}'
