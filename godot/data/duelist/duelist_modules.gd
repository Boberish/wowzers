## DuelistModules — the Floor-1 MODULE data for THE DUELIST (TANK-PLAN §3 · §9.1). The HUD offers
## 3-of-4 rolled at Floor-1; each auto-fires off a gauge. DATA only (id/type/blurb + the tuning
## knobs on DuelistConfig); the MECHANICS live guarded in DuelistKit via _m(id) — no module = the
## base build, byte-identical. Mirrors the Well/Twinfang module static API.
class_name DuelistModules
extends RefCounted

const MODULES := {
	"crucible": {
		"name": "The Crucible", "type": "RULE", "star": true,
		"blurb": "TRANSFORMER. Damage TAKEN fills it (the bleed is fuel). At full it IGNITES ~6s of WHITE STEEL — parries cost 0 wind, lands bank ◆◆, counters ×1.5 — then CRASHES (regen dead 4s, gauge empty). Timing the ignite into an unavoidable stretch is the decision. (Fills slower while the boss is peeled away.)",
	},
	"scales": {
		"name": "The Scales", "type": "STRAT",
		"blurb": "A balance pan: parries tip it crimson, dodges tip it blue. Near BALANCE it grows an edge (up to +12% dealt / −12% taken); pegging either side KILLS the edge until you re-centre. Anti-autopilot — mix your answers.",
	},
	"whetstone": {
		"name": "The Whetstone", "type": "GREED",
		"blurb": "Each banked ◆ SHARPENS over 4s; a sharp pip hits ×1.5 in a DUMP. But an un-answered real hit DULLS your sharpest pip. Hold to sharpen vs spend before you slip — with teeth.",
	},
	"flow": {
		"name": "The Flow", "type": "STRAT",
		"blurb": "Your FLOW is a weapon: while it's high your ⚡ DUMP hits harder (up to +50% at full flow). The aggro-hold becomes a damage engine — play clean, hit harder. (The repurposed flow module, §1b.)",
	},
}

const V1 := ["crucible", "scales", "whetstone", "flow"]

static func get_module(id: String) -> Dictionary:
	return MODULES.get(id, {})

static func ids() -> Array:
	return MODULES.keys()

## The HUD samples 3-of-4 at Floor-1 (§9.1 tension-point lean).
static func v1_ids(_aspect := "") -> Array:
	return V1.duplicate()

static func is_star(id: String) -> bool:
	return bool(MODULES.get(id, {}).get("star", false))

static func built_ids() -> Array:
	return V1.duplicate()

static func has_tag(_id: String, _tag: String) -> bool:
	return false
