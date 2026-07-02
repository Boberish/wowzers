## The Twinfang draft pool — the upgrades/relics/spell from poc/twinfang.html plus the
## Opus transform, as data. Effects are implemented in TwinfangKit (keyed by these ids).
## Draft 2.0: `rarity` = offer frequency (never a cap), `tags` = synergy vocabulary;
## the roll lives in the shared engine (Draft).
class_name TwinfangBoons
extends RefCounted

const SHARED := [
	{"id": "flowCap", "type": "upgrade", "rarity": "haiku", "tags": ["flow"], "title": "Momentum", "desc": "Flow cap +2 — a higher ceiling for every Flow bonus."},
	{"id": "strikeEnergy", "type": "upgrade", "rarity": "sonnet", "tags": ["perfect", "flow"], "title": "Efficiency", "desc": "Perfect Strikes refund 6 energy — sustain the rhythm longer."},
	{"id": "dodgeCp", "type": "relic", "rarity": "sonnet", "tags": ["dodge", "combo"], "title": "Riposte", "desc": "Every dodge grants 2 combo points — dodging feeds your rotation."},
	{"id": "execute", "type": "relic", "rarity": "sonnet", "tags": ["combo"], "title": "Finish It", "desc": "Below 35% boss HP, your damage is +30%."},
	{"id": "flurry", "type": "spell", "rarity": "sonnet", "tags": ["combo"], "title": "Flurry", "desc": "New spell (5): 28 energy for a 3-hit, +2 combo burst. Fast points under pressure."},
	{"id": "dancersgrace", "type": "relic", "rarity": "opus", "tags": ["perfect", "flow", "combo"], "title": "Dancer's Grace", "desc": "A PERFECT dodge primes your blades — the next Strike is automatically Perfect."},
]
const TEMPO := [
	{"id": "encore", "type": "upgrade", "rarity": "sonnet", "tags": ["flow"], "title": "Encore", "desc": "Double-hit (Tier 1) kicks in at Flow 2 instead of 3."},
	{"id": "crescendo", "type": "upgrade", "rarity": "haiku", "tags": ["coupdegrace", "flow"], "title": "Crescendo", "desc": "Coup de Grâce hits 40% harder."},
	{"id": "eviPlus", "type": "upgrade", "rarity": "haiku", "tags": ["eviscerate", "combo"], "title": "Deep Cuts", "desc": "Eviscerate deals +8 damage per combo point.", "req": "eviscerate"},
	{"id": "syncopation", "type": "relic", "rarity": "opus", "tags": ["flow", "perfect"], "title": "Syncopation", "desc": "At max Flow, your Strikes cost no energy — ride the solo forever."},
	{"id": "virtuoso", "type": "relic", "rarity": "sonnet", "tags": ["flow"], "title": "Virtuoso", "desc": "Flow decays 50% slower between Perfects."},
	{"id": "fifthCrit", "type": "relic", "rarity": "sonnet", "tags": ["perfect"], "title": "Killer's Eye", "desc": "Every 5th Perfect Strike is a guaranteed crit."},
]
const VENOM := [
	{"id": "potent", "type": "upgrade", "rarity": "haiku", "tags": ["poison"], "title": "Potent Toxins", "desc": "All poison ticks 30% harder."},
	{"id": "fastRot", "type": "upgrade", "rarity": "haiku", "tags": ["poison"], "title": "Fast Rot", "desc": "Festering grows faster the longer it sits."},
	{"id": "catalyst", "type": "upgrade", "rarity": "haiku", "tags": ["poison"], "title": "Catalyst", "desc": "Toxic Synergy ramps up 60% faster."},
	{"id": "rupturing", "type": "relic", "rarity": "haiku", "tags": ["rupture", "poison"], "title": "Rupturing Blades", "desc": "Rupture detonates for 40% more."},
	{"id": "contagion", "type": "relic", "rarity": "opus", "tags": ["perfect", "poison"], "title": "Contagion", "desc": "Perfect Strikes also apply a random second poison type — easier to keep all three live."},
	{"id": "debilitate", "type": "relic", "rarity": "sonnet", "tags": ["poison"], "title": "Debilitate", "desc": "Crippling stacks reduce the boss's damage to you (up to 30%)."},
]

const SPELL_CAP := 5

static func spec_pool(aspect: String) -> Array:
	return TEMPO if aspect == "tempo" else VENOM

## The Aspect's mechanic vocabulary — feeds the synergy slot's build-tag set.
static func aspect_tags(aspect: String) -> Array:
	if aspect == "tempo":
		return ["flow", "perfect", "combo"]
	return ["poison", "combo", "perfect"]

## Apply a chosen boon to the run.
static func apply(b: Dictionary, run) -> void:
	if b["type"] == "spell":
		if not (b["id"] in run.loadout) and run.loadout.size() < SPELL_CAP:
			run.loadout.append(b["id"])
	else:
		run.boons[b["id"]] = true
