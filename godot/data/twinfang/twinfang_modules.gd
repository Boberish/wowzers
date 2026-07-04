## TwinfangModules — the MODULE data for the Tempo rework (TEMPO-PLAN §4).
##
## A Module is a Hades-weapon-style UI addon: it puts a new gauge on the HUD and adds a
## way to play. You pick ONE at the end of Floor 1 (later — the pick UI is a follow-up).
## Each is kit-gated by `modules[id]`; equipping none = base Tempo (byte-identical path).
##
## Curated picks, NOT rarity-weighted. Tuning lives in TwinfangConfig (mod_edge_* / mark_*).
class_name TwinfangModules
extends RefCounted

const MODULES := {
	"opening": {
		"name": "The Opening", "kicker": "Offense timing", "gauge": "wound",
		"blurb": "A boss swing overextends it — slam your dumps into the vulnerability window for a spike.",
		"built": true,
	},
	"edge": {
		"name": "The Edge", "kicker": "Greed dial", "gauge": "heat",
		"blurb": "Your window runs TIGHTER (Perfect-only, no graze) and Perfects hit harder. Narrow for damage.",
		"built": true,
	},
	"deathmark": {
		"name": "The Deathmark", "kicker": "Combo layer", "gauge": "marks",
		"blurb": "Perfects stamp a Mark on the boss; your next dump DETONATES them for a burst.",
		"built": true,
	},
	"metronome": {
		"name": "The Metronome", "kicker": "Second rhythm", "gauge": "pendulum",
		"blurb": "An external steady beat — land Strikes ON it for a bonus. (design)",
		"built": false,
	},
	"hemorrhage": {
		"name": "The Hemorrhage", "kicker": "Sustain", "gauge": "bleed",
		"blurb": "Perfects open a stacking bleed; a dump reopens it for a spike. (design)",
		"built": false,
	},
}

static func get_module(id: String) -> Dictionary:
	return MODULES.get(id, {})

static func ids() -> Array:
	return MODULES.keys()

## The modules whose mechanics are implemented (offerable in the Floor-1 pick).
static func built_ids() -> Array:
	var out: Array = []
	for id in MODULES:
		if bool(MODULES[id].get("built", false)):
			out.append(id)
	return out
