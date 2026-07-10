## ARMORY — the armor-set PRESENTATION layer over the boon draft (Bill, 2026-07-03).
## Every drafted boon is displayed as a PIECE of run-armor on a paper-doll SET panel;
## the draft economy itself is untouched (Hades stacking, rarity, pity, tokens — all
## Draft 2.0). A slot's "piece" = the family's boon count + its best rarity glow.
## Curios stay their own lane: the two equip slots render as TRINKET sockets.
##
## Mapping rule of thumb (judgment-called per boon below):
##   WEAPON    — your output: damage, finishers, heal-throughput (healers), output procs
##   HELM      — the engine: resource regen/costs/economy, cast speed
##   CUIRASS   — survival: self-heals, wards, DR, guard-verb mods, thorns
##   GAUNTLETS — the class mechanic in hand: Chain/Momentum/Flow/Backlash/Silence/
##               Litany/Reservoir/Nerve/Verdance engines
##   GREAVES   — footwork: dodges, beats, timing windows, kick cadence
class_name ArmorSlots
extends RefCounted

const ORDER := ["weapon", "helm", "cuirass", "gauntlets", "greaves"]

const NAMES := {
	"weapon": "WEAPON", "helm": "HELM", "cuirass": "CUIRASS",
	"gauntlets": "GAUNTLETS", "greaves": "GREAVES",
}

## boon id -> slot, the class pools (bulwark / twinfang /
## bloomweaver). Unmapped future boons fall back onto tags (see slot_of).
const MAP := {
	# ---- BULWARK ----
	"rampagePlus": "weapon", "fortRage": "helm", "furyGain": "helm",
	"execute": "weapon", "bloodthirst": "weapon", "shockwave": "weapon",
	"retaliation": "cuirass", "trigRead": "greaves", "trigThird": "cuirass",
	"trigBeat": "greaves", "payReflect": "weapon", "payHeal": "cuirass",
	"payRage": "helm", "payExpose": "weapon", "propSwift": "cuirass",
	"propWide": "cuirass", "propCharge": "cuirass",
	"deepCounter": "gauntlets", "riposteHeal": "cuirass", "perfectReflect": "cuirass",
	"vindInterrupt": "weapon", "riposteChain": "cuirass", "trigRiposte": "weapon",
	"payCounter": "gauntlets",
	"unstoppable": "gauntlets", "snowball": "gauntlets", "bulldoze": "gauntlets",
	"landslide": "cuirass", "sureFoot": "greaves", "overrun": "cuirass",
	"payMomentum": "gauntlets",
	# ---- TWINFANG ---- (bulwark's execute id is shared — twinfang's is the same key)
	"flowCap": "gauntlets", "strikeEnergy": "helm", "dodgeCp": "greaves",
	"flurry": "weapon", "dancersgrace": "greaves", "tfTrigEvade": "greaves",
	"tfTrigSpender": "weapon", "tfTrigBeat": "greaves", "tfPayLash": "weapon",
	"tfPayEnergy": "helm", "tfPayLeech": "cuirass", "tfPropWindow": "weapon",
	"tfPropTwinStep": "greaves",
	"encore": "gauntlets", "crescendo": "weapon", "eviPlus": "weapon",
	"syncopation": "gauntlets", "virtuoso": "gauntlets", "fifthCrit": "weapon",
	"potent": "weapon", "fastRot": "weapon", "catalyst": "gauntlets",
	"rupturing": "weapon", "contagion": "weapon", "debilitate": "cuirass",
	"lingerVenom": "gauntlets",
	# ---- VOIDCALLER ----
	"silence": "gauntlets", "counterspell": "weapon", "fracplus": "weapon",
	"refund": "greaves", "nullbrand": "gauntlets", "voidfeast": "weapon",
	"vcTrigClean": "gauntlets", "vcTrigDeny": "gauntlets", "vcTrigBeat": "greaves",
	"vcPayVoid": "weapon", "vcPayFocus": "helm", "vcPayMend": "cuirass",
	"vcPropZone": "greaves", "vcPropTwinVoid": "greaves",
	"punish": "weapon", "overfocus": "helm", "backdot": "weapon", "quickint": "greaves",
	"longsil": "gauntlets", "deepexpose": "gauntlets", "silheal": "cuirass",
	# ---- MENDER ---- (healer WEAPON = heal throughput: the instrument)
	"conservation": "helm", "overflow": "cuirass", "afterglow": "weapon",
	"cascade4": "weapon", "wardplus": "cuirass", "sanctifiedward": "cuirass",
	"mdTrigDispel": "gauntlets", "mdTrigWard": "cuirass", "mdTrigBeat": "greaves",
	"mdPayShield": "cuirass", "mdPayMana": "helm", "mdPayHot": "weapon",
	"mdPropSwift": "helm", "mdPropBenediction": "gauntlets",
	"floodgate": "gauntlets", "reservoirplus": "gauntlets", "tideconv": "gauntlets",
	"bloodpact": "gauntlets", "secondwind": "cuirass", "nerveplus": "gauntlets",
	# ---- BLOOMWEAVER ----
	"deeproots": "weapon", "quickbloom": "weapon", "thickbark": "cuirass",
	"sapflow": "helm", "greenfuse": "helm", "evergreencycle": "cuirass",
	"bwTrigPerfect": "cuirass", "bwTrigPlant": "gauntlets", "bwTrigBeat": "greaves",
	"bwPayThorn": "cuirass", "bwPaySap": "helm", "bwPayMend": "weapon",
	"bwPropQuick": "weapon", "bwPropDeepGarden": "gauntlets",
	"evergreen": "gauntlets", "verdantsurge": "weapon", "photosynth": "gauntlets",
	"barbs": "cuirass", "perfectharvest": "cuirass", "ringbark": "cuirass",
}

static func pretty(slot: String) -> String:
	return String(NAMES.get(slot, slot.to_upper()))

## Which armor slot does this boon forge into? Explicit map first; a future boon
## falls back onto its tags so the doll never shows an unplaceable piece.
static func slot_of(b: Dictionary) -> String:
	var id := String(b.get("id", ""))
	if MAP.has(id):
		return String(MAP[id])
	for t in b.get("tags", []):
		match String(t):
			"dodge", "perfect":
				return "greaves"
			"ward", "bark", "guard", "parry":
				return "cuirass"
			"mana", "rage", "focus", "sap", "tokens":
				return "helm"
			"poison", "rupture", "riposte", "rampage", "combo":
				return "weapon"
	return "gauntlets"

## Fold a drafted-boon list into per-slot piece summaries for the doll:
## slot -> {"count": int, "best": rarity, "titles": ["Deep Counter (opus)", ...]}.
static func summarize(taken: Array) -> Dictionary:
	var out := {}
	for slot in ORDER:
		out[slot] = {"count": 0, "best": "", "titles": [], "pieces": []}
	var rank := {"haiku": 1, "sonnet": 2, "opus": 3}
	for b in taken:
		var bd: Dictionary = b
		var slot := slot_of(bd)
		var e: Dictionary = out[slot]
		e["count"] = int(e["count"]) + 1
		var r := String(bd.get("rarity", "haiku"))
		if int(rank.get(r, 0)) > int(rank.get(String(e["best"]), 0)):
			e["best"] = r
		(e["titles"] as Array).append("%s  ·  %s" % [String(bd.get("title", "?")), r])
		# ARMORY-UI: the rich hover/modal want the piece's full stat line
		(e["pieces"] as Array).append({"title": String(bd.get("title", "?")), "rarity": r,
			"desc": String(bd.get("desc", ""))})
	return out
