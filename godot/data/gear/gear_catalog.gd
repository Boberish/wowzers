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
		"name": "Riftmaw Tooth", "rarity": "sonnet", "cls": "", "kind": "sim",
		"desc": "Whenever a boss self-heal is DENIED — anyone's kick — your defensive verb and dodge reset, and you gain 20 resource.",
		"flavor": "Checkpoint corrupted. Scavenge the parts.",
	},
	"lechat_bell": {
		"name": "LE CHAT's Bell", "rarity": "sonnet", "cls": "", "kind": "sim",
		"desc": "Begin every fight with +30 resource, pre-warmed — and for the first 10 seconds your resource flows twice as fast.",
		"flavor": "Lightweight. Efficient. Rings exactly once.",
	},
	"swan_song": {
		"name": "Swan Song", "rarity": "haiku", "cls": "", "kind": "sim",
		"desc": "When you die: a 200 farewell blast, and 25 healing to each living ally.",
		"flavor": "It saved its best poem for last.",
	},
	"ticket_stub": {
		"name": "Ticket Stub", "rarity": "haiku", "cls": "", "kind": "util",
		"desc": "Closing a TICKET also pays +2⏣.",
		"flavor": "The subagent does the chores.",
	},
	"cooling_paste": {
		"name": "Cooling Paste", "rarity": "haiku", "cls": "", "kind": "util",
		"active": true, "charges": 2,
		"desc": "USE on the map (2 per run): repair every CORRUPTED SECTOR wound.",
		"flavor": "Thermal throttling recommended.",
	},
	"scratchpad": {
		"name": "Scratchpad", "rarity": "sonnet", "cls": "", "kind": "sim",
		"desc": "While a boss wind-up of 6s or longer is live, your resource regenerates three times as fast (rage and focus trickle in).",
		"flavor": "Use the thinking time.",
	},
	# ==== UNIVERSAL CURIO POOL v2 (2026-07-05) — always-on run-shapers, cross-spec ====
	# GEAR-CATALOG.md "UNIVERSAL CURIO POOL v2". kind "util" = map/economy (never in sims).
	# The 10 old verb-welded/class curios (powder_vial · encore_bell · grace_period ·
	# verify_stamp · sticky_note · debt_collector · spark_plug · echo_chamber · salt_vial ·
	# overflow_sluice) were CUT here per the doctrine (their dead kit code is gear-gated →
	# harmless). This slice ships 3 wired; the rest of the v2 pool arrives with its systems.
	"expansion_bus": {
		"name": "Expansion Bus", "rarity": "sonnet", "cls": "", "kind": "util",
		"desc": "Every boon draft deals 1-of-4 instead of 1-of-3 — one more choice, always.",
		"flavor": "More lanes on the board.",
	},
	"hashgrinder": {
		"name": "Hashgrinder Rig", "rarity": "sonnet", "cls": "", "kind": "util",
		"desc": "All Token income is doubled, forever.",
		"flavor": "It mines while you fight.",
	},
	"hot_reload": {
		"name": "Hot Reload", "rarity": "sonnet", "cls": "", "kind": "util",
		"desc": "Rerolling a boon draft is FREE — reload the offer as many times as you like, no Tokens spent.",
		"flavor": "Recompiled without restarting.",
	},
}

## Ledger tables: canonical EncounterRes.id -> rows. Row kinds: "signature" (first
## kill — guaranteed unlock + that kill's drop). (Gate-exam pages died with THE
## PURGE 2026-07-10 — gates and the exam bosses are deleted.)
## OATH rows carry a severity (I/II/III = printed rarity tier) + a deed the Oaths
## detector engine can evaluate off `seat.diag`/`seat.vars` (kinds in game/oaths.gd).
## v2: universal curios only. Offender rows removed; new curios unlock via UNIVERSAL deeds
## (zero_deaths / curses / no_dips — no class-specific deed, since curios are cross-spec).
## (The old gate pages died in THE PURGE; ELITE nodes are the candidate roll site
## when the v2 pool grows — GEAR-CATALOG.md banner.)
const TABLES := {
	"riftmaw": [
		{"row": "signature", "item": "riftmaw_tooth"},
		{"row": "oath", "item": "hot_reload", "sev": 1,
			"deed": {"kind": "curses"}, "deed_text": "answer every Baleful Curse within 2s"},
	],
	"mistral": [
		{"row": "signature", "item": "lechat_bell"},
		{"row": "oath", "item": "expansion_bus", "sev": 2,
			"deed": {"kind": "zero_deaths"}, "deed_text": "zero raider deaths"},
	],
	"mythos": [
		{"row": "oath", "item": "scratchpad", "sev": 2,
			"deed": {"kind": "zero_deaths"}, "deed_text": "bring all four out alive"},
		{"row": "oath", "item": "hashgrinder", "sev": 3,
			"deed": {"kind": "no_dips"}, "deed_text": "no ally below 30% health"},
	],
	"bard":   [{"row": "signature", "item": "swan_song"}],
	"sonnet": [{"row": "signature", "item": "ticket_stub"}],
	"opus":   [{"row": "signature", "item": "cooling_paste"}],
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
