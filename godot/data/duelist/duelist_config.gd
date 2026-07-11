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

# --- THE PRESS MODEL = THE TWINFANG'S (Bill 2026-07-11 pass 2: "the twinfang is super
#     good, do that"). A press CLAIMS the nearest unanswered bar within the claim range and
#     is graded INSTANTLY by |press − impact| as a fraction of the range — symmetric, so a
#     hair-late press grades exactly like a hair-early one (the old early-side-only model
#     read as input lag). Verdict fires at the press; mitigation applies at the bar's
#     resolve. Fractions mirror the blade's grade_bull/perfect_frac for one game feel. ---
@export var answer_claim: float = 0.30     ## a press claims a bar within ± this (the good window)
@export var grade_bull_frac: float = 0.18  ## |off|/claim ≤ this = BULLSEYE (the blade's fraction)
@export var grade_perfect_frac: float = 0.55
@export var grade_good_frac: float = 0.80  ## beyond = GRAZE out to the claim edge
@export var parry_land: float = 0.07       ## PARRY is BINARY: |off| ≤ this (±2t) = the land
# --- the TELEGRAPH path (busters/globals on the cast machinery) keeps the open-window
#     model — those are slow, huge reads; answer_active is generous there ---
@export var answer_active: float = 0.50    ## a press's answer stays open this long (telegraphs)
@export var dodge_bullseye: float = 0.07   ## telegraph-path dodge grading (legacy windows)
@export var dodge_perfect: float = 0.14
@export var dodge_good: float = 0.30

# --- MITIGATION (fraction REMOVED). Cap .90 (a sliver always leaks). The v3 matrix:
#     AUTO = parry or dodge any grade · HEAVY/BUSTER = parry, or dodge at BULLSEYE only
#     (and the power leak still applies — parry stays preferred on the big ones) ·
#     GLOBALS never reach this funnel (dodge-only for every seat, telegraph-side). ---
@export var mit_parry_land: float = 0.95
@export var mit_parry_miss: float = 0.18   ## a pressed-but-out-of-window parry keeps a token cut
# (the resolve slack that makes late presses possible is engine-side: TuningConfig.stream_resolve_slack)
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
@export var flow_start: float = 0.75         ## EASY AGGRO (pass 2): open with a real cushion

# --- EN GARDE (the ~1-min signature CD): the invite — melee tempo +25% (engine-side via the
#     stream tempo), leaks/slivers HALVED, clean answers pay DOUBLE flow, two slips break it. ---
@export var engarde_cd: float = 60.0
@export var engarde_dur: float = 4.0
@export var engarde_break_slips: int = 2
