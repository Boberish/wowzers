## The Voidcaller draft pool — the upgrades/relics/spells from poc/voidcaller.html plus
## the two Opus transforms, as data. Effects are implemented in VoidcallerKit (keyed by
## these ids). Draft 2.0: `rarity` = offer frequency (never a cap), `tags` = synergy
## vocabulary; the roll lives in the shared engine (Draft). Note `quickint` sits in both
## aspect pools by design — the shared roll dedupes by id.
class_name VoidcallerBoons
extends RefCounted

const SHARED := [
	{"id": "silence", "type": "spell", "rarity": "sonnet", "tags": ["interrupt", "silence"], "title": "Silence", "desc": "New spell (5): a 2nd interrupt on 11s cd that also Silences the boss 2.5s.", "excl": "counterspell"},
	{"id": "counterspell", "type": "spell", "rarity": "sonnet", "tags": ["interrupt"], "title": "Counterspell", "desc": "New spell (5): a 2nd interrupt on 9s cd that reflects 90 damage.", "excl": "silence"},
	{"id": "fracplus", "type": "upgrade", "rarity": "haiku", "tags": ["fracture"], "title": "Rupturing Bolt", "desc": "Fracture deals +30 damage."},
	{"id": "refund", "type": "relic", "rarity": "sonnet", "tags": ["interrupt"], "title": "Quick Recovery", "desc": "A clean interrupt refunds half its cooldown."},
	{"id": "nullbrand", "type": "relic", "rarity": "opus", "tags": ["interrupt", "silence"], "title": "Nullbrand", "desc": "Clean kicks also brand the boss with Silence for 1.5s."},
	{"id": "voidfeast", "type": "relic", "rarity": "opus", "tags": ["interrupt"], "title": "Void Feast", "desc": "Denying a heal devours it: 50% of the denied healing strikes back as damage."},
]
const DISRUPTOR := [
	{"id": "punish", "type": "upgrade", "rarity": "haiku", "tags": ["interrupt"], "title": "Punish", "desc": "Interrupt damage +40%."},
	{"id": "overfocus", "type": "upgrade", "rarity": "sonnet", "tags": ["overload", "backlash"], "title": "Feedback", "desc": "Overload also refunds 20 Focus."},
	{"id": "backdot", "type": "upgrade", "rarity": "sonnet", "tags": ["interrupt", "backlash"], "title": "Backlash Burn", "desc": "Clean interrupts leave a burn on the boss (14 dps, 4s)."},
	{"id": "quickint", "type": "relic", "rarity": "sonnet", "tags": ["interrupt"], "title": "Snap Cast", "desc": "Interrupt cooldown reduced to 3s."},
]
const SILENCER := [
	{"id": "longsil", "type": "upgrade", "rarity": "haiku", "tags": ["silence"], "title": "Lingering Hush", "desc": "Your Space silences last 40% longer."},
	{"id": "deepexpose", "type": "upgrade", "rarity": "haiku", "tags": ["silence"], "title": "Laid Bare", "desc": "Exposed from your interrupts is 50% stronger."},
	{"id": "silheal", "type": "relic", "rarity": "sonnet", "tags": ["silence"], "title": "Reprieve", "desc": "Each Silence heals you 30."},
	{"id": "quickint", "type": "relic", "rarity": "sonnet", "tags": ["interrupt"], "title": "Snap Cast", "desc": "Interrupt cooldown reduced to 3s."},
]

const SPELL_CAP := 5

static func spec_pool(aspect: String) -> Array:
	return DISRUPTOR if aspect == "disruptor" else SILENCER

## The Aspect's mechanic vocabulary — feeds the synergy slot's build-tag set.
static func aspect_tags(aspect: String) -> Array:
	if aspect == "disruptor":
		return ["interrupt", "backlash"]
	return ["interrupt", "silence"]

static func apply(b: Dictionary, run) -> void:
	if b["type"] == "spell":
		if not (b["id"] in run.loadout) and run.loadout.size() < SPELL_CAP:
			run.loadout.append(b["id"])
	else:
		run.boons[b["id"]] = true
