## The Reckoner (Warrior / melee DPS) tuning — verb: COMMIT. The swing clock
## AUTO-ADVANCES; you shape each swing with two tick-stamped presses:
##   WIND  (Timer 1) — when you commit picks the WEIGHT (Quick/Even/Heavy, or the
##                     OVER end-sliver when Overswing is armed).
##   STRIKE(Timer 2) — how you land the contracting apex picks the POWER
##                     (Finesse/True/Overload; no tap = a weak Glance).
## The cross-product is a grid of hits; a sloppy press only DEGRADES to a weaker
## valid hit (never a whiff). Ported from a tuned browser greybox (True band ±1 tick).
##
## A Resource so balance sims can sweep it. All windows are in SECONDS here and
## converted to ticks by the kit (ticks are truth). No GCD — the swing paces you.
class_name ReckonerConfig
extends Resource

@export var hp_max: float = 560.0
@export var rage_max: float = 100.0
@export var momentum_max: float = 8.0        ## clock-speed state, in ticks shaved off the next wind
@export var poise_max: float = 100.0

# --- the swing windows (seconds) ---
@export var wind_len: float = 0.90           ## the WIND window: tap anywhere in it to commit
@export var apex_delay: float = 0.40         ## STRIKE apex opens this long after the commit
@export var true_half: float = 0.033         ## ± this around the apex = a TRUE hit (~1 tick — Bill's pick)
@export var overload_late: float = 0.20      ## after True, still Overload out to here
@export var strike_deadline: float = 0.10    ## grace past overload_late before an auto-Glance
@export var recover: float = 0.27            ## dead time after a swing resolves before the next wind opens
@export var base_gap: float = 0.20           ## + this (minus Momentum) sets the next wind; the cadence
@export var gap_floor: float = 0.13          ## the interval never collapses below this

# --- weight zones (fraction of the wind window) & their damage multipliers ---
@export var quick_hi: float = 0.3333         ## [0, quick_hi) = Quick
@export var even_hi: float = 0.6667          ## [quick_hi, even_hi) = Even ; [even_hi, 1] = Heavy
@export var over_lo: float = 0.85            ## when Overswing armed, [over_lo, 1] = OVER
@export var w_quick: float = 0.7
@export var w_even: float = 1.0
@export var w_heavy: float = 1.5
@export var w_over: float = 2.4
@export var w_snap: float = 1.35             ## Snapshot boon super-early zone
@export var w_brink: float = 2.2             ## Brinkguard boon super-late zone

# --- power multipliers. COLOSSUS runs a WIDE spread (True matters a lot → punishing);
#     BERSERKER a NARROW spread (a Glance still lands hard → forgiving of sloppy rhythm). ---
@export var p_finesse: float = 0.7
@export var p_true: float = 1.0
@export var p_overload: float = 1.42
@export var p_glance: float = 0.42
@export var pb_finesse: float = 0.82
@export var pb_true: float = 1.0
@export var pb_overload: float = 1.3
@export var pb_glance: float = 0.70
@export var bers_out_per_mom: float = 0.02   ## Berserker: Momentum also snowballs damage

# --- damage ---
@export var base_swing: float = 46.0         ## a swing = base_swing × weight × power (× clash × stagger)
@export var clash_bonus: float = 1.4         ## apex released onto a boss impact tick
@export var clash_window: float = 0.10       ## ± this counts as a Clash
@export var stagger_bonus: float = 1.3       ## outgoing mult during a Poise-Break stagger window
@export var stagger_dur: float = 1.3         ## how long the stagger/execute window lasts

# --- resources ---
@export var rage_quick: float = 6.0          ## Rage per landed swing, by weight
@export var rage_even: float = 9.0
@export var rage_heavy: float = 12.0
@export var rage_on_hit: float = 8.0         ## Rage per chip taken (the greed loop — being hit feeds you)
@export var mom_gain_true: float = 2.0       ## a True apex quickens the next wind
@export var mom_loss_glance: float = 3.0     ## a Glance/miss slows it
@export var poise_true_colossus: float = 14.0
@export var poise_true_berserker: float = 8.0
@export var poise_clash: float = 12.0

# --- the dodge (defensive verb — negate a heavy swing; light chip is eaten for Rage) ---
@export var def_active: float = 0.5
@export var def_cd: float = 2.2
@export var def_zone: float = 0.45           ## answer window: press when the swing is this close

# --- Berserker: hyperarmor (momentum-scaled DR) ---
@export var bers_dr_per_mom: float = 0.035   ## Berserker mitigates min(cap, momentum × this)
@export var bers_dr_cap: float = 0.30

# --- abilities ---
@export var over_cost: float = 15.0
@export var over_cd: float = 2.4
@export var over_recover: float = 0.53       ## the overswing's longer recovery (commitment cost)
@export var ultra_cost: float = 12.0
@export var ultra_cd: float = 3.0
@export var ultra_delay: float = 0.43        ## the inserted bonus apex opens this long after the strike
@export var ultra_base: float = 55.0
@export var ultra_true: float = 3.0          ## super-strong on a tight tap
@export var ultra_overload: float = 3.4
@export var ultra_finesse: float = 1.5
@export var ultra_glance: float = 0.9
@export var ons_cost: float = 30.0
@export var ons_cd: float = 13.0             ## a periodic signature, not the main damage
@export var ons_base: float = 40.0           ## per pair; a phrase sums three
@export var ons_all_true: float = 1.5        ## all-True crescendo bonus
@export var seq_wind: float = 0.60           ## the onslaught sub-wind window
@export var seq_apex: float = 0.37           ## the onslaught sub-apex delay

## The four-slot rune bar for an Aspect (used by the HUD later).
func loadout(aspect: String) -> Array:
	if aspect == "berserker":
		return ["overswing", "ultraswing", "onslaught", "berserk"]
	return ["overswing", "ultraswing", "onslaught", "sunder"]
