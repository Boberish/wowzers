## The Twinfang draft pool — the upgrades/relics/spell from poc/twinfang.html, the Opus
## transform, and the Phase-B SLOT-VERB mods (build-your-RHYTHM), as data. Effects are
## implemented in TwinfangKit (keyed by these ids). Draft 2.0: `rarity` = offer frequency
## (never a cap), `tags` = synergy vocabulary; the roll lives in the shared engine (Draft).
## Slot-verbs: entries with `slot` are RHYTHM MOD PIECES — the innate proc moment is
## every PERFECT Strike; triggers add moments, payloads fire on EVERY proc, properties
## reshape the verb. NO LOCKOUTS — all pieces stack.
class_name TwinfangBoons
extends RefCounted

## SHARED — both aspects can draft these (spells + universal utility). Kept small so the
## Venomancer draft (frozen, being redone) isn't flooded with Tempo-only Flow cards.
const SHARED := [
	{"id": "flurry", "type": "spell", "rarity": "sonnet", "tags": ["combo", "spell"], "title": "Flurry", "desc": "New spell: 28 energy for a 3-hit, +2 combo burst. Fast points under pressure."},
	{"id": "gracenote", "type": "spell", "rarity": "haiku", "tags": ["spell", "energy"], "title": "Grace Note", "desc": "New spell (18 energy, cd 2): an off-beat jab that does NOT touch your rhythm clock — pure filler woven between beats."},
	{"id": "coda", "type": "spell", "rarity": "sonnet", "tags": ["spell", "perfect"], "title": "Coda", "desc": "New spell (25 energy, cd 10): your next Strike is ALL-GREEN — one guaranteed Perfect. Get back on the horse."},
	{"id": "strikeEnergy", "type": "upgrade", "rarity": "sonnet", "tags": ["perfect", "energy"], "title": "Efficiency", "desc": "Perfect Strikes refund 6 energy — sustain the rhythm longer."},
]

## TEMPO — the reworked address-organized slate (STRIKE · WINDOW · FLOW · EVISCERATE · COUP).
## Every card names the button or dial it touches (the legibility rule). Numbers = base;
## the tier ladder (Slice 2) scales them per instance. VENOM below is frozen (redone later).
const TEMPO := [
	# --- STRIKE — the crit + read package ---
	{"id": "fifthCrit", "type": "relic", "rarity": "sonnet", "tags": ["crit", "perfect", "strike"], "title": "Killer's Eye", "desc": "Every 5th Perfect Strike is a guaranteed crit."},
	{"id": "heartseeker", "type": "relic", "rarity": "sonnet", "tags": ["crit", "bullseye", "strike"], "title": "Heartseeker", "desc": "BULLSEYE Strikes (dead centre of the window) are guaranteed crits."},
	{"id": "serrated", "type": "upgrade", "rarity": "haiku", "tags": ["crit", "strike"], "title": "Serrated Fate", "desc": "Your crits deal 40% more damage."},
	{"id": "opportunist", "type": "relic", "rarity": "sonnet", "tags": ["crit", "strike"], "title": "Opportunist", "desc": "Strikes landed WHILE the boss winds up gain +25% crit chance — dance through the telegraph."},
	# --- THE WINDOW — where the green sits ---
	{"id": "wideTempo", "type": "upgrade", "rarity": "haiku", "tags": ["window"], "title": "Wide Tempo", "desc": "Your Perfect window is 15% wider on each side."},
	{"id": "fencersLine", "type": "relic", "rarity": "sonnet", "tags": ["window", "bullseye"], "title": "Fencer's Line", "desc": "A Bullseye widens your NEXT window by 25% — nail one, the next comes easier."},
	{"id": "rubato", "type": "relic", "rarity": "sonnet", "tags": ["window"], "title": "Rubato", "desc": "The Perfect window sits earlier — same skill, a faster song."},
	# --- FLOW — the greed dial ---
	{"id": "flowCap", "type": "upgrade", "rarity": "haiku", "tags": ["flow"], "title": "Momentum", "desc": "Flow cap +2 — a higher ceiling for every Flow bonus."},
	{"id": "tightrope", "type": "relic", "rarity": "sonnet", "tags": ["flow"], "title": "Tightrope", "desc": "While at MAX Flow, your damage is +15% — living on the edge pays."},
	{"id": "heldNote", "type": "relic", "rarity": "sonnet", "tags": ["flow"], "title": "Held Note", "desc": "Flow does not decay while the boss winds up a swing — read the telegraph in peace."},
	{"id": "encore", "type": "upgrade", "rarity": "sonnet", "tags": ["flow"], "title": "Encore", "desc": "The double-hit (Flow Tier 1) kicks in at Flow 2 instead of 3."},
	{"id": "shatterfall", "type": "relic", "rarity": "sonnet", "tags": ["flow", "crash"], "title": "Shatterfall", "desc": "When a slip crashes your Flow from 4+, the shattered tempo detonates for 25 per point lost."},
	{"id": "doubleTime", "type": "relic", "rarity": "opus", "tags": ["flow"], "title": "Double Time", "desc": "SIGNATURE: at max Flow the accelerando never stops — each further Perfect tightens the window AND adds +4% damage, stacking until you crash."},
	# --- EVISCERATE — the dump ---
	{"id": "eviPlus", "type": "upgrade", "rarity": "haiku", "tags": ["eviscerate", "combo"], "title": "Deep Cuts", "desc": "Eviscerate deals +8 damage per combo point.", "req": "eviscerate"},
	{"id": "execute", "type": "relic", "rarity": "sonnet", "tags": ["eviscerate", "execute"], "title": "Finish It", "desc": "Below 35% boss HP, your Eviscerate deals +35% — hold combo for the kill.", "req": "eviscerate"},
	{"id": "overkill", "type": "relic", "rarity": "sonnet", "tags": ["eviscerate", "combo"], "title": "Overkill", "desc": "Combo built past the cap banks (up to 3) into your next Eviscerate for +6 each.", "req": "eviscerate"},
	{"id": "staccato", "type": "relic", "rarity": "sonnet", "tags": ["eviscerate", "crash"], "title": "Staccato Fury", "desc": "After a Flow crash, your next Eviscerate is FREE and deals +50%.", "req": "eviscerate"},
	# --- COUP DE GRÂCE ---
	{"id": "crescendo", "type": "upgrade", "rarity": "haiku", "tags": ["coupdegrace", "flow"], "title": "Crescendo", "desc": "Coup de Grâce hits 40% harder."},
	{"id": "syncopation", "type": "relic", "rarity": "opus", "tags": ["flow", "energy"], "title": "Syncopation", "desc": "SIGNATURE: at max Flow your Strikes cost no energy, and a GOOD grades up to Perfect — ride the solo forever."},
	{"id": "daCapo", "type": "relic", "rarity": "sonnet", "tags": ["coupdegrace", "flow"], "title": "Da Capo", "desc": "Coup leaves you +1 Flow seed — come back from the top, not from walking pace."},
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
		return ["flow", "perfect", "combo", "crit", "bullseye", "window", "tempo"]
	return ["poison", "combo", "perfect"]

## Apply a chosen boon to the run.
static func apply(b: Dictionary, run) -> void:
	if b["type"] == "spell":
		if not (b["id"] in run.loadout) and run.loadout.size() < SPELL_CAP:
			run.loadout.append(b["id"])
	else:
		run.boons[b["id"]] = true

## The blade's build-summary lines for the raid build panel (raid_hud._verb_summary_lines).
## The reworked Tempo has no WHEN/THEN slot-verb board anymore — its build IS the drafted
## boons + its Creed/Module — so this is empty for now. verb_board() and the old slot-verb
## display were RETIRED 2026-07-05 with the dead VerbBoard combo GUI.
static func verb_summary(_boons: Dictionary, _aspect: String) -> Array:
	return []
