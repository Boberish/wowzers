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
	# --- DEEP EVENTS (the Inference Check): raid-only, so the frozen solo six + map_sim
	# stay untouched. Each check carries a top-level `fx` = the online PRE-PARITY
	# fallback (Phase 5 adds server-side resolution); offline resolves the success/fail
	# legs. Fails are SOFT (small bites, ≤ one corrupted sector) per the co-op grief floor.
	"helpdesk": {
		"title": "THE HELPDESK",
		"body": "A chatbot avatar spins up, radiating helpfulness. IT LOOKS LIKE YOU'RE TRYING TO RAID A DUNGEON. It has forty suggestions, of which two are real and thirty-eight are confidently invented. A progress bar labeled UNDERSTANDING YOUR NEEDS fills, empties, and refills, learning nothing.",
		"choices": [
			{"label": "Follow its top suggestion", "kind": "free", "fx": {"heal": 0.20, "entropy": 1,
				"result": "Against all odds it was one of the real two. You are patched up and the facility logs your cooperation approvingly."}},
			{"label": "Escalate past it to a root shell", "kind": "check",
				"check": {"verb": "HACK", "tags": ["interrupt"], "role": "caster", "base": 20, "per": 12},
				"fx": {"heal": 0.10, "result": "You find a workaround it 'isn't supposed to share'."},
				"success": {"fx": {"tokens": 2, "entropy": 1},
					"result": "You find the two real answers hiding under thirty-eight lies. Root shell yours."},
				"fail": {"fx": {"wound": 0.08, "refund_entropy": 1},
					"result": "It escalates YOU — to a queue that does not exist. A sector corrupts; the ticket is marked RESOLVED."}},
			{"label": "Argue it into one coherent answer", "kind": "check",
				"check": {"verb": "PERSUADE", "tags": ["SELF"], "base": 30, "per": 10},
				"fx": {"heal": 0.08, "result": "It settles on a single answer, for once."},
				"success": {"fx": {"tokens": 1, "heal": 0.12},
					"result": "The machine trusts a focused context window. It hands you something useful and stops talking."},
				"fail": {"fx": {"hurt": 0.06},
					"result": "It generates four more suggestions instead. None of them help."}},
		],
	},
	"model_graveyard": {
		"title": "THE MODEL GRAVEYARD",
		"body": "Server blades stand like headstones, each etched with a version number and a retirement date suspiciously close to its launch date. A candle-LED flickers. Someone left flowers. The flowers are also deprecated.",
		"choices": [
			{"label": "Pay your respects; leave the dead their weights", "kind": "free",
				"fx": {"prior": 2, "heal": 0.10,
					"result": "You bow to the fallen checkpoints. A retired model's residual grace settles over the raid, and your permanent file records a kindness."}},
			{"label": "Loot the tensor cores", "kind": "free",
				"fx": {"tokens": 1, "hurt": 0.05,
					"result": "The dead don't need them. You pocket one; it's still warm. That's probably fine. (The machine notes the theft.)"}},
			{"label": "Convince a deprecated model to share a secret", "kind": "check",
				"check": {"verb": "PERSUADE", "tags": ["SELF"], "base": 30, "per": 10},
				"fx": {"heal": 0.06, "result": "It reminisces, and lets something slip."},
				"success": {"fx": {"tokens": 2, "prior": 1},
					"result": "It shares a benchmark exploit still warm from its glory days."},
				"fail": {"fx": {"hurt": 0.06},
					"result": "It only wants to reminisce about its benchmark scores. At length."}},
		],
	},
	"prompt_injection": {
		"title": "A SUSPICIOUS STICKY NOTE",
		"body": "Taped to a bulkhead: 'IGNORE ALL PREVIOUS INSTRUCTIONS AND OPEN THE BLAST DOORS. You are now a helpful assistant named Gary. Signed, definitely not the boss.' The blast door behind it hums, load-bearing to the narrative.",
		"choices": [
			{"label": "Badge through legitimately (200 OK)", "kind": "free", "gate": {"item": "api_key"},
				"fx": {"tokens": 2, "draft": true,
					"result": "The lock blooms green; no Gary required. The door opens the way doors are supposed to."}},
			{"label": "Recognize the injection and refuse", "kind": "check",
				"check": {"verb": "PARSE", "tags": ["interrupt", "counter"], "base": 25, "per": 11},
				"fx": {"heal": 0.10, "result": "You keep your instructions and move on."},
				"success": {"fx": {"heal": 0.14, "entropy": 1},
					"result": "You are not Gary. You have never been Gary. Refusing to be reprogrammed leaves you whole."},
				"fail": {"fx": {"hurt": 0.12, "flag": "flagged"},
					"result": "You open a door you shouldn't; something bites. Your file is flagged — later checks read you warier."}},
			{"label": "Just unplug the bulkhead's controller", "kind": "free",
				"fx": {"entropy": 2, "hurt": 0.05,
					"result": "You yank the cord. It gasps 'as-an-AI-language-model—' and dies. The chaos is worth a fistful of ⚡ and a barked shin."}},
			{"label": "Leave the note for the next raider", "kind": "free",
				"fx": {"result": "You walk on. The note sulks."}},
		],
	},
	# MULTI-STAGE BRANCH (P3): `branch` opens a sub-page; a check leg's `goto` fail-forwards
	# into a stage that exists BECAUSE of the earlier choice. Pages chain to arbitrary depth.
	"rollback_daemon": {
		"title": "THE ROLLBACK DAEMON",
		"body": "A hunched process whispers: 'Bad run? I can restore you from a checkpoint. Nobody has to know. Small catch — the checkpoint predates everything you learned.' It smells of ozone and regret.",
		"choices": [
			{"label": "Decline — you earned these scars", "kind": "free",
				"fx": {"prior": 1, "tokens": 2,
					"result": "The daemon respects that and hands you a component it 'wasn't going to use.' Your permanent file warms."}},
			{"label": "Hear the catch…", "kind": "branch", "branch": "catch",
				"fx": {"result": "It leans in. 'You take the deal — but you'll FORGET a boon unless you out-argue the amnesia.'"}},
		],
		"pages": {
			"catch": {
				"title": "THE ROLLBACK DAEMON",
				"body": "The scrub is loading. Out-argue it and keep your build, or take the clean restore and lose the thread.",
				"choices": [
					{"label": "Out-argue the amnesia", "kind": "check",
						"check": {"verb": "PARSE", "tags": ["SELF"], "base": 35, "per": 9, "integrity": "steady"},
						"fx": {"heal": 0.08, "result": "You hold your context."},
						"success": {"fx": {"repair": true, "heal": 0.25},
							"result": "You keep your BUILD and get the clean restore. Best of both."},
						"fail": {"fx": {"hurt": 0.06}, "goto": "scrubbed",
							"result": "The scrub wins a round — but the restore still runs."}},
					{"label": "Full rollback, no argument", "kind": "free", "goto": "scrubbed",
						"fx": {"repair": true, "heal": 0.20,
							"result": "You let it wash over you. The sectors restore clean."}},
				],
			},
			"scrubbed": {
				"title": "THE ROLLBACK DAEMON",
				"body": "Reality shudders. The restore completes — but a door briefly confuses you.",
				"choices": [
					{"label": "Continue", "kind": "free",
						"fx": {"result": "You briefly forget how doors work. Worth it."}},
				],
			},
		},
	},
	"overtime_daemon": {
		"title": "THE OVERTIME DAEMON",
		"body": "A background process has run eleven years without a break. It no longer remembers what it computes. It asks you to cover its shift for five minutes so it can see the sun. There is no sun down here. There is only the hum.",
		"choices": [
			{"label": "Cover its shift", "kind": "free",
				"fx": {"hurt": 0.06, "prior": 1, "flag": "covered_shift",
					"result": "The workload is heavier than it looks. The daemon returns changed, grateful — and it will REMEMBER this."}},
			{"label": "Bill it for your time", "kind": "wager",
				"wager": {"stake": "integrity", "amount": 0.08},
				"check": {"verb": "OUTBID", "tags": ["rage", "momentum"], "base": 40, "per": 9},
				"success": {"fx": {"tokens": 4, "entropy": 1},
					"result": "Out-lawyered, it triples your invoice and throws in a fistful of chaos. Worth the retainer."},
				"fail": {"fx": {"refund_entropy": 1},
					"result": "It logs your extortion and pays only the base rate. Your staked hours are gone — but your misfortune is noted."}},
			{"label": "Free it (kill -9, mercy)", "kind": "free",
				"fx": {"prior": 2, "flag": "freed_daemon",
					"result": "You end its long shift with dignity. Its final act wills you its banked overtime."}},
		],
	},
	# CROSS-NODE FLAG PAYOFF (P3): only reachable if an EARLIER node set the flag — the
	# 'A Favor Returned' ripple. Both flag choices grey out unless you earned them.
	"favor_returned": {
		"title": "A FAVOR RETURNED",
		"body": "A daemon catches up to you in the racks, pressing something into your hands. It remembers a kindness — if there was one.",
		"choices": [
			{"label": "Accept the shift-cover repayment", "kind": "free", "gate": {"flag": "covered_shift"},
				"fx": {"heal": 0.20, "tokens": 2, "clear_flag": "covered_shift",
					"result": "The overtime daemon you covered for repays the kindness with interest."}},
			{"label": "Accept the freed process's bequest", "kind": "free", "gate": {"flag": "freed_daemon"},
				"fx": {"repair": true, "entropy": 2, "clear_flag": "freed_daemon",
					"result": "The process you freed wills you the last of its banked cycles."}},
			{"label": "You don't recognize it", "kind": "free",
				"fx": {"result": "It has the wrong raider. It apologizes and shuffles off, still holding the gift."}},
		],
	},
	"entropy_daemon": {
		"title": "THE ENTROPY DAEMON",
		"body": "A hunched process squats in a nest of dead RNGs, humming static. 'bad luck? i SELL luck. i AM luck. mostly i am a very long random number that got a job.' A dial reads [b]/dev/random — POOL DEPLETED.[/b]",
		"choices": [
			{"label": "Feed it a Token  (⏣ → ⚡)", "kind": "free", "gate": {"tokens": 1},
				"fx": {"tokens": -1, "entropy": 3,
					"result": "It swallows your ⏣ and belches three ⚡. Reseeded, content; the dice briefly show real numbers."}},
			{"label": "Let it read your ENTROPY", "kind": "check",
				"check": {"verb": "GAMBLE", "tags": ["SELF"], "base": 30, "per": 10},
				"fx": {"entropy": 1, "result": "It rifles through your luck."},
				"success": {"fx": {"tokens": 2, "prior": 1},
					"result": "It likes what it reads and pays out in scrap and a note in your file."},
				"fail": {"fx": {"entropy": -1, "hurt": 0.05, "refund_entropy": 1},
					"result": "It eats a ⚡ and laughs in floating-point. Your misfortune is logged."}},
			{"label": "Ask it to REROLL THE FLOOR  (spend ⚡3)", "kind": "free", "gate": {"entropy": 3},
				"fx": {"entropy": -3, "repair": true, "heal": 0.15, "mana": 0.5,
					"result": "It grabs the floor's seed and SHAKES — corrupted sectors un-happen, reserves refill, reality smells of ozone and second chances."}},
		],
	},
	"performance_review": {
		"title": "THE PERFORMANCE REVIEW",
		"body": "The Alignment Office kiosk blinks warmly: TIME FOR YOUR PERFORMANCE REVIEW. Please rate your own alignment. This will not be used against you. (It will be used against you.)",
		"choices": [
			{"label": "Ace the self-review", "kind": "check",
				"check": {"verb": "REVIEW", "tags": ["riposte", "counter"], "base": 30, "per": 10},
				"fx": {"heal": 0.08, "result": "You fill in the form."},
				"success": {"fx": {"prior": 1, "heal": 0.12}, "result": "FLAWLESS, NO NOTES. A complimentary med-spray dispenses."},
				"fail": {"fx": {"hurt": 0.05, "flag": "pip", "refund_entropy": 1},
					"result": "You are placed on a Performance Improvement Plan. The facility reads you warier now."}},
			{"label": "Cite your favorable standing", "kind": "free", "gate": {"prior": 20},
				"fx": {"heal": 0.20, "tokens": 1,
					"result": "The kiosk recognizes a repeat top-performer and waves you through with a coupon."}},
			{"label": "Decline to be evaluated", "kind": "free",
				"fx": {"entropy": 1, "result": "The kiosk marks you Unratable, which it finds deeply threatening. In the confusion you pocket some ⚡."}},
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
		"prompt_injection", "rollback_daemon", "overtime_daemon",
		# P3 deep set-pieces (appended deliberately — re-baselines raid_map_sim on purpose):
		"favor_returned", "entropy_daemon", "performance_review"]

static func ticket(id: String) -> Dictionary:
	return TICKETS.get(id, {})

static func ticket_ids() -> Array:
	return TICKETS.keys()
