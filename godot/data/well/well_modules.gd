## WellModules — the MODULE data for the reworked healer (MENDER-PLAN §3). Mirrors the
## TwinfangModules / AlchemistModules static API (get_module / ids / built_ids / has_tag)
## so the shared HUD framework dispatches by class. A Module is a Hades-weapon-style addon:
## a new HUD gauge + a new hands-free way the Well pays you back. You install ONE at the end
## of Floor 1. Each is kit-gated by modules[id]; equipping none = the base Well (byte-identical).
##
## All three AUTO-FIRE off the gauge (no extra button — the Well is already a 6-cast triage
## game, and the AI healer must pilot every module) so they add a NEW READ, never a new key.
##
## The three (⭐ transformer = the Reservoir, the re-homed Tidecaller flywheel):
##   The Reservoir ⭐ — SPILL banks into a reserve chamber; at full it SURGES a burst heal
##                      to the lowest ally (and re-banks a share). Overheal stops being waste.
##   Triage Protocol — bloodied allies build NERVE; at full it auto-fires LAST STAND
##                      (a party heal + a brief raid-wide damage cut). The reactive save.
##   Benediction     — good grades (a pour · a clean/still draw) light a PIP; the 5th cashes
##                      a party-wide BLOOM. Rewards clean play with a team payoff.
class_name WellModules
extends RefCounted

const MODULES := {
	"reservoir": {
		"name": "The Reservoir", "kicker": "⭐ Transformer", "gauge": "reserve",
		"blurb": "OVERHEAL stops being waste: every SPILL banks into the Reservoir. Fill it and it SURGES — a big burst heal to the most-hurt ally, and a share of the surge re-banks. The overheal build: spill on purpose, pour it back when it counts.",
		"built": true,
		"tags": [],
	},
	"triage": {
		"name": "Triage Protocol", "kicker": "Reactive", "gauge": "nerve",
		"blurb": "When it gets scary, steady the hand: every bloodied ally (below 40%) builds NERVE. At full, LAST STAND fires itself — a heal across the whole party and a brief damage cut for everyone. The panic button that presses itself.",
		"built": true,
		"tags": [],
	},
	"benediction": {
		"name": "Benediction", "kicker": "Combo / calm", "gauge": "bene",
		"blurb": "Clean play compounds: every good grade (a pour, or a clean/Still-Point draw) lights a PIP. The fifth pip cashes a BENEDICTION — a bloom of healing across the whole warband. Set a rhythm and the team drinks from it.",
		"built": true,
		"tags": [],
	},
	"vigil": {
		"name": "The Vigil", "kicker": "⭐ Transformer", "gauge": "hold", "spec": "draw",
		"blurb": "Walk with the drawn arrow: every OVERRUN becomes a HELD heal cocked in your hand (~3s). Release it the instant the spike lands for a full, instant heal. The hold visibly TREMBLES toward its gutter — camp too long and it's wasted, charge and cast both. The overrun stops being a shrug and becomes the held save. (DRAW only — Brim has no overrun to hold.)",
		"built": true,
		"tags": [],
	},
	"confluence": {
		"name": "The Confluence", "kicker": "Two wells", "gauge": "conflu",
		"blurb": "Split the Well into two chambers you fill in turn. (design)",
		"built": false,
		"tags": [],
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

## Built modules offerable for an aspect. A module with a `spec` is per-spec (⭐The Vigil is
## DRAW-only — Brim has no overrun to hold); specless modules read fine under either aspect.
static func offer_ids(aspect := "") -> Array:
	var out: Array = []
	for id in built_ids():
		var spec := String((MODULES.get(id, {}) as Dictionary).get("spec", ""))
		if spec != "" and spec != aspect:
			continue
		out.append(id)
	return out

## Does this module carry `tag` (for creed-aware offers)? No Well creed hides a module in v1.
static func has_tag(id: String, tag: String) -> bool:
	return tag in (MODULES.get(id, {}).get("tags", []) as Array)
