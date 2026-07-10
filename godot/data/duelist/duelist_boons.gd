## DuelistBoons — THE DUELIST's draft pool (TANK-PLAN §3 + §9.1 v1.1 reconcile + §10 ability pass).
## Grouped by dial-lane; mirrors the WellBoons / TwinfangBoons static API (spec_pool / aspect_tags /
## apply / verb_summary) so the shared Draft engine + REFORGE screen stay class-agnostic. One aspect
## (duelist) → one pool. Effects live GUARDED in DuelistKit keyed by id (_b) — no boon = byte-identical.
## RARITY = fixed offer frequency (Haiku common / Sonnet rare / Opus legendary). Numbers on
## DuelistConfig; first-cut, playtest tunes. KEYSTONES (elite-only, run 1) + TRANSFORMS/DOORS
## (Floor-2 ceremony + door-gated, §10) are separate arrays offered by their own mechanisms.
class_name DuelistBoons
extends RefCounted

## The regular draftable pool — the 4 dial-lanes + THE GAZE (aggro insurance) + the EASE dial + the
## support boon. CARRY = verbatim on the Warden later (§3 carries).
const POOL := [
	# --- LANE: THE SWING (the parry / counter) ---
	{"id": "heavierSteel", "type": "upgrade", "rarity": "haiku", "tags": ["swing"], "ctype": "POWER", "title": "Heavier Steel",
		"desc": "Your counter hits +30% harder — the perfect-parry payoff scales up."},
	{"id": "highLine", "type": "upgrade", "rarity": "sonnet", "tags": ["swing", "tall"], "ctype": "STRAT", "title": "High Line",
		"desc": "Landing a PARRY on a TALL bar banks ◆◆, refunds +1 wind, and the counter runs ×1.5 vs tall. Reward the hardest reads."},
	{"id": "overreach", "type": "upgrade", "rarity": "sonnet", "tags": ["swing", "bleed"], "ctype": "GREED", "title": "Overreach",
		"desc": "You can PARRY while WINDED — it costs 7% max-HP in blood instead of wind (never below 10% HP). A blood-parry that LANDS banks ◆◆ (feeds the Crucible)."},
	# --- LANE: THE STEP (the dodge / footwork) ---
	{"id": "featherStep", "type": "upgrade", "rarity": "haiku", "tags": ["step"], "ctype": "POWER", "title": "Feather Step", "carry": true,
		"desc": "DODGE costs 35% less wind (floor 0.5). The footwork gets cheap — weave forever. (CARRY.)"},
	{"id": "perfectForm", "type": "upgrade", "rarity": "sonnet", "tags": ["step"], "ctype": "STRAT", "title": "Perfect Form",
		"desc": "A PERFECT dodge refunds its wind, and your next PARRY within 2s costs −1.5 wind — the step-into-swing chain."},
	{"id": "readTheRoom", "type": "upgrade", "rarity": "sonnet", "tags": ["step", "read"], "ctype": "STRAT", "title": "Read the Room",
		"desc": "Correctly READING a feint pays +1 wind and your next counter +12%. The patience reward."},
	# --- LANE: THE BANK (◆ income) ---
	{"id": "deepPockets", "type": "upgrade", "rarity": "haiku", "tags": ["bank"], "ctype": "POWER", "title": "Deep Pockets", "carry": true,
		"desc": "The ◆ cap is +1 and you start each fight with 1◆ banked. Room to hoard. (CARRY.)"},
	{"id": "theRally", "type": "upgrade", "rarity": "sonnet", "tags": ["bank", "chain"], "ctype": "GREED", "title": "The Rally",
		"desc": "Every 3rd LAND in an unbroken chain banks DOUBLE ◆. A miss/graze breaks the chain; dodges don't. Keep the streak clean."},
	{"id": "bloodPrice", "type": "upgrade", "rarity": "sonnet", "tags": ["bank", "bleed"], "ctype": "STRAT", "title": "Blood Price",
		"desc": "EATING an unavoidable pays: bank ◆ + refund +2 wind. The bleed isn't pure loss."},
	# --- LANE: THE SPEND (the ⚡ DUMP) ---
	{"id": "powderKeg", "type": "upgrade", "rarity": "haiku", "tags": ["spend"], "ctype": "POWER", "title": "Powder Keg", "carry": true,
		"desc": "⚡ DUMP hits +30% per ◆ — the bank pays out bigger. (CARRY.)"},
	{"id": "allIn", "type": "upgrade", "rarity": "sonnet", "tags": ["spend"], "ctype": "GREED", "title": "All In",
		"desc": "A FULL-BANK dump hits ×1.4 — but at full bank you take +10% until you spend. Hold the whole hand or don't."},
	# --- LANE: THE GAZE (aggro insurance — the taunt-shaped boons, BOSS-PLAN §1's other half) ---
	{"id": "lodestone", "type": "relic", "rarity": "sonnet", "tags": ["gaze", "flow"], "ctype": "STRAT", "title": "Lodestone",
		"desc": "Your flow decays 40% slower — the boss's attention lingers on you between answers. Aggro insurance, the passive way."},
	{"id": "hardStare", "type": "relic", "rarity": "opus", "tags": ["gaze", "flow"], "ctype": "EASE", "title": "Hard Stare",
		"desc": "SIGNATURE: when your flow drops below the lock floor, your next PERFECT answer SPIKES it back above — a clutch re-grab, once per few seconds. The clean-play way back."},
	# --- THE EASE DIAL (the one EASE card — knobs rolled at draft, DECK-LAYOUT §4) ---
	{"id": "easeDial", "type": "upgrade", "rarity": "haiku", "tags": ["ease"], "ctype": "EASE", "title": "The Ease Dial",
		"desc": "Softens the read: a wider PERFECT window, more grace on dodge grades, and faster wind regen. The one difficulty knob — turn it as far as you need."},
	# --- SUPPORT (TEAM — keyed to FLOW uptime, §9.1) ---
	{"id": "holdTheLine", "type": "relic", "rarity": "opus", "tags": ["support", "flow"], "ctype": "TEAM", "title": "Hold the Line",
		"desc": "SUPPORT: while THE LINE HOLDS (flow stays above the lock floor), the whole warband deals +8% damage. Holding aggro IS the raid buff — no extra button."},
]

## KEYSTONES — elite-only spectacle, ≤1/run (§3). Offered at elite nodes, not the regular pool.
const KEYSTONES := [
	{"id": "ksAvalanche", "type": "keystone", "rarity": "opus", "tags": ["spend"], "ctype": "POWER", "title": "The Avalanche",
		"desc": "👑 DUMP becomes a returning string — each ◆ is a bar sailing BACK across the gate; press as it crosses for ×2. The offense on the same instrument, reversed."},
	{"id": "ksBorrowedTime", "type": "keystone", "rarity": "opus", "tags": ["step"], "ctype": "STRAT", "title": "Borrowed Time",
		"desc": "👑 A full-speed LAND slows the incoming stream 1.5s (the bars crawl). Slowed-time lands don't refresh it — no perma-slow."},
	{"id": "ksImpossibleParry", "type": "keystone", "rarity": "opus", "tags": ["swing", "bleed"], "ctype": "GREED", "title": "The Impossible Parry",
		"desc": "👑 Unavoidables grow a gold sliver: a PERFECT parry at DOUBLE wind cost parries them — land = counter ×2 + ◆◆; miss = eat the hit + the swing. Makes eating a choice."},
]

## TRANSFORMS (§10.3) — REWRITE one button, ≤1/run, offered 1-of-3 at the Floor-2 ceremony.
## Each is a DOOR: taking it gates its 2 sub-boons into later offers + adds one rig WHEN.
const TRANSFORMS := [
	{"id": "prisedefer", "type": "transform", "target": "parry", "rarity": "opus", "tags": ["swing"], "ctype": "STRAT", "title": "Prise de Fer",
		"desc": "PARRY transform — \"take the blade.\" A PERFECT parry SEIZES the bar (hold ≤1.2s, wind draining); release THROWS it back, scaling with the bar's power + hold length (cap ≈ counter ×1.5). The instant jackpot becomes a hold/release read. Affinity: IRONSIDE."},
	{"id": "remise", "type": "transform", "target": "parry", "rarity": "opus", "tags": ["step"], "ctype": "STRAT", "title": "Remise",
		"desc": "PARRY transform — \"the renewed attack.\" Parry becomes two half-presses: PRIME (early, ~1/3 wind — a primed-then-missed bar leaks 30% less) + COMMIT (in-window, the rest — full parry + counter). Prime the unsure bar, commit only on the real one. Affinity: GHOST."},
	{"id": "fleche", "type": "transform", "target": "dump", "rarity": "opus", "tags": ["spend"], "ctype": "GREED", "title": "Flèche",
		"desc": "DUMP transform — \"the running attack.\" DUMP LOADS the bank onto your blade (~2.5s); your next PERFECT answer releases it as the charging strike (full dump +25%). Nothing perfect before it expires → half the ◆ back, the rest fizzles. Affinity: HEADSMAN."},
]

## DOORS — the transform sub-boons (§10.3), offer-gated on holding their transform.
const DOORS := [
	{"id": "doorDisarm", "type": "upgrade", "door": "prisedefer", "rarity": "sonnet", "tags": ["swing"], "ctype": "STRAT", "title": "Disarm",
		"desc": "A full-length SEIZE downgrades the boss's next bar one size (tall→normal, normal→small)."},
	{"id": "doorWrenchedSteel", "type": "upgrade", "door": "prisedefer", "rarity": "sonnet", "tags": ["swing"], "ctype": "GREED", "title": "Wrenched Steel",
		"desc": "A seize drains wind ×2, but the THROW hits +40% (cap stated)."},
	{"id": "doorSecondIntention", "type": "upgrade", "door": "remise", "rarity": "sonnet", "tags": ["bank"], "ctype": "STRAT", "title": "Second Intention",
		"desc": "A committed remise (both presses landed) banks +1◆ — the planned second attack pays."},
	{"id": "doorBeatParry", "type": "upgrade", "door": "remise", "rarity": "sonnet", "tags": ["swing"], "ctype": "POWER", "title": "Beat Parry",
		"desc": "The PRIME alone deflects harder — a primed-then-missed bar leaks −45% (from −30%)."},
	{"id": "doorRunningEdge", "type": "upgrade", "door": "fleche", "rarity": "sonnet", "tags": ["spend"], "ctype": "POWER", "title": "Running Edge",
		"desc": "Flèche damage +30% (cap stated)."},
	{"id": "doorPointInLine", "type": "upgrade", "door": "fleche", "rarity": "sonnet", "tags": ["spend"], "ctype": "STRAT", "title": "Point in Line",
		"desc": "A flèche released on a TALL-bar land staggers the stream half a beat — a breath you earned."},
]

## The Duelist has ONE aspect, so everything lives in POOL (spec_pool) — SHARED is empty (the
## Draft engine reads both `cat.SHARED` and `cat.spec_pool(aspect)` and offers their union).
const SHARED := []

static func spec_pool(_aspect: String) -> Array:
	return POOL

static func aspect_tags(_aspect: String) -> Array:
	return ["swing", "step", "bank", "spend", "gaze", "flow", "bleed", "support", "tall", "read"]

## Apply a chosen boon/keystone/transform/door to the run (all just flag the id — the kit's
## _b()/observe read it; transforms/keystones are single-select gated by their offer mechanism).
static func apply(b: Dictionary, run) -> void:
	run.boons[b["id"]] = true

static func verb_summary(_boons: Dictionary, _aspect: String) -> Array:
	return []

## The Floor-2 transform offer, honoring the DANCER law (§10.4): a Dancer run (parry GONE)
## EXCLUDES the two PARRY transforms — flèche + a re-offer, never a dead card.
static func transform_offer(creed_id: String) -> Array:
	if creed_id == "dancer":
		return TRANSFORMS.filter(func(t): return String(t.get("target", "")) != "parry")
	return TRANSFORMS.duplicate()

## The sub-boons a held transform unlocks into later offers.
static func doors_for(transform_id: String) -> Array:
	return DOORS.filter(func(d): return String(d.get("door", "")) == transform_id)
