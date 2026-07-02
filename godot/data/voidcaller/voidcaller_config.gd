## All Voidcaller (Caster DPS) tuning constants + the spellbook, lifted from
## poc/voidcaller.html. A Resource so balance sims can sweep it.
##
## The verb is "interrupt": reading the boss's purple cast bar IS the fight. Space kicks
## the current cast (its own cooldown, not the GCD); a CLEAN interrupt — in the last
## slice of the bar — pays extra (Backlash / longer Silence). Every break also heals you.
##
## Fixed prototype discrepancies (fix-not-port, per CLAUDE.md): interrupt cd uses the
## executed 5.0 (the dead `const 3.5` was overwritten at runtime); Barrier cd = 10 and
## Overload = 68/Backlash are the executed code values (tooltips now match).
class_name VoidcallerConfig
extends Resource

@export var gcd: float = 1.0
@export var hp_max: float = 340.0
@export var focus_max: float = 100.0

@export var fracture_cast: float = 1.15
@export var pushback: float = 0.4          ## taking a hit mid-cast pushes it back this long
@export var push_cap: float = 1.2          ## …but a cast can't be pushed past cast+this

@export var int_cd: float = 5.0            ## interrupt (Space) cooldown
@export var int_cd_snap: float = 3.0       ## Snap Cast relic
@export var clean_zone: float = 0.62       ## last slice of a cast where a kick counts "clean"
@export var int_heal: float = 14.0         ## a broken cast feeds you — active kicking sustains

# --- M7 strike strings: dodge-beat payoffs ---
@export var strike_perfect_focus: float = 12.0  ## a PERFECT dodge feeds Focus
@export var strike_read_focus: float = 8.0      ## holding a feint beat pays too

# Disruptor
@export var backlash_max: int = 5
@export var bl_dmg: float = 52.0           ## Space-interrupt damage (regular)
@export var bl_dmg_clean: float = 104.0    ## …clean
@export var overload_per_bl: float = 68.0  ## Overload damage per Backlash spent

# Silencer
@export var sil_dur: float = 3.0           ## Space silence (regular)
@export var sil_dur_clean: float = 4.6     ## …clean
@export var expose_amt: float = 0.30       ## Exposed = you deal +30% to the boss
@export var sil_spell_dur: float = 2.5     ## the Silence spell's lockout
@export var quietus_sil: float = 5.0
@export var quietus_expose: float = 0.50

## The spellbook. Behaviour is dispatched by id in VoidcallerKit.
@export var abilities: Dictionary = {
	"bolt":         {"name": "Bolt",         "key": "1", "cost": 0.0,  "dmg": 34.0,  "focus": 14.0, "instant": true},
	"fracture":     {"name": "Fracture",     "key": "2", "cost": 26.0, "dmg": 118.0, "cast": 1.15},
	"barrier":      {"name": "Barrier",      "key": "3", "cost": 0.0,  "dr": 0.45, "dr_dur": 3.0, "cd": 10.0, "instant": true},
	"overload":     {"name": "Overload",     "key": "4", "cost": 0.0,  "spec": "disruptor", "instant": true},
	"quietus":      {"name": "Quietus",      "key": "4", "cost": 30.0, "spec": "silencer", "instant": true, "cd": 9.0},
	"silence":      {"name": "Silence",      "key": "5", "cost": 0.0,  "interrupt": true, "cd": 11.0, "silences": true, "instant": true},
	"counterspell": {"name": "Counterspell", "key": "5", "cost": 0.0,  "interrupt": true, "cd": 9.0, "reflect": 90.0, "instant": true},
}

## The four-slot bar for an Aspect (signature in slot 4). Draft spells fill slot 5.
func loadout(aspect: String) -> Array:
	if aspect == "disruptor":
		return ["bolt", "fracture", "barrier", "overload"]
	return ["bolt", "fracture", "barrier", "quietus"]
