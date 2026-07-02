## The Mender draft pool — upgrades/relics offered between fights, plus the Opus
## transform. Effects are read by MenderKit / MenderAllyKit (keyed by id). Draft 2.0:
## `rarity` = offer frequency (never a cap), `tags` = synergy vocabulary; the roll
## lives in the shared engine (Draft).
class_name MenderBoons
extends RefCounted

const SHARED := [
	{"id": "conservation", "type": "upgrade", "rarity": "haiku", "tags": ["mana"], "title": "Conservation", "desc": "Mana regenerates 60% faster."},
	{"id": "overflow", "type": "relic", "rarity": "sonnet", "tags": ["overheal", "ward"], "title": "Overflow", "desc": "Overhealing shields the target for 30% of the spill."},
	{"id": "afterglow", "type": "upgrade", "rarity": "sonnet", "tags": ["flash"], "title": "Afterglow", "desc": "Flash Heal also leaves a short heal-over-time."},
	{"id": "cascade4", "type": "upgrade", "rarity": "sonnet", "tags": ["cascade"], "title": "Wider Cascade", "desc": "Cascade heals 4 allies instead of 3."},
	{"id": "wardplus", "type": "relic", "rarity": "haiku", "tags": ["ward"], "title": "Bulwark", "desc": "Ward absorbs 40% more."},
	{"id": "sanctifiedward", "type": "relic", "rarity": "opus", "tags": ["ward"], "title": "Sanctified Ward", "desc": "A Ward fully consumed detonates in light: heals its bearer 120 and cleanses their debuff."},
]
const TIDE := [
	{"id": "floodgate", "type": "relic", "rarity": "sonnet", "tags": ["surge", "reservoir", "ward"], "title": "Floodgate", "desc": "Surge also heals each ally for 25% of the shield."},
	{"id": "reservoirplus", "type": "upgrade", "rarity": "haiku", "tags": ["reservoir", "overheal"], "title": "Deep Reservoir", "desc": "Reservoir capacity +200."},
	{"id": "tideconv", "type": "upgrade", "rarity": "haiku", "tags": ["reservoir", "overheal"], "title": "Undertow", "desc": "Bank 20% more overheal into the Reservoir."},
]
const BRINK := [
	{"id": "bloodpact", "type": "relic", "rarity": "sonnet", "tags": ["bloodied", "nerve"], "title": "Blood Pact", "desc": "Bloodied allies deal even more damage (+0.35 factor)."},
	{"id": "secondwind", "type": "relic", "rarity": "opus", "tags": ["laststand", "nerve", "bloodied"], "title": "Second Wind", "desc": "Last Stand also cleanses every debuff."},
	{"id": "nerveplus", "type": "upgrade", "rarity": "haiku", "tags": ["nerve", "bloodied"], "title": "Steel Nerve", "desc": "Build Nerve faster while allies are bloodied."},
]

static func spec_pool(aspect: String) -> Array:
	return TIDE if aspect == "tidecaller" else BRINK

## The Aspect's mechanic vocabulary — feeds the synergy slot's build-tag set.
static func aspect_tags(aspect: String) -> Array:
	if aspect == "tidecaller":
		return ["reservoir", "overheal", "ward", "mana"]
	return ["nerve", "bloodied", "mana"]

static func apply(b: Dictionary, run) -> void:
	run.boons[b["id"]] = true
