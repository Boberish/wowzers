## The Mender draft pool — upgrades/relics offered between fights, the Opus transform,
## and the Phase-B SLOT-VERB mods (build-your-TRIAGE). Effects are read by MenderKit /
## MenderAllyKit (keyed by id). Draft 2.0: `rarity` = offer frequency (never a cap),
## `tags` = synergy vocabulary; the roll lives in the shared engine (Draft).
## Slot-verbs: entries with `slot` are TRIAGE MOD PIECES — the innate proc moment is a
## CLUTCH HEAL (a single-target heal resolving on an ally below 50%).
class_name MenderBoons
extends RefCounted

const SHARED := [
	{"id": "conservation", "type": "upgrade", "rarity": "haiku", "tags": ["mana"], "title": "Conservation", "desc": "Mana regenerates 60% faster."},
	{"id": "overflow", "type": "relic", "rarity": "sonnet", "tags": ["overheal", "ward"], "title": "Overflow", "desc": "Overhealing shields the target for 30% of the spill."},
	{"id": "afterglow", "type": "upgrade", "rarity": "sonnet", "tags": ["flash"], "title": "Afterglow", "desc": "Flash Heal also leaves a short heal-over-time."},
	{"id": "cascade4", "type": "upgrade", "rarity": "sonnet", "tags": ["cascade"], "title": "Wider Cascade", "desc": "Cascade heals 4 allies instead of 3."},
	{"id": "wardplus", "type": "relic", "rarity": "haiku", "tags": ["ward"], "title": "Bulwark", "desc": "Ward absorbs 40% more."},
	{"id": "sanctifiedward", "type": "relic", "rarity": "opus", "tags": ["ward"], "title": "Sanctified Ward", "desc": "A Ward fully consumed detonates in light: heals its bearer 120 and cleanses their debuff."},
	# --- Triage mod pieces (Phase B slot-verbs) ---
	{"id": "mdTrigDispel", "slot": "trigger", "type": "relic", "rarity": "sonnet", "tags": ["mana", "ward"], "title": "Cleansing Rite", "desc": "New proc moment: every Dispel triggers your Triage payloads (+10 mana)."},
	{"id": "mdTrigWard", "slot": "trigger", "type": "relic", "rarity": "sonnet", "tags": ["ward"], "title": "Aegis Echo", "desc": "New proc moment: a Ward fully consumed triggers your payloads (+10 mana)."},
	{"id": "mdTrigBeat", "slot": "trigger", "type": "relic", "rarity": "sonnet", "tags": ["mana"], "title": "Graceful Step", "desc": "New proc moment: a PERFECT combo-beat dodge triggers your payloads (+10 mana)."},
	{"id": "mdPayShield", "slot": "payload", "type": "relic", "rarity": "sonnet", "tags": ["ward"], "title": "Lightward", "desc": "Triage payload: every proc shields the triaged ally for 25."},
	{"id": "mdPayMana", "slot": "payload", "type": "relic", "rarity": "haiku", "tags": ["mana"], "title": "Deep Well", "desc": "Triage payload: every proc restores 12 mana."},
	{"id": "mdPayHot", "slot": "payload", "type": "relic", "rarity": "sonnet", "tags": ["flash", "overheal"], "title": "Lingering Grace", "desc": "Triage payload: every proc leaves a small heal-over-time on the ally."},
	{"id": "mdPropSwift", "slot": "property", "type": "upgrade", "rarity": "haiku", "tags": ["mana", "flash"], "title": "Swift Litany", "desc": "Triage property: your cast times are 12% faster."},
	{"id": "mdPropBenediction", "slot": "property", "type": "upgrade", "rarity": "opus", "tags": ["mana", "ward"], "title": "Benediction", "desc": "Triage property: every 5th proc bathes the WHOLE party in light (heal 30 all)."},
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

## Assembled "YOUR TRIAGE" display lines (tooltips / binds). Empty when no mod pieces
## drafted. Numbers mirror MenderConfig mod_* defaults.
static func verb_summary(boons: Dictionary, _aspect: String) -> Array:
	var trig: Array = []
	var pay: Array = []
	var prop: Array = []
	if boons.get("mdTrigDispel", false): trig.append("Dispel")
	if boons.get("mdTrigWard", false): trig.append("consumed Ward")
	if boons.get("mdTrigBeat", false): trig.append("PERFECT beat")
	if boons.get("mdPayShield", false): pay.append("shield 25")
	if boons.get("mdPayMana", false): pay.append("+12 mana")
	if boons.get("mdPayHot", false): pay.append("small HoT")
	if boons.get("mdPropSwift", false): prop.append("casts -12%")
	if boons.get("mdPropBenediction", false): prop.append("every 5th proc: party heal 30")
	if trig.is_empty() and pay.is_empty() and prop.is_empty():
		return []
	var out: Array = []
	out.append("Proc moments: clutch heal (ally < 50%)" + ("" if trig.is_empty() else " · " + " · ".join(trig)))
	out.append("On every proc: " + (" · ".join(pay) if not pay.is_empty() else "(no payloads drafted yet)"))
	if not prop.is_empty():
		out.append("Properties: " + " · ".join(prop))
	return out
