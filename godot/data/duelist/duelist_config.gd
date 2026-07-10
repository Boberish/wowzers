## DuelistConfig — tuning for THE DUELIST, the dodge tank (TANK-PLAN §1/§1b, DUELIST-BRIEF S1).
## A Resource so balance sims can sweep it. Numbers = the tester-v5 baseline knobs (TANK-PLAN
## §1d end); RULES are locked, NUMBERS are first-cut → Bill's playtest supersedes them (the
## two-track process: structure now, feel from the thinnest live slice).
##
## THE FEEL: dense/twitch. LOW HP that swings fast (a build for a quick healer). WIND = a small
## pool with fast recharge (the "ninja" bubble) — it is the anti-spam leash, NOT a flat cooldown.
## DODGE (secondary) recovers fast; PARRY (main) recovers slow even on a land. Every mitigation
## leaks a sliver (partial-mit law, cap .90 — the healer is never bored) and NO self-heal, ever.
class_name DuelistConfig
extends Resource

# --- the body: LOW HP, fast swings ---
@export var hp_max: float = 320.0          ## low-ish, swings fast (playtest — the "quick healer" build)

# --- THE WIND (fatigue): a small pool, fast recharge (the leash, not a global cd) ---
@export var wind_max: float = 10.0
@export var wind_regen: float = 2.2        ## per second
@export var dodge_cost: float = 1.0        ## a DODGE press
@export var parry_cost: float = 3.5        ## a PARRY press — land OR miss (the commit)

# --- ANSWER WINDOWS (tick-native — the 30 Hz wall: never author tighter than ~2 ticks). A press
#     opens an "answer" that mitigates the NEXT incoming bar; the bar is graded by how tight the
#     press was to impact (fresh press = PERFECT). active = how long the answer stays open. ---
@export var answer_active: float = 0.50    ## the answer covers this long after the press
@export var parry_perfect: float = 0.10    ## a bar landing within this of a PARRY press = PERFECT (~3 ticks)
@export var parry_good: float = 0.26
@export var dodge_perfect: float = 0.12
@export var dodge_good: float = 0.30

# --- MITIGATION (fraction REMOVED), by button × grade. Cap .90 (a sliver always leaks). PARRY
#     (main) answers ANY size incl. tall; DODGE (secondary) leaks MORE the bigger the bar (the
#     height law — small any / normal ok / tall = MAIN only, so a dodged tall barely helps). ---
@export var mit_parry_perfect: float = 0.95
@export var mit_parry_good: float = 0.70
@export var mit_parry_graze: float = 0.40
@export var mit_dodge_perfect: float = 0.80
@export var mit_dodge_good: float = 0.55
@export var mit_dodge_graze: float = 0.28
@export var mit_cap: float = 0.90
@export var dodge_leak_per_size: float = 0.30  ## a DODGE loses this much mit per size step over LIGHT

# --- ◆ COMBO (build-and-spend). Income is PARRY-only at base (a perfect parry banks a pip);
#     spend = ⚡ DUMP (pure damage — tanks are defense-rich / damage-poor). ---
@export var combo_max: int = 5
@export var dump_per_combo: float = 70.0
@export var counter_dmg: float = 30.0      ## a PERFECT PARRY hits back for this (+ banks a ◆)

# --- RECOVERY: DODGE fast, PARRY slow (even on a land); a fumble (no wind / mis-press) is worse ---
@export var dodge_recover: float = 0.35
@export var parry_recover: float = 0.60
@export var fumble_recover: float = 1.30
@export var gcd: float = 0.60              ## the DUMP GCD (defensive presses are NOT on the GCD)

# --- FLOW start: the pull opens ON the tank (aggro ≥ the lock floor); slip and it drifts.
#     The shared flow economy knobs (gain/slip/decay/spike/lock-floor) live on TuningConfig —
#     they outlive any one tank class; only the pull's starting value is class-flavored here. ---
@export var flow_start: float = 0.55       ## initial flow so the boss opens on the tank

# --- THE DECK (creeds/modules/boons/rig — S5..S7). ALL guarded: an empty creed + no modules +
#     no boons + no rig reproduce the base numbers, so the base build stays byte-identical. ---
# EN GARDE (S6) — the signature CD
@export var engarde_cd: float = 60.0       ## ~1-min cooldown
@export var engarde_dur: float = 4.0       ## the challenge window
@export var engarde_break_slips: int = 2   ## two slips break it early
# MODULES (auto-fire off a gauge)
@export var crucible_full: float = 900.0   ## damage TAKEN that IGNITES the Crucible
@export var crucible_ignite_sec: float = 6.0
@export var crucible_crash_sec: float = 4.0
@export var whet_sharpen_sec: float = 4.0  ## a banked ◆ sharpens over this long
@export var whet_sharp_mult: float = 1.5   ## a sharp pip hits ×this in a dump
@export var scales_edge_max: float = 0.12  ## near-balance edge cap (±12%)
@export var flow_dump_max: float = 0.50    ## FLOW module: dump +up to this at full flow
# BOONS (first-cut; playtest tunes)
@export var heavier_steel_mult: float = 1.30
@export var feather_step_mult: float = 0.65
@export var feather_step_floor: float = 0.5
@export var deep_pockets_cap: int = 1
@export var powder_keg_per: float = 0.30
@export var all_in_mult: float = 1.40
@export var lodestone_decay_mult: float = 0.60
@export var hold_line_mult: float = 1.08
@export var overreach_hp_cost: float = 0.07  ## fraction of max HP a winded parry costs in blood
@export var overreach_floor: float = 0.10    ## never below this HP frac
# TRANSFORMS (§10) — kit-local knobs
@export var seize_max_hold: float = 1.2      ## Prise de Fer: max seize hold (s)
@export var seize_throw_mult: float = 1.5    ## a full seize throws for ≈ counter ×this
@export var remise_prime_frac: float = 0.34  ## Remise: the prime costs ~1/3 the parry
@export var remise_leak_cut: float = 0.30    ## a primed-then-missed bar leaks this much less
@export var fleche_load_sec: float = 2.5     ## Flèche: the load window
@export var fleche_bonus: float = 0.25       ## a released flèche hits full dump +this
