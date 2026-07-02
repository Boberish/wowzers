## The Bulwark draft pool — the 17 upgrades/relics/spells from poc/bulwark.html plus the
## Opus transform, as data. Effects are implemented in BulwarkKit (keyed by these ids).
## Draft 2.0: entries carry `rarity` (haiku/sonnet/opus — frequency, never a cap) and
## `tags` (synergy vocabulary); the roll itself lives in the shared engine (Draft).
class_name BulwarkBoons
extends RefCounted

const SHARED := [
	{"id": "rampagePlus", "type": "upgrade", "rarity": "haiku", "tags": ["rampage"], "title": "Heavy Rampage", "desc": "Rampage deals +45 damage.", "req": "rampage"},
	{"id": "fortRage", "type": "upgrade", "rarity": "sonnet", "tags": ["fortify", "rage"], "title": "Steadfast", "desc": "Fortify also grants 20 rage on use.", "req": "fortify"},
	{"id": "furyGain", "type": "relic", "rarity": "sonnet", "tags": ["rage"], "title": "Spite", "desc": "Damage taken grants 30% more rage."},
	{"id": "execute", "type": "relic", "rarity": "sonnet", "tags": ["rage"], "title": "Last Stand", "desc": "Below 35% HP, your damage is +35%."},
	{"id": "bloodthirst", "type": "spell", "rarity": "sonnet", "tags": ["rage"], "title": "Bloodthirst", "desc": "New spell (5): 25 rage → 80 dmg, heals 60% of it."},
	{"id": "shockwave", "type": "spell", "rarity": "sonnet", "tags": ["rage", "interrupt"], "title": "Shockwave", "desc": "New spell (5): 50 rage → 55 dmg, interrupts a swing."},
	{"id": "retaliation", "type": "relic", "rarity": "opus", "tags": ["guard", "parry", "dodge"], "title": "Retaliation", "desc": "Your guard becomes a weapon: a negated swing is hurled back at the boss for its full damage."},
]
const WARDEN := [
	{"id": "deepCounter", "type": "upgrade", "rarity": "haiku", "tags": ["parry", "counter"], "title": "Deep Counter", "desc": "Each parry banks +2 Counter instead of 1."},
	{"id": "riposteHeal", "type": "upgrade", "rarity": "sonnet", "tags": ["parry", "riposte"], "title": "Vengeful Guard", "desc": "Landing a Riposte also heals you 60."},
	{"id": "perfectReflect", "type": "relic", "rarity": "haiku", "tags": ["parry"], "title": "Mirror Edge", "desc": "Parries reflect double damage."},
	{"id": "vindInterrupt", "type": "relic", "rarity": "opus", "tags": ["vindicate", "interrupt"], "title": "Judgement", "desc": "Vindicate also interrupts the current swing."},
	{"id": "riposteChain", "type": "relic", "rarity": "opus", "tags": ["parry", "riposte"], "title": "Flowing Guard", "desc": "A parry nearly refunds its own cooldown."},
]
const JUGG := [
	{"id": "unstoppable", "type": "upgrade", "rarity": "haiku", "tags": ["momentum"], "title": "Unstoppable", "desc": "Momentum cap +4 (ride to 14)."},
	{"id": "snowball", "type": "upgrade", "rarity": "haiku", "tags": ["momentum"], "title": "Snowball", "desc": "Momentum decays later and falls off slower."},
	{"id": "bulldoze", "type": "upgrade", "rarity": "sonnet", "tags": ["momentum"], "title": "Bulldoze", "desc": "Eating a heavy or crush grants +3 Momentum."},
	{"id": "landslide", "type": "relic", "rarity": "sonnet", "tags": ["avalanche", "momentum"], "title": "Landslide", "desc": "Avalanche heals you for 40% of its damage."},
	{"id": "sureFoot", "type": "relic", "rarity": "sonnet", "tags": ["momentum", "dodge"], "title": "Sure-Footed", "desc": "Dodging only halves Momentum instead of dumping it."},
	{"id": "overrun", "type": "relic", "rarity": "sonnet", "tags": ["momentum"], "title": "Overrun", "desc": "At 8+ Momentum, take 40% less from Crush swings."},
]

static func spec_pool(aspect: String) -> Array:
	return WARDEN if aspect == "warden" else JUGG

## The Aspect's mechanic vocabulary — feeds the synergy slot's build-tag set.
static func aspect_tags(aspect: String) -> Array:
	if aspect == "warden":
		return ["parry", "counter", "riposte", "guard", "rage"]
	return ["momentum", "guard", "dodge", "rage"]

## Apply a chosen boon to the run.
static func apply(b: Dictionary, run) -> void:
	if b["type"] == "spell":
		if not (b["id"] in run.loadout) and run.loadout.size() < 5:
			run.loadout.append(b["id"])
	else:
		run.boons[b["id"]] = true
