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
		"desc": "Closing a TICKET also repairs +10% party integrity and pays +1⏣.",
		"flavor": "The subagent does the chores.",
	},
	"cooling_paste": {
		"name": "Cooling Paste", "rarity": "haiku", "cls": "", "kind": "util",
		"active": true, "charges": 2,
		"desc": "USE on the map (2 per run): repair every CORRUPTED SECTOR wound.",
		"flavor": "Thermal throttling recommended.",
	},
	"verify_stamp": {
		"name": "Verification Stamp", "rarity": "sonnet", "cls": "bulwark", "kind": "sim",
		"desc": "Your first clean guard each fight banks +4 Chain links (Warden) / +8 Momentum (Juggernaut) and resets Guard on the spot.",
		"flavor": "You are not a robot: verified.",
	},
	"powder_vial": {
		"name": "Powder Vial", "rarity": "sonnet", "cls": "twinfang", "kind": "sim",
		"desc": "Your Kick also applies 3 stacks of the lit poison lane (Venomancer) / +2 Flow (Tempo).",
		"flavor": "The boot carries the toxin.",
	},
	"spark_plug": {
		"name": "Spark Plug", "rarity": "sonnet", "cls": "voidcaller", "kind": "sim",
		"desc": "Your first TWO kicks each fight that answer a cast refund their whole cooldown.",
		"flavor": "Kick early, kick often.",
	},
	"salt_vial": {
		"name": "Salt Vial", "rarity": "sonnet", "cls": "mender", "kind": "sim",
		"desc": "Your Dispel also heals its target for 60 and refunds its mana.",
		"flavor": "Rub it in.",
	},
	# ---- GEAR-2: oath-row items (unlocked by SWORN OATHS, see GEAR-CATALOG.md) ----
	"grace_period": {
		"name": "Grace Period", "rarity": "sonnet", "cls": "", "kind": "sim",
		"desc": "Once per fight, your class streak survives its break — Chain, Flow, Litany pip, Momentum, or a whiffed kick.",
		"flavor": "Your first breach is forgiven.",
	},
	"sticky_note": {
		"name": "Sticky Note", "rarity": "haiku", "cls": "bulwark", "kind": "sim",
		"desc": "Taunting back within 2s of the boss forgetting you refunds 15 rage.",
		"flavor": "Taped to its monitor: THE TANK EXISTS.",
	},
	"scratchpad": {
		"name": "Scratchpad", "rarity": "sonnet", "cls": "", "kind": "sim",
		"desc": "While a boss wind-up of 6s or longer is live, your resource regenerates three times as fast (rage and focus trickle in).",
		"flavor": "Use the thinking time.",
	},
	"debt_collector": {
		"name": "Debt Collector", "rarity": "sonnet", "cls": "bulwark", "kind": "sim",
		"desc": "Vindicate cashed at 5+ Chain links also staggers the boss.",
		"flavor": "Payment is due, with interest.",
	},
	"encore_bell": {
		"name": "Encore Bell", "rarity": "sonnet", "cls": "twinfang", "kind": "sim",
		"desc": "After your finisher, your next 3 Strikes: Tempo — the Perfect window holds wide; Venom — each costs 6 less energy.",
		"flavor": "The crowd demands one more.",
	},
	"echo_chamber": {
		"name": "Echo Chamber", "rarity": "opus", "cls": "voidcaller", "kind": "sim",
		"desc": "A CLEAN kick at full Backlash echoes a free Overload at 0.6x — without spending the stacks.",
		"flavor": "The same opinion, louder.",
	},
	"overflow_sluice": {
		"name": "Overflow Sluice", "rarity": "sonnet", "cls": "mender", "kind": "sim",
		"desc": "Overheal spilling past a FULL Reservoir becomes a ward on the tank at half strength.",
		"flavor": "No drop wasted.",
	},
}

## Ledger tables: canonical EncounterRes.id -> rows. Row kinds: "signature" (first
## kill — guaranteed unlock + that kill's drop). Gate exams key by their canonical
## solo ids (the recast is display-only), so a PROVING GROUNDS practice kill of the
## same encounter stays inert simply because practice never rolls drops.
## OATH rows carry a severity (I/II/III = printed rarity tier) + a deed the Oaths
## detector engine can evaluate off `seat.diag`/`seat.vars` (kinds in game/oaths.gd).
const TABLES := {
	"riftmaw": [
		{"row": "signature", "item": "riftmaw_tooth"},
		{"row": "oath", "item": "sticky_note", "sev": 1,
			"deed": {"kind": "curses"}, "deed_text": "answer every Baleful Curse within 2s"},
		{"row": "oath", "item": "grace_period", "sev": 2,
			"deed": {"kind": "zero_deaths"}, "deed_text": "zero raider deaths"},
	],
	"mistral":    [{"row": "signature", "item": "lechat_bell"}],
	"mythos": [
		{"row": "oath", "item": "scratchpad", "sev": 2,
			"deed": {"kind": "zero_deaths"}, "deed_text": "bring all four out alive"},
	],
	"bard":       [{"row": "signature", "item": "swan_song"}],
	"sonnet":     [{"row": "signature", "item": "ticket_stub"}],
	"opus":       [{"row": "signature", "item": "cooling_paste"}],
	"gatekeeper": [
		{"row": "signature", "item": "verify_stamp"},
		{"row": "oath", "item": "debt_collector", "sev": 2,
			"deed": {"kind": "chain_intact", "n": 5},
			"deed_text": "5+ clean guards, the Chain never broken"},
	],
	"warden": [
		{"row": "signature", "item": "powder_vial"},
		{"row": "oath", "item": "encore_bell", "sev": 2,
			"deed": {"kind": "perfects_n", "n": 8}, "deed_text": "land 8 PERFECT strikes"},
	],
	"priest": [
		{"row": "signature", "item": "spark_plug"},
		{"row": "oath", "item": "echo_chamber", "sev": 3,
			"deed": {"kind": "kicks_clean", "n": 6}, "deed_text": "6+ kicks, none whiffed"},
	],
	"rendmaw": [
		{"row": "signature", "item": "salt_vial"},
		{"row": "oath", "item": "overflow_sluice", "sev": 2,
			"deed": {"kind": "no_dips"}, "deed_text": "no ally below 30% health"},
	],
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
