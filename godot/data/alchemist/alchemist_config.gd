## All Alchemist ("the Brew" — ALCHEMIST-PLAN.md) tuning constants, lifted verbatim
## from the feel-test artifact (003f6832…) so the Godot base plays EXACTLY like the
## thing Bill thumb-tested. A Resource so balance sims can sweep it.
##
## The verb is "brew the reaction": hold to charge the VIAL (fill accelerates hard near
## the top — greed), release in the sweet band for a POTENT pour, feed two OPPOSING
## poisons (Venom fades fast / Rot lingers), and the reaction = min(V,R) × balance.
## POTENCY fills while the reaction is balanced-and-fed and multiplies EVERYTHING;
## RUPTURE cashes the brew (FUEL × POWER) into a burst — the BUILD→PEAK→REBUILD wave.
class_name AlchemistConfig
extends Resource

@export var hp_max: float = 330.0

# --- the two poisons (artifact: CAP=12, DECAY_V=2.0, DECAY_R=0.5) ---
# SATURATION CUT (Bill 2026-07-06 — playtested off, "better off"): a full side no
# longer wastes pours. The HARD cap is the only ceiling; `soft` survives ONLY as the
# potency-fed reference (below), not a saturation line.
@export var cap: float = 12.0            ## hard cap per poison
@export var soft: float = 9.0            ## potency-fed reference: min(V,R) ≥ soft·pot_feed_frac counts as "fed"
@export var decay_venom: float = 2.0     ## per second — hot, fades FAST (demands attention)
@export var decay_rot: float = 0.5       ## per second — cold, LINGERS (set it and it holds)

# --- the VIAL (hold-release charge; artifact dL/dt = 0.40 + 1.9·L², max 1.30) ---
@export var charge_rate: float = 0.40    ## base fill per second
@export var charge_quad: float = 1.9     ## quadratic term — the fill ACCELERATES near the top
@export var charge_max: float = 1.30     ## the needle pegs here (deep overflow)
@export var fizzle_below: float = 0.45   ## min-charge floor: release under this = nothing (no tap-spam)
@export var sweet_lo: float = 0.70       ## sweet band start — POTENT dose
@export var sweet_hi: float = 0.98       ## sweet band end; (sweet_hi, 1.0] = HOT (bigger, riskier)
@export var overflow_at: float = 1.0     ## past the red line = SPOILED (~nothing)
@export var dose_ok: float = 3.0         ## an early (honest but weak) pour
@export var dose_sweet: float = 8.0      ## a sweet-band POTENT pour
@export var dose_hot: float = 9.0        ## the last 2% before the red line — the greed edge
@export var dose_spoiled: float = 1.0    ## overflow — nearly nothing

# --- the REACTION (artifact: REACT_MULT=5.5, RAW_MULT=0.4, RCONSUME=0.08) ---
@export var react_mult: float = 5.5      ## reaction dps per point of min(V,R), before balance/potency
@export var raw_mult: float = 0.4        ## weak single-poison drip per point of V+R (stacking one side is bad)
@export var react_consume: float = 0.08  ## the reaction EATS the brew: min·this/s off BOTH sides

# --- POTENCY (artifact: POT_FILL=0.26, POT_DRAIN=0.5, ×1 → ×2.6) ---
@export var pot_fill: float = 0.26       ## per second while the reaction is balanced AND fed
@export var pot_drain: float = 0.5       ## per second when lopsided or dry — sloppiness bleeds power
@export var pot_amp: float = 1.6         ## multiplier ceiling: ×(1 + potency·this) on EVERYTHING
@export var pot_feed_frac: float = 0.45  ## "fed" gate: min(V,R) ≥ soft·this
@export var pot_bal_min: float = 0.72    ## "balanced" gate: balance > this

# --- RUPTURE (artifact: burst = min · 24 · potMult; keeps 35%) ---
@export var rupture_per: float = 24.0    ## burst per point of min(V,R), ×potency mult
@export var rupture_keep: float = 0.35   ## both sides keep this fraction after the blast (the rebuild seed)
@export var rupture_min: float = 1.0     ## below this min(V,R) the tap is a dud (nothing to rupture)

# --- HUD ripe cue (artifact: rupGlow = min(1, m/8) · (0.35 + 0.65·potency)) ---
@export var ripe_fuel: float = 8.0       ## min(V,R) that reads as "full fuel" on the Rupture sigil
@export var ripe_glow_min: float = 0.35  ## the glow the fuel alone can reach at zero potency

# --- MODULES (Floor-1 pick; all guarded — no module = byte-identical base) ---
# Third Reagent: a catalyst bar charges, tap to amp the reaction for a window.
@export var reagent_fill: float = 0.10   ## catalyst charge per second (≈10s to full)
@export var reagent_amp: float = 0.60    ## reaction ×(1+this) while the catalyst is active
@export var reagent_dur: float = 5.0     ## seconds the amp lasts after a drop
# Fermentation: a meter fills while fed+balanced, auto-detonates at full (the calm module).
@export var ferment_fill: float = 0.11   ## meter per second while the reaction is good (≈9s)
@export var ferment_burst: float = 150.0 ## detonation damage at full, ×potency mult ×dmg_scale
# Reaction-Vessel (⭐): the reaction banks here instead of dealing; Rupture dumps it.
@export var vessel_release: float = 1.0  ## multiplier on the Vessel dump at Rupture

# --- BOONS (drafted; all guarded in the kit — no boon = byte-identical base) ---
@export var deep_cauldron_cap: float = 4.0    ## Deep Cauldron: both poison caps +this
@export var preservative_mult: float = 0.75   ## Preservative: both decays ×this
@export var clinging_rot_mult: float = 0.2    ## Clinging Rot: Rot decay ×this
@export var steady_pour_widen: float = 0.4    ## Steady Pour: sweet band WIDER by this fraction
@export var practiced_hand_mult: float = 0.92 ## Practiced Hand: charge rate ×this (a CALMER climb — a human-comfort sidegrade, so a light AI cost)
@export var quick_study_mult: float = 1.3     ## Quick Study: potency fill ×this
@export var distilled_focus_mult: float = 0.7 ## Distilled Focus: potency drain ×this
@export var concentrate_mult: float = 1.2     ## Concentrate: potency ceiling (pot_amp) ×this
@export var killing_draught_hp: float = 0.3   ## Killing Draught: below this boss HP frac, potency won't drain
@export var corrosive_blood_mult: float = 0.18   ## Corrosive Blood: reaction +this
@export var volatile_reaction_mult: float = 0.25 ## Volatile Reaction: reaction +this while potency > 0.66
@export var perfect_emulsion_mult: float = 0.30  ## Perfect Emulsion: reaction +this while balance ≥ 0.9
@export var deepening_rot_max: float = 0.40   ## Deepening Rot: reaction ramps up to +this
@export var deepening_rot_rate: float = 0.08  ## Deepening Rot: ramp gained per second fed+balanced
@export var rupturing_mult: float = 0.35      ## Rupturing: Rupture burst +this
@export var chain_rupture_keep: float = 0.30  ## Chain Rupture: rupture_keep +this (base 0.35 → ~0.65)
@export var catalyst_phantom: float = 0.5     ## Catalyst: phantom copy = burst ×this (value snapshot)
@export var debilitate_per: float = 1.5       ## Debilitator: stacks/sec fed by a live reaction (net +1.0/s vs 0.5 decay)
@export var debilitate_max: float = 3.0       ## Debilitator: stack cap (× TuningConfig.debilitate_k in damage_boss)

# --- SPELLS (drafted; keys 5/6/7) ---
@export var spitfire_dmg: float = 22.0        ## Spitfire: instant off-brew dart (×dmg_scale)
@export var spitfire_cd: float = 1.2          ## Spitfire: short cd so it's filler, not spam
@export var decant_cd: float = 8.0            ## Decant: snap-to-balance cooldown
@export var decant_frac: float = 0.5          ## Decant: move this fraction of the gap into the low side
@export var reduction_cd: float = 12.0        ## Reduction: volume→potency cooldown
@export var reduction_take: float = 0.35      ## Reduction: consume this fraction of the brew (less fuel lost)
@export var reduction_pot: float = 0.45       ## Reduction: instant Potency gained (a solid slug; persists across ruptures)

# --- dodge (the defensive verb — standard footwork numbers for the base build;
#     the F3 auto-evasion identity is an OPEN call settled by playtest) ---
@export var dodge_active: float = 0.55
@export var dodge_zone: float = 0.42
@export var dodge_cd: float = 2.4

# --- raid fit ---
## Global outgoing-damage scale. The artifact was tuned against a 3500 HP dummy;
## raid Seals are 13.5–19k with 4 seats — this dials the whole brew into the
## blade-seat DPS band without touching any of the feel numbers above. Sim-tuned.
@export var dmg_scale: float = 0.55

## The ability book (perform() ids). brew_venom/brew_rot START a charge, pour RELEASES
## it, rupture detonates. No GCD, no resource cost — the vial's timing is the gate.
@export var abilities: Dictionary = {
	"brew_venom": {"name": "Brew Venom", "key": "1"},
	"brew_rot":   {"name": "Brew Rot",   "key": "2"},
	"pour":       {"name": "Pour",       "key": "release"},
	"rupture":    {"name": "Rupture",    "key": "3"},
	"catalyst":   {"name": "Drop Catalyst", "key": "4"},  # only live with The Third Reagent module
}

## The bar for an Aspect. The Brew is the whole class (working-name filler aspect id).
func loadout(_aspect: String) -> Array:
	return ["brew_venom", "brew_rot", "rupture"]
