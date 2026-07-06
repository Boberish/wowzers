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

# --- the two poisons (artifact: CAP=12, SOFT=9, DECAY_V=2.0, DECAY_R=0.5) ---
@export var cap: float = 12.0            ## hard cap per poison
@export var soft: float = 9.0            ## saturation soft cap — pours above waste (dose ×sat_frac)
@export var sat_enabled: bool = true     ## PLAYTEST FLAG (Bill 2026-07-06): off = pours never
                                         ## saturate ("more isn't better" suspended — bank to cap).
                                         ## A/B it live (dev ⚗ SAT toggle) + in alchemist_sim
                                         ## (--sat=off). ⚠ if OFF wins, the Reckless Brewer creed
                                         ## (defined by removing saturation) needs a new hook.
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
@export var sat_frac: float = 0.3        ## dose multiplier pouring into a side already ≥ soft (min 1)

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
}

## The bar for an Aspect. The Brew is the whole class (working-name filler aspect id).
func loadout(_aspect: String) -> Array:
	return ["brew_venom", "brew_rot", "rupture"]
