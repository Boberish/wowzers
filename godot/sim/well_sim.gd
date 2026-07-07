## well_sim — balance loop for the reworked direct-cast healer (MENDER-PLAN.md).
## Both aspects (brim/draw) × 3 skill tiers × N seeds against two raid-style encounters.
## Measures the skill gradient (win-rate, kill time, deaths) and the class's economy
## (pours, Glint uptime, charge floor). Determinism proven on shard 0.
##
## Run:  godot --headless --path godot --script res://sim/well_sim.gd -- --seeds=300
## Shard: scripts/psim.sh well_sim 300 8
extends SceneTree

const TICK_CAP_SEC := 260.0

func _initialize() -> void:
	var seeds := SimUtil.arg_int("seeds", 200)
	var seed0 := SimUtil.arg_int("seed0", 1)
	var out := SimUtil.arg("out", "")

	if seed0 == 1:
		_prove_determinism()

	var encs := ["maw", "rot"]
	var aspects := ["brim", "draw"]
	var skills := [
		{"label": "expert", "lat": 0},
		{"label": "good", "lat": 6},
		{"label": "sloppy", "lat": 14},
	]

	print("\n=== WELL — %d seeds/cell (seed0=%d) ===" % [seeds, seed0])
	print("%-8s %-7s %-7s  win%%   ttk    pours/min glint%%  chgFloor deaths" % ["boss", "aspect", "skill"])
	var rows: Array = []
	for enc_name in encs:
		for aspect in aspects:
			for sk in skills:
				var wins := 0
				var ttk_sum := 0.0
				var pours_sum := 0.0
				var glint_sum := 0.0
				var chg_sum := 0.0
				var deaths := 0
				for seed in range(seed0, seed0 + seeds):
					var r := _run_one(seed, enc_name, aspect, int(sk["lat"]))
					if r["won"]:
						wins += 1
						ttk_sum += r["ttk_sec"]
					pours_sum += r["pours_per_min"]
					glint_sum += r["glint_pct"]
					chg_sum += r["chg_floor"]
					deaths += r["deaths"]
					rows.append("%s,%s,%s,%d,%d,%.1f,%.3f,%.3f,%d,%d" % [
						enc_name, aspect, sk["label"], seed, (1 if r["won"] else 0),
						r["ttk_sec"], r["pours_per_min"], r["glint_pct"], r["chg_floor"], r["deaths"]])
				var n := float(seeds)
				var wr := 100.0 * float(wins) / n
				var ttk := (ttk_sum / float(wins)) if wins > 0 else 0.0
				print("%-8s %-7s %-7s  %5.1f  %5.1f   %6.1f   %5.1f   %5.1f    %d" % [
					enc_name, aspect, sk["label"], wr, ttk,
					pours_sum / n, 100.0 * glint_sum / n, chg_sum / n, deaths])

	if out != "":
		_write_csv(out, rows)
	quit()

func _prove_determinism() -> void:
	print("--- determinism ---")
	for aspect in ["brim", "draw"]:
		var a := _run_one(1, "maw", aspect, 0)
		var b := _run_one(1, "maw", aspect, 0)
		var repro: bool = a["checksum"] == b["checksum"] and a["ttk_sec"] == b["ttk_sec"]
		var c := _run_one(2, "maw", aspect, 0)
		var diverge: bool = c["checksum"] != a["checksum"]
		print("  %-5s  seed1==seed1 -> %s (checksum %d)   seed1 vs seed2 -> %s" % [
			aspect, ("PASS" if repro else "FAIL"), a["checksum"],
			("differ (good)" if diverge else "IDENTICAL (suspect!)")])

func _run_one(seed: int, enc_name: String, aspect: String, latency: int) -> Dictionary:
	var cfg := WellContent.make_config()
	var wcfg := WellContent.make_well_config()
	var s := WellContent.make_state(seed, aspect, cfg, wcfg, _encounter(enc_name))
	var pol := s.seats[0].policy as WellPolicy
	pol.latency_ticks = latency
	pol.rng = DetRng.new(seed * 2749 + 4441)          # separate reproducible skill stream
	return _run(s, wcfg)

func _run(s: CombatState, wcfg: WellConfig) -> Dictionary:
	var cap := int(TICK_CAP_SEC / s.dt)
	var pours := 0
	var glint_ticks := 0
	var chg_floor := wcfg.charges_max
	var deaths := 0
	while not s.over and s.tick < cap:
		var seat := s.seats[0]
		if seat.policy != null and seat.alive():
			var a := seat.policy.act(CombatCore.observe(s, seat))
			if not a.is_empty():
				s.enqueue(s.tick + 1, seat, a)
		CombatCore.update(s)
		# metrics (read-only; must not touch state → checksum stays byte-stable)
		for ev in s.events:
			var t := String(ev.get("t", ""))
			if t == "well_pour" or t == "well_still":
				pours += 1
			elif t == "revive":
				pass
			elif t == "hurt" and int(ev.get("amt", 0)) > 0 and ev.get("seat") != null \
					and not (ev["seat"] as Seat).alive():
				deaths += 1
		var glinted := false
		for u in s.seats:
			if s.tick < int(u.vars.get("glint_until", -1)):
				glinted = true
				break
		if glinted:
			glint_ticks += 1
		var ch := int(seat.vars.get("charges", 0))
		if ch < chg_floor:
			chg_floor = ch
		s.events.clear()
	var ttk := s.tick * s.dt
	var won := s.over and s.boss.hp <= 0.0
	return {
		"won": won,
		"ttk_sec": ttk,
		"pours_per_min": 60.0 * float(pours) / maxf(1.0, ttk),
		"glint_pct": float(glint_ticks) / maxf(1.0, float(s.tick)),
		"chg_floor": float(chg_floor),
		"deaths": deaths,
		"checksum": s.checksum,
	}

func _encounter(name: String) -> EncounterRes:
	if name == "rot":
		return WellContent.make_attrition()
	return WellContent.make_spike()

func _write_csv(path: String, rows: Array) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.store_line("boss,aspect,skill,seed,won,ttk_sec,pours_per_min,glint_pct,chg_floor,deaths")
	for r in rows:
		f.store_line(String(r))
	f.close()

