## The Bloomweaver draft pool — upgrades/relics offered between fights, the Opus
## transform, and the Phase-B SLOT-VERB mods (build-your-GARDEN). Effects are read by
## BloomweaverKit (keyed by id). Draft 2.0: `rarity` = offer frequency (never a cap),
## `tags` = synergy vocabulary; the roll lives in the shared engine (Draft).
## Slot-verbs: entries with `slot` are GARDEN MOD PIECES — the innate proc moment is
## every cashed BLOOM (Lifesurge mass-blooms count individually).
class_name BloomweaverBoons
extends RefCounted

const SHARED := [
	{"id": "deeproots", "type": "upgrade", "rarity": "haiku", "tags": ["growth"], "title": "Deep Roots", "desc": "Seeds last 12s instead of 9s — a fatter bed with more life to cook and cash."},
	{"id": "quickbloom", "type": "relic", "rarity": "sonnet", "tags": ["bloom", "growth"], "title": "Quickbloom", "desc": "Bloom cashes out at 110% of the remaining ramped ticks (up from 90%)."},
	{"id": "ironbark", "type": "upgrade", "rarity": "sonnet", "tags": ["ward", "bark", "growth"], "title": "Ironbark Roots", "desc": "+10% Barkskin absorb per seed under it — deep beds armor into massive wards."},
	{"id": "bounty", "type": "relic", "rarity": "sonnet", "tags": ["growth"], "title": "Bountiful Bed", "desc": "+1 soft seed cap — a deeper bed becomes your baseline, no Verdance surcharge."},
	{"id": "cleanharvest", "type": "relic", "rarity": "sonnet", "tags": ["bloom", "verdance"], "title": "Clean Harvest", "desc": "Bloom spends 15 Verdance to detonate losslessly at 115% (instead of the lossy 90%)."},
	{"id": "thickbark", "type": "upgrade", "rarity": "haiku", "tags": ["ward", "bark"], "title": "Thick Bark", "desc": "Barkskin absorbs 40% more."},
	{"id": "sapflow", "type": "upgrade", "rarity": "haiku", "tags": ["sap"], "title": "Sapflow", "desc": "Sap regenerates 25% faster — stack the burst in fewer beats."},
	{"id": "greenfuse", "type": "relic", "rarity": "sonnet", "tags": ["overgrowth"], "title": "Green Fuse", "desc": "Overgrowth cooldown -4s."},
	{"id": "evergreencycle", "type": "relic", "rarity": "opus", "tags": ["ward", "growth"], "title": "Evergreen Cycle", "desc": "A Perfect Ward seeds itself: plants/refreshes a seed on its bearer (atop the cook-on-shatter)."},
	# --- Garden mod pieces (Phase B slot-verbs) ---
	{"id": "bwTrigPerfect", "slot": "trigger", "type": "relic", "rarity": "sonnet", "tags": ["ward", "bark"], "title": "Barkward Echo", "desc": "New proc moment: every Perfect Ward triggers your Garden payloads (+8 Sap)."},
	{"id": "bwTrigPlant", "slot": "trigger", "type": "relic", "rarity": "sonnet", "tags": ["growth"], "title": "Seedsower", "desc": "New proc moment: every 3rd seed planted triggers your payloads (+8 Sap)."},
	{"id": "bwTrigBeat", "slot": "trigger", "type": "relic", "rarity": "sonnet", "tags": ["sap"], "title": "Rootstep", "desc": "New proc moment: a PERFECT combo-beat dodge triggers your payloads (+8 Sap)."},
	{"id": "bwPayThorn", "slot": "payload", "type": "relic", "rarity": "sonnet", "tags": ["thorns"], "title": "Bramble Burst", "desc": "Garden payload: every proc rakes the boss for 18."},
	{"id": "bwPaySap", "slot": "payload", "type": "relic", "rarity": "haiku", "tags": ["sap"], "title": "Sapwell", "desc": "Garden payload: every proc restores 8 Sap."},
	{"id": "bwPayMend", "slot": "payload", "type": "relic", "rarity": "haiku", "tags": ["bloom", "growth"], "title": "Petalfall", "desc": "Garden payload: every proc mends the bloomed ally for 15."},
	{"id": "bwPropQuick", "slot": "property", "type": "upgrade", "rarity": "haiku", "tags": ["growth"], "title": "Quickening", "desc": "Garden property: seeds cook ~1.1s faster (shorter ramp to full)."},
	{"id": "bwPropDeepGarden", "slot": "property", "type": "upgrade", "rarity": "opus", "tags": ["growth", "bloom"], "title": "Deep Garden", "desc": "Garden property: while 3+ allies carry a bed, your payloads fire TWICE."},
]
const GROVE := [
	{"id": "evergreen", "type": "relic", "rarity": "sonnet", "tags": ["growth", "bloom"], "title": "Evergreen", "desc": "Flourish lights at 4 total seeds instead of 6."},
	{"id": "verdantsurge", "type": "relic", "rarity": "opus", "tags": ["wildbloom", "growth", "verdance"], "title": "Verdant Surge", "desc": "Wildbloom also plants a fresh seed on allies that lacked one."},
	{"id": "photosynth", "type": "upgrade", "rarity": "haiku", "tags": ["growth", "verdance"], "title": "Photosynthesis", "desc": "Effective seed healing builds 50% more Verdance."},
]
const THORN := [
	{"id": "barbs", "type": "relic", "rarity": "sonnet", "tags": ["thorns", "ward"], "title": "Barbed Bark", "desc": "Thorns reflect 70% of absorbed damage (up from 45%)."},
	{"id": "perfectharvest", "type": "upgrade", "rarity": "sonnet", "tags": ["ward", "verdance", "sap"], "title": "Perfect Harvest", "desc": "Perfect Wards refund 25 Sap and +8 more Verdance."},
	{"id": "thornbomb", "type": "relic", "rarity": "sonnet", "tags": ["thorns", "bloom"], "title": "Thornbomb", "desc": "A Bloom also rakes the boss for 8 × the bed's seed count — saved gardens become pressure."},
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

## Assembled "YOUR GARDEN" display lines (tooltips). Empty when no mod pieces drafted.
## Numbers mirror BloomweaverConfig mod_* defaults.
static func verb_summary(boons: Dictionary, _aspect: String) -> Array:
	var trig: Array = []
	var pay: Array = []
	var prop: Array = []
	if boons.get("bwTrigPerfect", false): trig.append("Perfect Ward")
	if boons.get("bwTrigPlant", false): trig.append("every 3rd Growth")
	if boons.get("bwTrigBeat", false): trig.append("PERFECT beat")
	if boons.get("bwPayThorn", false): pay.append("rake 18")
	if boons.get("bwPaySap", false): pay.append("+8 Sap")
	if boons.get("bwPayMend", false): pay.append("mend 15")
	if boons.get("bwPropQuick", false): prop.append("seeds cook faster")
	if boons.get("bwPropDeepGarden", false): prop.append("payloads ×2 at 3+ Growths")
	if trig.is_empty() and pay.is_empty() and prop.is_empty():
		return []
	var out: Array = []
	out.append("Proc moments: cashed Bloom" + ("" if trig.is_empty() else " · " + " · ".join(trig)))
	out.append("On every proc: " + (" · ".join(pay) if not pay.is_empty() else "(no payloads drafted yet)"))
	if not prop.is_empty():
		out.append("Properties: " + " · ".join(prop))
	return out
