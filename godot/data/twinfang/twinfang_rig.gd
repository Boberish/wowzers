## TwinfangRig — the ONE Combo rig per run (TEMPO-PLAN §5). You wire ONE WHEN → ONE THEN
## at the first draft (re-wire once at Floor 2). A WHEN is an earned OFFENSE moment; a THEN
## is a modest side-boost payoff. It's a flavour layer, not a pillar — ~10% of your damage.
##
## THE GREED-DIAL PAYOUT (the balancer + the reason to reach for rare WHENs):
##  - A THEN's magnitude is COMPUTED from the WHEN it's plugged into (`base * mult`), so a
##    frequent WHEN fires a small payoff and a rare WHEN fires a big one — even by construction.
##  - `mult` ~= (Riff's frequency / this WHEN's frequency) x a rarity PREMIUM, so rare WHENs
##    pay a bit MORE total — BUT only if you actually trigger them. Safe hum vs risky spike:
##    the rig is itself a small greed dial. The wiring board shows the number before you commit.
class_name TwinfangRig
extends RefCounted

## WHEN moments — the payout `mult` bakes in inverse-frequency + the rarity premium (Riff = 1.0
## anchor). Numbers are illustrative; sim/playtest tunes them so totals land ~480 (Riff) → ~690 (Coup).
const WHENS := {
	"riff":     {"name": "Riff",     "mult": 1.0, "tier": "frequent", "blurb": "every 3rd Perfect Strike — the steady drumbeat."},
	"bullseye": {"name": "Bullseye", "mult": 1.9, "tier": "medium",   "blurb": "a dead-centre Strike — rewards precision."},
	"finale":   {"name": "Finale",   "mult": 4.4, "tier": "medium",   "blurb": "a full 5-combo Eviscerate — rewards holding combo."},
	"punish":   {"name": "Punish",   "mult": 6.5, "tier": "rare",     "blurb": "a dump landed in the Opening — read the boss."},
	"peak":     {"name": "Peak",     "mult": 6.9, "tier": "rare",     "blurb": "reaching MAX Flow — you must ride the top."},
	"coup":     {"name": "Coup",     "mult": 8.4, "tier": "rare",     "blurb": "casting Coup de Grâce — full greed."},
}

## THEN effects — `base` is the per-fire magnitude at Riff (mult 1.0); the WHEN's mult scales it.
## `kind` drives how the kit applies it. All modest — a side boost, never the main event.
const THENS := {
	"echo":        {"name": "Echo",         "base": 12.0, "kind": "damage",  "blurb": "a delayed phantom slash for bonus damage."},
	"secondwind":  {"name": "Second Wind",  "base": 5.0,  "kind": "energy",  "blurb": "refund energy — keep the rhythm hot."},
	"edge":        {"name": "Killing Edge", "base": 0.5,  "kind": "crit", "cap": 3, "blurb": "bank guaranteed-crit charges for your next Strikes."},
	"bloodletter": {"name": "Bloodletter",  "base": 8.0,  "kind": "bleed",   "blurb": "open a small bleed on the boss."},
	"overcharge":  {"name": "Overcharge",   "base": 6.0,  "kind": "empower", "blurb": "your NEXT dump hits harder (Coup build-up bait)."},
	"expose":      {"name": "Expose",       "base": 3.0,  "kind": "expose",  "blurb": "the boss takes +% damage for 2s."},
}

static func mult(when_id: String) -> float:
	return float((WHENS.get(when_id, {}) as Dictionary).get("mult", 1.0))

static func then_kind(then_id: String) -> String:
	return String((THENS.get(then_id, {}) as Dictionary).get("kind", ""))

## The computed magnitude for a WHEN→THEN pairing — the number the kit applies AND the number
## the wiring board shows. Crit is charges (clamped); everything else is base*mult rounded.
static func magnitude(when_id: String, then_id: String) -> int:
	var t: Dictionary = THENS.get(then_id, {})
	if t.is_empty() or not WHENS.has(when_id):
		return 0
	var raw := float(t["base"]) * mult(when_id)
	if String(t.get("kind", "")) == "crit":
		return clampi(int(round(raw)), 1, int(t.get("cap", 3)))
	return int(round(raw))

## A one-line "WHEN → THEN: N" for the wiring board / HUD.
static func describe(when_id: String, then_id: String) -> String:
	if not (WHENS.has(when_id) and THENS.has(then_id)):
		return ""
	var w: Dictionary = WHENS[when_id]
	var t: Dictionary = THENS[then_id]
	var n := magnitude(when_id, then_id)
	var units := {"damage": " dmg", "energy": " energy", "crit": " crit", "bleed": " bleed",
		"empower": "%", "expose": "%"}
	var unit: String = units.get(String(t["kind"]), "")
	return "WHEN %s → THEN %s %d%s" % [String(w["name"]), String(t["name"]), n, unit]

static func when_ids() -> Array:
	return WHENS.keys()

static func then_ids() -> Array:
	return THENS.keys()

## Deterministic 3-of-N offer from `pool` using the run's draft stream (Fisher–Yates).
static func offer(pool: Array, rng, n := 3) -> Array:
	var ids: Array = pool.duplicate()
	if rng != null:
		for i in range(ids.size() - 1, 0, -1):
			var j := int(rng.next_u32() % (i + 1))
			var t = ids[i]; ids[i] = ids[j]; ids[j] = t
	return ids.slice(0, mini(n, ids.size()))
