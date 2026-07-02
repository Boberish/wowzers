## The Bloomweaver draft pool — upgrades/relics offered between fights, plus the Opus
## transform. Effects are read by BloomweaverKit (keyed by id). Draft 2.0: `rarity` =
## offer frequency (never a cap), `tags` = synergy vocabulary; the roll lives in the
## shared engine (Draft).
class_name BloomweaverBoons
extends RefCounted

const SHARED := [
	{"id": "deeproots", "type": "upgrade", "rarity": "haiku", "tags": ["growth"], "title": "Deep Roots", "desc": "Growth lasts 12s instead of 9s (two extra ticks to bloom)."},
	{"id": "quickbloom", "type": "relic", "rarity": "sonnet", "tags": ["bloom", "growth"], "title": "Quickbloom", "desc": "Bloom cashes out at 105% of remaining ticks (up from 90%)."},
	{"id": "thickbark", "type": "upgrade", "rarity": "haiku", "tags": ["ward", "bark"], "title": "Thick Bark", "desc": "Barkskin absorbs 40% more."},
	{"id": "sapflow", "type": "upgrade", "rarity": "haiku", "tags": ["sap"], "title": "Sapflow", "desc": "Sap regenerates 25% faster."},
	{"id": "greenfuse", "type": "relic", "rarity": "sonnet", "tags": ["overgrowth"], "title": "Green Fuse", "desc": "Overgrowth cooldown -4s."},
	{"id": "evergreencycle", "type": "relic", "rarity": "opus", "tags": ["ward", "growth"], "title": "Evergreen Cycle", "desc": "A Perfect Ward seeds itself: replants a fresh Growth on its bearer."},
]
const GROVE := [
	{"id": "evergreen", "type": "relic", "rarity": "sonnet", "tags": ["growth", "bloom"], "title": "Evergreen", "desc": "Flourish lights at 2 Growths instead of 3."},
	{"id": "verdantsurge", "type": "relic", "rarity": "opus", "tags": ["wildbloom", "growth", "verdance"], "title": "Verdant Surge", "desc": "Wildbloom also plants a fresh Growth on allies that lacked one."},
	{"id": "photosynth", "type": "upgrade", "rarity": "haiku", "tags": ["growth", "verdance"], "title": "Photosynthesis", "desc": "HoT healing builds 50% more Verdance."},
]
const THORN := [
	{"id": "barbs", "type": "relic", "rarity": "sonnet", "tags": ["thorns", "ward"], "title": "Barbed Bark", "desc": "Thorns reflect 70% of absorbed damage (up from 45%)."},
	{"id": "perfectharvest", "type": "upgrade", "rarity": "sonnet", "tags": ["ward", "verdance", "sap"], "title": "Perfect Harvest", "desc": "Perfect Wards refund 25 Sap and +8 more Verdance."},
	{"id": "ringbark", "type": "upgrade", "rarity": "haiku", "tags": ["ward", "bark"], "title": "Ringbark", "desc": "Barkskin cooldown -3s."},
]

static func spec_pool(aspect: String) -> Array:
	return GROVE if aspect == "wildgrove" else THORN

## The Aspect's mechanic vocabulary — feeds the synergy slot's build-tag set.
static func aspect_tags(aspect: String) -> Array:
	if aspect == "wildgrove":
		return ["growth", "bloom", "verdance", "sap"]
	return ["ward", "thorns", "verdance", "sap"]

static func apply(b: Dictionary, run) -> void:
	run.boons[b["id"]] = true
