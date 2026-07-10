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
		"built": false,
	},
	"edge": {
		"name": "The Edge", "kicker": "Greed dial", "gauge": "heat",
		"blurb": "Your window runs TIGHTER (Perfect-only, no graze) and Perfects hit harder. Narrow for damage.",
		"built": false,
	},
	"deathmark": {
		"name": "The Deathmark", "kicker": "Combo layer", "gauge": "marks",
		"blurb": "Perfects stamp a Mark on the boss; your next dump DETONATES them for a burst.",
		"built": false,
	},
	"overdrive": {
		"name": "The Overdrive", "kicker": "Transformer", "gauge": "overdrive",
		"blurb": "At max Flow the multiplier stops and fills an OVERDRIVE meter — unleash a FEVER (window all-green, Strikes auto-chain at Coup tier), then crash to a seed and rebuild.",
		"built": true,
		"aspect": "tempo",
	},
	# --- FERMATA (§13.3) modules — offered on the fermata aspect. ---
	"shadowdance": {
		"name": "Shadow Dance", "kicker": "Transformer", "gauge": "dance",
		"blurb": "Sharp Perfect/Bullseye releases at high Flow fill a meter; unleash THE DANCE — 3s where THERE IS NO SNAP (ride past the lip freely, everything grades at least Perfect, coils sharpen instantly) — then crash to a seed. Three seconds of fearlessness.",
		"built": true,
		"aspect": "fermata",
	},
	"mark": {
		"name": "The Mark", "kicker": "Combo layer", "gauge": "brand",
		"blurb": "Sharp Bullseye releases brand the boss (tier I→III). Eviscerate CONSUMES the brand for +12% per tier — cash at II or push for III? A finisher decision, not a passive.",
		"built": true,
		"aspect": "fermata",
	},
	"metronome": {
		"name": "The Metronome", "kicker": "Second rhythm", "gauge": "pendulum",
		"blurb": "An external steady beat — land Strikes ON it for a bonus. (design)",
		"built": false,
	},
	# --- D0 S1 · v4 branch modules (Tempo) — THE WOUND counter + THE EDGE keen meter ---
	"hemorrhage": {
		"name": "The Hemorrhage", "kicker": "The wound counter", "gauge": "bleed",
		"blurb": "The WOUND pot on the boss frame (count + total). Bleeds tick +1 beat longer, and Eviscerate may CASH the pot - consume every live bleed, pay its remaining value instantly +10% per bleed. Cash-now or let-it-tick is a per-Evis decision.",
		"built": true, "aspect": "tempo", "theme": "wound",
	},
	"strop": {
		"name": "The Strop", "kicker": "The KEEN meter", "gauge": "keen",
		"blurb": "Consecutive Perfect-or-better strikes whet a KEEN gauge (cap 5); your next CRIT consumes all KEEN for +8% per stack. Spend it on a strike or hold it for a dump - crit timing becomes a decision. THE EDGE's module.",
		"built": true, "aspect": "tempo", "theme": "edge",
	},
}

static func get_module(id: String) -> Dictionary:
	return MODULES.get(id, {})

static func ids() -> Array:
	return MODULES.keys()

## The modules whose mechanics are implemented (offerable in the Floor-1 pick). Pass an aspect
## to get only that aspect's modules — a module with no "aspect" key is aspect-neutral.
static func built_ids(aspect := "") -> Array:
	var out: Array = []
	for id in MODULES:
		if not bool(MODULES[id].get("built", false)):
			continue
		var a := String(MODULES[id].get("aspect", ""))
		if aspect != "" and a != "" and a != aspect:
			continue
		out.append(id)
	return out
