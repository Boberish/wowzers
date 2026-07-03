#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
#  tune.sh — FAST raid-tuning loop. A quick win-rate + healer readout you can
#  re-run after every tweak. Skips the slow correctness probes, few seeds by
#  default, and lets you change the big knobs WITHOUT editing any files.
#
#  Just play with it — arg ORDER doesn't matter, it figures out what you meant:
#
#     ./tune.sh                    riftmaw, 30 seeds, good+sloppy      (~8s)
#     ./tune.sh gemini             a different boss
#     ./tune.sh 60                 more seeds  (steadier %, a bit slower)
#     ./tune.sh all                all three skill tiers (expert/good/sloppy)
#     ./tune.sh good               just one tier (fastest)
#     ./tune.sh mythos 50 all      combine any of the above
#
#  LIVE KNOBS (tweak numbers on the spot, nothing saved to files):
#     --dmg=1.3      make the boss hit 30% harder (everything: melee/beats/dots)
#     --regen=0.4    lower the healer's mana regen  (make mana tighter)
#     --fortify=0.5  the tank's Fortify self-heal   (lower = healer works more)
#     e.g.  ./tune.sh riftmaw --dmg=1.25 --regen=0.45
#
#  Bosses:  riftmaw (the teacher) · mistral · gemini · mythos (finale)
#  Seeds = how many random fights it averages. 30 = rough & fast, 150 = precise.
#
#  When a build feels right, lock it in for real: bake the winning numbers into
#  data/raid/raid_content.gd (+ the regen_mult / raid_self_heal_mult), then run
#  the FULL sim once (no --probes=0, ~150 seeds) to confirm determinism + bands.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail
cd "$(dirname "$0")"                       # run from repo root, wherever you call it

GODOT="${GODOT:-$HOME/.local/bin/godot}"
[ -x "$GODOT" ] || GODOT=godot             # fall back to PATH

BOSS=riftmaw; SEEDS=30; SKILLS=good,sloppy; KNOBS=()
for a in "$@"; do
  case "$a" in
    -h|--help)                grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    riftmaw|mistral|gemini|mythos) BOSS=$a ;;
    all)                      SKILLS=expert,good,sloppy ;;
    expert|good|sloppy)       SKILLS=$a ;;
    --*)                      KNOBS+=("$a") ;;          # a live knob → pass through
    ''|*[!0-9]*)              echo "  (ignoring unknown arg: $a)" ;;
    *)                        SEEDS=$a ;;               # a bare number → seeds
  esac
done

echo "» boss=$BOSS  seeds=$SEEDS  skills=$SKILLS  ${KNOBS[*]:-}"
CMD=("$GODOT" --headless --path godot --script res://sim/raid_sim.gd --
     --boss="$BOSS" --seeds="$SEEDS" --skills="$SKILLS" --probes=0)
[ ${#KNOBS[@]} -gt 0 ] && CMD+=("${KNOBS[@]}")
"${CMD[@]}" 2>&1 | grep -vE '^Godot Engine|^$'
