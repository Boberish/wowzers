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
@export var brim_band: float = 0.90        ## land at/above this HP frac, no spill = PERFECT POUR
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

# --- THE BOOK: all heals are CAST, direct (Ward/Renew/Meditate cut from base). Costs in
#     CHARGES. Single-target flash/mend carry the grade; cascade/spring are throughput;
#     dispel is free utility; rekindle is the no-CD battle-rez commitment. ---
@export var book: Dictionary = {
	"flash":    {"name": "Flash Heal", "key": "1", "charges": 2, "cast": 1.5, "heal": 70.0,  "target": true},
	"mend":     {"name": "Mend",       "key": "2", "charges": 1, "cast": 2.6, "heal": 95.0,  "target": true},
	"cascade":  {"name": "Cascade",    "key": "3", "charges": 3, "cast": 2.0, "heal": 45.0,  "target": false, "aoe": 3,  "cd": 8.0},
	"spring":   {"name": "Wellspring", "key": "4", "charges": 4, "cast": 2.5, "heal": 55.0,  "target": false, "aoe": 99, "cd": 22.0},
	"dispel":   {"name": "Dispel",     "key": "q", "charges": 0, "cast": 0.0,                "target": true,  "offgcd": true, "cd": 8.0, "dispel": true},
	"rekindle": {"name": "Rekindle",   "key": "r", "charges": 6, "cast": 6.0,                "target": true,  "cd": 0.0, "revive": true, "revive_frac": 0.40},
}

## The bar for an Aspect. Both specs share the whole book — the aspect only changes how
## the graded window reads, not the buttons.
func loadout(_aspect: String) -> Array:
	return ["flash", "mend", "cascade", "spring", "dispel", "rekindle"]
