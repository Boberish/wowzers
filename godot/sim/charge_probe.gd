## charge_probe — certifies THE BIG-SWING ANSWER (TANK-PLAN §11) end-to-end, headless.
##
##  [1] THE CHARGED PARRY: Vorathek @ expert — every fight ARMS the gather on the CRUSH
##      wind-up (Riftmaw Crush) and LANDS charged releases (kind="charge", top-two tiers),
##      with the held fraction clearing THE COMMIT LAW (charge_min_frac).
##  [2] THE WEAVE RHYTHM: the dense golem's flurry groups carry the new shape — n = 6
##      (default), every gap ≥ 6 ticks (the 0.20s floor), and the rhythm VARIES across
##      groups (never straight twice — the §11.2 seeded jig).
##  [3] Determinism: same seed twice → byte-identical checksum (the new rng draws hold LAW 1).
##
## Run:  godot --headless --path godot --script res://sim/charge_probe.gd -- --seeds=5
extends SceneTree

const CAP_SEC := 300.0

func _initialize() -> void:
	var seeds := SimUtil.arg_int("seeds", 5)
	var fails := 0

	# --- [1] the charged parry, live on the teaching Seal ---
	print("--- charge_probe [1] CHARGED PARRY (riftmaw @ expert, %d seeds) ---" % seeds)
	for seed in range(1, 1 + seeds):
		var r := _run_raid(seed)
		var ok: bool = int(r["gathers"]) >= 1 and int(r["charge_land"]) >= 1 \
			and float(r["frac_min"]) >= 0.5
		if not ok:
			fails += 1
		print("  seed %d: gathers %d · landed %d · flinched %d · frac(min/avg) %.2f/%.2f -> %s" % [
			seed, r["gathers"], r["charge_land"], r["charge_flinch"],
			r["frac_min"], r["frac_avg"], "PASS" if ok else "FAIL"])

	# --- [2] the weave rhythm on the dense golem ---
	print("--- charge_probe [2] WEAVE RHYTHM (dense golem, %d seeds) ---" % seeds)
	for seed in range(1, 1 + seeds):
		var w := _run_weave(seed)
		var groups: Dictionary = w["groups"]
		var patterns: Dictionary = {}
		var n_bad := 0
		var gap_bad := 0
		for g in groups:
			var imps: Array = groups[g]
			imps.sort()
			if imps.size() != 6:
				n_bad += 1
			var pat: Array = []
			for i in range(1, imps.size()):
				var gap: int = int(imps[i]) - int(imps[i - 1])
				pat.append(gap)
				if gap < 6:
					gap_bad += 1
			patterns[str(pat)] = true
		var varied: bool = groups.size() < 2 or patterns.size() >= 2
		var ok2: bool = groups.size() >= 1 and n_bad == 0 and gap_bad == 0 and varied
		if not ok2:
			fails += 1
		print("  seed %d: weaves %d · distinct rhythms %d · n!=6 %d · gap<6t %d -> %s" % [
			seed, groups.size(), patterns.size(), n_bad, gap_bad, "PASS" if ok2 else "FAIL"])

	# --- [3] determinism across the new draws ---
	var a := _run_raid(1)
	var b := _run_raid(1)
	var det: bool = int(a["checksum"]) == int(b["checksum"])
	print("--- charge_probe [3] determinism: seed1==seed1 -> %s (checksum %d)" % [
		"PASS" if det else "FAIL", a["checksum"]])
	if not det:
		fails += 1

	if fails > 0:
		print("charge_probe: FAIL (%d)" % fails)
		quit(1)
	else:
		print("charge_probe: ALL PASS")
		quit()

func _run_raid(seed: int) -> Dictionary:
	var s := RaidContent.make_state(seed, RaidContent.make_riftmaw())
	var tank := s.seats[0]
	(tank.policy as DuelistPolicy).rng = DetRng.new(seed * 2749 + 6737)
	var gathers := 0
	var landed := 0
	var flinched := 0
	var frac_min := 1.0
	var frac_avg := 0.0
	var cap := int(CAP_SEC / s.dt)
	while not s.over and s.tick < cap:
		for seat in s.seats:
			if seat.policy != null and seat.alive():
				var act := seat.policy.act(CombatCore.observe(s, seat))
				if not act.is_empty():
					s.enqueue(s.tick + 1, seat, act)
		CombatCore.update(s)
		for ev in s.events:
			match String(ev.get("t", "")):
				"duel_charge":
					gathers += 1
				"duel_answer":
					if String(ev.get("kind", "")) == "charge":
						if int(ev.get("grade", -1)) == StrikeRes.Grade.MISS:
							flinched += 1
						else:
							landed += 1
							var fr := float(ev.get("charge_frac", 0.0))
							frac_min = minf(frac_min, fr)
							frac_avg += fr
		s.events.clear()
	return {"gathers": gathers, "charge_land": landed, "charge_flinch": flinched,
		"frac_min": (frac_min if landed > 0 else 0.0),
		"frac_avg": (frac_avg / float(landed) if landed > 0 else 0.0),
		"checksum": s.checksum}

func _run_weave(seed: int) -> Dictionary:
	var cfg := DuelistContent.make_config()
	var dcfg := DuelistContent.make_duelist_config()
	var s := DuelistContent.make_state(seed, "duelist", cfg, dcfg, DuelistContent.make_dense())
	(s.seats[0].policy as DuelistPolicy).rng = DetRng.new(seed * 2749 + 6737)
	var groups: Dictionary = {}
	var cap := int(CAP_SEC / s.dt)
	while not s.over and s.tick < cap:
		for seat in s.seats:
			if seat.policy != null and seat.alive():
				var act := seat.policy.act(CombatCore.observe(s, seat))
				if not act.is_empty():
					s.enqueue(s.tick + 1, seat, act)
		CombatCore.update(s)
		# read-only scan of the committed stream: record each weave group's impact ticks
		for b_v in s.boss.stream:
			var b: Dictionary = b_v
			if String(b["kind"]) != "flurry":
				continue
			var g := int(b["flurry_group"])
			if not groups.has(g):
				groups[g] = {}
			(groups[g] as Dictionary)[int(b["impact_tick"])] = true
		s.events.clear()
	var out: Dictionary = {}
	for g in groups:
		out[g] = (groups[g] as Dictionary).keys()
	return {"groups": out}
