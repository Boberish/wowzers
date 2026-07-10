#!/usr/bin/env bash
# verify-all.sh — THE MERGE-BACK BAR AS ONE COMMAND (REFIT-PLAN P2).
# Runs the whole ACTIVE VERIFICATION surface headless — the 5 balance sims (det
# self-checks live in each), every system probe, and the 4 smokes — in parallel,
# one log per script, and exits nonzero if ANY of them fails or script-errors.
#
#   scripts/verify-all.sh              # the full bar (default seeds, ~fast)
#   SEEDS=300 scripts/verify-all.sh    # heavier det/balance confidence
#   scripts/verify-all.sh --import     # rebuild the class cache first (fresh checkout)
#
# Byte-identical A/B vs a baseline is the OTHER half of the law — that's
# scripts/ab-gate.sh. Visual probes (screenshot_*) need WSLg and stay manual.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-$HOME/.local/bin/godot}"
SEEDS="${SEEDS:-120}"
NC="$(nproc)"
JOBS="${JOBS:-$(( NC > 6 ? 6 : NC ))}"   # ~30 concurrent Godots OOMs a WSL box — cap the stampede
LOGD="$(mktemp -d /tmp/rift-verify.XXXXXX)"

if [ "${1:-}" = "--import" ]; then
  "$GODOT" --headless --path "$ROOT/godot" --import >/dev/null 2>&1 || true
fi

# name[:extra args] — every entry runs as res://sim/<name>.gd
BALANCE=(
  "twinfang_sim:--seeds=$SEEDS" "raid_sim:--seeds=$SEEDS"
  "alchemist_sim:--seeds=$SEEDS" "well_sim:--seeds=$SEEDS" "forge_sim:--seeds=20"
)
PROBES=(
  draft_sim gear_probe commander_probe map_sim raid_map_sim map_check_sim
  map_advance_probe map_branch_probe map_charge_probe map_event_probe
  map_mark_probe map_wager_probe map_check_online_probe
  fight_seed_probe menu_probe meter_probe profile_probe splitlaw_probe integrity_probe
  raid_probe raid_boon_probe raid_bloom_probe
  fermata_input_check fightlen_probe pack_probe packroll_probe world_probe shell_probe
)
SMOKES=( ui_smoke_raid ui_smoke_map ui_smoke_world )
NET_SMOKES=( net_smoke net_map_smoke )   # sequential: both bind the loopback port

run_one() {  # $1 = "name[:args]"
  local name="${1%%:*}" extra="" log rc
  [ "$1" != "${1%%:*}" ] && extra="${1#*:}"
  log="$LOGD/${name}.log"
  if [ ! -f "$ROOT/godot/sim/${name}.gd" ]; then
    echo "MISSING" > "$log.status"; return
  fi
  # shellcheck disable=SC2086
  "$GODOT" --headless --path "$ROOT/godot" --script "res://sim/${name}.gd" -- $extra \
    > "$log" 2>&1
  rc=$?
  if [ $rc -ne 0 ] || grep -qE "SCRIPT ERROR|Parse Error|FAILURES|: FAIL|CHECK FAIL" "$log"; then
    echo "FAIL" > "$log.status"
  else
    echo "PASS" > "$log.status"
  fi
}

export -f run_one; export ROOT GODOT LOGD
ALL=( "${BALANCE[@]}" "${PROBES[@]}" "${SMOKES[@]}" "${NET_SMOKES[@]}" )
printf '%s\n' "${BALANCE[@]}" "${PROBES[@]}" "${SMOKES[@]}" \
  | xargs -P "$JOBS" -I{} bash -c 'run_one "$@"' _ {}
for ns in "${NET_SMOKES[@]}"; do run_one "$ns"; done   # one at a time on the port

fails=0; missing=0
echo "── verify-all ── seeds=$SEEDS jobs=$JOBS"
for entry in "${ALL[@]}"; do
  name="${entry%%:*}"; st="$(cat "$LOGD/${name}.log.status" 2>/dev/null || echo FAIL)"
  case "$st" in
    PASS) printf '  ok    %s\n' "$name" ;;
    MISSING) printf '  ????  %s (no such sim — update this script)\n' "$name"; missing=$((missing+1)) ;;
    *) printf '  FAIL  %s   → %s\n' "$name" "$LOGD/${name}.log"
       grep -m3 -E "SCRIPT ERROR|Parse Error|FAILURES|: FAIL|CHECK FAIL" "$LOGD/${name}.log" | sed 's/^/          /'
       fails=$((fails+1)) ;;
  esac
done
echo "──"
if [ $fails -eq 0 ] && [ $missing -eq 0 ]; then
  echo "VERIFY-ALL: ALL GREEN (${#ALL[@]} scripts)   logs: $LOGD"
  exit 0
fi
echo "VERIFY-ALL: $fails FAIL / $missing missing   logs: $LOGD"
exit 1
