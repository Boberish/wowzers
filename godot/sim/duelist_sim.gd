## duelist_sim — balance loop for THE DUELIST (the dodge tank, TANK-PLAN / DUELIST-BRIEF S3).
## The tank (seat 0) + 3 statblock DPS burning a boss that pressures the tank, across 3 skill
## tiers × N seeds × two training encounters. Measures the skill gradient (win-rate, kill time,
## deaths) and the class ECONOMY (flow uptime + peel count · wind floor/starvation · ◆ throughput ·
## parry perfect/graze rates · weave/answer mix). Determinism proven on shard 0. The healer DUET
## lives in raid_sim (this sim isolates the tank's own economy — no healer).
##
## Run:  godot --headless --path godot --script res://sim/duelist_sim.gd -- --seeds=300
## Shard: scripts/psim.sh duelist_sim 300 8
extends SceneTree

const TICK_CAP_SEC := 300.0

func _initialize() -> void:
	var seeds := SimUtil.arg_int("seeds", 200)
	var seed0 := SimUtil.arg_int("seed0", 1)
	var out := SimUtil.arg("out", "")
	var only := SimUtil.arg("boss", "")

	if seed0 == 1:
		_prove_determinism()

	var encs := ["dense", "spike"] if only == "" else [only]
	var skills := [
		{"label": "expert", "lat": 0},
		{"label": "good", "lat": 6},
		{"label": "sloppy", "lat": 14},
	]

	print("\n=== DUELIST — %d seeds/cell (seed0=%d) ===" % [seeds, seed0])
	print("%-7s %-7s  win%%   ttk    flow%%  peels  windFloor  ◆/min  sharp%%  fumbles deaths" % ["boss", "skill"])
	var rows: Array = []
	for enc_name in encs:
		for sk in skills:
			var wins := 0
			var ttk_sum := 0.0
			var flow_sum := 0.0
			var peel_sum := 0.0
			var wind_sum := 0.0
			var dump_sum := 0.0
			var sharp_sum := 0.0
			var fum_sum := 0.0
			var deaths := 0
			for seed in range(seed0, seed0 + seeds):
				var r := _run_one(seed, enc_name, int(sk["lat"]))
				if r["won"]:
					wins += 1
					ttk_sum += r["ttk_sec"]
				flow_sum += r["flow_pct"]
				peel_sum += r["peels"]
				wind_sum += r["wind_floor"]
				dump_sum += r["dumps_per_min"]
				sharp_sum += r["sharp_pct"]
				fum_sum += r["fumbles"]
				deaths += r["deaths"]
				rows.append("%s,%s,%d,%d,%.1f,%.3f,%d,%.2f,%.2f,%.1f,%d,%d" % [
					enc_name, sk["label"], seed, (1 if r["won"] else 0), r["ttk_sec"],
					r["flow_pct"], r["peels"], r["wind_floor"], r["dumps_per_min"],
					r["sharp_pct"], r["fumbles"], r["deaths"]])
			var n := float(seeds)
			var wr := 100.0 * float(wins) / n
			var ttk := (ttk_sum / float(wins)) if wins > 0 else 0.0
			print("%-7s %-7s  %5.1f  %5.1f   %5.1f  %5.1f  %7.1f   %5.1f   %5.1f   %5.1f   %d" % [
				enc_name, sk["label"], wr, ttk, 100.0 * flow_sum / n, peel_sum / n,
				wind_sum / n, dump_sum / n, 100.0 * sharp_sum / n, fum_sum / n, deaths])

	if out != "":
		_write_csv(out, rows)
	quit()

func _prove_determinism() -> void:
	print("--- determinism (base) ---")
	for enc_name in ["dense", "spike"]:
		var a := _run_one(1, enc_name, 0)
		var b := _run_one(1, enc_name, 0)
		var repro: bool = a["checksum"] == b["checksum"] and a["ttk_sec"] == b["ttk_sec"]
		var c := _run_one(2, enc_name, 0)
		print("  %-6s  seed1==seed1 -> %s (checksum %d)   seed1 vs seed2 -> %s" % [
			enc_name, ("PASS" if repro else "FAIL"), a["checksum"],
			("differ (good)" if c["checksum"] != a["checksum"] else "IDENTICAL (suspect!)")])

func _run_one(seed: int, enc_name: String, latency: int) -> Dictionary:
	var cfg := DuelistContent.make_config()
	var dcfg := DuelistContent.make_duelist_config()
	var s := DuelistContent.make_state(seed, "duelist", cfg, dcfg, _encounter(enc_name))
	var pol := s.seats[0].policy as DuelistPolicy
	pol.latency_ticks = latency
	pol.rng = DetRng.new(seed * 2749 + 6737)          # NEW salt — the byte-exact-history rule
	return _run(s, dcfg)

func _run(s: CombatState, dcfg: DuelistConfig) -> Dictionary:
	var cap := int(TICK_CAP_SEC / s.dt)
	var tank := s.seats[0]
	var flow_ticks := 0
	var wind_floor := dcfg.wind_max
	var dumps := 0
	var deaths := 0
	while not s.over and s.tick < cap:
		for seat in s.seats:
			if seat.policy != null and seat.alive():
				var a := seat.policy.act(CombatCore.observe(s, seat))
				if not a.is_empty():
					s.enqueue(s.tick + 1, seat, a)
		CombatCore.update(s)
		# metrics (read-only — must not touch state → checksum stays byte-stable)
		if float(tank.vars.get("flow", 0.0)) >= s.config.flow_lock_floor:
			flow_ticks += 1
		wind_floor = minf(wind_floor, float(tank.vars.get("wind", dcfg.wind_max)))
		for ev in s.events:
			var t := String(ev.get("t", ""))
			if t == "duel_dump":
				dumps += 1
			elif t == "hurt" and int(ev.get("amt", 0)) > 0 and ev.get("seat") != null \
					and not (ev["seat"] as Seat).alive():
				deaths += 1
		s.events.clear()
	var ttk := s.tick * s.dt
	var won := s.over and s.boss.hp <= 0.0
	var peels := 0
	for seat in s.seats:
		peels += int(seat.diag.get("aggro_pulled", 0))
	var d: Dictionary = tank.diag
	var graded := int(d.get("perfect", 0)) + int(d.get("good", 0)) + int(d.get("graze", 0)) + int(d.get("miss", 0))
	return {
		"won": won,
		"ttk_sec": ttk,
		"flow_pct": float(flow_ticks) / maxf(1.0, float(s.tick)),
		"peels": peels,
		"wind_floor": wind_floor,
		"dumps_per_min": 60.0 * float(dumps) / maxf(1.0, ttk),
		"sharp_pct": float(int(d.get("perfect", 0))) / maxf(1.0, float(graded)),
		"fumbles": int(d.get("fumble", 0)),
		"deaths": deaths,
		"checksum": s.checksum,
	}

func _encounter(name: String) -> EncounterRes:
	if name == "spike":
		return DuelistContent.make_spike()
	return DuelistContent.make_dense()

func _write_csv(path: String, rows: Array) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.store_line("boss,skill,seed,won,ttk_sec,flow_pct,peels,wind_floor,dumps_per_min,sharp_pct,fumbles,deaths")
	for r in rows:
		f.store_line(String(r))
	f.close()
