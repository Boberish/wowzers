## The Twinfang draft pool — the upgrades/relics/spell from poc/twinfang.html, the Opus
## transform, and the Phase-B SLOT-VERB mods (build-your-RHYTHM), as data. Effects are
## implemented in TwinfangKit (keyed by these ids). Draft 2.0: `rarity` = offer frequency
## (never a cap), `tags` = synergy vocabulary; the roll lives in the shared engine (Draft).
## Slot-verbs: entries with `slot` are RHYTHM MOD PIECES — the innate proc moment is
## every PERFECT Strike; triggers add moments, payloads fire on EVERY proc, properties
## reshape the verb. NO LOCKOUTS — all pieces stack.
class_name TwinfangBoons
extends RefCounted

const SHARED := [
	{"id": "flowCap", "type": "upgrade", "rarity": "haiku", "tags": ["flow"], "title": "Momentum", "desc": "Flow cap +2 — a higher ceiling for every Flow bonus."},
	{"id": "strikeEnergy", "type": "upgrade", "rarity": "sonnet", "tags": ["perfect", "flow"], "title": "Efficiency", "desc": "Perfect Strikes refund 6 energy — sustain the rhythm longer."},
	{"id": "dodgeCp", "type": "relic", "rarity": "sonnet", "tags": ["dodge", "combo"], "title": "Riposte", "desc": "Every dodge grants 2 combo points — dodging feeds your rotation."},
	{"id": "execute", "type": "relic", "rarity": "sonnet", "tags": ["combo"], "title": "Finish It", "desc": "Below 35% boss HP, your damage is +30%."},
	{"id": "flurry", "type": "spell", "rarity": "sonnet", "tags": ["combo"], "title": "Flurry", "desc": "New spell (5): 28 energy for a 3-hit, +2 combo burst. Fast points under pressure."},
	{"id": "dancersgrace", "type": "relic", "rarity": "opus", "tags": ["perfect", "flow", "combo"], "title": "Dancer's Grace", "desc": "A PERFECT dodge primes your blades — the next Strike is automatically Perfect."},
	# --- Rhythm mod pieces (Phase B slot-verbs) ---
	{"id": "tfTrigEvade", "slot": "trigger", "type": "relic", "rarity": "sonnet", "tags": ["dodge", "perfect"], "title": "Ghost Step", "desc": "New proc moment: a clean dodge also triggers your Rhythm payloads (+6 energy)."},
	{"id": "tfTrigSpender", "slot": "trigger", "type": "relic", "rarity": "sonnet", "tags": ["combo", "perfect"], "title": "Killing Tempo", "desc": "New proc moment: a full 5-point finisher triggers your payloads (+6 energy)."},
	{"id": "tfTrigBeat", "slot": "trigger", "type": "relic", "rarity": "sonnet", "tags": ["dodge", "perfect"], "title": "Beat Dancer", "desc": "New proc moment: a PERFECT combo-beat dodge triggers your payloads (+6 energy)."},
	{"id": "tfPayLash", "slot": "payload", "type": "relic", "rarity": "sonnet", "tags": ["perfect", "flow"], "title": "Razor Echo", "desc": "Rhythm payload: every proc cuts the boss for 6."},
	{"id": "tfPayEnergy", "slot": "payload", "type": "relic", "rarity": "haiku", "tags": ["perfect", "flow"], "title": "Quickblood", "desc": "Rhythm payload: every proc restores 3 energy."},
	{"id": "tfPayLeech", "slot": "payload", "type": "relic", "rarity": "haiku", "tags": ["perfect"], "title": "Red Harvest", "desc": "Rhythm payload: every proc mends you for 5."},
	{"id": "tfPropWindow", "slot": "property", "type": "upgrade", "rarity": "haiku", "tags": ["perfect", "flow"], "title": "Wide Tempo", "desc": "Rhythm property: the PERFECT window is 20% wider on each side."},
	{"id": "tfPropTwinStep", "slot": "property", "type": "upgrade", "rarity": "opus", "tags": ["dodge", "perfect"], "title": "Twin Step", "desc": "Rhythm property: a SECOND dodge charge — step twice back-to-back; the spare returns after 6s."},
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
	{"id": "lingerVenom", "type": "relic", "rarity": "sonnet", "tags": ["rupture", "poison"], "title": "Lingering Venom", "desc": "Rupture becomes a SIP: a smaller detonation that keeps HALF your cocktail + Synergy warm. Sustain the brew instead of cratering it."},
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

## Assembled "YOUR RHYTHM" display lines (tooltips / tome). Empty when no mod pieces
## are drafted. Numbers mirror TwinfangConfig mod_* defaults.
static func verb_summary(boons: Dictionary, _aspect: String) -> Array:
	var trig: Array = []
	var pay: Array = []
	var prop: Array = []
	if boons.get("tfTrigEvade", false): trig.append("clean dodge")
	if boons.get("tfTrigSpender", false): trig.append("5-point finisher")
	if boons.get("tfTrigBeat", false): trig.append("PERFECT beat")
	if boons.get("tfPayLash", false): pay.append("cut 6")
	if boons.get("tfPayEnergy", false): pay.append("+3 energy")
	if boons.get("tfPayLeech", false): pay.append("mend 5")
	if boons.get("tfPropWindow", false): prop.append("window +20%")
	if boons.get("tfPropTwinStep", false): prop.append("2 dodge charges")
	if trig.is_empty() and pay.is_empty() and prop.is_empty():
		return []
	var out: Array = []
	out.append("Proc moments: PERFECT Strike" + ("" if trig.is_empty() else " · " + " · ".join(trig)))
	out.append("On every proc: " + (" · ".join(pay) if not pay.is_empty() else "(no payloads drafted yet)"))
	if not prop.is_empty():
		out.append("Properties: " + " · ".join(prop))
	return out
