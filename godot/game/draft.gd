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
const REROLL_COST := 1
const UPSELL_COST := 2
const LOCK_COST := 1
## The class-signature skill counter each kit bumps into diag (see Draft.mint).
const SIG_KEY := {"bulwark": "negate", "twinfang": "perfect_strike",
	"voidcaller": "clean_kick", "mender": "dispel", "bloomweaver": "perfect_ward",
	"alchemist": "pour_potent"}

static func catalog(run) -> Variant:
	match String(run.char_class):
		"bulwark": return BulwarkBoons
		"twinfang": return TwinfangBoons
		"voidcaller": return VoidcallerBoons
		"mender": return MenderBoons
		"bloomweaver": return BloomweaverBoons
		"alchemist": return AlchemistBoons
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
	for b in cat.spec_pool(run.aspect) + cat.SHARED:
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

## Pay 1 Token, redraw the whole offer row (same rules, synergy guarantee holds again).
## CURIO Hot Reload: `free` skips the Token cost/gate entirely.
static func reroll(run, free: bool = false) -> Array:
	if not free:
		if run.tokens < REROLL_COST:
			return []
		run.tokens -= REROLL_COST
	return roll_offers(run)

## Pay LOCK_COST to hold a card through rerolls. Pure economy — consumes no rng.
static func lock(run) -> bool:
	if run.tokens < LOCK_COST:
		return false
	run.tokens -= LOCK_COST
	return true

## Pay REROLL_COST, keep the LOCKED offer indices verbatim, redraw only the rest
## (a locked id can't reappear in a redrawn slot). Empty `locked` delegates to the
## classic reroll — the rng draw sequence of lock-free runs is untouched. The synergy
## filter applies to slot 0 only when slot 0 itself is redrawn; the opus pity RAMP
## still applies to redrawn slots (the hard slot-2 force is a roll_offers-only rule).
static func reroll_kept(run, offers: Array, locked: Array, free: bool = false) -> Array:
	if locked.is_empty():
		return reroll(run, free)
	if not free:
		if run.tokens < REROLL_COST:
			return []
		run.tokens -= REROLL_COST
	var avail := offerable(run)
	var bt := build_tags(run)                # once, reused by the synergy-slot filter below
	var out: Array = []
	for i in offers.size():
		out.append(offers[i] if i in locked else null)
	for i in offers.size():
		if out[i] != null:
			continue
		var rest: Array = []
		for b in avail:
			if not _in_offers(out, b):
				rest.append(b)
		if rest.is_empty():
			out[i] = offers[i]              # pool exhausted — the old card stands
			continue
		if i == 0:
			var syn: Array = []
			for b in rest:
				if _matches_tags(b, bt):
					syn.append(b)
			if not syn.is_empty():
				rest = syn
		out[i] = _draw(run, rest)
	if _has_opus(out):
		run.pity_opus = 0
	elif not _of_tier(avail, "opus").is_empty():
		run.pity_opus += 1
	return out

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
static func mint(state, char_class: String) -> int:
	var cfg = state.config
	var d: Dictionary = state.diag
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
		if o != null and o["id"] == b["id"]:   # null-tolerant: reroll_kept builds sparse rows
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
