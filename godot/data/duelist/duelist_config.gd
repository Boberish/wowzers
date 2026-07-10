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
