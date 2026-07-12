## DEV · GENERATED SETUPS (dev tooling — Bill 2026-07-12): synthesize the AVERAGE build a
## descent would carry when it reaches a given Seal, from ONE seed. Pick a class/spec (+ an
## optional module ANCHOR, e.g. the Well's ⭐Vigil), pick the Seal, and this replays the
## run's REAL economy in fast-forward:
##   · walks each floor's actual RunMap (the same seed→topology formula _build_floor uses)
##     along a seeded route, tallying what an average path hits
##   · every fight won = one 1-of-3 boon draft through the LIVE Draft engine (synergy slot,
##     rarity weights, opus pity), picked by an "average player" policy — rarity + synergy
##     nudge the choice, they never optimize it (an average build, not a perfect one)
##   · milestones land where the run lands them: creed at descent start · rig at the first
##     draft · module at the Floor-1 elevation · transform + rewire at Floor 2 (Twinfang) ·
##     keystone at the first elite on the route · a curio bought at a market when affordable
##   · AI seats ride Commander parity: boons + keystones only, decorrelated seeds
## Same (class, aspect, anchor, boss, seed) → the identical build, so a setup you like
## replays from its printed seed. Dev-only: nothing live calls this; the fight it feeds is
## a plain single-Seal spec (see raid_hud._launch_dev_gen).
class_name DevSetups
extends RefCounted

const TOKENS_PER_FIGHT := 2     ## the average mint (cap 3, flawless +1 — an average sheet)
const CURIO_BASE_PRICE := 6     ## a haiku curio's base ⏣ (+30%/floor — mirrors _market_price)

## FLOORS index of a Seal id (-1 = not a floor Seal — e.g. a Forge filler).
static func boss_floor(enc_id: String) -> int:
	for i in RaidContent.FLOORS.size():
		if String((RaidContent.FLOORS[i] as Dictionary)["seal"]) == enc_id:
			return i
	return -1

## The generated setup. `party` = the AI seats (seat_key -> {cls, aspect}, the human seat
## absent — raid_hud._d.party's shape). `anchor` = a module id to build around ("" = any).
## Returns {run, ai:{key->RunState}, taken:[boon dicts], gear:[curio ids],
##          fights/elites/markets:int, title/blurb:String, lines:[String], seed/boss_i, …}.
static func generate(cls: String, aspect: String, anchor: String, boss_i: int,
		seed_v: int, party: Dictionary) -> Dictionary:
	boss_i = clampi(boss_i, 0, RaidContent.FLOORS.size() - 1)
	var rng := DetRng.new((seed_v ^ 0xD37A11) & 0x7FFFFFFF)   # walk + pick stream (never state.rng)
	var run: RunState = ClassRegistry.start_run(cls, aspect, seed_v)
	var fw := fw_of(cls)
	if fw != "":
		run.creed = _pick_creed(fw, aspect, anchor, rng)
	# COMMANDER parity: each AI raider gets its own boon run, decorrelated with the same
	# salt _start_map_run uses; they draft boons + keystones only (no creed/module/rig).
	var ai := {}
	for key in RaidNet.SEAT_KEYS:
		if not party.has(key):
			continue
		var e: Dictionary = party[key]
		ai[key] = ClassRegistry.start_run(String(e["cls"]), String(e["aspect"]),
			int((seed_v ^ (0x515EED + RaidNet.SEAT_KEYS.find(key) * 0x9E3779)) & 0x7FFFFFFF))
	var taken: Array = []
	var gear: Array = []
	var tally := {"fights": 0, "elites": 0, "markets": 0}
	for f in range(boss_i + 1):
		var kinds := _walk_floor(f, seed_v, rng)
		if f == boss_i:
			kinds = kinds.slice(0, kinds.size() - 1)   # this floor's Seal IS the fight under test
		for k in kinds:
			match String(k):
				RunMap.KIND_COMBAT, RunMap.KIND_SEAL:
					_fight_won(run, ai, taken, rng)
					tally["fights"] = int(tally["fights"]) + 1
				RunMap.KIND_ELITE:
					_keystones(run, ai, taken, rng)
					_fight_won(run, ai, taken, rng)
					tally["fights"] = int(tally["fights"]) + 1
					tally["elites"] = int(tally["elites"]) + 1
				RunMap.KIND_MARKET:
					_market_stop(run, gear, rng, f)
					tally["markets"] = int(tally["markets"]) + 1
		if f < boss_i:                    # the floor's Seal is down → the elevation ceremony
			if f == 0 and fw != "":
				_pick_module(run, fw, aspect, anchor, rng)
			elif f == 1:
				if cls == "twinfang":
					_pick_transform(run, rng)
				if fw != "":
					_wire_rig(run, fw, aspect, rng)   # the Floor-2 REWIRE
	var out := {
		"seed": seed_v, "boss_i": boss_i, "cls": cls, "aspect": aspect, "anchor": anchor,
		"run": run, "ai": ai, "taken": taken, "gear": gear,
		"fights": int(tally["fights"]), "elites": int(tally["elites"]),
		"markets": int(tally["markets"]),
	}
	_describe(out, fw)
	return out

# ------------------------------------------------------------------ the route walk
## Generate floor f's REAL map (the exact seed→topology formula _build_floor uses) and
## walk one seeded route entry→Seal, returning the effective node kinds in path order.
## Shards are cheated into the inventory so ROOT's gate never dead-ends the tally walk.
static func _walk_floor(f: int, seed_v: int, rng: DetRng) -> Array:
	var fl: Dictionary = RaidContent.FLOORS[f]
	var fights: Array = RaidContent.floor_fights(int(fl["ring"]))
	var map := RunMap.generate(int((seed_v * 1000003 + (f + 1) * 7919 + 1) & 0x7FFFFFFF),
		fights.size(), MapContent.raid_event_ids(),
		{}, int(fl["shard_req"]), int(fl.get("tickets", 0)), int(fl.get("rows", 8)),
		fl.get("quota", {}), String(fl.get("minigame", "")))
	var inv := {"shards": 99}
	var cur := -1
	var kinds: Array = []
	var guard := 0
	while cur != map.seal_id and guard < 64:
		guard += 1
		var opts: Array = map.reachable(cur, inv)
		if opts.is_empty():
			break
		cur = int(opts[rng.next_u32() % opts.size()])
		kinds.append(RunMap.effective_kind(map.node(cur)))
	return kinds

# ------------------------------------------------------------------ the economy replay
## A won fight: the FIRST draft wires the rig (mirrors _show_boon_draft), then one 1-of-3
## boon for the human and each AI raider, and everyone mints an average wallet.
static func _fight_won(run: RunState, ai: Dictionary, taken: Array, rng: DetRng) -> void:
	var fw := fw_of(run.char_class)
	if fw != "" and run.rig.is_empty():
		_wire_rig(run, fw, run.aspect, rng)
	var picks := Draft.roll_offers(run)
	if not picks.is_empty():
		var b := _avg_pick(picks, run, rng)
		Draft.take(run, b)
		taken.append(b)
	run.tokens += TOKENS_PER_FIGHT
	for key in ai:
		var r: RunState = ai[key]
		var ap := Draft.roll_offers(r)
		if not ap.is_empty():
			Draft.take(r, _avg_pick(ap, r, rng))
		r.tokens += TOKENS_PER_FIGHT

## The "average player" pick: rarity and synergy WEIGHT the roll, they never decide it.
static func _avg_pick(offers: Array, run: RunState, rng: DetRng) -> Dictionary:
	var ws: Array = []
	var wsum := 0.0
	for b in offers:
		var w := 1.0
		match Draft.rarity(b):
			"sonnet": w += 0.6
			"opus": w += 1.4
		if Draft.matches(b, run):
			w += 0.8
		ws.append(w)
		wsum += w
	var x := rng.next_float() * wsum
	for i in offers.size():
		x -= float(ws[i])
		if x <= 0.0:
			return offers[i]
	return offers[offers.size() - 1]

## An elite: the keystone 1-of-2, one per run per seat (human, then each AI raider).
static func _keystones(run: RunState, ai: Dictionary, taken: Array, rng: DetRng) -> void:
	var offer := Draft.roll_keystone_offer(run)
	if not offer.is_empty():
		var b: Dictionary = offer[rng.next_u32() % offer.size()]
		Draft.take(run, b)
		taken.append(b)
	for key in ai:
		var r: RunState = ai[key]
		var o := Draft.roll_keystone_offer(r)
		if not o.is_empty():
			Draft.take(r, o[rng.next_u32() % o.size()])

## A market stop: buy ONE curio when the wallet covers it (price mirrors _market_price's
## +30%/floor). Pool = the profile's unlocked curios (disk; headless stays inert → none).
static func _market_stop(run: RunState, gear: Array, rng: DetRng, floor_i: int) -> void:
	var price := int(round(float(CURIO_BASE_PRICE) * (1.0 + 0.30 * float(floor_i))))
	if run.tokens < price:
		return
	var pool := _curio_pool(run.char_class, gear)
	if pool.is_empty():
		return
	run.tokens -= price
	gear.append(String(pool[rng.next_u32() % pool.size()]))

static func _curio_pool(cls: String, gear: Array) -> Array:
	if DisplayServer.get_name() == "headless":
		return []
	var unlocks := GearStore.load_unlocks()
	var seen := {}
	var pool: Array = []
	for boss in unlocks:
		for id in (unlocks[boss] as Array):
			var sid := String(id)
			if seen.has(sid) or gear.has(sid) or not Gear._fits(sid, cls):
				continue
			seen[sid] = true
			pool.append(sid)
	pool.sort()
	return pool

# ------------------------------------------------------------------ the milestones
## Creed at descent start. With an anchor module, creeds that would hide it from the
## Floor-1 board are filtered out first (the Purist never anchors a Rupture module).
static func _pick_creed(fw: String, aspect: String, anchor: String, rng: DetRng) -> String:
	var ids := _creed_ids(fw, aspect)
	if anchor != "":
		var ok: Array = []
		for id in ids:
			if module_offer_ids(fw, String(id), aspect).has(anchor):
				ok.append(id)
		if not ok.is_empty():
			ids = ok
	if ids.is_empty():
		return ""
	return String(ids[rng.next_u32() % ids.size()])

static func _pick_module(run: RunState, fw: String, aspect: String, anchor: String,
		rng: DetRng) -> void:
	var avail := module_offer_ids(fw, run.creed, aspect)
	if avail.is_empty():
		return
	var id := anchor if anchor != "" and avail.has(anchor) \
		else String(avail[rng.next_u32() % avail.size()])
	run.modules[id] = true

static func _pick_transform(run: RunState, rng: DetRng) -> void:
	if TwinfangBoons.TRANSFORMS.is_empty():
		return
	var t: Dictionary = TwinfangBoons.TRANSFORMS[rng.next_u32() % TwinfangBoons.TRANSFORMS.size()]
	run.transform = String(t.get("id", ""))

## Wire (or Floor-2 rewire) the ONE Combo: roll the same 3-of-N boards the wiring screen
## rolls (consuming run.draft_rng exactly like the real board), then pick one of each.
static func _wire_rig(run: RunState, fw: String, aspect: String, rng: DetRng) -> void:
	var offered := _rig_offered(fw, run.creed, aspect, run.draft_rng)
	var whens: Array = offered["whens"]
	var thens: Array = offered["thens"]
	if whens.is_empty() or thens.is_empty():
		return
	run.rig = {"when": String(whens[rng.next_u32() % whens.size()]),
		"then": String(thens[rng.next_u32() % thens.size()])}

# ------------------------------------------------------------------ framework dispatch
## Static mirrors of raid_hud's _fw/_fw_creed_ids/_fw_module_offer_ids/_fw_rig_offered
## (those are instance methods reading HUD seat state; the generator has no HUD).
static func fw_of(cls: String) -> String:
	if cls == "twinfang" or cls == "alchemist" or cls == "well":
		return cls
	return ""    # duelist DECKLESS (TANK-PLAN §0) · bloomweaver pre-framework

static func _creed_ids(fw: String, aspect: String) -> Array:
	if fw == "alchemist":
		return AlchemistCreeds.v1_ids()
	if fw == "well":
		return WellCreeds.v1_ids(aspect)      # per-spec pools (brim vs draw)
	return TwinfangCreeds.v1_ids()

static func creed_data(fw: String, id: String) -> Dictionary:
	if fw == "alchemist":
		return AlchemistCreeds.get_creed(id)
	if fw == "well":
		return WellCreeds.get_creed(id)
	return TwinfangCreeds.get_creed(id)

static func module_offer_ids(fw: String, creed: String, aspect: String) -> Array:
	if fw == "well":
		return WellModules.offer_ids(aspect)   # ⭐The Vigil is Draw-only
	if fw != "alchemist":
		return TwinfangModules.built_ids()
	var out: Array = []
	for id in AlchemistModules.built_ids():
		if creed != "" and AlchemistModules.has_tag(String(id), "rupture") \
				and AlchemistCreeds.hides_tag(creed, "rupture"):
			continue
		out.append(String(id))
	return out

static func module_data(fw: String, id: String) -> Dictionary:
	if fw == "alchemist":
		return AlchemistModules.get_module(id)
	if fw == "well":
		return WellModules.get_module(id)
	return TwinfangModules.get_module(id)

static func _rig_offered(fw: String, creed: String, aspect: String, rng) -> Dictionary:
	if fw == "well":
		var wp: Array = []
		for id in WellRig.when_ids():
			if WellRig.when_spec(String(id)) == aspect:
				wp.append(id)
		return {"whens": WellRig.offer(wp, rng, 3), "thens": WellRig.offer(WellRig.then_ids(), rng, 3)}
	if fw != "alchemist":
		return {"whens": TwinfangRig.offer(TwinfangRig.when_ids(), rng, 3),
			"thens": TwinfangRig.offer(TwinfangRig.then_ids(), rng, 3)}
	var wpool: Array = []
	for id in AlchemistRig.when_ids():
		if creed != "" and AlchemistRig.when_has_tag(String(id), "rupture") \
				and AlchemistCreeds.hides_tag(creed, "rupture"):
			continue
		wpool.append(id)
	var tpool: Array = []
	for id in AlchemistRig.then_ids():
		if creed != "" and AlchemistRig.then_has_tag(String(id), "rupture") \
				and AlchemistCreeds.hides_tag(creed, "rupture"):
			continue
		tpool.append(id)
	return {"whens": AlchemistRig.offer(wpool, rng, 3), "thens": AlchemistRig.offer(tpool, rng, 3)}

static func rig_describe(fw: String, w: String, t: String) -> String:
	if fw == "alchemist":
		return AlchemistRig.describe(w, t)
	if fw == "well":
		return WellRig.describe(w, t)
	return TwinfangRig.describe(w, t)

# ------------------------------------------------------------------ the description
## Fill gen.title / gen.blurb / gen.lines — the quick human-readable read of the build.
static func _describe(gen: Dictionary, fw: String) -> void:
	var run: RunState = gen["run"]
	var taken: Array = gen["taken"]
	var boss_i := int(gen["boss_i"])
	var fl: Dictionary = RaidContent.FLOORS[boss_i]
	# rarity split + tag lean (count the taken boons' tags, top two)
	var counts := {"haiku": 0, "sonnet": 0, "opus": 0}
	var tags := {}
	var keystone := ""
	for b in taken:
		counts[Draft.rarity(b)] = int(counts[Draft.rarity(b)]) + 1
		for t in (b.get("tags", []) as Array):
			var ts := String(t)
			if ts == "keystone":
				keystone = String(b.get("title", "?"))
				continue
			if ts == run.char_class or ts == run.aspect:
				continue                     # class/spec vocabulary tags say nothing about the lean
			tags[ts] = int(tags.get(ts, 0)) + 1
	var lean: Array = tags.keys()
	lean.sort_custom(func(a, b): return int(tags[a]) > int(tags[b]))
	lean = lean.slice(0, 2)
	var creed_name := ""
	if run.creed != "":
		creed_name = String(creed_data(fw, run.creed).get("name", run.creed))
	var mod_names: Array = []
	for id in run.modules:
		mod_names.append(String(module_data(fw, String(id)).get("name", id)))
	# title: the build's two loudest words
	var w1 := creed_name if creed_name != "" else String(ClassRegistry.table()[run.char_class]["display"])
	var w2 := String(mod_names[0]) if not mod_names.is_empty() \
		else (keystone if keystone != "" else (String(lean[0]).to_upper() if not lean.is_empty() else "BASELINE"))
	gen["title"] = "%s · %s" % [w1, w2]
	var bits: Array = ["%d boons (%d·%d·%d)" % [taken.size() - (1 if keystone != "" else 0),
		int(counts["haiku"]), int(counts["sonnet"]), int(counts["opus"])]]
	if not lean.is_empty():
		bits.append("leaning " + " + ".join(lean))
	if keystone != "":
		bits.append("keystone %s" % keystone)
	if not (gen["gear"] as Array).is_empty():
		bits.append("%d curio(s)" % (gen["gear"] as Array).size())
	bits.append("%d⏣ banked" % run.tokens)
	gen["blurb"] = "An average %s setup, %d fights deep — %s." \
		% [String(fl.get("title", "")), int(gen["fights"]), " · ".join(bits)]
	# the panel lines
	var lines: Array = []
	if fw != "":
		lines.append("CREED — %s" % (creed_name if creed_name != "" else "(none)"))
		if mod_names.is_empty():
			lines.append("MODULE — (lands after this floor's Seal)" if boss_i == 0 else "MODULE — (none)")
		else:
			lines.append("MODULE — %s%s" % [" + ".join(mod_names),
				"  (anchored)" if String(gen["anchor"]) != "" and run.modules.has(String(gen["anchor"])) else ""])
		if not run.rig.is_empty():
			lines.append("RIG — %s" % rig_describe(fw, String(run.rig.get("when", "")),
				String(run.rig.get("then", ""))))
		if run.transform != "":
			lines.append("TRANSFORM — %s" % run.transform.capitalize())
	elif run.char_class == "duelist":
		lines.append("(the Duelist runs DECKLESS — curios + wallet only)")
	lines.append("KEYSTONE — %s" % (keystone if keystone != "" else "(no elite on this route)"))
	var titles: Array = []
	for b in taken:
		if String(b.get("title", "")) != keystone:
			titles.append(String(b.get("title", "?")))
	if titles.is_empty():
		lines.append("BOONS — (none yet)")
	else:
		for i in range(0, titles.size(), 4):
			var chunk: Array = titles.slice(i, i + 4)
			lines.append(("BOONS (%d) — " % titles.size() if i == 0 else "     ") + ", ".join(chunk))
	if not (gen["gear"] as Array).is_empty():
		lines.append("CURIOS — " + ", ".join(gen["gear"]))
	var ai_bits: Array = []
	for key in gen["ai"]:
		ai_bits.append("%s %d" % [String(key), (gen["ai"][key] as RunState).boons.size()])
	if not ai_bits.is_empty():
		lines.append("WARBAND BOONS — " + " · ".join(ai_bits))
	gen["lines"] = lines
