## Headless Reckoner (Warrior) balance sim. Proves determinism, then runs the solo
## bosses for both Aspects across a skill sweep (reaction latency), printing win-rate
## bands + kill times + timing diagnostics + loss causes, and writing a CSV. The
## timing gate (landing True apexes) must MOVE the band — else the swing is decoration.
##
##   godot --headless --path godot --script res://sim/reckoner_sim.gd -- --seeds=300
##   scripts/psim.sh reckoner_sim 300
extends SceneTree

const TICK_CAP_SEC := 180.0

func _initialize() -> void:
	var seeds := int(_arg("seeds", "300"))
	var seed0 := int(_arg("seed0", "1"))
	print("=== Project Rift — Reckoner headless sim ===")
	print("Godot ", Engine.get_version_info().get("string", "?"), "  | ", seeds, " seeds/cell")
	print("")
	if seed0 == 1: _prove_determinism()
	print("")

	var rows: Array = []
	var matchups := [
		{"enc": "sentinel", "aspect": "colossus"},
		{"enc": "sentinel", "aspect": "berserker"},
		{"enc": "adjudicator", "aspect": "colossus"},
		{"enc": "adjudicator", "aspect": "berserker"},
	]
	var skills := [
		{"label": "expert", "lat": 0},
		{"label": "good", "lat": 6},
		{"label": "sloppy", "lat": 14},
	]
	print("encounter    aspect       skill    win-rate   avg TTK(win)  avg Mom   losses")
	print("------------------------------------------------------------------------------------------")
	for m in matchups:
		for sk in skills:
			var wins := 0
			var ttk_sum := 0.0
			var mom_sum := 0.0
			var causes := {}
			var dsum := {}
			for seed in range(seed0, seed0 + seeds):
				var r := _run_one(seed, String(m["enc"]), String(m["aspect"]), int(sk["lat"]))
				r["enc"] = m["enc"]; r["aspect"] = m["aspect"]; r["skill"] = sk["label"]; r["seed"] = seed
				rows.append(r)
				for k in r.get("diag", {}):
					dsum[k] = int(dsum.get(k, 0)) + int(r["diag"][k])
				mom_sum += float(r["avg_mom"])
				if r["won"]:
					wins += 1; ttk_sum += float(r["ttk_sec"])
				else:
					var c := String(r["loss_cause"])
					causes[c] = int(causes.get(c, 0)) + 1
			var wr := 100.0 * float(wins) / float(seeds)
			var avg := (ttk_sum / float(wins)) if wins > 0 else 0.0
			print("%-12s %-11s %-7s  %6.1f%%   %8.1fs   %5.2f   %s" % [
				m["enc"], m["aspect"], sk["label"], wr, avg, mom_sum / float(seeds), _fmt(causes)])
			if not dsum.is_empty():
				print("              per-run: %s" % _fmt_diag(dsum, seeds))
		print("")

	_write_csv(_arg("out", "res://out/reckoner_results.csv"), rows)
	print("wrote %d rows -> %s" % [rows.size(), ProjectSettings.globalize_path(_arg("out", "res://out/reckoner_results.csv"))])
	quit()

func _encounter(name: String) -> EncounterRes:
	return ReckonerContent.make_adjudicator() if name == "adjudicator" else ReckonerContent.make_sentinel()

func _run_one(seed: int, enc_name: String, aspect: String, latency: int,
		boons: Dictionary = {}) -> Dictionary:
	var cfg := ReckonerContent.make_config()
	var rcfg := ReckonerContent.make_reckoner_config()
	var s := ReckonerContent.make_state(seed, aspect, cfg, rcfg, _encounter(enc_name), boons)
	var pol := s.seats[0].policy as ReckonerPolicy
	pol.latency_ticks = latency
	pol.rng = DetRng.new(seed * 2749 + 2338)
	return _run(s)

func _run(s: CombatState) -> Dictionary:
	var cap := int(TICK_CAP_SEC / s.dt)
	var mom_acc := 0.0
	var samples := 0
	while not s.over and s.tick < cap:
		var seat := s.seats[0]
		if seat.policy != null and seat.alive():
			var a := seat.policy.act(CombatCore.observe(s, seat))
			if not a.is_empty():
				s.enqueue(s.tick + 1, seat, a)
		CombatCore.update(s)
		s.events.clear()
		mom_acc += float(seat.vars.get("momentum", 0.0))
		samples += 1
	if not s.over:
		s.loss_cause = "timeout"
	if s.loss_cause == "player_death" and s.encounter.enrage_at > 0.0 and s.time() >= s.encounter.enrage_at:
		s.loss_cause = "enraged"
	return {
		"won": s.won,
		"ttk_sec": s.time(),
		"boss_hp_left": s.boss.hp,
		"avg_mom": (mom_acc / float(samples)) if samples > 0 else 0.0,
		"diag": s.diag,
		"loss_cause": s.loss_cause,
		"checksum": s.checksum,
	}

func _prove_determinism() -> void:
	var a := _run_one(1, "sentinel", "colossus", 6)
	var b := _run_one(1, "sentinel", "colossus", 6)
	print("determinism check:")
	print("  Sentinel/Colossus seed 1 == seed 1  -> %s   (checksum %d, TTK %.3fs, %s)" % [
		("PASS" if a["checksum"] == b["checksum"] and a["ttk_sec"] == b["ttk_sec"] else "FAIL"),
		a["checksum"], a["ttk_sec"], ("win" if a["won"] else a["loss_cause"])])
	var c := _run_one(1, "adjudicator", "berserker", 14)
	var c2 := _run_one(2, "adjudicator", "berserker", 14)
	print("  Adjudicator/Bers  seed 1 vs seed 2  -> %s" % (
		"differ (good)" if c["checksum"] != c2["checksum"] else "IDENTICAL (suspect!)"))
	var d := _run_one(3, "adjudicator", "colossus", 6)
	var e := _run_one(3, "adjudicator", "colossus", 6)
	print("  Adjudicator/Col   seed 3 == seed 3  -> %s   (checksum %d)" % [
		("PASS" if d["checksum"] == e["checksum"] else "FAIL"), d["checksum"]])

func _fmt_diag(d: Dictionary, seeds: int) -> String:
	var parts: Array = []
	for k in ["apex", "clash"]:
		if d.has(k):
			parts.append("%s %.1f" % [k, float(d[k]) / float(seeds)])
	return " · ".join(parts) if not parts.is_empty() else "-"

func _write_csv(path: String, rows: Array) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("cannot open %s" % path); return
	f.store_line("enc,aspect,skill,seed,won,ttk_sec,boss_hp_left,avg_mom,loss_cause,checksum")
	for r in rows:
		f.store_line("%s,%s,%s,%d,%d,%.3f,%.1f,%.3f,%s,%d" % [
			r["enc"], r["aspect"], r["skill"], r["seed"], (1 if r["won"] else 0),
			r["ttk_sec"], r["boss_hp_left"], r["avg_mom"], r["loss_cause"], r["checksum"]])
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
