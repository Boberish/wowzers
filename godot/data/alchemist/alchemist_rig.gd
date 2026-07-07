## AlchemistRig — the Brew's ONE Combo rig (ALCHEMIST-PLAN verdict 2; mirrors TwinfangRig).
## You wire ONE WHEN → ONE THEN at the first draft (re-wire once at Floor 2). A WHEN is an
## earned BREWING moment authored off this class's OWN beats (not "every 3rd Perfect"); a THEN
## is a modest side-boost. A flavour layer (~10% of damage), not a pillar.
##
## THE GREED-DIAL PAYOUT (same construction as Twinfang): a THEN's magnitude is base × mult,
## and `mult` ≈ inverse-frequency × a rarity premium — so a frequent WHEN (Sweet Pour) fires a
## small payoff often, a rare WHEN (Perfect Wave) fires a big one seldom. The board shows the
## number before you commit. Sim/playtest tunes the constants.
class_name AlchemistRig
extends RefCounted

## WHEN moments off the brew's beats. `tags:["rupture"]` marks the burst WHENs the Purist
## never sees (creed-aware board — verdict 6). Sweet Pour = the 1.0 anchor.
const WHENS := {
	"sweet_pour":   {"name": "Sweet Pour",   "mult": 1.0, "tier": "frequent", "tags": [],          "blurb": "a POTENT release — the steady drumbeat of good pours."},
	"hot_pour":     {"name": "Hot Pour",     "mult": 2.3, "tier": "medium",   "tags": [],          "blurb": "a HOT release — the last 2% before the red line, rewarded."},
	"emulsion":     {"name": "Emulsion",     "mult": 3.0, "tier": "medium",   "tags": [],          "blurb": "hold near-perfect balance for 4s — reward the even hand."},
	"ripe":         {"name": "Ripe",         "mult": 4.5, "tier": "rare",     "tags": ["rupture"], "blurb": "Rupture on a glowing RIPE sigil — cash at the peak."},
	"boil":         {"name": "Boil",         "mult": 6.5, "tier": "rare",     "tags": [],          "blurb": "drive Potency to its ceiling — you rode it to a full boil."},
	"perfect_wave": {"name": "Perfect Wave", "mult": 8.0, "tier": "rare",     "tags": ["rupture"], "blurb": "Rupture within 2s of hitting max Potency — the wave, cashed at the top."},
}

## THEN effects. `base` is the per-fire magnitude at Sweet Pour (mult 1.0); the WHEN's mult
## scales it. `kind` drives how the kit applies it. `tags:["rupture"]` = Purist hides it.
const THENS := {
	"splash":   {"name": "Splash",   "base": 14.0, "kind": "damage",  "tags": [],          "blurb": "a spatter of raw acid damage on the boss."},
	"backwash": {"name": "Backwash", "base": 0.5,  "kind": "fuel",    "tags": [],          "blurb": "top up BOTH poisons — free fuel back into the brew."},
	"quicken":  {"name": "Quicken",  "base": 6.0,  "kind": "potency", "tags": [],          "blurb": "a jolt of instant Potency."},
	"residue":  {"name": "Residue",  "base": 10.0, "kind": "dot",     "tags": [],          "blurb": "a lingering acid residue eats the boss over a few seconds."},
	"fume":     {"name": "Fume",     "base": 4.0,  "kind": "amp",     "tags": [],          "blurb": "caustic fumes make the boss reel — your damage +% for 2s."},
	"overfill": {"name": "Overfill", "base": 8.0,  "kind": "empower", "tags": ["rupture"], "blurb": "your NEXT Rupture detonates +% harder."},
}

static func mult(when_id: String) -> float:
	return float((WHENS.get(when_id, {}) as Dictionary).get("mult", 1.0))

## The raw (unrounded) base × mult — the FUEL kind applies this directly to the float poison
## pools so it can be tuned below 1 (a per-fire int floor of 1 makes fuel dominate frequent WHENs).
static func raw_amount(when_id: String, then_id: String) -> float:
	var t: Dictionary = THENS.get(then_id, {})
	if t.is_empty() or not WHENS.has(when_id):
		return 0.0
	return float(t["base"]) * mult(when_id)

static func then_kind(then_id: String) -> String:
	return String((THENS.get(then_id, {}) as Dictionary).get("kind", ""))

## The computed magnitude for a WHEN→THEN pairing — the number the kit applies AND the number
## the wiring board shows. Everything is base*mult rounded to an int (fractions read via /100).
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
	# fuel is fractional (applied raw); everything else reads as a whole number.
	if String(t["kind"]) == "fuel":
		return "WHEN %s → THEN %s +%.1f fuel" % [String(w["name"]), String(t["name"]), raw_amount(when_id, then_id)]
	var n := magnitude(when_id, then_id)
	var units := {"damage": " dmg", "potency": "% pot", "dot": " dmg/dot",
		"amp": "% dmg", "empower": "% rupture"}
	var unit: String = units.get(String(t["kind"]), "")
	return "WHEN %s → THEN %s %d%s" % [String(w["name"]), String(t["name"]), n, unit]

static func when_ids() -> Array:
	return WHENS.keys()

static func then_ids() -> Array:
	return THENS.keys()

## Does a WHEN/THEN carry `tag` (creed-aware board — Purist hides "rupture"-tagged entries)?
static func when_has_tag(id: String, tag: String) -> bool:
	return tag in (WHENS.get(id, {}).get("tags", []) as Array)

static func then_has_tag(id: String, tag: String) -> bool:
	return tag in (THENS.get(id, {}).get("tags", []) as Array)

## Deterministic n-of-N offer from `pool` using the run's draft stream (Fisher–Yates).
## Mirrors TwinfangRig.offer so the shared HUD wiring board is class-agnostic.
static func offer(pool: Array, rng, n := 3) -> Array:
	var ids: Array = pool.duplicate()
	if rng != null:
		for i in range(ids.size() - 1, 0, -1):
			var j := int(rng.next_u32() % (i + 1))
			var t = ids[i]; ids[i] = ids[j]; ids[j] = t
	return ids.slice(0, mini(n, ids.size()))
