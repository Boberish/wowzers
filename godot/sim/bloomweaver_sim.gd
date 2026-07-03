## Headless Bloomweaver balance sim. Proves determinism, then runs the three authored
## encounters (Ashmaul, Swarmheart, Hollowking) for both Aspects across a healer-skill
## sweep, printing win-rate bands + kill times + loss causes + class diagnostics
## (blooms, perfect wards, wilted absorb, thorn damage), and writing a CSV.
##
##   godot --headless --path godot --script res://sim/bloomweaver_sim.gd -- --seeds=200
extends SceneTree

const TICK_CAP_SEC := 240.0

func _initialize() -> void:
	var seeds := int(_arg("seeds", "200"))
	var seed0 := int(_arg("seed0", "1"))   # seed shard offset (scripts/psim.sh); 1 = a full run
	print("=== Project Rift — Bloomweaver (Healer #2) headless sim ===")
	print("Godot ", Engine.get_version_info().get("string", "?"), "  | ", seeds, " seeds/cell")
	print("")
	if seed0 == 1: _prove_determinism()
	print("")
	if seed0 == 1: _prove_verb_mods(seeds)

	var rows: Array = []
	var matchups := [
		{"enc": "ashmaul", "aspect": "wildgrove"},
		{"enc": "ashmaul", "aspect": "thornveil"},
		{"enc": "swarmheart", "aspect": "wildgrove"},
		{"enc": "swarmheart", "aspect": "thornveil"},
		{"enc": "hollowking", "aspect": "wildgrove"},
		{"enc": "hollowking", "aspect": "thornveil"},
	]
	var skills := [
		{"label": "expert", "lat": 0},
		{"label": "good", "lat": 6},
		{"label": "sloppy", "lat": 18},
	]
	print("encounter   aspect      skill    win-rate   avg TTK(win)   blooms  perfW  wilt   thorns   losses")
	print("---------------------------------------------------------------------------------------------------")
	for m in matchups:
		for sk in skills:
			var wins := 0
			var ttk_sum := 0.0
			var causes := {}
			var blooms := 0.0
			var perfect := 0.0
			var wilted := 0.0
			var thorns := 0.0
			var dsum := {}
			for seed in range(seed0, seed0 + seeds):
				var r := _run_one(seed, String(m["enc"]), String(m["aspect"]), int(sk["lat"]))
				r["enc"] = m["enc"]; r["aspect"] = m["aspect"]; r["skill"] = sk["label"]; r["seed"] = seed
				rows.append(r)
				var rd: Dictionary = r.get("diag", {})
				for k in rd:
					dsum[k] = int(dsum.get(k, 0)) + int(rd[k])
				blooms += float(r["blooms"]); perfect += float(r["perfect"])
				wilted += float(r["wilted"]); thorns += float(r["thorns"])
				if r["won"]:
					wins += 1; ttk_sum += float(r["ttk_sec"])
				else:
					var c := String(r["loss_cause"])
					causes[c] = int(causes.get(c, 0)) + 1
			var wr := 100.0 * float(wins) / float(seeds)
			var avg := (ttk_sum / float(wins)) if wins > 0 else 0.0
			var n := float(seeds)
			print("%-11s %-10s %-7s  %6.1f%%   %8.1fs      %5.1f  %5.1f  %5.0f  %6.0f   %s" % [
				m["enc"], m["aspect"], sk["label"], wr, avg,
				blooms / n, perfect / n, wilted / n, thorns / n, _fmt(causes)])
			if not dsum.is_empty():
				print("            healer beats/run: %s" % _fmt_diag(dsum, seeds))
		print("")

	_write_csv(_arg("out", "res://out/bloomweaver_results.csv"), rows)
	print("wrote %d rows -> %s" % [rows.size(), ProjectSettings.globalize_path(_arg("out", "res://out/bloomweaver_results.csv"))])
	quit()

func _encounter(name: String) -> EncounterRes:
	match name:
		"swarmheart":
			return BloomweaverContent.make_swarmheart()
		"hollowking":
			return BloomweaverContent.make_hollowking()
		_:
			return BloomweaverContent.make_ashmaul()

func _run_one(seed: int, enc_name: String, aspect: String, latency: int,
		boons: Dictionary = {}) -> Dictionary:
	var cfg := BloomweaverContent.make_config()
	var bcfg := BloomweaverContent.make_bloom_config()
	var s := BloomweaverContent.make_state(seed, aspect, cfg, bcfg, _encounter(enc_name), boons)
	(s.seats[0].policy as BloomweaverPolicy).latency_ticks = latency
	var r := _run(s)
	r["verb_procs"] = int(s.seats[0].vars.get("verb_procs", 0))
	return r

## Phase B probe: the Garden mod pieces change the fight and stay deterministic.
## Paired seeds on the Hollowking (wildgrove @sloppy) — boonless vs a modded build.
func _prove_verb_mods(seeds: int) -> void:
	var n := mini(seeds, 120)
	var mods := {"bwTrigPerfect": true, "bwTrigPlant": true, "bwPayThorn": true,
		"bwPaySap": true, "bwPropDeepGarden": true}
	var bw := 0
	var mw := 0
	var procs := 0.0
	for seed in range(1, n + 1):
		var a := _run_one(seed, "hollowking", "wildgrove", 18)
		var b := _run_one(seed, "hollowking", "wildgrove", 18, mods)
		procs += float(b["verb_procs"])
		if a["won"]: bw += 1
		if b["won"]: mw += 1
	var d1 := _run_one(17, "hollowking", "wildgrove", 18, mods)
	var d2 := _run_one(17, "hollowking", "wildgrove", 18, mods)
	var det: bool = d1["checksum"] == d2["checksum"]
	print("garden-mods probe (Hollowking / wildgrove @sloppy, %d paired seeds):" % n)
	print("  boonless %.1f%%   modded %.1f%%   procs/run %.1f   det %s  -> %s" % [
		100.0 * bw / n, 100.0 * mw / n, procs / n, ("PASS" if det else "FAIL"),
		("PASS" if (mw >= bw and procs > 0.0 and det) else "FAIL")])
	print("")

func _run(s: CombatState) -> Dictionary:
	var cap := int(TICK_CAP_SEC / s.dt)
	while not s.over and s.tick < cap:
		for seat in s.seats:
			if seat.policy != null and seat.alive():
				var a := seat.policy.act(CombatCore.observe(s, seat))
				if not a.is_empty():
					s.enqueue(s.tick + 1, seat, a)
		CombatCore.update(s)
	if not s.over:
		s.loss_cause = "timeout"
	var deaths := 0
	for seat in s.seats:
		if seat.role != "healer" and not seat.alive():
			deaths += 1
	var hv: Dictionary = s.seats[0].vars
	return {
		"won": s.won,
		"ttk_sec": s.time(),
		"boss_hp_left": s.boss.hp,
		"deaths": deaths,
		"loss_cause": s.loss_cause,
		"blooms": int(hv.get("stat_blooms", 0)),
		"perfect": int(hv.get("stat_perfect", 0)),
		"wilted": float(hv.get("stat_wilted", 0.0)),
		"thorns": float(hv.get("stat_thorns", 0.0)),
		"planted": int(hv.get("stat_planted", 0)),
		"diag": s.diag,
		"checksum": s.checksum,
	}

## M7: the healer's own strike-beat grades, averaged per run.
func _fmt_diag(d: Dictionary, seeds: int) -> String:
	var parts: Array = []
	for k in ["perfect", "good", "graze", "miss", "baited", "read", "whiff"]:
		if d.has(k):
			parts.append("%s %.2f" % [k, float(d[k]) / float(seeds)])
	return " · ".join(parts)

func _prove_determinism() -> void:
	var a := _run_one(1, "ashmaul", "wildgrove", 0)
	var b := _run_one(1, "ashmaul", "wildgrove", 0)
	var c := _run_one(2, "ashmaul", "wildgrove", 0)
	var repro: bool = (a["checksum"] == b["checksum"]) and (a["ttk_sec"] == b["ttk_sec"])
	print("determinism check (Ashmaul / Wildgrove):")
	print("  seed 1 == seed 1  -> %s   (checksum %d, TTK %.3fs, result %s)" % [
		("PASS" if repro else "FAIL"), a["checksum"], a["ttk_sec"], ("win" if a["won"] else a["loss_cause"])])
	print("  seed 1 vs seed 2  -> %s" % ("differ (good)" if a["checksum"] != c["checksum"] else "IDENTICAL (suspect!)"))
	var d := _run_one(3, "hollowking", "thornveil", 6)
	var e := _run_one(3, "hollowking", "thornveil", 6)
	print("  thornveil/hollowking seed 3 == seed 3 -> %s   (checksum %d, %s)" % [
		("PASS" if d["checksum"] == e["checksum"] else "FAIL"), d["checksum"],
		("win" if d["won"] else d["loss_cause"])])

func _write_csv(path: String, rows: Array) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("cannot open %s" % path); return
	f.store_line("enc,aspect,skill,seed,won,ttk_sec,boss_hp_left,deaths,loss_cause,blooms,perfect,wilted,thorns,planted,checksum")
	for r in rows:
		f.store_line("%s,%s,%s,%d,%d,%.3f,%.1f,%d,%s,%d,%d,%.0f,%.0f,%d,%d" % [
			r["enc"], r["aspect"], r["skill"], r["seed"], (1 if r["won"] else 0),
			r["ttk_sec"], r["boss_hp_left"], r["deaths"], r["loss_cause"],
			r["blooms"], r["perfect"], r["wilted"], r["thorns"], r["planted"], r["checksum"]])
	f.close()

func _fmt(causes: Dictionary) -> String:
	if causes.is_empty():
		return "-"
	var parts: Array = []
	for k in causes:
		parts.append("%s=%d" % [k, causes[k]])
	return ", ".join(parts)

func _arg(key: String, def: String) -> String:
	var prefix := "--%s=" % key
	for a in OS.get_cmdline_user_args():
		if a.begins_with(prefix):
			return a.substr(prefix.length())
	return def
