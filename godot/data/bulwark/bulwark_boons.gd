## The Bulwark draft pool — the 17 upgrades/relics/spells from poc/bulwark.html,
## as data. Effects are implemented in BulwarkKit (keyed by these ids); this file is
## the catalogue + the "roll 3 choices, Aspect-weighted" logic.
class_name BulwarkBoons
extends RefCounted

const SHARED := [
	{"id": "rampagePlus", "type": "upgrade", "title": "Heavy Rampage", "desc": "Rampage deals +45 damage.", "req": "rampage"},
	{"id": "fortRage", "type": "upgrade", "title": "Steadfast", "desc": "Fortify also grants 20 rage on use.", "req": "fortify"},
	{"id": "furyGain", "type": "relic", "title": "Spite", "desc": "Damage taken grants 30% more rage."},
	{"id": "execute", "type": "relic", "title": "Last Stand", "desc": "Below 35% HP, your damage is +35%."},
	{"id": "bloodthirst", "type": "spell", "title": "Bloodthirst", "desc": "New spell (5): 25 rage → 80 dmg, heals 60% of it."},
	{"id": "shockwave", "type": "spell", "title": "Shockwave", "desc": "New spell (5): 50 rage → 55 dmg, interrupts a swing."},
]
const WARDEN := [
	{"id": "deepCounter", "type": "upgrade", "title": "Deep Counter", "desc": "Each parry banks +2 Counter instead of 1."},
	{"id": "riposteHeal", "type": "upgrade", "title": "Vengeful Guard", "desc": "Landing a Riposte also heals you 60."},
	{"id": "perfectReflect", "type": "relic", "title": "Mirror Edge", "desc": "Parries reflect double damage."},
	{"id": "vindInterrupt", "type": "relic", "title": "Judgement", "desc": "Vindicate also interrupts the current swing."},
	{"id": "riposteChain", "type": "relic", "title": "Flowing Guard", "desc": "A parry nearly refunds its own cooldown."},
]
const JUGG := [
	{"id": "unstoppable", "type": "upgrade", "title": "Unstoppable", "desc": "Momentum cap +4 (ride to 14)."},
	{"id": "snowball", "type": "upgrade", "title": "Snowball", "desc": "Momentum decays later and falls off slower."},
	{"id": "bulldoze", "type": "upgrade", "title": "Bulldoze", "desc": "Eating a heavy or crush grants +3 Momentum."},
	{"id": "landslide", "type": "relic", "title": "Landslide", "desc": "Avalanche heals you for 40% of its damage."},
	{"id": "sureFoot", "type": "relic", "title": "Sure-Footed", "desc": "Dodging only halves Momentum instead of dumping it."},
	{"id": "overrun", "type": "relic", "title": "Overrun", "desc": "At 8+ Momentum, take 40% less from Crush swings."},
]

static func spec_pool(aspect: String) -> Array:
	return WARDEN if aspect == "warden" else JUGG

## Is this boon offerable given the current run?
static func _ok(b: Dictionary, run) -> bool:
	if b["type"] == "spell":
		return run.loadout.size() < 5 and not (b["id"] in run.loadout)
	if b.has("req") and not (b["req"] in run.loadout):
		return false
	return not run.boons.has(b["id"])

static func _available(list: Array, run) -> Array:
	var out: Array = []
	for b in list:
		if _ok(b, run):
			out.append(b)
	return out

## Roll a draft: up to 2 Aspect-flavoured picks, then fill to 3 from the shared pool
## (and any leftover Aspect picks). Uses the global RNG (call randomize() at run start).
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

## Apply a chosen boon to the run.
static func apply(b: Dictionary, run) -> void:
	if b["type"] == "spell":
		if not (b["id"] in run.loadout) and run.loadout.size() < 5:
			run.loadout.append(b["id"])
	else:
		run.boons[b["id"]] = true
