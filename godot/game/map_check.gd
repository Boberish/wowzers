## MapCheck — THE INFERENCE CHECK. The pure, Node-free resolver that turns a build
## into a success %, the Across-the-Obelisk "cards of Fire" mechanic adapted to Rift:
## a check names boon TAGS and counts how many of your boons carry them, then leans the
## odds by your aspect + trinity role, comeback pity, and any ⚡ LUCK you feed it.
## (The retired integrity term and the cross-run 📁 Prior floor are both gone — DESCENT
## §9/§11.) Everything is integer %, computed in one fixed, documented order, and
## printed as an itemized breakdown BEFORE you commit.
##
## The die is a FRESH throwaway DetRng seeded from (map_seed, node, choice, attempt) —
## a pure function every machine (client, server, sim) computes identically, so co-op
## needs zero new sync and every headless run replays it. It never touches map-gen rng,
## combat state.rng, or the draft stream.
##
## Kept pure & testable: chance()/gate_ok()/resolve() read a plain `ctx` dict of already-
## resolved ingredients (build_ctx). The HUD/server build the ctx from live state; the
## sim feeds synthetic builds. No RunState/Node dependency lives here.
class_name MapCheck
extends RefCounted

const DEF_BASE := 25
const DEF_PER := 12
const DEF_CAP := 5
const DEF_ASPECT_BONUS := 15
const DEF_ROLE_BONUS := 15
const DEF_FLOOR := 5
const DEF_CEIL := 95
const PITY_PER := 8              ## +% per consecutive prior fail …
const PITY_CAP := 32            ## … capped
const NUDGE_PER := 8             ## +% per ⚡ fed pre-commit …
const NUDGE_MAX := 3            ## … up to this many points
const MULLIGAN_COST := 2        ## ⚡ per post-fail reroll (attempt+1 → a new deterministic die)
const MULLIGAN_MAX := 3         ## most rerolls a single check allows
const START_ENTROPY := 2        ## ⚡ every descent opens with — V#8: NOTHING carries across
                                ## runs (the old 📁 Prior file is deleted; fresh stays fresh)

# ---------------------------------------------------------------- context
## A pure bag of resolved ingredients. `boon_tags`/`gear_tags` are Arrays of tag-arrays
## (one entry per owned boon / equipped curio) — so a boon is counted ONCE even if it
## carries two of a check's tags, and SELF checks can read the largest single-tag cluster.
static func build_ctx(boon_tags: Array, gear_tags: Array, aspect: String, role: String,
		party_frac: float, entropy: int, check_fails: int,
		inv: Dictionary, flags: Dictionary, tokens: int) -> Dictionary:
	return {
		"boon_tags": boon_tags, "gear_tags": gear_tags, "aspect": aspect, "role": role,
		"party_frac": party_frac, "entropy": entropy,
		"check_fails": check_fails, "inv": inv, "flags": flags, "tokens": tokens,
	}

## The class boon module by class name (the server holds seats, not RunStates, so it
## can't use Draft.catalog(run)). Mirrors Draft.catalog's mapping.
static func catalog_for(cls: String) -> Variant:
	match cls:
		"twinfang": return TwinfangBoons
		"bloomweaver": return BloomweaverBoons
	return null

## Resolve a run's owned boon ids into their tag-arrays via the class boon module
## (Draft.catalog(run)). `cat` exposes SHARED + spec_pool(aspect). Kept here (duck-typed)
## so both the HUD and the online server share one id→tags path.
static func tags_for_boons(cat: Variant, aspect: String, boons: Dictionary) -> Array:
	if cat == null:
		return []
	var id2tags := {}
	for b in cat.spec_pool(aspect) + cat.SHARED:
		id2tags[String(b["id"])] = b.get("tags", [])
	var out: Array = []
	for id in boons.keys():
		if id2tags.has(String(id)):
			out.append(id2tags[String(id)])
	return out

# ---------------------------------------------------------------- the math
## A check and a wager both roll a build-read die (a wager just adds a fixed stake).
static func check_like(kind: String) -> bool:
	return kind == "check" or kind == "wager"

## strength = how many owned boons+gear match the check's tags (each counted once).
## SELF = the largest single-tag cluster (build coherence — the early-run valve).
static func strength(chk: Dictionary, ctx: Dictionary) -> int:
	var tags: Array = chk.get("tags", [])
	if tags.size() == 1 and String(tags[0]) == "SELF":
		var hist := {}
		for src in [ctx.get("boon_tags", []), ctx.get("gear_tags", [])]:
			for tl in src:
				for t in tl:
					hist[String(t)] = int(hist.get(String(t), 0)) + 1
		var mx := 0
		for k in hist:
			mx = maxi(mx, int(hist[k]))
		return mx
	var want := {}
	for t in tags:
		want[String(t)] = true
	var n := 0
	for src in [ctx.get("boon_tags", []), ctx.get("gear_tags", [])]:
		for tl in src:
			for t in tl:
				if want.has(String(t)):
					n += 1
					break                 # count each boon/curio at most once
	return n

## chance(check, ctx, nudge) -> {p:int, parts:[[label,delta], …], strength:int}.
## `parts` is the itemized breakdown shown to the player (base + each contributing row).
static func chance(chk: Dictionary, ctx: Dictionary, nudge: int = 0) -> Dictionary:
	var parts: Array = []
	var base := int(chk.get("base", DEF_BASE))
	parts.append(["base odds", base])
	var p := base

	var s := strength(chk, ctx)
	var per := int(chk.get("per", DEF_PER))
	var cap := int(chk.get("cap", DEF_CAP))
	var tag_bonus := per * mini(s, cap)
	if tag_bonus != 0:
		parts.append([_tag_label(chk, s), tag_bonus])
		p += tag_bonus

	var aspects: Array = chk.get("aspects", [])
	if not aspects.is_empty() and String(ctx.get("aspect", "")) in aspects:
		var ab := int(chk.get("aspect_bonus", DEF_ASPECT_BONUS))
		parts.append(["%s affinity" % String(ctx["aspect"]), ab])
		p += ab

	var role := String(chk.get("role", ""))
	if role != "" and String(ctx.get("role", "")) == role:
		var rb := int(chk.get("role_bonus", DEF_ROLE_BONUS))
		parts.append(["%s at the terminal" % role, rb])
		p += rb

	# THE RAID INTEGRITY KILL (DESCENT §9/§11 #2): the old "raid integrity"/"desperation"
	# check-row leaned the % off party_frac — the RETIRED integrity carry (a dead number).
	# Dropped. `ctx["party_frac"]` is now unread but stays in build_ctx (removing it ripples
	# to every caller); the check no longer prices in a resource that no longer matters.

	var pity := mini(PITY_CAP, int(ctx.get("check_fails", 0)) * PITY_PER)
	if pity > 0:
		parts.append(["comeback", pity]); p += pity

	var nb := mini(NUDGE_MAX, maxi(0, nudge)) * NUDGE_PER
	if nb > 0:
		parts.append(["⚡ LUCK", nb]); p += nb

	p = clampi(p, int(chk.get("floor", DEF_FLOOR)), int(chk.get("ceil", DEF_CEIL)))
	return {"p": p, "parts": parts, "strength": s}

## Preview the % ladder if you feed 0..NUDGE_MAX Entropy (for the live "→84·92·95" line).
static func nudge_ladder(chk: Dictionary, ctx: Dictionary) -> Array:
	var out: Array = []
	var have := int(ctx.get("entropy", 0))
	for k in range(1, mini(NUDGE_MAX, have) + 1):
		out.append(int(chance(chk, ctx, k)["p"]))
	return out

# ---------------------------------------------------------------- gates
## A gate wraps any kind; unmet ⇒ the choice greys out with a printed reason.
static func gate_ok(gate: Dictionary, ctx: Dictionary) -> bool:
	if gate.is_empty():
		return true
	if gate.has("item"):
		var inv: Dictionary = ctx.get("inv", {})
		match String(gate["item"]):
			"api_key": return bool(inv.get("api_key", false))
			"shards": return int(inv.get("shards", 0)) >= int(gate.get("count", 1))
		return false
	if gate.has("tags"):
		return strength({"tags": gate["tags"]}, ctx) >= int(gate.get("min", 1))
	if gate.has("aspect"):
		return String(ctx.get("aspect", "")) == String(gate["aspect"])
	if gate.has("role"):
		return String(ctx.get("role", "")) == String(gate["role"])
	if gate.has("entropy"):
		return int(ctx.get("entropy", 0)) >= int(gate["entropy"])
	if gate.has("flag"):
		return bool((ctx.get("flags", {}) as Dictionary).has(String(gate["flag"])))
	if gate.has("tokens"):
		return int(ctx.get("tokens", 0)) >= int(gate["tokens"])
	return true

static func gate_reason(gate: Dictionary) -> String:
	if gate.has("item"):
		match String(gate["item"]):
			"api_key": return "Requires an API KEY"
			"shards": return "Requires %d credential shard(s)" % int(gate.get("count", 1))
	if gate.has("tags"):
		return "Requires %d× %s" % [int(gate.get("min", 1)), String((gate["tags"] as Array)[0]).to_upper()]
	if gate.has("aspect"):
		return "Requires the %s aspect" % String(gate["aspect"]).capitalize()
	if gate.has("role"):
		return "Requires the %s at the terminal" % String(gate["role"])
	if gate.has("entropy"):
		return "Requires ⚡%d" % int(gate["entropy"])
	if gate.has("flag"):
		return "Requires an earlier choice"
	if gate.has("tokens"):
		return "Requires ⏣%d" % int(gate["tokens"])
	return ""

# ---------------------------------------------------------------- the die
## A distinct die SLOT per (stage page, choice) so a multi-stage branch's sub-page checks
## never share the root page's die. The ROOT page ("") returns the choice index unchanged,
## so single-stage events (every existing one) keep byte-identical dice. Server + both
## clients compute this identically → no desync across stages.
static func choice_slot(page_id: String, orig: int) -> int:
	if page_id == "":
		return orig
	var h := 2166136261
	for i in page_id.length():
		h = (h ^ page_id.unicode_at(i)) & 0xFFFFFFFF
		h = (h * 16777619) & 0xFFFFFFFF
	return orig + (h % 8000) + 1000        # page-specific offset, clear of small root indices

static func roll_seed(map_seed: int, node_id: int, choice_i: int, attempt: int) -> int:
	var h := map_seed & 0x7FFFFFFF
	h = (h * 1000003 + (node_id + 1) * 6763) & 0x7FFFFFFF
	h = (h * 1000003 + (choice_i + 1) * 7919) & 0x7FFFFFFF
	h = (h * 1000003 + (attempt + 1) * 104729) & 0x7FFFFFFF
	return h

## The roll in [0,100). FIXED per (map_seed,node,choice,attempt) — a mulligan bumps
## `attempt` for a genuinely different but still-deterministic die.
static func roll(map_seed: int, node_id: int, choice_i: int, attempt: int) -> float:
	return DetRng.new(roll_seed(map_seed, node_id, choice_i, attempt)).next_float() * 100.0

## resolve a check/wager choice. Returns everything the panel + applier need.
## `spend` = {"nudge": int} (⚡ fed pre-commit). `attempt` supports mulligan (Phase 2).
static func resolve(choice: Dictionary, ctx: Dictionary, map_seed: int, node_id: int,
		choice_i: int, attempt: int, spend: Dictionary) -> Dictionary:
	var chk: Dictionary = choice.get("check", {})
	var info := chance(chk, ctx, int(spend.get("nudge", 0)))
	var p := int(info["p"])
	var r := roll(map_seed, node_id, choice_i, attempt)
	var success := r < float(p)
	var leg: Dictionary = choice.get("success" if success else "fail", {})
	var fx: Dictionary = (leg.get("fx", {}) as Dictionary).duplicate(true)
	# WAGER: a fixed stake, paid on commit WIN OR LOSE (it IS the risk — the fail leg
	# carries no extra bite per the soft-fail rule). Folded into the result fx.
	var w: Dictionary = choice.get("wager", {})
	if not w.is_empty():
		var amt := float(w.get("amount", 0))
		match String(w.get("stake", "integrity")):
			"integrity": fx["hurt"] = float(fx.get("hurt", 0.0)) + amt
			"tokens": fx["tokens"] = int(fx.get("tokens", 0)) - int(amt)
			"entropy": fx["entropy"] = int(fx.get("entropy", 0)) - int(amt)
	return {
		"kind": String(choice.get("kind", "check")),
		"p": p, "roll": r, "success": success, "parts": info["parts"],
		"strength": int(info["strength"]),
		"fx": fx,
		"goto": String(leg.get("goto", "")),
		"result": String(leg.get("result", ("The check holds." if success else "The check fails."))),
		"verb": String(chk.get("verb", "CHECK")),
	}

# ---------------------------------------------------------------- helpers
static func _tag_label(chk: Dictionary, s: int) -> String:
	var tags: Array = chk.get("tags", [])
	if tags.size() == 1 and String(tags[0]) == "SELF":
		return "build coherence ×%d" % s
	var names: Array = []
	for t in tags:
		names.append(String(t).to_upper())
	return "%s ×%d" % ["/".join(names), s]
