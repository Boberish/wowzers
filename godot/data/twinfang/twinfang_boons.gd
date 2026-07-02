## The Twinfang draft pool — the upgrades/relics/spell from poc/twinfang.html, as data.
## Effects are implemented in TwinfangKit (keyed by these ids); this file is the
## catalogue + the "roll 3, Aspect-weighted" logic. Shuffle is Godot's Array.shuffle()
## (Fisher-Yates via the randomize()'d global RNG) — the prototype's biased
## sort(()=>rand-0.5) is a bug we DON'T port (see CLAUDE.md).
class_name TwinfangBoons
extends RefCounted

const SHARED := [
	{"id": "flowCap", "type": "upgrade", "title": "Momentum", "desc": "Flow cap +2 — a higher ceiling for every Flow bonus."},
	{"id": "strikeEnergy", "type": "upgrade", "title": "Efficiency", "desc": "Perfect Strikes refund 6 energy — sustain the rhythm longer."},
	{"id": "dodgeCp", "type": "relic", "title": "Riposte", "desc": "Every dodge grants 2 combo points — dodging feeds your rotation."},
	{"id": "execute", "type": "relic", "title": "Finish It", "desc": "Below 35% boss HP, your damage is +30%."},
	{"id": "flurry", "type": "spell", "title": "Flurry", "desc": "New spell (5): 28 energy for a 3-hit, +2 combo burst. Fast points under pressure."},
]
const TEMPO := [
	{"id": "encore", "type": "upgrade", "title": "Encore", "desc": "Double-hit (Tier 1) kicks in at Flow 2 instead of 3."},
	{"id": "crescendo", "type": "upgrade", "title": "Crescendo", "desc": "Coup de Grâce hits 40% harder."},
	{"id": "eviPlus", "type": "upgrade", "title": "Deep Cuts", "desc": "Eviscerate deals +8 damage per combo point.", "req": "eviscerate"},
	{"id": "syncopation", "type": "relic", "title": "Syncopation", "desc": "At max Flow, your Strikes cost no energy — ride the solo forever."},
	{"id": "virtuoso", "type": "relic", "title": "Virtuoso", "desc": "Flow decays 50% slower between Perfects."},
	{"id": "fifthCrit", "type": "relic", "title": "Killer's Eye", "desc": "Every 5th Perfect Strike is a guaranteed crit."},
]
const VENOM := [
	{"id": "potent", "type": "upgrade", "title": "Potent Toxins", "desc": "All poison ticks 30% harder."},
	{"id": "fastRot", "type": "upgrade", "title": "Fast Rot", "desc": "Festering grows faster the longer it sits."},
	{"id": "catalyst", "type": "upgrade", "title": "Catalyst", "desc": "Toxic Synergy ramps up 60% faster."},
	{"id": "rupturing", "type": "relic", "title": "Rupturing Blades", "desc": "Rupture detonates for 40% more."},
	{"id": "contagion", "type": "relic", "title": "Contagion", "desc": "Perfect Strikes also apply a random second poison type — easier to keep all three live."},
	{"id": "debilitate", "type": "relic", "title": "Debilitate", "desc": "Crippling stacks reduce the boss's damage to you (up to 30%)."},
]

const SPELL_CAP := 5

static func spec_pool(aspect: String) -> Array:
	return TEMPO if aspect == "tempo" else VENOM

static func _ok(b: Dictionary, run) -> bool:
	if b["type"] == "spell":
		return run.loadout.size() < SPELL_CAP and not (b["id"] in run.loadout)
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
## (and any leftover Aspect picks). Uses the global RNG (randomize() at run start).
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
		if not (b["id"] in run.loadout) and run.loadout.size() < SPELL_CAP:
			run.loadout.append(b["id"])
	else:
		run.boons[b["id"]] = true
