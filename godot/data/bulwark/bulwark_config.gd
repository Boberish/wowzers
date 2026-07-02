## All Bulwark (Tank) tuning constants, lifted verbatim from poc/bulwark.html.
## Kept as a Resource so balance sims can sweep them. Per-aspect defensive params
## live in dicts; ability numbers in `abilities`.
class_name BulwarkConfig
extends Resource

@export var gcd: float = 1.0
@export var hp_max: float = 520.0
@export var rage_max: float = 100.0

# defensive verb, per aspect: {active, zone, cd} seconds
@export var def_warden: Dictionary = {"active": 0.34, "zone": 0.30, "cd": 2.0}
@export var def_jugg: Dictionary = {"active": 0.55, "zone": 0.42, "cd": 2.2}

# Warden
@export var parry_reflect: float = 50.0
@export var parry_rage: float = 14.0
@export var parry_counter: int = 1
@export var riposte_dur: float = 2.6
@export var riposte_bonus: float = 95.0
@export var counter_max: int = 5

# Juggernaut
@export var mom_dmg: float = 0.06
@export var mom_dr: float = 0.025
@export var mom_max: int = 10
@export var mom_delay: float = 2.5
@export var mom_decay_step: float = 0.5
@export var mom_dr_cap: float = 0.85

# shared
@export var rage_from_dmg: float = 0.42

# The Duelist: consequences of reading (or misreading) a Feint. Punishing on purpose —
# a perfect read takes ~none of this, so only sloppy play feels it.
@export var feint_bait_dmg: float = 150.0    ## you PARRIED a feint — the bait connects
@export var feint_lockout: float = 2.6       ## …and your guard is disrupted this long
                                             ## (must exceed the ~2.0s guard cd to bite;
                                             ## so the NEXT real swing often lands too)
@export var feint_read_rage: float = 18.0    ## you HELD (correct) — bonus rage
@export var feint_exposed_dur: float = 2.2   ## …and the boss is exposed: your dmg is up
@export var feint_exposed_mult: float = 1.30

# M7 strike strings: grade payoffs. A PERFECT dodge feeds the spec engine —
# weaving the combo IS tank gameplay, not just damage avoidance.
@export var strike_perfect_rage: float = 8.0
@export var strike_perfect_counter: int = 1    ## Warden: PERFECT banks Counter + opens Riposte
@export var strike_perfect_momentum: int = 2   ## Juggernaut: PERFECT feeds the snowball
@export var strike_good_rage: float = 4.0
@export var strike_read_rage: float = 10.0     ## held a feint BEAT (smaller than a whole-swing read)
@export var strike_read_exposed: float = 1.4   ## short Exposed window for a beat read

# spec spenders
@export var vindicate_dmg_per: float = 40.0
@export var vindicate_dr: float = 0.25
@export var vindicate_dr_dur: float = 3.0
@export var avalanche_cost: float = 20.0
@export var avalanche_dmg_per: float = 30.0

## Challenge (raid-only taunt): its own cooldown, off-GCD. Unused solo.
@export var challenge_cd: float = 8.0

## Generic abilities (cleave/rampage/fortify + draftable bloodthirst/shockwave).
## Vindicate & Avalanche are handled specially in BulwarkKit.
@export var abilities: Dictionary = {
	"cleave":     {"cost": 0.0,  "dmg": 42.0,  "rage": 6.0, "gcd": 1.0},
	"rampage":    {"cost": 40.0, "dmg": 130.0, "gcd": 1.0},
	"fortify":    {"cost": 30.0, "heal": 130.0, "dr": 0.30, "drDur": 3.5, "gcd": 1.0},
	"bloodthirst":{"cost": 25.0, "dmg": 80.0,  "lifesteal": 0.6, "gcd": 1.0},
	"shockwave":  {"cost": 50.0, "dmg": 55.0,  "stagger": true, "gcd": 1.0},
}
