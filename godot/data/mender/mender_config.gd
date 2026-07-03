## All Mender (Healer) tuning constants + the spellbook, lifted from poc/mender.html.
## A Resource so the sim can sweep it.
class_name MenderConfig
extends Resource

@export var gcd: float = 1.2
@export var mana_max: float = 900.0
@export var mana_regen: float = 8.0        ## per second (× regen_mult × dt)
@export var strike_perfect_mana: float = 20.0  ## M7: a PERFECT dodge refunds a sip of mana

# --- LITANY: the visible combo pip meter (both aspects). An IN-CONDITION single-target
#     heal lights a pip; payloads scale ×(1 + litany_per_pip · pips); the 5th pip cashes a
#     party Benediction bloom and resets. The aspect INVERTS the fill condition — the two
#     builds literally can't be piloted the same way to feed the same meter:
#       Tidecaller: a heal LEAVING the target at/above foresight_line (topped AHEAD).
#       Brinkwarden: a heal CATCHING the target at/below blood_thresh (0.40, played BEHIND).
@export var litany_max: int = 5
@export var litany_per_pip: float = 0.15   ## payloads scale ×(1 + this × current pips)
@export var litany_decay: float = 3.0      ## seconds without an in-condition heal → lose a pip
@export var foresight_line: float = 0.60   ## Tidecaller's beat line (Brinkwarden reuses blood_thresh)
@export var bene_heal: float = 30.0        ## Benediction party-bloom heal per ally on the 5th pip
@export var ls_spend_frac: float = 0.6     ## Last Stand spends this share of Nerve (keeps the rest)

# Tidecaller
@export var tide_conv: float = 0.55        ## fraction of overheal banked into the Reservoir
@export var reservoir_max: float = 520.0
@export var surge_rebank_frac: float = 0.35  ## the FLYWHEEL: damage a Tidecaller shield ABSORBS
                                             ## re-banks this share into the Reservoir (capped by
                                             ## reservoir_max) — Surge re-arms out of the hits it eats

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

# Phase B slot-verb TRIAGE mods (build-your-Triage; entries with `slot` in MenderBoons).
# Innate proc = a single-target heal resolving on an ally below mod_clutch_frac.
@export var mod_clutch_frac: float = 0.5     ## the "clutch" threshold for the innate proc
@export var mod_shield: float = 25.0         ## mdPayShield absorb on the triaged ally
@export var mod_mana: float = 12.0           ## mdPayMana per proc
@export var mod_hot_tick: float = 8.0        ## mdPayHot tick amount (every 1.5s for 3s)
@export var mod_trig_mana: float = 10.0      ## built-in mana on a drafted trigger fire
@export var mod_cast_mult: float = 0.88      ## mdPropSwift cast-time multiplier
@export var mod_bene_every: int = 5          ## mdPropBenediction: every Nth proc...
@export var mod_bene_heal: float = 30.0      ## ...bathes the whole party for this much
