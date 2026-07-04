## GateContent — Tier-1 PERSONAL GATE exams (MASTER-PLAN §GAME SHAPE, locked with
## Bill 2026-07-03): a Topology node where ONE seat steps through alone and fights
## its class's teaching exam — the existing solo boss, recast with its Realm-1
## casting-pool identity (DISPLAY FIELDS ONLY; encounter ids stay canonical so the
## stage variant tints and any future loot tables key off them unchanged).
## The raid watches: panel + result in v1 (live spectate is a later nicety).
##
## Gate semantics (locked): losing a gate does NOT end the run — the checkpoint
## force-reboots you and waves you through FLAGGED: integrity to the reboot floor
## plus a CORRUPTED SECTOR wound. The exam's cost is attrition into the Seal.
class_name GateContent
extends RefCounted

## Per-seat exam: which solo encounter, its Realm-1 identity, and the panel copy.
## `actor`/`variant` pick the stage puppet ("" = the standard boss body + variant tint).
const EXAMS := {
	"tank": {
		"boss": "CAPTCHA-9, the Gatekeeper",
		"variant": "gatekeeper",
		"actor": "",
		"body": "A turnstile with one enormous eye bars the aisle: \"SECURITY CHECKPOINT. ONE PROCESS AT A TIME. PROVE YOU ARE NOT A ROBOT.\" The Bulwark steps through alone — the raid watches through the glass.",
		"challenge": "\"VERIFICATION METHOD: survive me. Robots parry on instruction. Humans parry on INSTINCT. Show me your instincts.\" The turnstile unfolds into something much larger.",
		"win": "200 OK — VERIFICATION PASSED: PROBABLY HUMAN. The turnstile reassembles itself, ticks once, and stamps your hand with ink it insists is there.",
		"lose": "VERIFICATION FAILED: SUSPICIOUSLY ROBOTIC. You are force-rebooted and waved through anyway — flagged, escorted, and one sector corrupted.",
	},
	"blade": {
		"boss": "FIREWALL",
		"variant": "warden",
		"actor": "executioner",
		"body": "The aisle narrows into a scarred iron bulkhead that inspects everything it passes. \"INBOUND PACKET DETECTED. ONE AT A TIME.\" The Twinfang steps through alone — today, YOU are the packet.",
		"challenge": "\"DEEP PACKET INSPECTION ENGAGED. Malformed packets are dropped.\" It draws something that filters at the edge — keep your rhythm or be discarded.",
		"win": "PACKET ACCEPTED. The bulkhead grinds open, logging you as trusted traffic. (It will regret this.)",
		"lose": "PACKET DROPPED. You are force-rebooted past the filter — flagged, throttled, and one sector corrupted.",
	},
	"caster": {
		"boss": "THE PROMPTER",
		"variant": "priest",
		"actor": "",
		"body": "A pulpit of screens blocks the row, already talking: \"GREAT QUESTION! Before you pass, allow me to elaborate. And elaborate. And elaborate.\" The Voidcaller steps through alone — someone has to make it stop generating.",
		"challenge": "\"Let me walk you through my reasoning—\" It inhales for a WALL of text. Kick the casts. Every one you miss, it heals itself with more words.",
		"win": "GENERATION STOPPED. The pulpit powers down mid-sentence, which is the only way it was ever going to end.",
		"lose": "It finished the whole answer. You are force-rebooted past the pulpit — flagged, subscribed to its newsletter, and one sector corrupted.",
	},
	"healer": {
		"boss": "POPUP, the Adhound",
		"variant": "rendmaw",
		"actor": "",
		"body": "The doorway ahead erupts in floating panels: CONGRATULATIONS! YOU ARE THE 1,000,000th RAIDER! A hound of ad-frames circles a sandboxed test party. \"ONE SUPPORT PROCESS MAY ENTER.\" The Mender steps through alone — keep the sandbox alive through the storm.",
		"challenge": "\"ONE WEIRD CLAW. DOCTORS HATE IT.\" The hound pounces the sandbox party — triage through the pop-up barrage, and dodge the ones aimed at YOU.",
		"win": "STORM DISMISSED. The sandbox party waves goodbye and dissolves. One panel lingers: WAS THIS HEAL HELPFUL? (yes / very yes)",
		"lose": "The sandbox collapsed. You are force-rebooted past the doorway — flagged, retargeted, and one sector corrupted.",
	},
}

## Post-fight capper (the result page under the win/lose copy).
const CAPPER := {
	true: "The raid pretends it wasn't worried.",
	false: "Nobody mentions the smell of burnt sectors. A Cooling Station can repair them.",
}

static func exam(seat_key: String) -> Dictionary:
	return EXAMS.get(seat_key, EXAMS["tank"])

## The class's exam fight, exactly as the solo game builds it (party-of-one for the
## martial seats; the healer brings its sandboxed stat-block party) — display name
## and intro recast to the Realm-1 identity.
static func make_state(seed: int, seat_key: String, aspect: String, cls: String = "") -> CombatState:
	var ex: Dictionary = exam(seat_key)
	match seat_key:
		"blade":
			# the blade seat has two classes — the Reckoner's exam is its own solo boss
			# (the Sentinel), recast to the FIREWALL identity like the Mender/Bloomweaver split.
			if cls == "reckoner":
				var er := ReckonerContent.make_sentinel()
				_recast(er, ex)
				return ReckonerContent.make_state(seed, aspect, ReckonerContent.make_config(),
					ReckonerContent.make_reckoner_config(), er)
			var e := TwinfangContent.make_warden()
			_recast(e, ex)
			return TwinfangContent.make_state(seed, aspect, TwinfangContent.make_config(),
				TwinfangContent.make_twinfang_config(), e)   # THE OPENING live in the FIREWALL gate too
		"caster":
			var e2 := VoidcallerContent.make_priest()
			_recast(e2, ex)
			return VoidcallerContent.make_state(seed, aspect, VoidcallerContent.make_config(),
				VoidcallerContent.make_voidcaller_config(), e2)
		"healer":
			# the healer seat has two classes — the Bloomweaver's exam is its own solo
			# spike fight (Ashmaul), not the Mender's (Rendmaw).
			if cls == "bloomweaver":
				var eb := BloomweaverContent.make_ashmaul()
				_recast(eb, ex)
				return BloomweaverContent.make_state(seed, aspect, BloomweaverContent.make_config(),
					BloomweaverContent.make_bloom_config(), eb)
			var e3 := MenderContent.make_rendmaw()
			_recast(e3, ex)
			return MenderContent.make_state(seed, aspect, MenderContent.make_config(),
				MenderContent.make_mender_config(), e3)
		_:
			var e4 := BulwarkContent.make_gatekeeper()
			_recast(e4, ex)
			return BulwarkContent.make_state(seed, aspect, BulwarkContent.make_config(),
				BulwarkContent.make_bulwark_config(), e4)

## Realm-1 recast — DISPLAY fields only (the id stays canonical, per the theme
## acceptance bar: rename via display fields, never ids).
static func _recast(e: EncounterRes, ex: Dictionary) -> void:
	e.name = String(ex["boss"])
	e.intro = String(ex["challenge"])

## Stage cast for RaidStage2D.setup — seat-ordered actor specs matching the gate
## state's seats. The healer's stat-block sandbox party borrows the class puppets.
static func stage_cast(seat_key: String, aspect: String) -> Array:
	match seat_key:
		"blade":
			return [{"id": "twinfang", "key": "blade", "aspect": aspect}]
		"caster":
			return [{"id": "voidcaller", "key": "caster", "aspect": aspect}]
		"healer":
			return [
				{"id": "mender", "key": "healer", "aspect": aspect},
				{"id": "bulwark", "key": "tank"},
				{"id": "twinfang", "key": "blade"},
				{"id": "voidcaller", "key": "caster"},
				{"id": "twinfang", "key": "blade", "at": Vector2(0.30, 0.745)},
			]
		_:
			return [{"id": "bulwark", "key": "tank", "aspect": aspect}]
