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
@export var dodge_recovery: float = 0.35   ## min gap between dodge presses
@export var dodge_whiff_cd: float = 1.3    ## lockout for a press that answered nothing (or took a feint beat's bait)
@export var graze_mult: float = 0.5        ## damage fraction still taken on a GRAZE of a DODGEABLE beat
# BLOCKABLE beats: damage fraction that lands anyway, by grade (partial even when perfect).
@export var block_perfect: float = 0.25
@export var block_good: float = 0.5
@export var block_graze: float = 0.75
@export var statblock_dodge: float = 0.65  ## stat-block ally chance to auto-dodge an answerable beat

# --- Raid threat (threat_enabled fights only; ignored by all solo content) ---
@export var threat_tank_mult: float = 4.0    ## tank threat per point of boss damage (dps/healers: 1.0)
@export var threat_heal_factor: float = 0.5  ## threat per point of EFFECTIVE healing
@export var taunt_dur: float = 3.0           ## taunt forces the boss onto you this long, seconds
@export var taunt_threat_bonus: float = 1.1  ## taunt also sets your threat to top × this

# --- Draft 2.0 token mint (game layer reads state.diag at fight end — see game/draft.gd;
#     diag is deterministic and never in the checksum, so these can't shift combat) ---
@export var mint_per_grades: int = 3         ## PERFECT dodges + held feints per Token
@export var mint_per_signature: int = 4      ## class-signature skill events per Token
@export var mint_flawless_bonus: int = 1     ## bonus Token: no miss/bait/whiff all fight
@export var mint_cap: int = 3                ## max Tokens minted per fight

func dt() -> float:
	return 1.0 / float(fixed_hz)
