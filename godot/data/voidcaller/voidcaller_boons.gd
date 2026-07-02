## The Voidcaller draft pool — the upgrades/relics/spells from poc/voidcaller.html, as
## data. Effects are implemented in VoidcallerKit (keyed by these ids). Shuffle is Godot's
## Array.shuffle() (Fisher-Yates) — not the prototype's biased sort (see CLAUDE.md).
class_name VoidcallerBoons
extends RefCounted

const SHARED := [
	{"id": "silence", "type": "spell", "title": "Silence", "desc": "New spell (5): a 2nd interrupt on 11s cd that also Silences the boss 2.5s.", "excl": "counterspell"},
	{"id": "counterspell", "type": "spell", "title": "Counterspell", "desc": "New spell (5): a 2nd interrupt on 9s cd that reflects 90 damage.", "excl": "silence"},
	{"id": "fracplus", "type": "upgrade", "title": "Rupturing Bolt", "desc": "Fracture deals +30 damage."},
	{"id": "refund", "type": "relic", "title": "Quick Recovery", "desc": "A clean interrupt refunds half its cooldown."},
]
const DISRUPTOR := [
	{"id": "punish", "type": "upgrade", "title": "Punish", "desc": "Interrupt damage +40%."},
	{"id": "overfocus", "type": "upgrade", "title": "Feedback", "desc": "Overload also refunds 20 Focus."},
	{"id": "backdot", "type": "upgrade", "title": "Backlash Burn", "desc": "Clean interrupts leave a burn on the boss (14 dps, 4s)."},
	{"id": "quickint", "type": "relic", "title": "Snap Cast", "desc": "Interrupt cooldown reduced to 3s."},
]
const SILENCER := [
	{"id": "longsil", "type": "upgrade", "title": "Lingering Hush", "desc": "Your Space silences last 40% longer."},
	{"id": "deepexpose", "type": "upgrade", "title": "Laid Bare", "desc": "Exposed from your interrupts is 50% stronger."},
	{"id": "silheal", "type": "relic", "title": "Reprieve", "desc": "Each Silence heals you 30."},
	{"id": "quickint", "type": "relic", "title": "Snap Cast", "desc": "Interrupt cooldown reduced to 3s."},
]

const SPELL_CAP := 5

static func spec_pool(aspect: String) -> Array:
	return DISRUPTOR if aspect == "disruptor" else SILENCER

static func _ok(b: Dictionary, run) -> bool:
	if b["type"] == "spell":
		if run.loadout.size() >= SPELL_CAP or b["id"] in run.loadout:
			return false
		return not (b.get("excl", "") in run.loadout)   # Silence/Counterspell are mutually exclusive
	return not run.boons.has(b["id"])

static func _available(list: Array, run) -> Array:
	var out: Array = []
	for b in list:
		if _ok(b, run):
			out.append(b)
	return out

## Roll a draft: up to 2 Aspect-flavoured picks, then fill to 3 from the shared pool.
## Uses the global RNG (randomize() at run start).
static func roll(run) -> Array:
	var spec := _available(spec_pool(run.aspect), run)
	var shared := _available(SHARED, run)
	spec.shuffle()
	shared.shuffle()
	var pick: Array = spec.slice(0, 2)
	var rest: Array = shared + spec.slice(2)
	rest.shuffle()
	while pick.size() < 3 and not rest.is_empty():
		pick.append(rest.pop_front())
	return pick.slice(0, 3)

static func apply(b: Dictionary, run) -> void:
	if b["type"] == "spell":
		if not (b["id"] in run.loadout) and run.loadout.size() < SPELL_CAP:
			run.loadout.append(b["id"])
	else:
		run.boons[b["id"]] = true
