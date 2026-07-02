## All Mender (Healer) tuning constants + the spellbook, lifted from poc/mender.html.
## A Resource so the sim can sweep it.
class_name MenderConfig
extends Resource

@export var gcd: float = 1.2
@export var mana_max: float = 900.0
@export var mana_regen: float = 8.0        ## per second (× regen_mult × dt)
@export var strike_perfect_mana: float = 20.0  ## M7: a PERFECT dodge refunds a sip of mana

# Tidecaller
@export var tide_conv: float = 0.55        ## fraction of overheal banked into the Reservoir
@export var reservoir_max: float = 520.0

# Brinkwarden
@export var brink_heal_scale: float = 1.5  ## heal ×(1 + (1-hp%)*scale) → 2.5× at 0%
@export var brink_mana_disc: float = 0.55  ## mana ×(1 - (1-hp%)*disc)  → 45% at 0%
@export var blood_thresh: float = 0.40     ## at/under this an ally is "bloodied"
@export var nerve_max: float = 100.0
@export var nerve_rate: float = 7.0        ## Nerve/sec per bloodied ally
@export var ls_heal: float = 2.6           ## Last Stand heal = Nerve × this
@export var ls_dr: float = 0.45            ## Last Stand party DR
@export var ls_dur: float = 3.0

## The spellbook. `effect` is inferred from the fields present.
@export var spells: Dictionary = {
	"flash":     {"name": "Flash Heal", "key": "1", "mana": 22.0, "cast": 1.5, "cd": 0.0,  "target": true,  "heal": 70.0},
	"mend":      {"name": "Mend",       "key": "2", "mana": 16.0, "cast": 2.6, "cd": 0.0,  "target": true,  "heal": 95.0},
	"renew":     {"name": "Renew",      "key": "3", "mana": 18.0, "cast": 0.0, "cd": 0.0,  "target": true,  "hot_tick": 12.0, "hot_every": 1.5, "hot_dur": 9.0},
	"ward":      {"name": "Ward",       "key": "4", "mana": 20.0, "cast": 0.0, "cd": 6.0,  "target": true,  "shield": 60.0, "ward_dur": 6.0},
	"cascade":   {"name": "Cascade",    "key": "5", "mana": 40.0, "cast": 2.0, "cd": 8.0,  "target": false, "heal": 45.0, "aoe": "lowest3"},
	"well":      {"name": "Wellspring", "key": "6", "mana": 30.0, "cast": 0.0, "cd": 30.0, "target": false, "heal": 90.0, "aoe": "all"},
	"dispel":    {"name": "Dispel",     "key": "q", "mana": 10.0, "cast": 0.0, "cd": 8.0,  "target": true,  "offgcd": true, "dispel": true},
	"medit":     {"name": "Meditate",   "key": "e", "mana": 0.0,  "cast": 0.0, "cd": 45.0, "target": false, "offgcd": true, "restore": 280.0},
	"surge":     {"name": "Surge",      "key": "7", "mana": 15.0, "cast": 0.0, "cd": 0.0,  "target": false, "spec": "tidecaller"},
	"laststand": {"name": "Last Stand", "key": "7", "mana": 20.0, "cast": 0.0, "cd": 0.0,  "target": false, "spec": "brinkwarden"},
}

## Ability bar order (the signature is appended per aspect).
func order(aspect: String) -> Array:
	return ["flash", "mend", "renew", "ward", "cascade", "well", "dispel", "medit",
		("surge" if aspect == "tidecaller" else "laststand")]
