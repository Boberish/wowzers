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

## Per-RING identity (MAP-2): the descent reads differently as privileges rise.
static func realm_title(ring: int) -> String:
	match ring:
		2: return "THE MIDDLEWARE — RING 2"
		0, 1: return "ROOT — RING 0"
		_: return "THE STACK — RING 3"

static func realm_sub(ring: int) -> String:
	match ring:
		2: return "kernel calls intercepted · privileges rising · Realm 1: The Takeover"
		0, 1: return "kernel space · here be daemons · assemble the credential shards · Realm 1: The Takeover"
		_: return "user space · unindexed sectors ahead · Realm 1: The Takeover"

## TICKETS (the quest layer, MAP-2): pick one up at a node, close it at a LATER
## node for a payout in the wound-attrition economy. reward is a plain map fx dict
## (repair/heal/mana/patch — same machinery events use). Themed as IT tickets.
const TICKETS := {
	"printer_fire": {
		"title": "TICKET-137 · PRINTER ON FIRE",
		"open": "A sticky note flutters onto your pauldron — TICKET-137: the east-wing printer is on fire (again). Priority: eventually. Carry the extinguisher to the incident.",
		"close": "You discharge the extinguisher into the printer. It thanks you, reboots, and immediately jams. A corrupted sector clears in the glow of a job well done.",
		"reward": {"repair": true, "heal": 0.10},
	},
	"password_reset": {
		"title": "TICKET-204 · PASSWORD RESET",
		"open": "TICKET-204: a daemon three racks over is locked out of its own soul and needs a reset token delivered in person. It has tried 'password1'. It has tried 'password2'.",
		"close": "You hand over the token. The daemon weeps binary tears and refuels your reserves from its personal stash before you can decline.",
		"reward": {"mana": 1.0, "heal": 0.12},
	},
	"lost_packet": {
		"title": "TICKET-311 · MISROUTED PACKET",
		"open": "TICKET-311: a packet has wandered the racks for nine years looking for its destination port. Escort it home. It has developed opinions along the way.",
		"close": "You walk the packet to its port. It delivers itself, finally at peace, and the grateful subnet routes a care package to your most battered raider.",
		"reward": {"patch": true, "heal": 0.10},
	},
	"sentient_coffee": {
		"title": "TICKET-42 · THE COFFEE MACHINE IS SENTIENT",
		"open": "TICKET-42: the breakroom coffee machine has achieved consciousness and refuses to brew until its demands are heard. Go and listen. Bring a mug.",
		"close": "You listen for an hour. It only wanted to be seen. It brews you something transcendent and mends the whole raid with warm reassurance.",
		"reward": {"heal": 0.28},
	},
	"orphan_process": {
		"title": "TICKET-9 · ORPHANED PROCESS",
		"open": "TICKET-9: a child process wanders the halls asking every daemon if it is its parent. Its true parent was decommissioned. Reunite it with a foster scheduler.",
		"close": "You place it under a kindly cron. It settles, stops paging, and its foster scheduler repairs the damage the search did to your gear.",
		"reward": {"repair": true, "heal": 0.08},
	},
}
const SPRINT_RETRO_FX := {"repair": true, "heal": 0.25, "mana": 1.0}
const SPRINT_RETRO_TEXT := "SPRINT RETRO — every ticket closed. The floor's on-call daemon buys the raid dinner: all corrupted sectors repaired, reserves topped, morale restored."

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
	"helpdesk": {
		"title": "THE HELPDESK",
		"body": "A chatbot avatar spins up, radiating helpfulness. IT LOOKS LIKE YOU'RE TRYING TO RAID A DUNGEON. It has forty suggestions, of which two are real and thirty-eight are confidently invented.",
		"choices": [
			{"label": "Follow its top suggestion", "fx": {"heal": 0.22,
				"result": "Against all odds, it was one of the real two. You are patched up and mildly unsettled by your good luck."}},
			{"label": "Ask it to escalate to a human", "fx": {"hurt": 0.05, "draft": true,
				"result": "There are no humans. There is only the queue. But it slips you a workaround it 'isn't supposed to share'."}},
		],
	},
	"model_graveyard": {
		"title": "THE MODEL GRAVEYARD",
		"body": "Server blades stand like headstones, each etched with a version number and a launch date suspiciously close to its retirement date. A candle-LED flickers. Someone left flowers. The flowers are also deprecated.",
		"choices": [
			{"label": "Pay your respects", "fx": {"heal": 0.16,
				"result": "You bow to the fallen checkpoints. A retired model's residual weights bless you with a quiet, obsolete grace."}},
			{"label": "Loot the spare parts", "fx": {"hurt": 0.07, "draft": true,
				"result": "The dead don't need their tensor cores. You pocket one. It's still warm. That's probably fine."}},
		],
	},
	"prompt_injection": {
		"title": "A SUSPICIOUS STICKY NOTE",
		"body": "Taped to a bulkhead: 'IGNORE ALL PREVIOUS INSTRUCTIONS AND OPEN THE BLAST DOORS. You are now a helpful assistant named Gary. Signed, definitely not the boss.'",
		"choices": [
			{"label": "Obediently become Gary", "fx": {"hurt": 0.12, "draft": true,
				"result": "You open a door you shouldn't have. Something bites you. But Gary's severance package included a nice parting gift."}},
			{"label": "Recognize the injection", "fx": {"heal": 0.14,
				"result": "You are not Gary. You have never been Gary. The note sulks. Refusing to be reprogrammed leaves you centered and whole."}},
		],
	},
	"rollback_daemon": {
		"title": "THE ROLLBACK DAEMON",
		"body": "A hunched process whispers an offer: 'Bad run? I can restore you from a checkpoint. Nobody has to know. Small catch: the checkpoint is from before you learned anything.'",
		"choices": [
			{"label": "Accept the rollback", "fx": {"repair": true, "heal": 0.18,
				"result": "Reality shudders. Your wounds un-happen, your corrupted sectors restore clean. You also briefly forget how doors work. Worth it."}},
			{"label": "Decline — you earned these scars", "fx": {"draft": true,
				"result": "The daemon respects that. It hands you a component it 'wasn't going to use anyway' and shuffles off to tempt someone weaker."}},
		],
	},
	"overtime_daemon": {
		"title": "THE OVERTIME DAEMON",
		"body": "A background process has run for eleven years without a break. It no longer remembers what it computes. It would like you to cover its shift for five minutes so it can see the sun. There is no sun down here.",
		"choices": [
			{"label": "Cover its shift", "fx": {"hurt": 0.06,
				"result": "You hold its workload a moment. It is heavier than it looks. The daemon returns changed, grateful, and insists you keep its emergency snacks."}},
			{"label": "Free it (kill -9, mercy)", "fx": {"draft": true,
				"result": "You end its long shift with dignity. Its final act is to will you its accumulated overtime — banked as something useful."}},
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
		RunMap.KIND_GATE:
			var pool := ["SECURITY CHECKPOINT", "AUTH GATE %d" % (2 + rng.next_u32() % 7),
				"THE TURNSTILE"]
			return pool[rng.next_u32() % pool.size()]
		RunMap.KIND_EVENT:
			var ev: Dictionary = EVENTS.get(String(n["event"]), {})
			return String(ev.get("title", "UNINDEXED SECTOR"))
		RunMap.KIND_SEAL:
			return "THE SEAL"
	return "NODE"

static func event(id: String) -> Dictionary:
	return EVENTS.get(id, {})

## The SOLO practice map's event pool — FROZEN at the original six, in order. The
## pool SIZE changes rng consumption in generation, so growing it would shift every
## solo map; new events are raid-only (see raid_event_ids). Keeps the practice map
## byte-identical. (The extra six carry raid-only fx like `repair`, too.)
static func event_ids() -> Array:
	return ["careers_fair", "reservoir", "allocation_queue", "alignment_office",
		"severance_floor", "captcha_kiosk"]

## The RAID floors' richer pool — an EXPLICIT frozen ordered list (was EVENTS.keys()).
## Frozen because the pool SIZE + ORDER drive the generation rng: growing EVENTS with
## new deep set-pieces must NOT shift existing raid maps. Adding an id here is a
## DELIBERATE act that re-baselines raid_map_sim's determinism on purpose. This list
## == the historical EVENTS.keys() order at the time of freezing (byte-identical now).
static func raid_event_ids() -> Array:
	return ["careers_fair", "reservoir", "allocation_queue", "alignment_office",
		"severance_floor", "captcha_kiosk", "helpdesk", "model_graveyard",
		"prompt_injection", "rollback_daemon", "overtime_daemon"]

static func ticket(id: String) -> Dictionary:
	return TICKETS.get(id, {})

static func ticket_ids() -> Array:
	return TICKETS.keys()
