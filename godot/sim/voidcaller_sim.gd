## Headless Voidcaller balance sim. Proves determinism (incl. the silence-hold, empower,
## and pushback paths), then runs the ported encounters (Choir-Priest, Twin Cantors) for
## both Aspects across a skill sweep, printing win-rate bands, kill times, kicks landed,
## and how much the boss self-healed (the DPS check: miss the Mendings and it out-heals
## you). Writes a CSV.
##
##   godot --headless --path godot --script res://sim/voidcaller_sim.gd -- --seeds=300
extends SceneTree

const TICK_CAP_SEC := 150.0

func _initialize() -> void:
	var seeds := int(_arg("seeds", "300"))
	print("=== Project Rift — M5 Voidcaller headless sim ===")
	print("Godot ", Engine.get_version_info().get("string", "?"), "  | ", seeds, " seeds/cell")
	print("")
	_prove_determinism()
	print("")

	var rows: Array = []
	var matchups := [
		{"enc": "priest", "aspect": "disruptor"},
		{"enc": "priest", "aspect": "silencer"},
		{"enc": "cantors", "aspect": "disruptor"},
		{"enc": "cantors", "aspect": "silencer"},
	]
	var skills := [
		{"label": "expert", "lat": 0},
		{"label": "good", "lat": 6},
		{"label": "sloppy", "lat": 14},
	]
	print("encounter  aspect      skill    win-rate   avg TTK(win)  kicks  boss-heal   losses")
	print("-----------------------------------------------------------------------------------------")
	for m in matchups:
		for sk in skills:
			var wins := 0
			var ttk_sum := 0.0
			var kick_sum := 0.0
			var heal_sum := 0.0
			var causes := {}
			var dsum := {}
			for seed in range(1, seeds + 1):
				var r := _run_one(seed, String(m["enc"]), String(m["aspect"]), int(sk["lat"]))
				r["enc"] = m["enc"]; r["aspect"] = m["aspect"]; r["skill"] = sk["label"]; r["seed"] = seed
				rows.append(r)
				var rd: Dictionary = r.get("diag", {})
				for k in rd:
					dsum[k] = int(dsum.get(k, 0)) + int(rd[k])
				kick_sum += float(r["kicks"])
				heal_sum += float(r["boss_healed"])
				if r["won"]:
					wins += 1; ttk_sum += float(r["ttk_sec"])
				else:
					var c := String(r["loss_cause"])
					causes[c] = int(causes.get(c, 0)) + 1
			var wr := 100.0 * float(wins) / float(seeds)
			var avg := (ttk_sum / float(wins)) if wins > 0 else 0.0
			print("%-10s %-11s %-7s  %6.1f%%   %8.1fs   %5.1f   %7.0f    %s" % [
				m["enc"], m["aspect"], sk["label"], wr, avg,
				kick_sum / float(seeds), heal_sum / float(seeds), _fmt(causes)])
			if not dsum.is_empty():
				print("            strike beats/run: %s" % _fmt_diag(dsum, seeds))
		print("")

	_write_csv(_arg("out", "res://out/voidcaller_results.csv"), rows)
	print("wrote %d rows -> %s" % [rows.size(), ProjectSettings.globalize_path(_arg("out", "res://out/voidcaller_results.csv"))])
	quit()

func _encounter(name: String) -> EncounterRes:
	return VoidcallerContent.make_cantors() if name == "cantors" else VoidcallerContent.make_priest()

func _run_one(seed: int, enc_name: String, aspect: String, latency: int) -> Dictionary:
	var cfg := VoidcallerContent.make_config()
	var vcfg := VoidcallerContent.make_voidcaller_config()
	var s := VoidcallerContent.make_state(seed, aspect, cfg, vcfg, _encounter(enc_name))
	var pol := s.seats[0].policy as VoidcallerPolicy
	pol.latency_ticks = latency
	pol.rng = DetRng.new(seed * 2749 + 1337)   # separate reproducible beat-read stream
	return _run(s)

func _run(s: CombatState) -> Dictionary:
	var cap := int(TICK_CAP_SEC / s.dt)
	var seat := s.seats[0]
	while not s.over and s.tick < cap:
		if seat.policy != null and seat.alive():
			var a := seat.policy.act(CombatCore.observe(s, seat))
			if not a.is_empty():
				s.enqueue(s.tick + 1, seat, a)
		CombatCore.update(s)
	if not s.over:
		s.loss_cause = "outhealed"          # couldn't out-damage the boss's Mending in time
	return {
		"won": s.won,
		"ttk_sec": s.time(),
		"boss_hp_left": s.boss.hp,
		"boss_healed": s.boss.heal_total,
		"kicks": int(seat.vars.get("kicks", 0)),
		"diag": s.diag,
		"loss_cause": s.loss_cause,
		"checksum": s.checksum,
	}

## M7 strike-grade averages per run.
func _fmt_diag(d: Dictionary, seeds: int) -> String:
	var parts: Array = []
	for k in ["perfect", "good", "graze", "miss", "baited", "read", "whiff"]:
		if d.has(k):
			parts.append("%s %.2f" % [k, float(d[k]) / float(seeds)])
	return " · ".join(parts)

func _prove_determinism() -> void:
	var a := _run_one(1, "priest", "disruptor", 0)
	var b := _run_one(1, "priest", "disruptor", 0)
	var c := _run_one(2, "priest", "disruptor", 0)
	var repro: bool = (a["checksum"] == b["checksum"]) and (a["ttk_sec"] == b["ttk_sec"])
	print("determinism check (Choir-Priest / Disruptor):")
	print("  seed 1 == seed 1  -> %s   (checksum %d, TTK %.3fs, result %s)" % [
		("PASS" if repro else "FAIL"), a["checksum"], a["ttk_sec"], ("win" if a["won"] else a["loss_cause"])])
	print("  seed 1 vs seed 2  -> %s" % ("differ (good)" if a["checksum"] != c["checksum"] else "IDENTICAL (suspect!)"))
	# Silencer + Cantors exercises silence-hold + empower + expose paths
	var d := _run_one(3, "cantors", "silencer", 0)
	var e := _run_one(3, "cantors", "silencer", 0)
	print("  silencer/cantors seed 3 == seed 3 -> %s   (checksum %d, %s)" % [
		("PASS" if d["checksum"] == e["checksum"] else "FAIL"), d["checksum"],
		("win" if d["won"] else d["loss_cause"])])

func _write_csv(path: String, rows: Array) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("cannot open %s" % path); return
	f.store_line("enc,aspect,skill,seed,won,ttk_sec,boss_hp_left,boss_healed,kicks,loss_cause,checksum")
	for r in rows:
		f.store_line("%s,%s,%s,%d,%d,%.3f,%.1f,%.1f,%d,%s,%d" % [
			r["enc"], r["aspect"], r["skill"], r["seed"], (1 if r["won"] else 0),
			r["ttk_sec"], r["boss_hp_left"], r["boss_healed"], r["kicks"], r["loss_cause"], r["checksum"]])
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
