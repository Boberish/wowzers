## WellRig — the Well's ONE Combo rig (MENDER-PLAN §4; mirrors TwinfangRig / AlchemistRig).
## You wire ONE WHEN → ONE THEN at the first draft (re-wire once at Floor 2). A WHEN is an
## earned HEALING moment authored off this class's OWN grades; a THEN is a modest side-boost.
## A flavour layer (~10% of throughput), not a pillar.
##
## THE GREED-DIAL PAYOUT (same construction as Twinfang/Alchemist): a THEN's magnitude is
## base × mult, and `mult` ≈ inverse-frequency × a rarity premium — so a frequent WHEN
## (Sweet Pour / Clean Draw) fires a small payoff often, a rare WHEN (Low Catch / Still
## Point) fires a big one seldom. The board shows the number before you commit.
##
## WHENs are PER-SPEC (Brim grades landings, Draw grades releases) — `spec` scopes the board
## so a Brim run never sees a Draw WHEN. THENs are shared (both specs heal the same way).
class_name WellRig
extends RefCounted

## WHEN moments off the Well's grades. Sweet Pour / Clean Draw = the 1.0 anchors (one per spec).
const WHENS := {
	# --- BRIM (grade the landing) ---
	"sweet_pour":  {"name": "Sweet Pour",  "mult": 1.0, "tier": "frequent", "spec": "brim", "blurb": "a PERFECT POUR — the steady drumbeat of clean landings."},
	"spill_catch": {"name": "Spillover",   "mult": 2.0, "tier": "medium",   "spec": "brim", "blurb": "a SPILL — turn the overflow into a little something back."},
	"low_catch":   {"name": "Low Catch",   "mult": 4.5, "tier": "rare",     "spec": "brim", "blurb": "pour on an ally below 25% — a catch from the very brink."},
	# --- DRAW (grade the release) ---
	"clean_draw":  {"name": "Clean Draw",  "mult": 1.0, "tier": "frequent", "spec": "draw", "blurb": "a CLEAN release — the steady drumbeat of good draws."},
	"high_water":  {"name": "High Water",  "mult": 2.5, "tier": "medium",   "spec": "draw", "blurb": "a clean draw at MAX Current — cashed while riding high."},
	"still_point": {"name": "Still Point", "mult": 5.5, "tier": "rare",     "spec": "draw", "blurb": "tag the STILL POINT — the hairline centre of the band."},
}

## THEN effects. `base` is the per-fire magnitude at the 1.0 anchor; the WHEN's mult scales it.
## `kind` drives how the kit applies it. `charge`/`glint` are FRACTIONAL (raw_amount → a float
## accumulator / a duration in seconds); the rest read as whole numbers.
const THENS := {
	"mend":    {"name": "Mend",    "base": 14.0, "kind": "heal",   "blurb": "a splash of healing on the most-hurt ally."},
	"ward":    {"name": "Ward",    "base": 12.0, "kind": "shield", "blurb": "a small absorb shield braces the most-hurt ally."},
	"bloom":   {"name": "Bloom",   "base": 7.0,  "kind": "party",  "blurb": "a bloom of healing washes over the whole warband."},
	"draught": {"name": "Draught", "base": 0.35, "kind": "charge", "blurb": "a draught of charges drips back into the Well."},
	"gleam":   {"name": "Gleam",   "base": 0.8,  "kind": "glint",  "blurb": "the most-hurt ally catches the light — a bonus Glint."},
}

static func mult(when_id: String) -> float:
	return float((WHENS.get(when_id, {}) as Dictionary).get("mult", 1.0))

## The raw (unrounded) base × mult — CHARGE (float accumulator) and GLINT (seconds) apply this
## directly so they can be tuned below 1 (a per-fire int floor of 1 would dominate frequent WHENs).
static func raw_amount(when_id: String, then_id: String) -> float:
	var t: Dictionary = THENS.get(then_id, {})
	if t.is_empty() or not WHENS.has(when_id):
		return 0.0
	return float(t["base"]) * mult(when_id)

static func then_kind(then_id: String) -> String:
	return String((THENS.get(then_id, {}) as Dictionary).get("kind", ""))

## The computed magnitude for a WHEN→THEN pairing — the number the kit applies AND the number
## the wiring board shows. base*mult rounded to an int (fractional kinds read via raw_amount).
static func magnitude(when_id: String, then_id: String) -> int:
	var t: Dictionary = THENS.get(then_id, {})
	if t.is_empty() or not WHENS.has(when_id):
		return 0
	return int(round(float(t["base"]) * mult(when_id)))

## A one-line "WHEN → THEN: N" for the wiring board / HUD.
static func describe(when_id: String, then_id: String) -> String:
	if not (WHENS.has(when_id) and THENS.has(then_id)):
		return ""
	var w: Dictionary = WHENS[when_id]
	var t: Dictionary = THENS[then_id]
	var kind := String(t["kind"])
	if kind == "charge":
		return "WHEN %s → THEN %s +%.1f charges" % [String(w["name"]), String(t["name"]), raw_amount(when_id, then_id)]
	if kind == "glint":
		return "WHEN %s → THEN %s +%.1fs Glint" % [String(w["name"]), String(t["name"]), raw_amount(when_id, then_id)]
	var n := magnitude(when_id, then_id)
	var units := {"heal": " heal", "shield": " absorb", "party": " party heal"}
	var unit: String = units.get(kind, "")
	return "WHEN %s → THEN %s +%d%s" % [String(w["name"]), String(t["name"]), n, unit]

static func when_ids() -> Array:
	return WHENS.keys()

static func then_ids() -> Array:
	return THENS.keys()

## Which spec a WHEN belongs to ("brim"/"draw") — the board filters WHENs to the run's aspect.
static func when_spec(id: String) -> String:
	return String((WHENS.get(id, {}) as Dictionary).get("spec", ""))

## Does a WHEN/THEN carry `tag`? No Well creed hides rig entries in v1 (the framework calls these).
static func when_has_tag(_id: String, _tag: String) -> bool:
	return false

static func then_has_tag(_id: String, _tag: String) -> bool:
	return false

## Deterministic n-of-N offer from `pool` using the run's draft stream (Fisher–Yates).
## Mirrors TwinfangRig.offer / AlchemistRig.offer so the shared HUD wiring board is class-agnostic.
static func offer(pool: Array, rng, n := 3) -> Array:
	var ids: Array = pool.duplicate()
	if rng != null:
		for i in range(ids.size() - 1, 0, -1):
			var j := int(rng.next_u32() % (i + 1))
			var t = ids[i]; ids[i] = ids[j]; ids[j] = t
	return ids.slice(0, mini(n, ids.size()))
