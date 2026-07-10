## Draft — the shared Draft 2.0 engine (game layer). ONE roll implementation for all
## five classes: a synergy slot (offer 1 of 3 always connects to your build), rarity as
## FREQUENCY (Haiku / Sonnet / Opus — never a cap, never a lockout) with opus pity, and
## the Token economy (skilled play mints Tokens from state.diag at fight end; spent here
## as REROLL / UPSELL). Every roll consumes run.draft_rng (DetRng) and nothing else, so
## a run's drafts replay exactly from (run_seed, picks made, tokens spent).
## Per-class catalogues (<Class>Boons) hold the data + apply(); this file holds the rules.
class_name Draft
extends RefCounted

const RARITIES := ["haiku", "sonnet", "opus"]
const WEIGHTS := {"haiku": 0.70, "sonnet": 0.25, "opus": 0.05}
const OPUS_PITY_STEP := 0.05      ## +5pp effective opus weight per opus-less draft
const OPUS_PITY_HARD := 5         ## the draft after this many opus-less ones forces an opus offer
const UPSELL_COST := 2
## REROLL_COST + LOCK_COST retired (§11 #3, rerolls-out): the reroll spends a banked
## REGENERATE charge (run.regenerate), not a Token; LOCK is gone entirely.
## The class-signature skill counter each kit bumps into diag (see Draft.mint).
const SIG_KEY := {"bulwark": "negate", "twinfang": "perfect_strike",
	"bloomweaver": "perfect_ward",
	"alchemist": "pour_potent", "well": "well_pour"}

static func catalog(run) -> Variant:
	match String(run.char_class):
		"bulwark": return BulwarkBoons
		"twinfang": return TwinfangBoons
		"bloomweaver": return BloomweaverBoons
		"alchemist": return AlchemistBoons
		"well": return WellBoons
	return null

static func rarity(b: Dictionary) -> String:
	return String(b.get("rarity", "haiku"))

# ---------------------------------------------------------------- offerability
## Generic offer gate — covers every per-class variant: spells need a free bar slot
## (cap 5) and no exclusive twin already slotted; `req` needs its ability on the bar;
## non-spells can't already be owned.
static func _ok(b: Dictionary, run) -> bool:
	# CREED-AWARE OFFERS (ALCHEMIST verdict 6): a card tagged hide_creeds is never offered to
	# a run running one of those creeds (the Purist never sees Rupture cards). Byte-identical
	# for untagged cards and for runs whose creed isn't listed (every non-Alchemist run today).
	if b.has("hide_creeds") and String(run.creed) in (b["hide_creeds"] as Array):
		return false
	if String(b.get("type", "")) == "spell":
		if run.loadout.size() >= 5 or (b["id"] in run.loadout):
			return false
		return not (String(b.get("excl", "")) in run.loadout)
	if b.has("req") and not (b["req"] in run.loadout):
		return false
	return not run.boons.has(b["id"])

## Aspect pool first, then shared — deduped by id (deterministic const-array order).
## A class with no boon catalog yet (the Alchemist base build) offers nothing —
## every caller already handles an empty roll (the draft is skipped).
static func offerable(run) -> Array:
	var cat = catalog(run)
	if cat == null:
		return []
	var seen := {}
	var out: Array = []
	# D0 S4 · a held TRANSFORM gates its 2 sub-boons (doors) into later offers (Twinfang only).
	# D0 S3 · an ARMED DUO (>=2 cards from each of its two themes) enters the offers too.
	var pool: Array = cat.spec_pool(run.aspect) + cat.SHARED
	if String(run.char_class) == "twinfang":
		if String(run.transform) != "":
			pool += TwinfangBoons.doors_for(String(run.transform))
		pool += TwinfangBoons.armed_duos(run)
	for b in pool:
		if seen.has(b["id"]):
			continue
		seen[b["id"]] = true
		if _ok(b, run):
			out.append(b)
	return out

# ---------------------------------------------------------------- synergy
## The build's tag set: bar ability ids + owned boon ids + the aspect + the aspect's
## mechanic vocabulary. One flat namespace — a collision MEANS overlap.
static func build_tags(run) -> Dictionary:
	var t := {}
	for id in run.loadout:
		t[String(id)] = true
	for id in run.boons.keys():
		t[String(id)] = true
	t[String(run.aspect)] = true
	var cat = catalog(run)
	if cat != null:
		for tag in cat.aspect_tags(run.aspect):
			t[String(tag)] = true
	return t

static func matches(b: Dictionary, run) -> bool:
	return _matches_tags(b, build_tags(run))

## Does boon `b` share a tag with the pre-built tag set `bt`? Hoist `build_tags(run)`
## once per roll and call this in loops instead of matches() (which rebuilds it each call).
static func _matches_tags(b: Dictionary, bt: Dictionary) -> bool:
	for tag in b.get("tags", []):
		if bt.has(String(tag)):
			return true
	return false

# ---------------------------------------------------------------- the roll
## 3 offers. Slot 0 is the SYNERGY slot (guaranteed tag-match when any offerable boon
## matches). Rarity is rolled per slot at WEIGHTS (opus weight ramps with pity), then
## the pick is uniform inside that tier — falling through to neighbouring tiers when
## the rolled tier has no candidate. Hard pity: after OPUS_PITY_HARD opus-less drafts,
## slot 2 draws opus-only. Pity resets when an opus is OFFERED (not taken) and only
## counts drafts where an opus was actually offerable.
## `extra` = extra non-synergy slots (CURIO: Expansion Bus grants +1 → a 1-of-4 draft).
static func roll_offers(run, extra: int = 0) -> Array:
	var avail := offerable(run)
	if avail.is_empty():
		return []
	var offers: Array = []
	var syn: Array = []
	var bt := build_tags(run)                # once per roll, not once per candidate
	for b in avail:
		if _matches_tags(b, bt):
			syn.append(b)
	if syn.is_empty():
		syn = avail
	offers.append(_draw(run, syn))
	for slot in range(1, 3 + maxi(0, extra)):
		var rest: Array = []
		for b in avail:
			if not _in_offers(offers, b):
				rest.append(b)
		if rest.is_empty():
			break
		if slot == 2 and run.pity_opus >= OPUS_PITY_HARD and not _has_opus(offers):
			var forced := _of_tier(rest, "opus")
			if not forced.is_empty():
				rest = forced
		offers.append(_draw(run, rest))
	if _has_opus(offers):
		run.pity_opus = 0
	elif not _of_tier(avail, "opus").is_empty():
		run.pity_opus += 1
	return offers

## Spend ONE banked REGENERATE charge to redraw the whole offer row (rerolls-out §11 #3
## — the 1⏣ reroll + per-card LOCK are gone; the synergy guarantee holds again on the new
## row). No charge ⇒ no reroll (returns [] unchanged). Consumes `run.draft_rng` exactly as
## before, so a spent-charge redraw is the same rng draw the old token reroll produced.
static func reroll(run) -> Array:
	if run.regenerate <= 0:
		return []
	run.regenerate -= 1
	return roll_offers(run)

## Can slot i be transmuted into a strictly higher tier?
static func can_upsell(run, offers: Array, i: int) -> bool:
	if i < 0 or i >= offers.size() or run.tokens < UPSELL_COST:
		return false
	return not _higher(run, offers, i).is_empty()

## Pay 2 Tokens: slot i becomes a random offerable boon of a strictly higher tier
## (sonnet-vs-opus weighted when both exist). Returns the new offer row.
static func upsell(run, offers: Array, i: int) -> Array:
	if not can_upsell(run, offers, i):
		return offers
	run.tokens -= UPSELL_COST
	var cand := _higher(run, offers, i)
	var sonnets := _of_tier(cand, "sonnet")
	var opuses := _of_tier(cand, "opus")
	var pool: Array = cand
	if not sonnets.is_empty() and not opuses.is_empty():
		var w_o := float(WEIGHTS["opus"]) + OPUS_PITY_STEP * float(run.pity_opus)
		var x: float = run.draft_rng.next_float() * (float(WEIGHTS["sonnet"]) + w_o)
		pool = opuses if x < w_o else sonnets
	var nb: Dictionary = pool[run.draft_rng.next_u32() % pool.size()]
	if rarity(nb) == "opus":
		run.pity_opus = 0                     # the chase item made it onto the table
	var out := offers.duplicate()
	out[i] = nb
	return out

static func take(run, b: Dictionary) -> void:
	catalog(run).apply(b, run)

# ---------------------------------------------------------------- token mint
## Called by the HUD at fight end (state.over): deterministic Tokens from state.diag —
## footwork (PERFECT dodges + held feints) + the class-signature verb (SIG_KEY), plus a
## flawless bonus for a sheet with no miss/bait/whiff. Rates live on TuningConfig.
## Reads the is_player mirror `state.diag` — kept BYTE-IDENTICAL (delegates to mint_diag),
## so solo play + draft_sim are unchanged.
static func mint(state, char_class: String) -> int:
	return mint_diag(state.diag, state.config, char_class)

## PER-SEAT MINT (V#11): the same formula off ANY seat's own diag + the run's config.
## The raid credits each of the 4 seats' wallets from its own `seat.diag` (combat_core
## tracks grades per seat), so a clean AI raider mints its own ⏣ — nobody shares a pot.
static func mint_diag(d: Dictionary, cfg, char_class: String) -> int:
	var t := int(d.get("perfect", 0) + d.get("read", 0)) / maxi(1, cfg.mint_per_grades)
	t += int(d.get(String(SIG_KEY.get(char_class, "")), 0)) / maxi(1, cfg.mint_per_signature)
	if int(d.get("miss", 0)) == 0 and int(d.get("baited", 0)) == 0 and int(d.get("whiff", 0)) == 0:
		t += cfg.mint_flawless_bonus
	return mini(t, cfg.mint_cap)

# ---------------------------------------------------------------- internals
## One offer: tier roll (opus weight ramps with pity) -> uniform pick in that tier,
## falling through to the nearest non-empty tier. Always exactly two rng draws.
static func _draw(run, cand: Array) -> Dictionary:
	var w_o := float(WEIGHTS["opus"]) + OPUS_PITY_STEP * float(run.pity_opus)
	var w_s := float(WEIGHTS["sonnet"])
	var w_h := float(WEIGHTS["haiku"])
	var x: float = run.draft_rng.next_float() * (w_h + w_s + w_o)
	var order: Array
	if x < w_o:
		order = ["opus", "sonnet", "haiku"]
	elif x < w_o + w_s:
		order = ["sonnet", "haiku", "opus"]
	else:
		order = ["haiku", "sonnet", "opus"]
	var pool: Array = []
	for tier in order:
		pool = _of_tier(cand, tier)
		if not pool.is_empty():
			break
	return pool[run.draft_rng.next_u32() % pool.size()]

static func _of_tier(list: Array, tier: String) -> Array:
	var out: Array = []
	for b in list:
		if rarity(b) == tier:
			out.append(b)
	return out

static func _in_offers(offers: Array, b: Dictionary) -> bool:
	for o in offers:
		if o != null and o["id"] == b["id"]:   # null-tolerant (defensive; callers pass full rows)
			return true
	return false

static func _has_opus(offers: Array) -> bool:
	for o in offers:
		if o != null and rarity(o) == "opus":
			return true
	return false

## Offerable boons of a strictly higher tier than slot i, excluding anything already
## on the table.
static func _higher(run, offers: Array, i: int) -> Array:
	var cur := RARITIES.find(rarity(offers[i]))
	var out: Array = []
	for b in offerable(run):
		if RARITIES.find(rarity(b)) > cur and not _in_offers(offers, b):
			out.append(b)
	return out
