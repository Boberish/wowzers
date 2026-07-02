## The Voidcaller draft pool — the upgrades/relics/spells from poc/voidcaller.html, the
## two Opus transforms, and the Phase-B SLOT-VERB mods (build-your-KICK), as data.
## Effects are implemented in VoidcallerKit (keyed by these ids). Draft 2.0: `rarity` =
## offer frequency (never a cap), `tags` = synergy vocabulary; the roll lives in the
## shared engine (Draft). `quickint` sits in both aspect pools by design — the shared
## roll dedupes by id. Slot-verbs: entries with `slot` are KICK MOD PIECES — the innate
## proc moment is every LANDED interrupt; kicks are rare, so payloads are chunky.
class_name VoidcallerBoons
extends RefCounted

const SHARED := [
	{"id": "silence", "type": "spell", "rarity": "sonnet", "tags": ["interrupt", "silence"], "title": "Silence", "desc": "New spell (5): a 2nd interrupt on 11s cd that also Silences the boss 2.5s.", "excl": "counterspell"},
	{"id": "counterspell", "type": "spell", "rarity": "sonnet", "tags": ["interrupt"], "title": "Counterspell", "desc": "New spell (5): a 2nd interrupt on 9s cd that reflects 90 damage.", "excl": "silence"},
	{"id": "fracplus", "type": "upgrade", "rarity": "haiku", "tags": ["fracture"], "title": "Rupturing Bolt", "desc": "Fracture deals +30 damage."},
	{"id": "refund", "type": "relic", "rarity": "sonnet", "tags": ["interrupt"], "title": "Quick Recovery", "desc": "A clean interrupt refunds half its cooldown."},
	{"id": "nullbrand", "type": "relic", "rarity": "opus", "tags": ["interrupt", "silence"], "title": "Nullbrand", "desc": "Clean kicks also brand the boss with Silence for 1.5s."},
	{"id": "voidfeast", "type": "relic", "rarity": "opus", "tags": ["interrupt"], "title": "Void Feast", "desc": "Denying a heal devours it: 50% of the denied healing strikes back as damage."},
	# --- Kick mod pieces (Phase B slot-verbs) ---
	{"id": "vcTrigClean", "slot": "trigger", "type": "relic", "rarity": "sonnet", "tags": ["interrupt"], "title": "Resonant Break", "desc": "New proc moment: a CLEAN kick triggers your Kick payloads a second time (+8 Focus)."},
	{"id": "vcTrigDeny", "slot": "trigger", "type": "relic", "rarity": "sonnet", "tags": ["interrupt"], "title": "Starve the Choir", "desc": "New proc moment: denying a heal cast triggers your payloads again (+8 Focus)."},
	{"id": "vcTrigBeat", "slot": "trigger", "type": "relic", "rarity": "sonnet", "tags": ["interrupt"], "title": "Void Step", "desc": "New proc moment: a PERFECT combo-beat dodge triggers your payloads (+8 Focus)."},
	{"id": "vcPayVoid", "slot": "payload", "type": "relic", "rarity": "sonnet", "tags": ["interrupt"], "title": "Null Lash", "desc": "Kick payload: every proc lashes the boss for 30."},
	{"id": "vcPayFocus", "slot": "payload", "type": "relic", "rarity": "haiku", "tags": ["interrupt"], "title": "Mind Siphon", "desc": "Kick payload: every proc restores 12 Focus."},
	{"id": "vcPayMend", "slot": "payload", "type": "relic", "rarity": "haiku", "tags": ["interrupt"], "title": "Umbral Mending", "desc": "Kick payload: every proc mends you for 20."},
	{"id": "vcPropZone", "slot": "property", "type": "upgrade", "rarity": "haiku", "tags": ["interrupt"], "title": "Perfect Pitch", "desc": "Kick property: the CLEAN zone is 35% wider."},
	{"id": "vcPropTwinVoid", "slot": "property", "type": "upgrade", "rarity": "opus", "tags": ["interrupt"], "title": "Twin Void", "desc": "Kick property: a SECOND kick charge — kick twice back-to-back; the spare returns after 8s."},
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

## Assembled "YOUR KICK" display lines (tooltips). Empty when no mod pieces drafted.
## Numbers mirror VoidcallerConfig mod_* defaults.
static func verb_summary(boons: Dictionary, _aspect: String) -> Array:
	var trig: Array = []
	var pay: Array = []
	var prop: Array = []
	if boons.get("vcTrigClean", false): trig.append("CLEAN kick (double)")
	if boons.get("vcTrigDeny", false): trig.append("denied heal")
	if boons.get("vcTrigBeat", false): trig.append("PERFECT beat")
	if boons.get("vcPayVoid", false): pay.append("lash 30")
	if boons.get("vcPayFocus", false): pay.append("+12 Focus")
	if boons.get("vcPayMend", false): pay.append("mend 20")
	if boons.get("vcPropZone", false): prop.append("clean zone +35%")
	if boons.get("vcPropTwinVoid", false): prop.append("2 kick charges")
	if trig.is_empty() and pay.is_empty() and prop.is_empty():
		return []
	var out: Array = []
	out.append("Proc moments: landed kick" + ("" if trig.is_empty() else " · " + " · ".join(trig)))
	out.append("On every proc: " + (" · ".join(pay) if not pay.is_empty() else "(no payloads drafted yet)"))
	if not prop.is_empty():
		out.append("Properties: " + " · ".join(prop))
	return out
