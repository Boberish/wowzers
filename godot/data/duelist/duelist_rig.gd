## DuelistRig — THE DUELIST's ONE Combo rig (TANK-PLAN §3 + §10 transform WHENs). Wire ONE WHEN →
## ONE THEN at the first draft (re-wire once at Floor 2). A WHEN is an earned moment off this class's
## OWN grades; a THEN is a modest side-boost (~10% flavour, not a pillar). Mirrors WellRig / TwinfangRig
## (mult / raw_amount / then_kind / magnitude / describe / when_ids / then_ids / offer). Guarded: an
## empty rig is never fired → byte-identical base. GREED-DIAL: mult ≈ inverse-frequency × rarity.
class_name DuelistRig
extends RefCounted

const WHENS := {
	"tall_land":   {"name": "The Tall Land", "mult": 1.4, "tier": "medium",   "blurb": "PARRY a TALL bar — the hardest read, the premium moment."},
	"big_spend":   {"name": "The Big Spend", "mult": 2.0, "tier": "medium",   "blurb": "⚡ DUMP a bank of 4◆ or more — the big cash-out."},
	"the_read":    {"name": "The Read",      "mult": 1.0, "tier": "frequent", "blurb": "correctly IGNORE a feint — patience, rewarded."},
	# --- transform WHENs (§10.3 — offered only while the matching transform is held) ---
	"full_seize":  {"name": "Full Seize",    "mult": 5.0, "tier": "rare", "door": "prisedefer", "blurb": "THROW a full-length seize — the rarest, priciest read (Prise de Fer)."},
	"tall_commit": {"name": "Tall Commit",   "mult": 4.5, "tier": "rare", "door": "remise",     "blurb": "COMMIT a remise on a TALL bar (Remise)."},
	"perfect_fleche": {"name": "Perfect Flèche", "mult": 5.0, "tier": "rare", "door": "fleche",  "blurb": "release a flèche on a PERFECT answer (Flèche)."},
}

## THEN effects (§3): STRIKE 20 dmg · IRON 2s +20% DR · BREATH +2 wind · PIP +1◆ · BANNER 2.5s +5%.
## `kind` drives how the kit applies it; BREATH/PIP read whole, IRON/BANNER carry a duration.
const THENS := {
	"strike": {"name": "Strike", "base": 20.0, "kind": "strike", "blurb": "a bar of damage snaps back at the boss."},
	"iron":   {"name": "Iron",   "base": 20.0, "kind": "iron",   "blurb": "2s of +20% DR — a moment of hardened guard."},
	"breath": {"name": "Breath", "base": 2.0,  "kind": "breath", "blurb": "a breath of WIND drips back into the pool."},
	"pip":    {"name": "Pip",    "base": 1.0,  "kind": "pip",    "blurb": "a ◆ pip banks straight into the combo."},
	"banner": {"name": "Banner", "base": 5.0,  "kind": "banner", "blurb": "2.5s the whole warband deals +5%."},
}

static func mult(when_id: String) -> float:
	return float((WHENS.get(when_id, {}) as Dictionary).get("mult", 1.0))

static func raw_amount(when_id: String, then_id: String) -> float:
	var t: Dictionary = THENS.get(then_id, {})
	if t.is_empty() or not WHENS.has(when_id):
		return 0.0
	return float(t["base"]) * mult(when_id)

static func then_kind(then_id: String) -> String:
	return String((THENS.get(then_id, {}) as Dictionary).get("kind", ""))

static func magnitude(when_id: String, then_id: String) -> int:
	var t: Dictionary = THENS.get(then_id, {})
	if t.is_empty() or not WHENS.has(when_id):
		return 0
	return int(round(float(t["base"]) * mult(when_id)))

static func describe(when_id: String, then_id: String) -> String:
	if not (WHENS.has(when_id) and THENS.has(then_id)):
		return ""
	var w: Dictionary = WHENS[when_id]
	var t: Dictionary = THENS[then_id]
	return "WHEN %s → THEN %s +%d" % [String(w["name"]), String(t["name"]), magnitude(when_id, then_id)]

static func when_ids() -> Array:
	return WHENS.keys()

static func then_ids() -> Array:
	return THENS.keys()

static func when_spec(_id: String) -> String:
	return ""

static func when_has_tag(_id: String, _tag: String) -> bool:
	return false

static func then_has_tag(_id: String, _tag: String) -> bool:
	return false

## The base (non-transform) WHEN pool — the offer board hides transform WHENs until their
## transform is held.
static func base_when_ids() -> Array:
	return WHENS.keys().filter(func(id): return not WHENS[id].has("door"))

static func offer(pool: Array, rng, n := 3) -> Array:
	var ids: Array = pool.duplicate()
	if rng != null:
		for i in range(ids.size() - 1, 0, -1):
			var j := int(rng.next_u32() % (i + 1))
			var t = ids[i]; ids[i] = ids[j]; ids[j] = t
	return ids.slice(0, mini(n, ids.size()))
