## The Bulwark draft pool — upgrades/relics/spells from poc/bulwark.html, the Opus
## transform, and the Phase-B SLOT-VERB mods (build-your-Guard), as data. Effects are
## implemented in BulwarkKit (keyed by these ids). Draft 2.0: entries carry `rarity`
## (haiku/sonnet/opus — frequency, never a cap) and `tags` (synergy vocabulary); the
## roll lives in the shared engine (Draft).
## Slot-verbs: entries with a `slot` key are Guard MOD PIECES — "trigger" adds a proc
## moment, "payload" fires on EVERY proc moment (innate: any clean guard), "property"
## reshapes the verb. NO LOCKOUTS — all pieces stack, N triggers × M payloads all live.
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
	# --- Guard mod pieces (Phase B slot-verbs) ---
	{"id": "trigRead", "slot": "trigger", "type": "relic", "rarity": "sonnet", "tags": ["guard", "parry", "dodge"], "title": "Punish the Lie", "desc": "New proc moment: correctly HOLDING a feint also triggers your Guard payloads (+4 rage)."},
	{"id": "trigThird", "slot": "trigger", "type": "relic", "rarity": "sonnet", "tags": ["guard"], "title": "Rhythm of Iron", "desc": "New proc moment: every 3rd successful guard triggers your payloads (+4 rage)."},
	{"id": "trigBeat", "slot": "trigger", "type": "relic", "rarity": "sonnet", "tags": ["guard", "dodge"], "title": "Perfect Footwork", "desc": "New proc moment: a PERFECT combo-beat dodge triggers your payloads (+4 rage)."},
	{"id": "payReflect", "slot": "payload", "type": "relic", "rarity": "sonnet", "tags": ["guard"], "title": "Spiteguard", "desc": "Guard payload: every proc lashes the boss for 35."},
	{"id": "payHeal", "slot": "payload", "type": "relic", "rarity": "haiku", "tags": ["guard"], "title": "Warding Light", "desc": "Guard payload: every proc mends you for 30."},
	{"id": "payRage", "slot": "payload", "type": "relic", "rarity": "haiku", "tags": ["guard", "rage"], "title": "Ironheart", "desc": "Guard payload: every proc grants 8 rage."},
	{"id": "payExpose", "slot": "payload", "type": "relic", "rarity": "sonnet", "tags": ["guard"], "title": "Sunder Guard", "desc": "Guard payload: every proc leaves the boss Exposed for 1.2s (+15% damage taken)."},
	{"id": "propSwift", "slot": "property", "type": "upgrade", "rarity": "haiku", "tags": ["guard"], "title": "Swiftguard", "desc": "Guard property: cooldown -20%."},
	{"id": "propWide", "slot": "property", "type": "upgrade", "rarity": "haiku", "tags": ["guard"], "title": "Broadguard", "desc": "Guard property: the active window is 30% wider."},
	{"id": "propCharge", "slot": "property", "type": "upgrade", "rarity": "opus", "tags": ["guard"], "title": "Twin Guard", "desc": "Guard property: a SECOND guard charge — press twice back-to-back; the spare returns after 6s."},
]
const WARDEN := [
	{"id": "deepCounter", "slot": "property", "type": "upgrade", "rarity": "haiku", "tags": ["parry", "counter"], "title": "Deep Counter", "desc": "Each parry banks +2 Counter instead of 1."},
	{"id": "riposteHeal", "type": "upgrade", "rarity": "sonnet", "tags": ["parry", "riposte"], "title": "Vengeful Guard", "desc": "Landing a Riposte also heals you 60."},
	{"id": "perfectReflect", "slot": "property", "type": "relic", "rarity": "haiku", "tags": ["parry"], "title": "Mirror Edge", "desc": "Parries reflect double damage."},
	{"id": "vindInterrupt", "type": "relic", "rarity": "opus", "tags": ["vindicate", "interrupt"], "title": "Judgement", "desc": "Vindicate also interrupts the current swing."},
	{"id": "riposteChain", "slot": "property", "type": "relic", "rarity": "opus", "tags": ["parry", "riposte"], "title": "Flowing Guard", "desc": "A parry nearly refunds its own cooldown."},
	# --- Guard mod pieces (Phase B slot-verbs, Warden flavor) ---
	{"id": "trigRiposte", "slot": "trigger", "type": "relic", "rarity": "sonnet", "tags": ["guard", "riposte", "parry"], "title": "Flowing Wrath", "desc": "New proc moment: landing a Riposte triggers your Guard payloads (+4 rage)."},
	{"id": "payCounter", "slot": "payload", "type": "relic", "rarity": "sonnet", "tags": ["guard", "counter"], "title": "Counterflow", "desc": "Guard payload: every proc banks +1 Counter."},
]
const JUGG := [
	{"id": "unstoppable", "type": "upgrade", "rarity": "haiku", "tags": ["momentum"], "title": "Unstoppable", "desc": "Momentum cap +4 (ride to 14)."},
	{"id": "snowball", "type": "upgrade", "rarity": "haiku", "tags": ["momentum"], "title": "Snowball", "desc": "Momentum decays later and falls off slower."},
	{"id": "bulldoze", "type": "upgrade", "rarity": "sonnet", "tags": ["momentum"], "title": "Bulldoze", "desc": "Eating a heavy or crush grants +3 Momentum."},
	{"id": "landslide", "type": "relic", "rarity": "sonnet", "tags": ["avalanche", "momentum"], "title": "Landslide", "desc": "Avalanche heals you for 40% of its damage."},
	{"id": "sureFoot", "slot": "property", "type": "relic", "rarity": "sonnet", "tags": ["momentum", "dodge"], "title": "Sure-Footed", "desc": "Dodging only halves Momentum instead of dumping it."},
	{"id": "overrun", "type": "relic", "rarity": "sonnet", "tags": ["momentum"], "title": "Overrun", "desc": "At 8+ Momentum, take 40% less from Crush swings."},
	# --- Guard mod pieces (Phase B slot-verbs, Juggernaut flavor) ---
	{"id": "payMomentum", "slot": "payload", "type": "relic", "rarity": "sonnet", "tags": ["guard", "momentum"], "title": "Rolling Iron", "desc": "Guard payload: every proc grants +2 Momentum."},
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

## Assembled "YOUR GUARD" display lines (spellbook / guard tooltip). Empty when no
## guard mod pieces are drafted. Numbers mirror BulwarkConfig mod_* defaults.
static func guard_summary(boons: Dictionary, _aspect: String) -> Array:
	var trig: Array = []
	var pay: Array = []
	var prop: Array = []
	if boons.get("trigRead", false): trig.append("feint READ")
	if boons.get("trigThird", false): trig.append("every 3rd guard")
	if boons.get("trigBeat", false): trig.append("PERFECT beat")
	if boons.get("trigRiposte", false): trig.append("landed Riposte")
	if boons.get("payReflect", false): pay.append("lash 35")
	if boons.get("payHeal", false): pay.append("mend 30")
	if boons.get("payRage", false): pay.append("+8 rage")
	if boons.get("payCounter", false): pay.append("+1 Counter")
	if boons.get("payMomentum", false): pay.append("+2 Momentum")
	if boons.get("payExpose", false): pay.append("Expose 1.2s")
	if boons.get("propSwift", false): prop.append("cooldown -20%")
	if boons.get("propWide", false): prop.append("window +30%")
	if boons.get("propCharge", false): prop.append("2 charges")
	if trig.is_empty() and pay.is_empty() and prop.is_empty():
		return []
	var out: Array = []
	out.append("Proc moments: clean guard" + ("" if trig.is_empty() else " · " + " · ".join(trig)))
	out.append("On every proc: " + (" · ".join(pay) if not pay.is_empty() else "(no payloads drafted yet)"))
	if not prop.is_empty():
		out.append("Properties: " + " · ".join(prop))
	return out
