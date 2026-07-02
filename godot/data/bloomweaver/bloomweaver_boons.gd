## The Bloomweaver draft pool — upgrades/relics offered between fights. Effects are
## read by BloomweaverKit (keyed by id). Aspect-weighted 1-of-3, like the Mender.
class_name BloomweaverBoons
extends RefCounted

const SHARED := [
	{"id": "deeproots", "type": "upgrade", "title": "Deep Roots", "desc": "Growth lasts 12s instead of 9s (two extra ticks to bloom)."},
	{"id": "quickbloom", "type": "relic", "title": "Quickbloom", "desc": "Bloom cashes out at 105% of remaining ticks (up from 90%)."},
	{"id": "thickbark", "type": "upgrade", "title": "Thick Bark", "desc": "Barkskin absorbs 40% more."},
	{"id": "sapflow", "type": "upgrade", "title": "Sapflow", "desc": "Sap regenerates 25% faster."},
	{"id": "greenfuse", "type": "relic", "title": "Green Fuse", "desc": "Overgrowth cooldown -4s."},
]
const GROVE := [
	{"id": "evergreen", "type": "relic", "title": "Evergreen", "desc": "Flourish lights at 2 Growths instead of 3."},
	{"id": "verdantsurge", "type": "relic", "title": "Verdant Surge", "desc": "Wildbloom also plants a fresh Growth on allies that lacked one."},
	{"id": "photosynth", "type": "upgrade", "title": "Photosynthesis", "desc": "HoT healing builds 50% more Verdance."},
]
const THORN := [
	{"id": "barbs", "type": "relic", "title": "Barbed Bark", "desc": "Thorns reflect 70% of absorbed damage (up from 45%)."},
	{"id": "perfectharvest", "type": "upgrade", "title": "Perfect Harvest", "desc": "Perfect Wards refund 25 Sap and +8 more Verdance."},
	{"id": "ringbark", "type": "upgrade", "title": "Ringbark", "desc": "Barkskin cooldown -3s."},
]

static func spec_pool(aspect: String) -> Array:
	return GROVE if aspect == "wildgrove" else THORN

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
