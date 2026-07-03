## Reckoner boons — swing-reshaping upgrades read by ReckonerKit via _b(id). All are
## OFF by default, so a boonless sim is byte-identical to the base swing. Bill's
## confirmed on-ramp gear (Wide Heavy CUT): Heavy Focus, Swap, Snapshot, Brinkguard,
## Steady Hand. The full aspect-weighted branch tree (Haymaker/Phrase/Tempo/Executioner/
## Virtuoso) lands with the HUD/draft stage — this is the Stage-1 minimal, valid pool.
class_name ReckonerBoons
extends RefCounted

# Each: {id, name, rarity, desc}. `id` is what ReckonerKit._b() reads.
const SHARED := [
	{"id": "rkHeavyFocus", "name": "Heavy Focus",  "rarity": "haiku",  "desc": "Heavy & Over swings hit ~35% harder."},
	{"id": "rkSwap",       "name": "Swap Grip",    "rarity": "haiku",  "desc": "The Even and Heavy wind zones trade places."},
	{"id": "rkSnap",       "name": "Snapshot",     "rarity": "sonnet", "desc": "A super-early bonus wind zone (Snap)."},
	{"id": "rkBrink",      "name": "Brinkguard",   "rarity": "sonnet", "desc": "A super-late bonus wind zone (Brink)."},
	{"id": "rkSteady",     "name": "Steady Hand",  "rarity": "sonnet", "desc": "Widens the True strike band (±3 ticks)."},
]

const COLOSSUS := []
const BERSERKER := []

static func spec_pool(aspect: String) -> Array:
	return BERSERKER if aspect == "berserker" else COLOSSUS

## Aspect-weighted draft pool (shared + the current aspect's).
static func pool(aspect: String) -> Array:
	var out: Array = []
	out.append_array(SHARED)
	out.append_array(spec_pool(aspect))
	return out

## Fold a picked boon into a run's boons dict (id -> true). Mirrors the other classes.
static func apply(b: Dictionary, run) -> void:
	if b.has("id"):
		run.boons[String(b["id"])] = true

## One-line HUD summary of the reshaped swing (Stage-2 HUD reads this).
static func verb_summary(boons: Dictionary, _aspect: String) -> String:
	var parts: Array = []
	for e in SHARED:
		if bool(boons.get(String(e["id"]), false)):
			parts.append(String(e["name"]))
	return "SWING" if parts.is_empty() else "SWING · " + " · ".join(parts)
