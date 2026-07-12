## Every balance-critical number lives here — NOT as a hard-coded literal in the
## engine. The sim harness sweeps these to tune the game (see PORT-PLAN.md §M3).
## This is the whole point of the "tuning-first" architecture: change numbers,
## re-run thousands of sims, read the win-rate bands.
class_name TuningConfig
extends Resource

## Fixed simulation rate. The engine advances in whole ticks of 1/fixed_hz seconds.
## 30 Hz is ample for these low-frequency combat decisions and cheap for netcode.
@export var fixed_hz: int = 30

# --- Defensive verb (tank) ---
@export var defense_active: float = 0.5        ## how long a press stays "active", seconds
@export var defense_cd: float = 2.2            ## cooldown between presses, seconds
@export var defense_mitigation: float = 0.7    ## fraction of a defended hit removed (0..1)

# --- Win condition: group damage curve  f(hp%) = f_floor + f_scale * hp_frac ---
# Healthy allies deal more damage, so the boss dies before your party/resources run out.
@export var f_floor: float = 0.3
@export var f_scale: float = 0.7

# --- Enrage ramp ---
@export var enrage_base: float = 6.0           ## raid dmg/sec added per second past enrage

# --- PACK walk-in (WORLD-PLAN §FIGHT LENGTH: the diegetic valley) ---
## Ticks after a pack member takes the field before it ACTS (no melee/telegraphs/forms).
## Players may act — opening on the approaching enemy is the pull fantasy. Only pack
## members 2+ ever have entered_tick > 0, so classic fights never read this.
@export var pack_walkin_ticks: int = 75        ## 2.5s at 30 Hz

# --- boss scheduling + engine ceilings (the P4 literals sweep — defaults are the
#     exact old hard-codes, so every fight stays byte-identical until someone tunes) ---
@export var open_stagger_base: float = 2.0     ## first ability arms this many seconds in
@export var open_stagger_step: float = 1.5     ## each further ability arms this much later
@export var open_stagger_jitter: float = 0.3   ## + rng × (cd × this) — spreads the opening
@export var silence_recheck: float = 0.4       ## a silenced interruptible cast re-checks after this
@export var chain_splash: float = 0.28         ## CHAIN ability: the arced second hit's fraction
@export var dmg_buff_cap: float = 0.55         ## EMPOWER_BOSS permanent-buff ceiling (+55%)
@export var curse_answer_window: float = 2.0   ## a taunt within this of a THREAT_DROP answers the curse

# --- THE STREAM (TANK-PLAN §0, tank-v2; only melee dicts carrying a "rhythm" key read these —
#     every other fight is byte-identical) ---
@export var rhythm_open_delay: float = 0.5     ## first stream bar lands this many seconds after the pull
@export var stream_horizon: float = 3.0        ## publish lead: bars commit this far ahead (the visible runway)
@export var stream_gap_after_cast: float = 0.6 ## RETIRED (tank-v3 S2): the barrier is gone; publishing no longer reads this
@export var stream_answer_clear: float = 0.30  ## RETIRED (tank-v3 S2): the barrier is gone; no longer read by the publisher
@export var stream_flurry_cd: float = 10.0     ## min spacing between texture-rolled flurry bursts
@export var stream_late_lead: float = 0.55     ## a LATE bar pops in this many seconds before impact
@export var stream_late_min_travel: float = 0.4## DEC-11 fairness floor: a LATE pop is guaranteed at
                                               ## least this much remaining travel (obs lead = max(lead, this))
@export var stream_late_cap: int = 8           ## DEC-11 per-fight LATE budget (a SealTune knob; a melee
                                               ## dict may override with "late_cap"); beyond it, bars ship on-time
@export var stream_resolve_slack: float = 0.04 ## THE PRESS: damage bars resolve this long AFTER gate-touch —
                                               ## ~1 tick of tick-alignment fairness ONLY (Bill 2026-07-12: a
                                               ## comet never sits pressable at the line; past the line = MISSED,
                                               ## it turns red and keeps flowing). Feints/eats resolve at impact.
## CONTINUITY RE-BASELINE (tank-v3 S2 fallout, 2026-07-12): retiring the barrier made the
## melee stream publish CONTINUOUSLY — the old model DROPPED every bar that fell inside a
## telegraph/cast (barrier<0 → no publish, stream_next_impact frozen), so the tank now faces
## the bars it used to be spared, raising its total melee exposure ~15-20% on cast-heavy Seals.
## This single scalar holds the tank's stream DPS near the pre-continuity budget (one knob, not
## four per-Seal magic numbers). FIRST CUT — final value is Bill's playtest (project law).
@export var stream_dmg_mult: float = 0.85      ## global scale on every committed stream bar's damage

# --- SUNDER (tank break meter; only the Bulwark feeds boss.sunder, so this is inert for
#     every other class/fight — boss.sunder stays 0 → the amplifier is a guarded no-op). ---
@export var sunder_max: float = 5.0            ## pip ceiling
@export var sunder_k: float = 0.06             ## boss takes +6% MORE per pip (×1.30 at full)
@export var sunder_decay: float = 1.1          ## pips bled per second when not fed (aggressive)
# --- DEBILITATE (Alchemist Debilitator boon feeds boss.debilitate; inert/0 for everyone else) ---
@export var debilitate_k: float = 0.03         ## boss takes +3% MORE per stack (×1.09 at 3 stacks)
@export var debilitate_decay: float = 0.5      ## stacks bled per second when not fed (gentle corrosion)

# --- M7 strike strings + the universal dodge ---
# Grade windows: seconds BEFORE a beat's impact that a dodge press still answers
# it (perfect ⊂ good ⊂ graze; outside graze the press is a WHIFF). Sized for the
# 30 Hz tick — never author a window tighter than ~2 ticks (66ms).
@export var strike_perfect: float = 0.14
@export var strike_good: float = 0.34
@export var strike_graze: float = 0.50
@export var dodge_recovery: float = 0.35   ## min gap between dodge presses (tank-v3 S3 / §7 item 1:
                                           ## REVERTED 0.8 -> 0.35. The barrage un-collapse restores the
                                           ## non-tank multi-beat DODGE RATION (authored beats >= this gap
                                           ## apart), so a one-dodge seat must weave at the 0.35s cadence
                                           ## again. The tank's own leash is WIND, not this shared constant.)
@export var dodge_whiff_cd: float = 1.3    ## lockout for a press that answered nothing (or took a feint beat's bait)
@export var graze_mult: float = 0.5        ## damage fraction still taken on a GRAZE of a DODGEABLE beat
# BLOCKABLE beats: damage fraction that lands anyway, by grade (partial even when perfect).
@export var block_perfect: float = 0.25
@export var block_good: float = 0.5
@export var block_graze: float = 0.75
@export var statblock_dodge: float = 0.65  ## stat-block ally chance to auto-dodge an answerable beat

# --- FLOW=AGGRO (threat_enabled fights only; ignored by all solo content). TANK-PLAN §1c:
#     the tank's FLOW (0..1) is the boss's attention. RULES locked, NUMBERS = playtest
#     (first thing a live slice tunes — build-process-two-track). No taunt exists. ---
## EASY AGGRO (DEC-8 / pass 2, carried into v3 2026-07-12: the branch was cut PRE pass-2
## and shipped the harsh pre-pass-2 aggro — restore the mandated cut): slips sting a third
## as hard, drift crawls, the lock floor is halved, answers refill faster — losing the boss
## now takes a real losing STREAK (~10 straight slips), and clean play claws it back. Knobs.
@export var flow_lock_floor: float = 0.15    ## flow ≥ this → boss locked on the tank; below → peel
@export var flow_gain_perfect: float = 0.10  ## a BULLSEYE/PERFECT answer adds this much flow
@export var flow_gain_good: float = 0.08     ## a GOOD answer
@export var flow_gain_graze: float = 0.04    ## a GRAZE / a held READ
@export var flow_slip: float = 0.05          ## an un-clean answer (miss/whiff/baited) DROPS flow
@export var flow_spike: float = 0.20         ## a LANDED PARRY grants this bonus flow — the valve
@export var flow_decay: float = 0.02         ## flow drifts down this much/sec (hold it by playing clean)

# --- Draft 2.0 token mint (game layer reads state.diag at fight end — see game/draft.gd;
#     diag is deterministic and never in the checksum, so these can't shift combat) ---
@export var mint_per_grades: int = 3         ## PERFECT dodges + held feints per Token
@export var mint_per_signature: int = 4      ## class-signature skill events per Token
@export var mint_flawless_bonus: int = 1     ## bonus Token: no miss/bait/whiff all fight
@export var mint_cap: int = 3                ## max Tokens minted per fight

func dt() -> float:
	return 1.0 / float(fixed_hz)
