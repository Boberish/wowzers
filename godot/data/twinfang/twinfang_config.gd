## All Twinfang (Melee DPS) tuning constants + the ability table, lifted verbatim
## from poc/twinfang.html. A Resource so balance sims can sweep it.
##
## The verb is "drive the rhythm": Strike is gated by a per-strike timing window
## (wait for the green), not a GCD. Perfect Strikes build Flow, and Flow multiplies
## ALL your damage — chaining Perfects is the skill ceiling. Getting hit by a swing
## wipes Flow, so dodging protects your damage as much as your health.
class_name TwinfangConfig
extends Resource

@export var hp_max: float = 310.0
@export var energy_max: float = 100.0
@export var energy_regen: float = 20.0      ## per second

@export var cp_max: int = 5                 ## combo points
@export var flow_max: int = 6
@export var flow_per: float = 0.08          ## +8% damage per Flow point
@export var flow_decay_every: float = 2.4   ## seconds without a Perfect → lose 1 Flow

# --- M7 strike strings: dodge-beat payoffs (PERFECT grants +1 Flow — no knob) ---
@export var strike_good_energy: float = 6.0
@export var strike_read_energy: float = 10.0

# --- the rhythm: seconds since your last Strike ---
@export var swing_min: float = 0.42         ## earliest you may Strike (before = ignored, no cost)
@export var perfect_start: float = 0.60     ## [perfect_start, perfect_end] = the green window (Perfect)
@export var perfect_end: float = 0.95

# --- dodge (the defensive verb) ---
@export var dodge_active: float = 0.55      ## how long a dodge stays "active"
@export var dodge_zone: float = 0.42        ## the visible answer window (last stretch of the swing)
@export var dodge_cd: float = 2.4

# --- Venomancer poison model ---
@export var ven_cap: int = 8                ## per-type poison cap (V/F/C)
@export var syn_cap: float = 1.8            ## Toxic Synergy ramp cap
@export var syn_rate: float = 0.14          ## Synergy growth per second while all three live
@export var venom_decay_every: float = 3.0  ## every this long, each poison type bleeds 1 stack
@export var venom_tick_every: float = 1.0   ## poison damage cadence

## The ability book. `effect` is inferred from the fields/id in TwinfangKit.
## strike is the rhythm builder; eviscerate/envenom are finishers (spend all combo);
## coupdegrace/rupture are the per-Aspect signatures; flurry is a draftable spell.
@export var abilities: Dictionary = {
	"strike":      {"name": "Strike",        "key": "1", "energy": 12.0, "dmg": 19.0, "cp": 1},
	"eviscerate":  {"name": "Eviscerate",    "key": "2", "energy": 25.0, "finisher": true, "per_cp": 23.0},
	"kick":        {"name": "Kick",          "key": "3", "energy": 10.0, "cd": 7.0, "interrupt": true},
	"envenom":     {"name": "Envenom",       "key": "4", "energy": 25.0, "finisher": true, "poison": true},
	"flurry":      {"name": "Flurry",        "key": "5", "energy": 28.0, "dmg": 13.0, "cp": 2, "hits": 3},
	"coupdegrace": {"name": "Coup de Grâce", "key": "4", "energy": 30.0, "cd": 5.0, "spec": "tempo", "dmg": 120.0},
	"rupture":     {"name": "Rupture",       "key": "4", "energy": 22.0, "cd": 3.5, "spec": "venomancer", "per": 9.0},
}

## The four-slot bar for an Aspect (signature appended last). Draft spells fill 5+.
func loadout(aspect: String) -> Array:
	if aspect == "tempo":
		return ["strike", "eviscerate", "kick", "coupdegrace"]
	return ["strike", "envenom", "kick", "rupture"]
