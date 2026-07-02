## The Mender draft pool — upgrades/relics offered between fights. Effects are read
## by MenderKit / MenderAllyKit (keyed by id). Aspect-weighted 1-of-3, like the tank.
class_name MenderBoons
extends RefCounted

const SHARED := [
	{"id": "conservation", "type": "upgrade", "title": "Conservation", "desc": "Mana regenerates 60% faster."},
	{"id": "overflow", "type": "relic", "title": "Overflow", "desc": "Overhealing shields the target for 30% of the spill."},
	{"id": "afterglow", "type": "upgrade", "title": "Afterglow", "desc": "Flash Heal also leaves a short heal-over-time."},
	{"id": "cascade4", "type": "upgrade", "title": "Wider Cascade", "desc": "Cascade heals 4 allies instead of 3."},
	{"id": "wardplus", "type": "relic", "title": "Bulwark", "desc": "Ward absorbs 40% more."},
]
const TIDE := [
	{"id": "floodgate", "type": "relic", "title": "Floodgate", "desc": "Surge also heals each ally for 25% of the shield."},
	{"id": "reservoirplus", "type": "upgrade", "title": "Deep Reservoir", "desc": "Reservoir capacity +200."},
	{"id": "tideconv", "type": "upgrade", "title": "Undertow", "desc": "Bank 20% more overheal into the Reservoir."},
]
const BRINK := [
	{"id": "bloodpact", "type": "relic", "title": "Blood Pact", "desc": "Bloodied allies deal even more damage (+0.35 factor)."},
	{"id": "secondwind", "type": "relic", "title": "Second Wind", "desc": "Last Stand also cleanses every debuff."},
	{"id": "nerveplus", "type": "upgrade", "title": "Steel Nerve", "desc": "Build Nerve faster while allies are bloodied."},
]

static func spec_pool(aspect: String) -> Array:
	return TIDE if aspect == "tidecaller" else BRINK

static func _available(list: Array, run) -> Array:
	var out: Array = []
	for b in list:
		if not run.boons.has(b["id"]):
			out.append(b)
	return out

## Roll 3: up to 2 Aspect-flavoured, then fill from the shared pool.
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
	run.boons[b["id"]] = true
