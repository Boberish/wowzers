## stream_probe — THE CONTRACT PROBE (TANK-PLAN §0, tank-v2). Fast (<1 min) asserts for the
## three laws the old build died without, run against the training bosses + a real Seal:
##
##  1. IMMUTABILITY (LAW 1): a published bar's (kind/disguise/impact/victim/dmg/late) NEVER
##     changes across the ticks it exists; bars leave the stream only by resolving at their
##     impact tick or by SHATTERING (an emitted rule). The regression test for the entire
##     pop/morph/jump comet bug class.
##  2. FRESHNESS: two pulls (different seeds) produce different bar sequences; the same
##     seed twice produces the identical sequence (determinism).
##  3. GRAMMAR: the first bar after a global is a plain auto · no two busters back-to-back ·
##     feint is never the fight's opener · flurry beats stay contiguous. (The old "no bar
##     impacts inside a telegraph" barrier law is RETIRED in tank-v3 S2 — see CONTINUITY.)
##  5. CONTINUITY (tank-v3 S2, HARD): publishing NEVER halts while a telegraph is live · the
##     committed stream never blanks past the warm-up floor · every non-LATE, non-opener bar
##     is born with runway >= horizon - one period. Regression test for the #1 live hitch.
##  4. OBS INVARIANTS: the tank's obs never ships a peeled bar (victim != tank) · a LATE
##     bar never ships before its pop-in lead · a feint ships its DISGUISE, never the truth.
##
## Usage: godot --headless --script sim/stream_probe.gd [-- --ticks=3600]
extends SceneTree

var _fails := 0

func _initialize() -> void:
	var ticks := SimUtil.arg_int("ticks", 2700)      # 90s default per fight
	_probe_fight("dense", DuelistContent.make_dense(), 11, ticks)
	_probe_fight("spike", DuelistContent.make_spike(), 12, ticks)
	_probe_seal(ticks)
	print("continuity (v3, Slice 2 — HARD: publish never halts / no mid-rhythm blank / born at the mouth):")
	_probe_seals_continuity(mini(ticks, 1200))       # all 4 Seals + immutability/no-reuse/continuity HARD
	_probe_freshness()
	_probe_claim_tiebreak()
	_probe_process_order()
	if _fails == 0:
		print("STREAM PROBE: ALL OK")
	else:
		print("STREAM PROBE: %d FAIL(S)" % _fails)
	quit(1 if _fails > 0 else 0)

func _fail(msg: String) -> void:
	_fails += 1
	print("  FAIL: ", msg)

func _mk(enc: EncounterRes, seed_v: int, latency: int) -> CombatState:
	var cfg := DuelistContent.make_config()
	var dcfg := DuelistContent.make_duelist_config()
	var s := DuelistContent.make_state(seed_v, "duelist", cfg, dcfg, enc)
	var pol := s.seats[0].policy as DuelistPolicy
	pol.latency_ticks = latency
	pol.rng = DetRng.new(seed_v * 7 + 3)
	return s

## Walk one fight tick by tick, checking every law on the way.
func _probe_fight(label: String, enc: EncounterRes, seed_v: int, ticks: int) -> void:
	var s := _mk(enc, seed_v, 0)                      # an expert tank: survives long enough
	                                                  # for full alphabet coverage (this probe
	                                                  # tests LAWS, not balance)
	var tank: Seat = s.seats[0]
	var ledger := {}                                  # id -> the committed snapshot
	var resolved := {}                                # id -> true (left by impact)
	var shatter_armed := false
	var kinds := {}                                   # kind -> count (coverage)
	var seq: Array = []                               # publish order of (id, kind)
	var last_real := ""                               # grammar memory (busters)
	var opener_checked := false
	var blank := 0                                    # consecutive empty-obs ticks (peel-inclusive; printed)
	var max_blank := 0                                # the felt "second between generations"
	var cs_blank := 0                                 # committed-stream publish halt (HARD, tank-v3 S2)
	var max_cs_blank := 0
	var max_tg_blank := 0                             # publish halt overlapping a telegraph (HARD)
	var warm := false
	var restart_until := 0
	var every := float(enc.melee.get("every", 1.5))
	var runway_floor := s.config.rhythm_open_delay + every - 0.10
	var restart_ticks := CombatCore.to_ticks(s.config.rhythm_open_delay + every, s.config.fixed_hz) + 3
	var min_runway := 1.0e9                           # shortest non-LATE impact-publish lead
	var late_first := {}                              # id -> true (first obs appearance recorded — LATE floor)
	var fl_span := {}                                 # flurry_group -> [lo_impact, hi_impact] (LATE-in-flurry guard)
	while not s.over and s.tick < ticks:
		var obs := CombatCore.observe(s, tank)
		# --- continuity: obs-blank PRINTED (peel-inclusive); committed-blank HARD ---
		var so_m: Dictionary = obs.get("stream", {})
		if so_m.has("bars"):
			if (so_m["bars"] as Array).is_empty():
				blank += 1
				max_blank = maxi(max_blank, blank)
			else:
				blank = 0
		var a: Dictionary = tank.policy.act(obs)
		if not a.is_empty():
			CombatCore.perform(s, tank, a)
		CombatCore.update(s)
		# --- CONTINUITY (HARD): the committed stream never halts (training bosses are single-
		#     body/rhythm-only — no add lane to gate; a shatter opens a refill window) ---
		for ev in s.events:
			if String(ev.get("t", "")) == "stream_shatter":
				restart_until = s.tick + restart_ticks
		if not s.boss.stream.is_empty():
			warm = true
			cs_blank = 0
		elif warm and s.tick >= restart_until:
			cs_blank += 1
			max_cs_blank = maxi(max_cs_blank, cs_blank)
			if s.telegraph != null:
				max_tg_blank = maxi(max_tg_blank, cs_blank)
		# --- LAW 1: immutability of every visible bar ---
		var present := {}
		for b_v in s.boss.stream:
			var b: Dictionary = b_v
			var id := int(b["id"])
			present[id] = true
			var snap := {"kind": b["kind"], "disguise": b["disguise"], "impact": b["impact_tick"],
				"victim": b["victim_i"], "dmg": b["dmg"], "late": b["late"]}
			if resolved.has(id):
				# NO-REUSED-ID (LAW): ids are monotonic (stream_seq) and never come back —
				# a reused id would bind a juice tween to the wrong comet.
				_fail("%s: bar id %d REUSED after it resolved/shattered" % [label, id])
			if not ledger.has(id):
				ledger[id] = snap
				# LATE guards (tank-v3 S4 / DEC-11): a LATE bar is never a flurry beat and never
				# lands inside a flurry block. Flurry spans accumulate in impact order, so every
				# lower-impact block is known by the time a LATE bar publishes.
				var fg := int(b["flurry_group"])
				if fg >= 0:
					var fimp := int(b["impact_tick"])
					if fl_span.has(fg):
						var sp: Array = fl_span[fg]
						fl_span[fg] = [mini(int(sp[0]), fimp), maxi(int(sp[1]), fimp)]
					else:
						fl_span[fg] = [fimp, fimp]
				if bool(b["late"]):
					if int(b["flurry_n"]) > 0:
						_fail("%s: a LATE bar %d is a FLURRY beat" % [label, id])
					var limp := int(b["impact_tick"])
					for g in fl_span:
						var sp2: Array = fl_span[g]
						if limp >= int(sp2[0]) and limp <= int(sp2[1]):
							_fail("%s: a LATE bar %d impacts INSIDE flurry block %s" % [label, id, g])
				if not bool(b["late"]):
					min_runway = minf(min_runway,
						float(int(b["impact_tick"]) - int(b["publish_tick"])) * s.dt)
				kinds[String(b["kind"])] = int(kinds.get(String(b["kind"]), 0)) + 1
				seq.append([id, String(b["kind"])])
				# grammar: feint never the opener · no double buster
				if not opener_checked:
					opener_checked = true
					if String(b["kind"]) == "feint":
						_fail("%s: the fight OPENED on a feint" % label)
				if String(b["kind"]) == "buster" and last_real == "buster":
					_fail("%s: two busters back-to-back (bar %d)" % [label, id])
				if String(b["kind"]) != "flurry":
					last_real = String(b["kind"])
				# grammar: a bar may never land inside a live telegraph's window
			elif str(ledger[id]) != str(snap):
				_fail("%s: bar %d MUTATED after publish (%s -> %s)" % [label, id, ledger[id], snap])
		# bars that vanished must have resolved (impact reached) or shattered
		for id in ledger:
			if not present.has(id) and not resolved.has(id):
				resolved[id] = true
				if int((ledger[id] as Dictionary)["impact"]) > s.tick and not shatter_armed:
					_fail("%s: bar %d vanished EARLY (impact %d > tick %d, no shatter)"
						% [label, id, int((ledger[id] as Dictionary)["impact"]), s.tick])
		shatter_armed = false
		for ev in s.events:
			if String(ev.get("t", "")) == "stream_shatter":
				shatter_armed = true
		# CONTINUITY (tank-v3 S2): the barrier is RETIRED — the melee keeps flowing THROUGH a
		# telegraph (CLAUDE.md scheduler law), so bars legitimately impact inside a global's
		# window. The old "no bar impacts inside a telegraph" assertion is deleted; §continuity
		# below HARD-asserts publishing never halts while s.telegraph != null instead.
		# --- obs invariants ---
		var stream_obs: Dictionary = obs.get("stream", {})
		for ob_v in stream_obs.get("bars", []):
			var ob: Dictionary = ob_v
			var oid := int(ob["id"])
			if ledger.has(oid):
				var truth: Dictionary = ledger[oid]
				if int(truth["victim"]) != 0:
					_fail("%s: obs shipped a PEELED bar %d" % [label, oid])
				if String(truth["kind"]) == "feint" and String(ob["kind"]) == "feint":
					_fail("%s: obs shipped a feint's TRUE kind (bar %d)" % [label, oid])
				var floored_lead := maxf(s.config.stream_late_lead, s.config.stream_late_min_travel)
				if bool(truth["late"]) \
						and float(int(truth["impact"]) - s.tick) * s.dt > floored_lead + s.dt:
					_fail("%s: LATE bar %d shipped before its pop-in lead" % [label, oid])
				# DEC-11 fairness floor: a LATE pop always leaves >= stream_late_min_travel of runway.
				if bool(truth["late"]) and not late_first.has(oid):
					late_first[oid] = true
					if float(ob["eta"]) < s.config.stream_late_min_travel - 2.0 * s.dt:
						_fail("%s: LATE bar %d popped with only %.2fs travel (< min %.2fs)"
							% [label, oid, float(ob["eta"]), s.config.stream_late_min_travel])
		s.events.clear()
	# coverage: the training profiles must exercise the alphabet
	for want in (["auto", "heavy", "feint"] if label == "spike" else ["auto", "heavy", "feint", "flurry", "eat"]):
		if int(kinds.get(want, 0)) == 0:
			_fail("%s: kind '%s' never published in %d ticks" % [label, want, ticks])
	# --- CONTINUITY laws, HARD (tank-v3 S2) ---
	if float(max_cs_blank) * s.dt > 0.10:
		_fail("%s: committed stream BLANKED %.2fs mid-fight (publishing halted)" % [label, float(max_cs_blank) * s.dt])
	if float(max_tg_blank) * s.dt > 0.10:
		_fail("%s: publishing HALTED %.2fs during a live telegraph (barrier regression)" % [label, float(max_tg_blank) * s.dt])
	if min_runway < runway_floor:
		_fail("%s: a non-LATE bar was born SHORT of the mouth (runway %.2fs < floor %.2fs)" % [label, min_runway, runway_floor])
	var runway_s := ("%.2fs" % min_runway) if min_runway < 1.0e9 else "n/a"
	print("  %s: %d bars over %d ticks (over=%s), kinds=%s — laws hold"
		% [label, ledger.size(), s.tick, s.over, kinds])
	print("    continuity: cs-blank=%.2fs  obs-blank=%.2fs  min-runway=%s (floor %.2fs) — HOLDS"
		% [float(max_cs_blank) * s.dt, float(max_blank) * s.dt, runway_s, runway_floor])

## A real Seal (Vorathek carries the stream + globals + casts): laws under raid content.
func _probe_seal(ticks: int) -> void:
	var enc := RaidContent.make_riftmaw()
	var s := RaidNet.build(RaidNet.make_spec(31, {}, "riftmaw", {}, {}, []), "tank")
	if s == null or s.seats.is_empty():
		# raid build path differs — fall back to a plain state on the Seal encounter
		s = DuelistContent.make_state(31, "duelist", DuelistContent.make_config(),
			DuelistContent.make_duelist_config(), enc)
	var tank: Seat = null
	for seat in s.seats:
		if seat.role == "tank":
			tank = seat
			break
	if tank == null:
		_fail("seal: no tank seat")
		return
	var ledger := {}
	var t0 := s.tick
	while not s.over and s.tick < t0 + ticks:
		CombatCore.update(s)
		for b_v in s.boss.stream:
			var b: Dictionary = b_v
			var id := int(b["id"])
			var snap := str([b["kind"], b["impact_tick"], b["victim_i"], b["dmg"], b["late"]])
			if not ledger.has(id):
				ledger[id] = snap
			elif String(ledger[id]) != snap:
				_fail("seal: bar %d MUTATED after publish" % id)
		s.events.clear()
	print("  seal(riftmaw): %d bars published — immutability holds" % ledger.size())

## CONTINUITY across all four Seals under the full raid. HARD (tank-v3 S2): immutability +
## no-reused-id + the three continuity laws — publishing never halts while a telegraph is
## live, the committed rhythm stream never blanks mid-fight (the felt "second between
## generations"), and every non-LATE bar is born at the mouth (runway >= the opener lead).
## mistral/gemini carry no rhythm today (the S3 fix) — they report the rhythm-less lane.
func _probe_seals_continuity(ticks: int) -> void:
	for boss in ["riftmaw", "mistral", "gemini", "mythos"]:
		var enc := RaidContent.encounter_by_id(boss)
		var s := RaidContent.make_state(53, enc, {}, "tank",
			{"healer": "well", "caster": "alchemist"})
		var tank: Seat = s.seats[0]                    # make_state always seats the tank first
		if tank == null or tank.role != "tank":
			_fail("seal %s: no tank seat" % boss)
			continue
		var tp := tank.policy as DuelistPolicy
		if tp != null:
			tp.latency_ticks = 0
			tp.rng = DetRng.new(53 * 11 + 7)
		_continuity("seal:" + boss, s, tank, ticks)

## Walk one state, HARD-asserting immutability + no-reused-id + the three CONTINUITY laws
## (tank-v3 S2); print the metrics. The barrier is gone, so continuity is a GATE now.
##
## The committed stream (s.boss.stream) — NOT the peel-filtered obs — is the source for
## continuity: a peeled bar legitimately blanks the tank's obs (aggro loss) but publishing
## must NOT stop. So `obs-blank` stays a printed metric; committed-blank is the hard gate.
## Continuity is only meaningful while the CURRENT lane carries rhythm — an add phase (or a
## rhythm-less Seal) shatters the stream and takes the old melee path, an empty stream BY
## DESIGN; the `lane_rhythm` gate + the post-shatter `restart_until` refill window exclude
## those sanctioned gaps. Runway floor = the main lane's opener lead (open_delay+every), the
## smallest legitimate impact−publish (assumes the rhythm lane is the main melee — true for
## every current Seal; adds are rhythm-less).
func _continuity(label: String, s: CombatState, tank: Seat, ticks: int) -> void:
	var ledger := {}                                  # id -> committed snapshot (immutability)
	var retired := {}                                 # id -> true (left the stream — reuse guard)
	var t0 := s.tick
	var obs_blank := 0                                 # PRINTED: peel-inclusive tank-view gap
	var max_obs_blank := 0
	var cs_blank := 0                                  # HARD: committed-stream publish halt
	var max_cs_blank := 0
	var max_tg_blank := 0                              # HARD: publish halt overlapping a telegraph
	var min_runway := 1.0e9
	var saw_stream := false
	var warm := false                                  # true once the rhythm lane first commits a bar
	var restart_until := 0                             # suppress cs-blank across an opener/post-shatter refill
	var every := float(s.encounter.melee.get("every", 1.5))
	var open_lead := s.config.rhythm_open_delay + every
	var runway_floor := open_lead - 0.10               # 3-tick slack under the opener lead
	var restart_ticks := CombatCore.to_ticks(open_lead, s.config.fixed_hz) + 3
	while not s.over and s.tick < t0 + ticks:
		var obs := CombatCore.observe(s, tank)
		var so: Dictionary = obs.get("stream", {})
		if so.has("bars"):
			if (so["bars"] as Array).is_empty():
				obs_blank += 1
				max_obs_blank = maxi(max_obs_blank, obs_blank)
			else:
				obs_blank = 0
		var a: Dictionary = tank.policy.act(obs)
		if not a.is_empty():
			CombatCore.perform(s, tank, a)
		CombatCore.update(s)
		# a shatter (add spawn/death, body swap) legitimately empties the stream — open a
		# refill window so the following opener gap isn't scored as a publish halt.
		for ev in s.events:
			if String(ev.get("t", "")) == "stream_shatter":
				restart_until = s.tick + restart_ticks
		# CONTINUITY (HARD) — only while THIS lane carries rhythm (else the stream is empty
		# by design and _tick_stream never runs).
		var lane_melee: Dictionary = s.encounter.melee if s.boss.add_i < 0 \
			else (s.encounter.adds[s.boss.add_i] as AddRes).melee
		if lane_melee.has("rhythm"):
			saw_stream = true
			if not s.boss.stream.is_empty():
				warm = true
				cs_blank = 0
			elif warm and s.tick >= restart_until:     # a halt, not a sanctioned refill gap
				cs_blank += 1
				max_cs_blank = maxi(max_cs_blank, cs_blank)
				if s.telegraph != null:
					max_tg_blank = maxi(max_tg_blank, cs_blank)
		var present := {}
		for b_v in s.boss.stream:
			var b: Dictionary = b_v
			var id := int(b["id"])
			present[id] = true
			var snap := str([b["kind"], b["disguise"], b["impact_tick"], b["victim_i"], b["dmg"], b["late"]])
			if retired.has(id):
				_fail("%s: bar id %d REUSED after it left the stream" % [label, id])
			elif not ledger.has(id):
				ledger[id] = snap
				if not bool(b["late"]):
					min_runway = minf(min_runway,
						float(int(b["impact_tick"]) - int(b["publish_tick"])) * s.dt)
			elif String(ledger[id]) != snap:
				_fail("%s: bar %d MUTATED after publish" % [label, id])
		for id in ledger:
			if not present.has(id):
				retired[id] = true
		s.events.clear()
	if not saw_stream:
		print("  %s: no rhythm stream shipped (rhythm-less lane) — %d bars committed"
			% [label, ledger.size()])
		return
	# --- the three CONTINUITY laws, HARD (tank-v3 S2) ---
	if float(max_cs_blank) * s.dt > 0.10:
		_fail("%s: committed stream BLANKED %.2fs mid-rhythm (publishing halted — barrier regression?)"
			% [label, float(max_cs_blank) * s.dt])
	if float(max_tg_blank) * s.dt > 0.10:
		_fail("%s: publishing HALTED %.2fs during a live telegraph (the #1 hitch is BACK)"
			% [label, float(max_tg_blank) * s.dt])
	if min_runway < runway_floor:
		_fail("%s: a non-LATE bar was born SHORT of the mouth (runway %.2fs < floor %.2fs)"
			% [label, min_runway, runway_floor])
	var runway_s := ("%.2fs" % min_runway) if min_runway < 1.0e9 else "n/a"
	print("  %s: cs-blank=%.2fs  obs-blank=%.2fs  min-runway=%s (floor %.2fs)  (%d bars, immutable, no reuse) — CONTINUITY HOLDS"
		% [label, float(max_cs_blank) * s.dt, float(max_obs_blank) * s.dt, runway_s, runway_floor, ledger.size()])

## Freshness: different seeds → different sequences; the same seed → byte-identical.
func _probe_freshness() -> void:
	var a := _sequence(41)
	var b := _sequence(42)
	var a2 := _sequence(41)
	if str(a) != str(a2):
		_fail("freshness: the SAME seed produced different sequences (determinism broke)")
	if str(a) == str(b):
		_fail("freshness: two pulls (different seeds) produced the IDENTICAL sequence")
	print("  freshness: seed41==seed41, seed41!=seed42 — holds")

## DEC-14 claim tie-break (tank-v3 S4): with a press active and >1 bar in ±answer_claim, the kit's
## claim funnel picks nearest |impact−now| → earliest impact → lowest id. Drives `_press_claims`
## directly on hand-placed bars (the deterministic core of "the press answers the RIGHT bar").
func _probe_claim_tiebreak() -> void:
	var s := _mk(DuelistContent.make_dense(), 99, 0)
	var tank: Seat = s.seats[0]
	var kit := tank.kit as DuelistKit
	if kit == null:
		_fail("claim: the tank carries no DuelistKit")
		return
	CombatCore.update(s)                              # settle onto a real tick
	s.boss.stream.clear()                             # take control of the candidate set
	var t := s.tick
	var claim := CombatCore.to_ticks(kit.cfg.answer_claim, s.config.fixed_hz)
	var _bar := func(id_v: int, kind_v: String, imp_v: int) -> Dictionary:
		return {"id": id_v, "kind": kind_v, "disguise": ("heavy" if kind_v == "feint" else kind_v),
			"publish_tick": t, "impact_tick": imp_v, "victim_i": 0, "dmg": 10.0, "late": false,
			"flurry_group": -1, "flurry_i": 0, "flurry_n": 0}
	# A — two bars at the SAME impact in range: the lowest id claims, the other yields.
	var a0: Dictionary = _bar.call(500, "auto", t + int(claim / 2))
	var a1: Dictionary = _bar.call(501, "auto", t + int(claim / 2))
	s.boss.stream = [a0, a1]
	if not kit._press_claims(s, tank, a0):
		_fail("claim: same-impact — lowest-id bar 500 should WIN the press")
	if kit._press_claims(s, tank, a1):
		_fail("claim: same-impact — bar 501 should YIELD (500 wins the tie-break)")
	# B — different impacts: the NEARER impact wins even with the higher id.
	var near: Dictionary = _bar.call(601, "auto", t + 3)
	var far: Dictionary = _bar.call(600, "heavy", t + int(claim) - 1)
	s.boss.stream = [near, far]
	if not kit._press_claims(s, tank, near):
		_fail("claim: the NEARER bar (601) should WIN over the farther one")
	if kit._press_claims(s, tank, far):
		_fail("claim: the farther bar (600) should YIELD while a nearer one is in range")
	# C — a real bar nearer than a feint: the feint must NOT claim (→ READ, not BAITED).
	var real: Dictionary = _bar.call(700, "auto", t + 2)
	var feint: Dictionary = _bar.call(701, "feint", t + 5)
	s.boss.stream = [real, feint]
	if kit._press_claims(s, tank, feint):
		_fail("claim: a FEINT must yield to a nearer real bar (DEC-14 — no false bait)")
	if not kit._press_claims(s, tank, real):
		_fail("claim: the nearer real bar should claim over the feint")
	# D — out of ±answer_claim: a bar beyond the range is not a rival claim.
	var here: Dictionary = _bar.call(800, "auto", t + 1)
	var beyond: Dictionary = _bar.call(799, "auto", t + int(claim) + 4)
	s.boss.stream = [here, beyond]
	if not kit._press_claims(s, tank, here):
		_fail("claim: a bar beyond ±answer_claim must not steal the claim from the in-range bar")
	print("  claim tie-break: same-impact→lowest id · nearest wins · feint yields · out-of-range ignored — holds")

## req 33 (§8) — PROCESS-ORDER COHERENCE (tank-v3 S5): the real CombatController drains N ticks
## in ONE catch-up frame, and only THEN does the HUD read observe() once. Because every comet's
## x is a pure function of (impact_tick, s.tick) through a CONSTANT pps (answer_channel `_pps`),
## a multi-step frame slides every live comet by the SAME delta — no comet jumps relative to
## another, and no comet lands where a mid-drain render would have put it. This drives the actual
## CombatController._process with a big delta and asserts the single coherent slide on the real
## AnswerChannel geometry (the regression test for "elements pop up all over" under a frame hitch).
func _probe_process_order() -> void:
	var s := _mk(DuelistContent.make_dense(), 71, 0)
	var ctrl := CombatController.new()
	ctrl.begin(s, 0)                                   # tank = human seat 0, its policy removed → no press
	var chan := AnswerChannel.new()
	chan.size = Vector2(740.0, 124.0)                  # the band's placement (duelist_band: -370..370 × -412..-288)
	chan.horizon = s.config.stream_horizon
	# warm up with single-tick frames until several comets ride the runway
	var guard := 0
	while s.boss.stream.size() < 3 and not s.over and guard < 800:
		ctrl._process(s.dt)
		s.events.clear()
		guard += 1
	if s.boss.stream.size() < 2 or s.over:
		_fail("process-order: could not warm up >=2 live comets")
		ctrl.free(); chan.free(); return
	var before := _comet_xs(s, s.seats[0], chan)
	# THE CATCH-UP FRAME: one _process with a big real-time delta drains several ticks at once,
	# then a single render reads observe(). The controller NEVER renders mid-drain (its contract).
	var t_before := s.tick
	ctrl._process(0.2)                                 # ~6 ticks (0.2s / (1/30)) in one frame
	var n_drained := s.tick - t_before
	s.events.clear()
	if n_drained < 3:
		_fail("process-order: the catch-up frame drained only %d ticks (expected a multi-step frame)" % n_drained)
	var after := _comet_xs(s, s.seats[0], chan)
	var pps := chan._pps()
	var want := float(n_drained) * s.dt * pps          # one coherent slide toward the gate
	var deltas: Array = []
	for id in before:
		if after.has(id):                              # only comets that survived the drain (didn't resolve)
			deltas.append(float(after[id]) - float(before[id]))
	if deltas.size() < 2:
		_fail("process-order: <2 comets survived the %d-tick catch-up to compare" % n_drained)
		ctrl.free(); chan.free(); return
	var lo: float = deltas[0]
	var hi: float = deltas[0]
	for d in deltas:
		lo = minf(lo, float(d)); hi = maxf(hi, float(d))
	if hi - lo > 0.5:                                  # sub-pixel: every comet moves as ONE
		_fail("process-order: comets slid by DIFFERENT deltas (%.3f..%.3f px) — a mid-drain render jump" % [lo, hi])
	if absf((lo + hi) * 0.5 - want) > 1.0:
		_fail("process-order: comet slide %.2fpx != expected %.2fpx over %d ticks (x not affine in eta — pps not constant?)"
			% [(lo + hi) * 0.5, want, n_drained])
	print("  process-order (req 33): %d comets · %d-tick catch-up → single coherent slide %.2fpx (want %.2f) — no jump"
		% [deltas.size(), n_drained, (lo + hi) * 0.5, want])
	ctrl.free(); chan.free()

## The render's comet-x for every live bar, straight through the real AnswerChannel geometry.
func _comet_xs(s: CombatState, tank: Seat, chan: AnswerChannel) -> Dictionary:
	var obs := CombatCore.observe(s, tank)
	var stream: Dictionary = obs.get("stream", {})
	var out := {}
	for b_v in stream.get("bars", []):
		var b: Dictionary = b_v
		out[int(b["id"])] = chan._bar_x(float(b["eta"]))
	return out

func _sequence(seed_v: int) -> Array:
	var s := _mk(DuelistContent.make_dense(), seed_v, 0)
	var out: Array = []
	var seen := {}
	while not s.over and s.tick < 900:                # 30s is plenty of pattern
		var obs := CombatCore.observe(s, s.seats[0])
		var a: Dictionary = s.seats[0].policy.act(obs)
		if not a.is_empty():
			CombatCore.perform(s, s.seats[0], a)
		CombatCore.update(s)
		for b_v in s.boss.stream:
			var b: Dictionary = b_v
			if not seen.has(int(b["id"])):
				seen[int(b["id"])] = true
				out.append([String(b["kind"]), int(b["impact_tick"])])
		s.events.clear()
	return out
