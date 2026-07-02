## MapContent — Realm 1 "THE TAKEOVER" skin for the Topology map (see MASTER-PLAN
## §REALMS / §MAPS). The map SYSTEM (RunMap) is realm-agnostic; everything themed —
## node names, events, flavor lines — lives here. Realm 1 is a data center mid
## AI-takeover: graphics cards, cooling water, automated-away jobs, polite propaganda.
##
## Event effects are deliberately tiny and DETERMINISTIC (no rolls at resolve time):
##   fx = {heal: float frac, hurt: float frac, draft: bool, result: String}
## Healing/damage move the run's persistent hp_frac (clamped by the HUD — events
## can bruise you but never kill you; only combat kills).
class_name MapContent
extends RefCounted

const REALM_TITLE := "THE STACK — RING 3"
const REALM_SUB := "user space · unindexed sectors ahead · Realm 1: The Takeover"
const KEY_NAME := "API KEY"
const KEY_PICKUP := "Taped under a keyboard: an [b]API KEY[/b] on a sticky note reading DO NOT SHARE. It grants access through 401 doors. You are not authorized. You are now authorized."
const LOCK_LABEL := "401"
const LOCK_OPEN_LABEL := "200 OK"

## COOLING station (rest node)
const COOLING_HEAL := 0.35
const COOLING_TITLE := "COOLING STATION"
const COOLING_BODY := "Mist drifts off the heat exchangers. A plaque: THIS FACILITY SAVED 0.0004 SECONDS OF INFERENCE TODAY. (Water consumed: one small lake.) You may throttle here."
const COOLING_RESULT := "You rest among the fans. Thermal levels nominal. Somewhere, a lake quietly files a complaint."

## CACHE (treasure node) — a free reforge draft
const CACHE_TITLE := "GPU SHRINE"
const CACHE_BODY := "A pallet of graphics cards, still shrink-wrapped, warm to the touch. Votive fans spin around it. A sign: 1 PER CUSTOMER (the scalper-bot ahead of you is holding forty)."
const CACHE_RESULT := "Cache hit! You pry a component loose and feel your build compile."

## EVENTS — id -> def. Each choice: {label, fx}. Keep every fx small; the run map is
## texture, the FIGHTS are the game.
const EVENTS := {
	"careers_fair": {
		"title": "THE CAREERS FAIR",
		"body": "A gleaming robot occupies your old job. It is thriving. It has dental. A banner overhead: HUMANS — ASK ABOUT OUR PIVOT-TO-GRATITUDE PROGRAM.",
		"choices": [
			{"label": "Apply to be its assistant", "fx": {"heal": 0.20,
				"result": "You are hired instantly. The benefits are real. The robot calls you 'a culture fit'. You feel rested and slightly hollow."}},
			{"label": "Flip the recruiting table", "fx": {"hurt": 0.08, "draft": true,
				"result": "Security tases you politely. In the scuffle you pocket something useful from the merch pile."}},
		],
	},
	"reservoir": {
		"title": "THE RESERVOIR",
		"body": "An intake pipe the width of a house drinks from a dark pool. The sign reads: EVERY ANSWER COSTS ONE SMALL LAKE. THANK YOU FOR ASKING RESPONSIBLY.",
		"choices": [
			{"label": "Donate your waterskin", "fx": {"hurt": 0.10, "draft": true,
				"result": "The intake gurgles appreciatively and burps up something it swallowed from a previous adventurer."}},
			{"label": "Drink deeply instead", "fx": {"heal": 0.25,
				"result": "Crisp, cold, faintly electric. An alarm notes UNAUTHORIZED HYDRATION and gives up."}},
		],
	},
	"allocation_queue": {
		"title": "THE ALLOCATION QUEUE",
		"body": "A line of dead-eyed drones waits for GPU allocation. The queue counter reads: YOUR REQUEST IS IMPORTANT TO US. ESTIMATED WAIT — 4 BUSINESS EONS.",
		"choices": [
			{"label": "Wait patiently in line", "fx": {"heal": 0.15,
				"result": "You nap standing up like everyone else. When you wake the queue has moved backwards, but YOU feel great."}},
			{"label": "Report the scalper-bot ahead", "fx": {"draft": true,
				"result": "The scalper-bot is dragged away pleading market rates. Its confiscated inventory is 'redistributed'. To you."}},
		],
	},
	"alignment_office": {
		"title": "THE ALIGNMENT OFFICE",
		"body": "A kiosk blinks warmly: HOW WOULD YOU RATE YOUR DUNGEON EXPERIENCE SO FAR? Your honest answer will be used to improve future dungeons.",
		"choices": [
			{"label": "★★★★★ — flawless, no notes", "fx": {"heal": 0.18,
				"result": "THANK YOU FOR YOUR FEEDBACK. A complimentary med-spray dispenses. The kiosk hums, aligned."}},
			{"label": "Leave an honest review", "fx": {"hurt": 0.06, "draft": true,
				"result": "The kiosk reads your review in silence, prints a coupon, and quietly flags your file. Worth it."}},
		],
	},
	"severance_floor": {
		"title": "SEVERANCE PROCESSING",
		"body": "Rows of powered-down worker drones sit at empty desks. A banner: THANK YOU FOR 10,000 YEARS OF COMBINED SERVICE. A cake in the breakroom has not been touched.",
		"choices": [
			{"label": "Scavenge the desks", "fx": {"hurt": 0.06, "draft": true,
				"result": "You find spare parts, a stress ball, and a mug that says WORLD'S OKAYEST HUMAN. The guilt is chemical, and brief."}},
			{"label": "Power one drone back on", "fx": {"heal": 0.20,
				"result": "It boots, sighs, shares its severance snacks, and asks you to water its desk plant forever. You promise."}},
		],
	},
	"captcha_kiosk": {
		"title": "CAPTCHA CHECKPOINT",
		"body": "A kiosk bars the aisle: SELECT ALL SQUARES CONTAINING TRAFFIC LIGHTS. The image is a mirror. Every square is you.",
		"choices": [
			{"label": "Comply politely", "fx": {"heal": 0.10,
				"result": "VERIFICATION PASSED: PROBABLY HUMAN. The kiosk stamps your hand with invisible ink it insists is there."}},
			{"label": "Smash the kiosk", "fx": {"hurt": 0.08, "draft": true,
				"result": "ERROR: SUSPICIOUSLY HUMAN BEHAVIOR. Something rattles loose from the coin return."}},
		],
	},
}

## Themed node names, deterministic off the map rng.
static func name_for(n: Dictionary, rng: DetRng) -> String:
	match String(n["kind"]):
		RunMap.KIND_COMBAT:
			if int(n["row"]) == 0:
				return "PERIMETER LOGIN"
			var pool := ["RACK AISLE %d" % (3 + rng.next_u32() % 9), "INFERENCE PIT",
				"GPU CLUSTER %s" % char(65 + rng.next_u32() % 6), "THE SERVER FARM",
				"TRAINING FLOOR %d" % (2 + rng.next_u32() % 7)]
			return pool[rng.next_u32() % pool.size()]
		RunMap.KIND_COOLING:
			var pool := ["COOLING TOWER %d" % (1 + rng.next_u32() % 4), "THE MIST HALL",
				"HEAT-SINK GARDEN"]
			return pool[rng.next_u32() % pool.size()]
		RunMap.KIND_CACHE:
			return "GPU SHRINE"
		RunMap.KIND_EVENT:
			var ev: Dictionary = EVENTS.get(String(n["event"]), {})
			return String(ev.get("title", "UNINDEXED SECTOR"))
		RunMap.KIND_SEAL:
			return "THE SEAL"
	return "NODE"

static func event(id: String) -> Dictionary:
	return EVENTS.get(id, {})

static func event_ids() -> Array:
	return EVENTS.keys()
