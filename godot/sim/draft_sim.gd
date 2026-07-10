## Headless verification for Draft 2.0 (game/draft.gd) — the merge gate for the draft
## engine + token economy. Proves, for all five classes × both aspects:
##   1. DETERMINISM  — same run seed => identical draft transcripts (offers, rarities,
##      fight seeds, token balances) through takes, a REROLL, and an UPSELL.
##   2. SYNERGY      — whenever any offerable boon tag-matches the build, slot 0 matches.
##   3. PITY BOUND   — an opus offer within OPUS_PITY_HARD+1 drafts while one is offerable.
##   4. SPEND LEGALITY — a refused (broke) reroll/upsell spends nothing AND consumes no
##      rng (the next roll is identical to a control run's).
##   5. MINT         — exact token values from synthetic diags (cap + flawless), and a
##      real seeded Bulwark fight minting identically twice.
## Run:  godot --headless --path godot --script res://sim/draft_sim.gd
extends SceneTree

const CLASSES := {
	"bulwark": ["warden", "juggernaut"],
	"twinfang": ["tempo", "venomancer"],
	"bloomweaver": ["wildgrove", "thornveil"],
}

var _fails := 0

func _initialize() -> void:
	print("=== DRAFT SIM — Draft 2.0 + Tokens ===")
	_test_determinism()
	_test_synergy()
	_test_pity()
	_test_spend_legality()
	_test_regenerate()
	_test_mint_table()
	_test_mint_integration()
	if _fails > 0:
		print("DRAFT SIM: %d FAILURE(S)" % _fails)
		quit(1)
	else:
		print("DRAFT SIM: ALL OK")
		quit(0)

func _check(ok: bool, what: String) -> void:
	if ok:
		print("  PASS  %s" % what)
	else:
		print("  FAIL  %s" % what)
		_fails += 1

func _start(cls: String, aspect: String, seed_v: int) -> RunState:
	match cls:
		"bulwark": return RunState.start(aspect, seed_v)
		"twinfang": return RunState.start_twinfang(aspect, seed_v)
		"bloomweaver": return RunState.start_bloomweaver(aspect, seed_v)
	return null

## Drive 4 drafts with a fixed script (take slot 0; draft 1 grants 5 tokens + rerolls;
## draft 2 upsells slot 1 when legal) and record everything decision-relevant.
func _transcript(cls: String, aspect: String, seed_v: int) -> String:
	var run := _start(cls, aspect, seed_v)
	var out := ""
	for d in 4:
		out += "F%d " % run.fight_seed()
		var offers := Draft.roll_offers(run)
		if d == 1:
			run.tokens = 5
			run.regenerate = 1                          # rerolls-out: a banked charge redraws
			var rr := Draft.reroll(run)
			if not rr.is_empty():
				offers = rr
		if d == 2 and Draft.can_upsell(run, offers, 1):
			offers = Draft.upsell(run, offers, 1)
		if offers.is_empty():
			out += "(none) "
		else:
			for o in offers:
				out += "%s/%s " % [o["id"], Draft.rarity(o)]
			Draft.take(run, offers[0])
		out += "t%d p%d | " % [run.tokens, run.pity_opus]
		run.enc_index += 1
	return out

func _test_determinism() -> void:
	print("-- determinism (transcripts incl. reroll/upsell/fight seeds)")
	for cls in CLASSES:
		for aspect in CLASSES[cls]:
			var a := _transcript(cls, aspect, 12345)
			var b := _transcript(cls, aspect, 12345)
			var c := _transcript(cls, aspect, 999)
			_check(a == b, "%s/%s same seed reproduces" % [cls, aspect])
			_check(a != c, "%s/%s different seed differs" % [cls, aspect])

func _test_synergy() -> void:
	print("-- synergy slot (slot 0 matches whenever a match is offerable)")
	for cls in CLASSES:
		for aspect in CLASSES[cls]:
			var checked := 0
			var ok := true
			for seed_v in range(1, 51):
				var run := _start(cls, aspect, seed_v)
				for d in 5:
					var avail := Draft.offerable(run)
					var any_match := false
					for b in avail:
						if Draft.matches(b, run):
							any_match = true
							break
					var offers := Draft.roll_offers(run)
					if offers.is_empty():
						break
					if any_match:
						checked += 1
						if not Draft.matches(offers[0], run):
							ok = false
					Draft.take(run, offers[0])
			_check(ok and checked > 0, "%s/%s synergy guarantee (%d drafts checked)" % [cls, aspect, checked])

func _test_pity() -> void:
	print("-- opus pity (an opus offer within %d drafts while offerable)" % (Draft.OPUS_PITY_HARD + 1))
	for cls in CLASSES:
		var aspect: String = CLASSES[cls][0]
		var worst := 0
		for seed_v in range(1, 41):
			var run := _start(cls, aspect, seed_v)
			var streak := 0
			for d in 40:
				var opus_avail := false
				for b in Draft.offerable(run):
					if Draft.rarity(b) == "opus":
						opus_avail = true
						break
				var offers := Draft.roll_offers(run)
				if offers.is_empty():
					break
				var got_opus := false
				for o in offers:
					if Draft.rarity(o) == "opus":
						got_opus = true
						break
				if got_opus:
					streak = 0
				elif opus_avail:
					streak += 1
					worst = maxi(worst, streak)
		_check(worst <= Draft.OPUS_PITY_HARD + 1, "%s worst opus drought = %d drafts" % [cls, worst])

func _test_spend_legality() -> void:
	print("-- spend legality (broke spends refused, no tokens/charges, NO rng consumed)")
	for cls in CLASSES:
		var aspect: String = CLASSES[cls][0]
		# control: two straight rolls
		var ctrl := _start(cls, aspect, 777)
		var c1 := Draft.roll_offers(ctrl)
		var c2 := Draft.roll_offers(ctrl)
		# probe: refused reroll (no charge) + refused upsell (no tokens) between the same rolls
		var run := _start(cls, aspect, 777)
		var p1 := Draft.roll_offers(run)
		var rr := Draft.reroll(run)                     # regenerate = 0 -> refused
		var up := Draft.upsell(run, p1, 0)              # tokens = 0 -> unchanged
		var p2 := Draft.roll_offers(run)
		_check(rr.is_empty() and up == p1 and run.tokens == 0 and run.regenerate == 0, "%s broke spends refused" % cls)
		_check(_ids(p1) == _ids(c1) and _ids(p2) == _ids(c2), "%s refused spends consume no rng" % cls)

func _ids(offers: Array) -> String:
	var out := ""
	for o in offers:
		out += String(o["id"]) + ","
	return out

## Phase B — REGENERATE · a banked charge redraws the whole row (rerolls-out §11 #3;
## the token REROLL + per-card LOCK are gone).
func _test_regenerate() -> void:
	print("-- REGENERATE (banked charge redraws the row; no token cost, no LOCK)")
	for cls in CLASSES:
		var aspect: String = CLASSES[cls][0]
		# a charge spends one and redraws; Tokens are NOT touched by a reroll now
		var run := _start(cls, aspect, 555)
		run.regenerate = 2
		run.tokens = 7
		var offers := Draft.roll_offers(run)
		var next := Draft.reroll(run)
		_check(not next.is_empty() and run.regenerate == 1 and run.tokens == 7,
			"%s REGENERATE redraws, decrements 2->1, leaves Tokens" % cls)
		# the charge-gated redraw is the SAME rng stream a token reroll used to produce
		var a := _start(cls, aspect, 888)
		a.regenerate = 1
		var _ao := Draft.roll_offers(a)
		var ar := Draft.reroll(a)
		var b := _start(cls, aspect, 888)
		var bo := Draft.roll_offers(b)
		var br := Draft.roll_offers(b)   # a second straight roll = the redraw's rng draw
		_check(_ids(ar) == _ids(br), "%s a REGENERATE redraw == the next straight roll's stream" % cls)
		# broke: no charge -> reroll refused, tokens untouched, NO rng consumed
		var ctrl := _start(cls, aspect, 777)
		var c1 := Draft.roll_offers(ctrl)
		var c2 := Draft.roll_offers(ctrl)
		var probe := _start(cls, aspect, 777)
		probe.tokens = 9                 # Tokens can't buy a reroll anymore
		var p1 := Draft.roll_offers(probe)
		var rr := Draft.reroll(probe)    # regenerate = 0 -> refused
		var p2 := Draft.roll_offers(probe)
		_check(rr.is_empty() and probe.tokens == 9 and probe.regenerate == 0 \
			and _ids(p1) == _ids(c1) and _ids(p2) == _ids(c2),
			"%s no-charge reroll refused, tokens kept, no rng" % cls)

func _test_mint_table() -> void:
	print("-- mint formula (synthetic diags, exact values)")
	var s := CombatState.new()
	s.config = TuningConfig.new()
	# footwork only: (6+0)/3 = 2, miss present -> no flawless
	s.diag = {"perfect": 6, "read": 0, "miss": 1}
	_check(Draft.mint(s, "bulwark") == 2, "footwork tokens (expect 2)")
	# signature + footwork + flawless: (2+1)/3=1 + 8/4=2 + 1 = 4 -> capped at 3
	s.diag = {"perfect": 2, "read": 1, "negate": 8}
	_check(Draft.mint(s, "bulwark") == 3, "cap applies (expect 3)")
	# scrappy but flawless-by-absence: only the flawless bonus
	s.diag = {"perfect": 1, "graze": 4}
	_check(Draft.mint(s, "twinfang") == 1, "flawless bonus alone (expect 1)")
	# signature key is per class: bloomweaver wards
	s.diag = {"perfect_ward": 8, "miss": 2}
	_check(Draft.mint(s, "bloomweaver") == 2, "bloomweaver signature (expect 2)")
	# wrong class's signature earns nothing
	s.diag = {"negate": 8, "miss": 2}
	_check(Draft.mint(s, "bloomweaver") == 0, "signature is class-keyed (expect 0)")

## The same seeded Bulwark fight (real policy) minted twice must agree — proves the
## mint source (state.diag) is deterministic end-to-end.
func _test_mint_integration() -> void:
	print("-- mint integration (seeded Bulwark fight, twice)")
	var a := _fight_mint(31337)
	var b := _fight_mint(31337)
	_check(a["mint"] == b["mint"] and a["diag"] == b["diag"] and a["cs"] == b["cs"],
		"identical fight -> identical diag (%s) -> identical mint (%d)" % [str(a["diag"]), a["mint"]])

func _fight_mint(seed_v: int) -> Dictionary:
	var cfg := BulwarkContent.make_config()
	var bcfg := BulwarkContent.make_bulwark_config()
	var s := BulwarkContent.make_state(seed_v, "warden", cfg, bcfg, BulwarkContent.make_the_duelist())
	var pol := s.seats[0].policy as BulwarkPolicy
	pol.reaction_slack = 0.0
	pol.rng = DetRng.new(seed_v * 2749 + 1337)
	var cap := int(120.0 / s.dt)
	while not s.over and s.tick < cap:
		for seat in s.seats:
			if seat.policy != null and seat.alive():
				var act := seat.policy.act(CombatCore.observe(s, seat))
				if not act.is_empty():
					s.enqueue(s.tick + 1, seat, act)
		CombatCore.update(s)
	return {"mint": Draft.mint(s, "bulwark"), "diag": s.diag.duplicate(), "cs": s.checksum}
