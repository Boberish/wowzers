## DuelistConfig — tuning for THE DUELIST, the dodge tank (TANK-PLAN §0 THE CHANNEL CONTRACT v3,
## tank-v2 rewrite). A Resource so balance sims can sweep it. RULES are locked in §0; NUMBERS
## are first-cut → Bill's playtest supersedes them.
##
## THE FEEL: dense/twitch. LOW HP that swings fast (a build for a quick healer). WIND = a small
## pool with fast recharge — the anti-spam leash, NOT a flat cooldown. The v3 choice economy:
## PARRY = the damage/aggro engine (binary land/miss, counter + ◆ + flow spike, best mit, big
## wind cost) · DODGE = the economy play (cheap, graded GRAZE<GOOD<PERFECT<BULLSEYE, no counter;
## a BULLSEYE dodge answers anything aimed at you). Every mitigation leaks a sliver (partial-mit
## law, cap .90 — the healer is never bored) and NO self-heal, ever.
class_name DuelistConfig
extends Resource

# --- the body: LOW HP, fast swings ---
@export var hp_max: float = 320.0          ## low-ish, swings fast (playtest — the "quick healer" build)

# --- THE WIND (fatigue): a small pool, fast recharge (the leash, not a global cd) ---
@export var wind_max: float = 10.0
@export var wind_regen: float = 2.2        ## per second
@export var dodge_cost: float = 1.0        ## a DODGE press (FLURRY MODE presses are FREE — §0)
@export var parry_cost: float = 3.5        ## a PARRY press — land OR miss (the commit)

# --- ANSWER WINDOWS (tick-native — the 30 Hz wall: never author tighter than ~2 ticks).
#     STREAM bars: THE PRESS (§0 pass 2) — a press CLAIMS the nearest bar within ±answer_claim
#     and is judged INSTANTLY, symmetric around gate-touch: |press−impact|/answer_claim on the
#     grade_*_frac ladder (PARRY binary at ±parry_land). TELEGRAPH busters/globals keep the
#     open-window model: the press stays open answer_active and grades by press age at impact
#     (parry_window / dodge_* below). ---
@export var answer_active: float = 0.50    ## telegraph path: the answer stays open this long after the press
@export var answer_claim: float = 0.30     ## DEC-14 claim range: a press answers a bar within
                                           ## ±this of now; among several, the tie-break picks nearest
                                           ## |impact−now| → earliest impact → lowest id (deterministic)
@export var parry_land: float = 0.07       ## stream-claim PARRY: lands within ±this of gate-touch
                                           ## (~2 ticks symmetric — tick-native, never float-ms)
@export var grade_bull_frac: float = 0.18  ## stream-claim DODGE ladder: |press−impact|/answer_claim
@export var grade_perfect_frac: float = 0.55
@export var grade_good_frac: float = 0.80  ## …beyond = GRAZE, out to the claim edge
@export var parry_window: float = 0.10     ## telegraph land window (~3 ticks) — binary, the commit
@export var dodge_bullseye: float = 0.07   ## telegraph dead-center read (~2 ticks) — answers heavy/buster
@export var dodge_perfect: float = 0.14
@export var dodge_good: float = 0.30

# --- MITIGATION (fraction REMOVED). THE SINGLE MIT AUTHORITY (DEC-6): DODGE tops out at
#     BULLSEYE = .85, strictly UNDER the partial-mit cap .90 (a sliver always leaks — the healer
#     is never bored); a LANDED PARRY = .95 is the one explicit ABOVE-cap payout, the reward for
#     the binary commit. The v3 legality matrix (enforced in the kit's claim funnel before grading):
#     AUTO = parry or dodge any grade · HEAVY/BUSTER = parry, or dodge at BULLSEYE only
#     (and the power leak still applies — parry stays preferred on the big ones) ·
#     GLOBALS = dodge-only if one reaches this funnel (parry rejected); EAT takes no press. ---
@export var mit_parry_land: float = 0.95
@export var mit_parry_miss: float = 0.18   ## a pressed-but-out-of-window parry keeps a token cut
@export var mit_dodge_bullseye: float = 0.85
@export var mit_dodge_perfect: float = 0.80
@export var mit_dodge_good: float = 0.55
@export var mit_dodge_graze: float = 0.28
@export var mit_cap: float = 0.90
@export var dodge_leak_per_size: float = 0.30  ## a DODGE loses this much mit per size step over LIGHT

# --- ◆ COMBO (build-and-spend). Income is PARRY-only at base (a landed parry banks a pip);
#     spend = ⚡ DUMP (pure damage — tanks are defense-rich / damage-poor). ---
@export var combo_max: int = 5
@export var dump_per_combo: float = 70.0
@export var counter_dmg: float = 30.0      ## a LANDED PARRY hits back for this (+ banks a ◆)

# --- RECOVERY: DODGE fast, PARRY slow (even on a land); a fumble (no wind / mis-press) is worse.
#     FLURRY MODE presses recover on their own fast clock (beats come ~0.35s apart). ---
@export var dodge_recover: float = 0.35
@export var parry_recover: float = 0.60
@export var flurry_recover: float = 0.15
@export var fumble_recover: float = 1.30
@export var gcd: float = 0.60              ## the DUMP GCD (defensive presses are NOT on the GCD)

# --- FLURRY MODE (§0): dodge-only, parry sealed, wind FREE — pure execution, don't miss one.
#     Miss a beat and the group is BLOWN (the rest land unmitigated); weave it clean and the
#     free RIPOSTE pays out. ---
@export var flurry_riposte_mult: float = 1.2   ## the clean-weave riposte ≈ counter × this

# --- FLOW start: the pull opens ON the tank (aggro ≥ the lock floor); slip and it drifts.
#     The shared flow economy knobs (gain/slip/decay/spike/lock-floor) live on TuningConfig. ---
@export var flow_start: float = 0.75         ## EASY AGGRO (DEC-8 / pass 2): open with a real cushion

# --- EN GARDE (the ~1-min signature CD): the invite — melee tempo +25% (engine-side via the
#     stream tempo), leaks/slivers HALVED, clean answers pay DOUBLE flow, two slips break it. ---
@export var engarde_cd: float = 60.0
@export var engarde_dur: float = 4.0
@export var engarde_break_slips: int = 2
