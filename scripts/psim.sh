#!/usr/bin/env bash
# psim.sh — run a class balance sim in PARALLEL by sharding its seeds across CPU cores.
# Each fight is independent and deterministic per seed, so N shards over disjoint seed
# ranges produce the SAME aggregate bands as one run — just ~N× faster on a multi-core
# box (the sims are otherwise single-threaded). Uses the sims' --seed0 offset.
#
#   scripts/psim.sh <sim> [total_seeds] [jobs]
#   e.g.  scripts/psim.sh bloomweaver_sim 300
#         scripts/psim.sh bulwark_sim 200 6
# Works for the five class sims (bulwark/twinfang/voidcaller/mender/bloomweaver_sim).
set -euo pipefail
SIM="${1:?usage: psim.sh <sim_name> [seeds] [jobs]}"
case "$SIM" in
  bulwark_sim|twinfang_sim|voidcaller_sim|mender_sim|bloomweaver_sim) ;;
  *) echo "psim.sh supports the five class sims (they share the enc,aspect,skill CSV"
     echo "schema + the --seed0 offset): bulwark_sim twinfang_sim voidcaller_sim"
     echo "mender_sim bloomweaver_sim.  Got: '$SIM'"; exit 2 ;;
esac
TOTAL="${2:-200}"
NC="$(nproc)"
JOBS="${3:-$(( NC > 8 ? 8 : NC ))}"      # default up to 8 shards (headroom on a 12-thread box)
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
    > "$TMP/shard${i}.log" 2>&1 &
  pids+=($!); i=$((i+1)); s0=$(( s0 + chunk ))
done
fail=0
for pid in "${pids[@]}"; do wait "$pid" || fail=1; done
end=$(date +%s.%N)
[ "$fail" = 0 ] || { echo "!! a shard errored — see logs in $TMP (copied below)"; cat "$TMP"/shard*.log | grep -iE "error|fail" | head; }

# merge shard CSVs (header once) into the sim's normal results path
combined="$OUT/${SIM}_results.csv"
head -1 "$OUT/${SIM}.shard0.csv" > "$combined"
for f in "$OUT/${SIM}.shard"*.csv; do tail -n +2 "$f" >> "$combined"; rm -f "$f" "$f.uid" 2>/dev/null || true; done
rows=$(( $(wc -l < "$combined") - 1 ))

# win-rate bands, merged (generic class-sim schema: enc,aspect,skill = $1..$3, won=$5, ttk=$6)
awk -F, 'NR>1 && $5 ~ /^[01]$/ {
    k=$1" "$2" "$3; n[k]++; w[k]+=$5; if($5==1) tt[k]+=$6;
    if(!(k in seen)){order[++m]=k; seen[k]=1}
  } END {
    printf "%-12s %-11s %-7s %8s %10s %6s\n","encounter","aspect","skill","win%","avgTTK","n";
    printf "%s\n","------------------------------------------------------------";
    for(j=1;j<=m;j++){k=order[j]; split(k,a," ");
      printf "%-12s %-11s %-7s %7.1f%% %9.1fs %6d\n",a[1],a[2],a[3],100*w[k]/n[k],(w[k]>0?tt[k]/w[k]:0),n[k]}
  }' "$combined"

awk -v s="$start" -v e="$end" -v sim="$SIM" -v t="$TOTAL" -v j="$JOBS" -v r="$rows" -v c="$combined" \
  'BEGIN{printf "\n%s: %d seeds/cell, %d shards, %.1fs  (%d rows) -> %s\n", sim, t, j, e-s, r, c}'
