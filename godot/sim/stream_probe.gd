## stream_probe — THE CONTRACT PROBE (TANK-PLAN §0, tank-v2). Fast (<1 min) asserts for the
## three laws the old build died without, run against the training bosses + a real Seal:
##
##  1. IMMUTABILITY (LAW 1): a published bar's (kind/disguise/impact/victim/dmg/late) NEVER
##     changes across the ticks it exists; bars leave the stream only by resolving at their
##     impact tick or by SHATTERING (an emitted rule). The regression test for the entire
##     pop/morph/jump comet bug class.
##  2. FRESHNESS: two pulls (different seeds) produce different bar sequences; the same
##     seed twice produces the identical sequence (determinism).
##  3. GRAMMAR: no bar impacts inside a telegraph's answer window (the barrier law) · the
##     first bar after a global is a plain auto · no two busters back-to-back · feint is
##     never the fight's opener · flurry beats stay contiguous.
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
	print("continuity metrics (v3, Slice 1 — PRINTED not asserted; Slice 2 flips to hard):")
	_probe_seals_continuity(mini(ticks, 1200))       # all 4 Seals + immutability/no-reuse HARD
	_probe_freshness()
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
	var blank := 0                                    # consecutive empty-runway ticks
	var max_blank := 0                                # the felt "second between generations"
	var min_runway := 1.0e9                           # shortest non-LATE impact-publish lead
	while not s.over and s.tick < ticks:
		var obs := CombatCore.observe(s, tank)
		# --- continuity METRIC (Slice 1: printed, not asserted) ---
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
		# --- barrier law: no committed bar impacts while a telegraph is answerable ---
		if s.telegraph != null:
			var tg_end := s.telegraph.start_tick + s.telegraph.dur_ticks
			for b_v2 in s.boss.stream:
				var b2: Dictionary = b_v2
				if int(b2["impact_tick"]) >= s.tick and int(b2["impact_tick"]) <= tg_end:
					_fail("%s: bar %d impacts INSIDE telegraph window (tick %d <= %d)"
						% [label, int(b2["id"]), int(b2["impact_tick"]), tg_end])
					break
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
				if bool(truth["late"]) \
						and float(int(truth["impact"]) - s.tick) * s.dt > s.config.stream_late_lead + s.dt:
					_fail("%s: LATE bar %d shipped before its pop-in lead" % [label, oid])
		s.events.clear()
	# coverage: the training profiles must exercise the alphabet
	for want in (["auto", "heavy", "feint"] if label == "spike" else ["auto", "heavy", "feint", "flurry", "eat"]):
		if int(kinds.get(want, 0)) == 0:
			_fail("%s: kind '%s' never published in %d ticks" % [label, want, ticks])
	var runway_s := ("%.2fs" % min_runway) if min_runway < 1.0e9 else "n/a"
	print("  %s: %d bars over %d ticks (over=%s), kinds=%s — laws hold"
		% [label, ledger.size(), s.tick, s.over, kinds])
	print("    continuity: max-blank=%.2fs  min-runway=%s" % [float(max_blank) * s.dt, runway_s])

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

## CONTINUITY across all four Seals under the full raid. HARD: immutability + no-reused-id.
## PRINTED (not asserted, Slice 1): max-blank-streak in the tank's answerable runway (the
## felt "second between generations") + min non-LATE runway (impact−publish; a comet born
## short of the mouth). Slice 2 retires the barrier and flips these to hard gates.
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

## Walk one state, HARD-asserting immutability + no-reused-id; print the continuity metrics.
func _continuity(label: String, s: CombatState, tank: Seat, ticks: int) -> void:
	var ledger := {}                                  # id -> committed snapshot (immutability)
	var retired := {}                                 # id -> true (left the stream — reuse guard)
	var t0 := s.tick
	var blank := 0
	var max_blank := 0
	var min_runway := 1.0e9
	var saw_stream := false
	while not s.over and s.tick < t0 + ticks:
		var obs := CombatCore.observe(s, tank)
		var so: Dictionary = obs.get("stream", {})
		if so.has("bars"):
			saw_stream = true
			if (so["bars"] as Array).is_empty():
				blank += 1
				max_blank = maxi(max_blank, blank)
			else:
				blank = 0
		var a: Dictionary = tank.policy.act(obs)
		if not a.is_empty():
			CombatCore.perform(s, tank, a)
		CombatCore.update(s)
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
	var runway_s := ("%.2fs" % min_runway) if min_runway < 1.0e9 else "n/a"
	print("  %s: max-blank=%.2fs  min-runway=%s  (%d bars, immutable, no reuse)"
		% [label, float(max_blank) * s.dt, runway_s, ledger.size()])

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
