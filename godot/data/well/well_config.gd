## WellConfig — tuning for the reworked direct-cast healer (MENDER-PLAN.md; codename
## "well", the class name is Bill's open call). A Resource so balance sims can sweep it.
##
## The class is the WELL: a discrete CHARGES economy (no continuous mana) that refills
## in pulses; every heal is a measured pour. Two aspects grade the SAME book in two
## places — BRIM (dev-label TARGET) grades where the heal LANDS on the ally's bar; DRAW
## (dev-label SPEED) grades WHEN you release the cast and rides THE CURRENT (a cast-haste
## streak). A perfect (Brim pour · Draw Still Point) fires the personal GLINT: the healed
## ally deals bonus damage for a few seconds — precision pays OUTWARD, never in charges.
## Numbers seeded from the feel-tester (artifact 80b2169b…); Bill's playtest supersedes.
class_name WellConfig
extends Resource

# --- THE WELL: discrete charges (the whole economy; NO separate mana) ---
@export var charges_max: int = 12
@export var pulse_every: float = 2.0       ## seconds between refill pulses (the ONLY base income)
@export var pulse_amount: int = 1          ## charges per pulse
@export var gcd: float = 1.2

# --- BRIM (aspect "brim" / TARGET): grade the LANDING ---
@export var brim_band: float = 0.80        ## land at/above this HP frac, no spill = PERFECT POUR (Bill's playtest: 0.90→0.80)
@export var spill_eps: float = 0.5         ## overheal above this many HP = SPILL (counted waste)

# --- DRAW (aspect "draw" / SPEED): grade the RELEASE, ride THE CURRENT ---
@export var draw_band: float = 0.15        ## final fraction of the cast where a release is CLEAN
@export var still_point: float = 0.04      ## centre sliver width (frac of the whole bar) = STILL POINT
@export var undercook_exp: float = 1.5     ## early release heals ×(progress ^ this)
@export var current_max: int = 5
@export var current_haste: float = 0.06    ## cast time ×(1 - this·stacks) — faster the higher you ride
@export var current_ebb: float = 4.0       ## seconds idle → shed one stack

# --- THE GLINT (both specs; personal — the healed ally only) ---
@export var glint_mult: float = 1.40       ## glinted ally deals ×this damage
@export var glint_dur: float = 4.0         ## seconds

# --- SKIN (the water's film — the missing-heal base cast, MENDER §13.2). Grades like every
#     cast; for skin_dur seconds the ally's incoming hits SOFTEN — a share DEFERS into a drip
#     over skin_drip_sec. Never absorbs, never heals: every point still arrives, just LATE.
#     Draw-graded / Brim-plain (§0). ALL guarded: no skin cast ⇒ no seat ever gets the drip
#     fields ⇒ the reducer's skin branch is a dead -1 compare ⇒ byte-identical. ---
@export var skin_dur: float = 6.0          ## seconds the film clings to the ally
@export var skin_drip_sec: float = 3.0     ## a deferred chunk drips over this many seconds
@export var skin_defer_clean: float = 0.35 ## CLEAN release: this fraction of each hit defers
@export var skin_defer_plain: float = 0.20 ## plain/overrun/undercook (and every Brim cast): softer
@export var skin_defer_still: float = 0.45 ## STILL POINT: the deepest film (+ a Glint, superset law)

# --- THE DECK (creeds/modules/boons/rig — MENDER-PLAN §2-5). ALL guarded: an empty creed
#     + no modules + no boons + no rig reproduce the base numbers, so the base build stays
#     byte-identical (the sim gate). Creed multipliers live on WellCreeds; these are the
#     class anchors the deck layers scale. ---
# MODULES (Floor-1 pick; each auto-fires off a gauge)
@export var reserve_full: float = 130.0      ## Reservoir SURGES when banked overheal hits this
@export var reserve_bank: float = 0.5        ## fraction of each overheal that banks into the Reservoir
@export var reserve_rebank: float = 0.30     ## fraction of a surge that re-banks (the flywheel)
@export var nerve_full: float = 100.0        ## Triage: LAST STAND fires at full Nerve
@export var nerve_rate: float = 10.0         ## Nerve/sec gained per bloodied ally (below nerve_at)
@export var nerve_at: float = 0.40           ## an ally below this HP frac feeds Nerve
@export var last_stand_heal: float = 90.0    ## party heal when LAST STAND fires
@export var last_stand_dr: float = 0.15      ## raid-wide damage cut on LAST STAND
@export var last_stand_dr_sec: float = 4.0
@export var bene_pips: int = 5               ## Benediction cashes a BLOOM at this many pips
@export var bene_heal: float = 120.0         ## party bloom heal when Benediction cashes
# BOONS (guarded by boon id — see WellBoons)
@export var deep_well_bonus: int = 4         ## Deep Well: +charges to the cap
@export var steady_pulse_mult: float = 0.80  ## Steady Pulse: pulse_every ×this
@export var meditate_charges: int = 6        ## Meditate: charges restored over the channel
@export var shining_hour_mult: float = 1.12  ## Shining Hour: warband damage ×this while topped
@export var shining_hour_floor: float = 0.80 ## every ally at/above this = the Hour is lit
@export var boiling_base: float = 140.0      ## Boiling Over: base boss damage
@export var boiling_per_charge: float = 22.0 ## Boiling Over: +damage per unspent charge (all charges dumped)
@export var brink_bell_absorb: float = 90.0  ## Brink Bell: emergency absorb (once per ally)
@export var brink_bell_at: float = 0.35      ## the drop-below threshold that tolls the bell
@export var still_water_frac: float = 0.25   ## Still Water: pour leaves this fraction of the heal as absorb
@export var second_ring_frac: float = 0.30   ## Second Ring: a pour ripples this fraction to 2nd-most-hurt
@export var overflow_frac: float = 0.33      ## Overflowing Cup: this fraction of spill heals the most-hurt
@export var low_catch_frac: float = 0.25     ## Low Catch: an ally below this = a stronger Glint
@export var low_catch_glint: float = 0.30    ## Low Catch: +glint_mult on the low catch
@export var blindfold_glint: float = 0.40    ## Blindfold: +glint_mult (preview off — HUD reads the flag)
@export var wide_brim_delta: float = 0.08    ## Wide Brim: pour band lowers by this (easier)
@export var loose_grip_mult: float = 1.5     ## Loose Grip: draw clean band ×this (wider)
@export var deep_still_mult: float = 1.6     ## Deep Still: Still Point sliver ×this (wider)
@export var short_pour_exp: float = 0.6      ## Short Pour: undercook exponent (< base → heals more)
@export var strong_pull_bonus: float = 0.30  ## Strong Pull: clean heal ×(1+this) at max Current
@export var double_draw_bonus: float = 0.28  ## Double Draw: 2nd clean within window ×(1+this)
@export var double_draw_sec: float = 3.0
@export var last_drops_at: int = 2           ## Last Drops: charges ≤ this = the dregs bonus
@export var last_drops_heal: float = 0.15    ## Last Drops: heal ×(1+this)
@export var last_drops_haste: float = 0.20   ## Last Drops: cast ×(1-this)
@export var cool_hand_cd: float = 1.0        ## Cool Hand: a clean draw shaves this off Cascade cd
@export var cadence_min: int = 1             ## Cadence of Mend: min charge floor after the discount

# --- D6 DECK RESHAPE (MENDER §12 — themes VIGIL · RAPIDS · EDDY). New Draw boons/keystones,
#     ALL guarded by boon id (no boon ⇒ untouched ⇒ byte-identical). ---
# RAPIDS (the Current ladder)
@export var whitewater_per: float = 0.04       ## Whitewater: a clean/still heal +this per Current stack
@export var shootgap_still_mult: float = 1.30  ## Shoot the Gap: Still-Point tags ×this while at MAX Current
@export var eddyline_cd: float = 10.0          ## Eddyline: min seconds between Current-downgrade saves
@export var flume_hold_sec: float = 12.0       ## The Flume (keystone): hold MAX Current this long to trip it
@export var flume_run_sec: float = 6.0         ## The Flume: seconds every release auto-grades CLEAN, then Current 0
# VIGIL (held heals)
@export var ridetremble_per: float = 0.08      ## Ride the Tremble: a held heal +this per half-second held
@export var ridetremble_cap: float = 0.60      ## Ride the Tremble: the held bonus caps here
@export var loosed_window: float = 0.2         ## Loosed at Last (keystone): held release within this of the ally's hit
@export var loosed_shield_frac: float = 0.5    ## Loosed at Last: the intercept absorb = this × the heal
@export var loosed_shield_sec: float = 2.0
# EDDY (drift reads)
@export var currentreading_third: float = 0.3333 ## Current Reading: a tag in the band's first this-fraction → +1 Current
@export var deepeddy_drift_mult: float = 2.0   ## Deep Eddy: the eddy drift range ×this
@export var deepeddy_still_mult: float = 1.5   ## Deep Eddy: Still-Point tags heal ×this
@export var glassriver_streak: int = 3         ## The Glass River (keystone): consecutive Still tags to freeze the water
@export var glassriver_sec: float = 5.0        ## The Glass River: seconds of frozen drift + all-Still grading

# --- EASE dial (Draw) — the rolled comfort↔bite knobs (MENDER §12.3). The dial MACHINERY is a
#     shared debt (draft.gd knob-roll); until it lands these sit at neutral and nothing sets them.
#     Kept here so the reshape's knob surface is named and the dial has a target when built. ---
@export var ease_draw_band_mult: float = 1.0   ## release-band width (looseGrip's fold — the widener law)
@export var ease_current_ebb_mult: float = 1.0 ## Current ebb-grace (idle seconds before a stack sheds)
@export var ease_gutter_delay: float = 0.0     ## extra seconds before a held heal gutters
@export var ease_drift_mult: float = 1.0       ## eddy drift speed/range

# --- THE BOOK: all heals are CAST, direct (Ward/Renew/Meditate cut from base). Costs in
#     CHARGES. Single-target flash/mend carry the grade; cascade/spring are throughput;
#     dispel is free utility; rekindle is the no-CD battle-rez commitment. ---
@export var book: Dictionary = {
	"flash":    {"name": "Flash Heal", "key": "1", "charges": 2, "cast": 1.5, "heal": 70.0,  "target": true},
	"mend":     {"name": "Mend",       "key": "2", "charges": 1, "cast": 2.6, "heal": 95.0,  "target": true},
	"skin":     {"name": "Skin",       "key": "e", "charges": 1, "cast": 1.4,                "target": true, "skin": true},
	"cascade":  {"name": "Cascade",    "key": "3", "charges": 3, "cast": 2.0, "heal": 45.0,  "target": false, "aoe": 3,  "cd": 8.0},
	"spring":   {"name": "Wellspring", "key": "4", "charges": 4, "cast": 2.5, "heal": 55.0,  "target": false, "aoe": 99, "cd": 22.0},
	"dispel":   {"name": "Dispel",     "key": "q", "charges": 0, "cast": 0.0,                "target": true,  "offgcd": true, "cd": 8.0, "dispel": true},
	"rekindle": {"name": "Rekindle",   "key": "r", "charges": 6, "cast": 6.0,                "target": true,  "cd": 0.0, "revive": true, "revive_frac": 0.40},
	# BOON-GATED spells (drafted via WellBoons; "boon" gates castability, NOT in base loadout):
	"meditate": {"name": "Meditate",   "key": "5", "charges": 0, "cast": 3.0,                "target": false, "boon": true, "cd": 25.0, "battery": true},
	"boil":     {"name": "Boiling Over","key": "6","charges": 0, "cast": 0.0,                "target": false, "boon": true, "cd": 30.0, "dump": true},
}

## The bar for an Aspect. Both specs share the whole book — the aspect only changes how
## the graded window reads, not the buttons.
func loadout(_aspect: String) -> Array:
	return ["flash", "mend", "skin", "cascade", "spring", "dispel", "rekindle"]
