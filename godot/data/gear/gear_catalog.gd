## GEAR-1 — the CURIO catalog (Realm-1 display: PERIPHERALS) + per-boss Ledger tables.
## Pure data: combat effects live gear-gated in the class kits (via GearFx), UTIL
## items in the raid HUD's map layer. Design of record: GEAR-CATALOG.md (every row's
## hook/combo/tags). GEAR-1 scope = SIGNATURE rows only (first-kill unlocks); oath /
## version rows arrive with GEAR-2+.
##
## NOTE Bloomweaver: not in the raid comp (tank/blade/caster/healer=Mender), so it
## has no unlock-live surface yet — its catalog rows stay parked in GEAR-CATALOG.md.
class_name GearCatalog
extends RefCounted

## id -> item def. cls "" = universal (any seat); kind "sim" = combat-touching
## (enters balance sims) | "util" = map/economy (sims never see it). Actives carry
## per-run charges. Rarity strings match Draft.RARITIES.
const ITEMS := {
	"riftmaw_tooth": {
		"name": "Riftmaw Tooth", "rarity": "haiku", "cls": "", "kind": "sim",
		"desc": "Whenever a boss self-heal is DENIED — anyone's kick — you gain 15 resource.",
		"flavor": "Checkpoint corrupted. Scavenge the parts.",
	},
	"lechat_bell": {
		"name": "LE CHAT's Bell", "rarity": "haiku", "cls": "", "kind": "sim",
		"desc": "Begin every fight with +30 resource, pre-warmed.",
		"flavor": "Lightweight. Efficient. Rings exactly once.",
	},
	"swan_song": {
		"name": "Swan Song", "rarity": "haiku", "cls": "", "kind": "sim",
		"desc": "When you die: a 120 farewell blast, and 15 healing to each living ally.",
		"flavor": "It saved its best poem for last.",
	},
	"ticket_stub": {
		"name": "Ticket Stub", "rarity": "haiku", "cls": "", "kind": "util",
		"desc": "Closing a TICKET also repairs +5% party integrity.",
		"flavor": "The subagent does the chores.",
	},
	"cooling_paste": {
		"name": "Cooling Paste", "rarity": "haiku", "cls": "", "kind": "util",
		"active": true, "charges": 2,
		"desc": "USE on the map (2 per run): repair every CORRUPTED SECTOR wound.",
		"flavor": "Thermal throttling recommended.",
	},
	"verify_stamp": {
		"name": "Verification Stamp", "rarity": "haiku", "cls": "bulwark", "kind": "sim",
		"desc": "Your first clean guard each fight banks +2 Chain links (Warden) / +4 Momentum (Juggernaut).",
		"flavor": "You are not a robot: verified.",
	},
	"powder_vial": {
		"name": "Powder Vial", "rarity": "haiku", "cls": "twinfang", "kind": "sim",
		"desc": "Your Kick also applies 2 stacks of the lit poison lane (Venomancer) / +1 Flow (Tempo).",
		"flavor": "The boot carries the toxin.",
	},
	"spark_plug": {
		"name": "Spark Plug", "rarity": "haiku", "cls": "voidcaller", "kind": "sim",
		"desc": "Your first kick each fight refunds half its cooldown.",
		"flavor": "Kick early, kick often.",
	},
	"salt_vial": {
		"name": "Salt Vial", "rarity": "haiku", "cls": "mender", "kind": "sim",
		"desc": "Your Dispel also heals its target for 25.",
		"flavor": "Rub it in.",
	},
}

## Ledger tables: canonical EncounterRes.id -> rows. Row kinds: "signature" (first
## kill — guaranteed unlock + that kill's drop). Gate exams key by their canonical
## solo ids (the recast is display-only), so a PROVING GROUNDS practice kill of the
## same encounter stays inert simply because practice never rolls drops.
const TABLES := {
	"riftmaw":    [{"row": "signature", "item": "riftmaw_tooth"}],
	"mistral":    [{"row": "signature", "item": "lechat_bell"}],
	"bard":       [{"row": "signature", "item": "swan_song"}],
	"sonnet":     [{"row": "signature", "item": "ticket_stub"}],
	"opus":       [{"row": "signature", "item": "cooling_paste"}],
	"gatekeeper": [{"row": "signature", "item": "verify_stamp"}],
	"warden":     [{"row": "signature", "item": "powder_vial"}],
	"priest":     [{"row": "signature", "item": "spark_plug"}],
	"rendmaw":    [{"row": "signature", "item": "salt_vial"}],
}

static func item(id: String) -> Dictionary:
	return ITEMS.get(id, {})

static func table(boss_id: String) -> Array:
	return TABLES.get(boss_id, [])

## Scrap value in Tokens (⏣) by printed rarity.
static func scrap_value(id: String) -> int:
	match String(item(id).get("rarity", "haiku")):
		"opus":   return 3
		"sonnet": return 2
		_:        return 1
