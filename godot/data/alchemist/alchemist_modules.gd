## AlchemistModules — the MODULE data for the Brew (ALCHEMIST-PLAN §3). Mirrors the
## TwinfangModules static API (get_module / ids / built_ids) so the shared HUD framework
## dispatches by class. A Module is a Hades-weapon-style addon: a new ALEMBIC gauge + a new
## way to play. You install ONE at the end of Floor 1. Each is kit-gated by modules[id];
## equipping none = the base brew (byte-identical path).
##
## The three (the ⭐ TRANSFORMER = Reaction-Vessel, ALCHEMIST-PLAN pre-build verdict 1):
##   Third Reagent — a charging catalyst you tap to AMP the reaction for a while (active)
##   Fermentation  — a meter that fills from sustained reaction and auto-DETONATES (calm)
##   Reaction-Vessel ⭐ — INVERTS the loop: the reaction banks instead of dealing; Rupture
##                        dumps the whole vessel — a pure charge-and-release cannon
class_name AlchemistModules
extends RefCounted

const MODULES := {
	"third_reagent": {
		"name": "The Third Reagent", "kicker": "Active catalyst", "gauge": "catalyst",
		"blurb": "A catalyst bar charges up top. TAP it (key 4) to drop it in — the reaction is amplified for a few seconds. Drop it while potency is high for the biggest window.",
		"built": true,
		"tags": [],
	},
	"fermentation": {
		"name": "Fermentation", "kicker": "Calm / auto", "gauge": "ferment",
		"blurb": "A meter fills whenever the reaction is fed and balanced. At full it FERMENTS — a hands-free detonation. The low-intensity pick: set the brew and let it cook.",
		"built": true,
		"tags": ["rupture"],   # a detonation identity — hidden from the no-burst Purist (verdict 6)
	},
	"reaction_vessel": {
		"name": "The Reaction-Vessel", "kicker": "⭐ Transformer", "gauge": "vessel",
		"blurb": "INVERTS the brew: the reaction deals NOTHING — it banks into the Vessel. RUPTURE dumps the whole Vessel at once. A pure charge-and-release cannon; stall or die with it full and the damage is never dealt.",
		"built": true,
		"tags": ["rupture"],   # a burst identity — hidden from the no-Rupture Purist (verdict 6)
	},
	"twin_still": {
		"name": "The Twin-Still", "kicker": "Two reactions", "gauge": "still",
		"blurb": "Run two reactions at once. (design)",
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

## Does this module carry `tag` (for creed-aware offers — Purist hides "rupture" modules)?
static func has_tag(id: String, tag: String) -> bool:
	return tag in (MODULES.get(id, {}).get("tags", []) as Array)
