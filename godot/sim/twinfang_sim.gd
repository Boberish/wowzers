## Headless Twinfang balance sim. Proves determinism, then runs the ported encounters
## (The Warden, The Executioner) for both Aspects across a skill sweep (reaction latency),
## printing win-rate bands + kill times + loss causes, and writing a CSV. This is the
## "the melee DPS works" milestone: an AI blade drives the rhythm, kicks the heals, and
## out-paces bosses built to grind it out — and skill (rhythm accuracy) moves TTK.
##
##   godot --headless --path godot --script res://sim/twinfang_sim.gd -- --seeds=300
extends SceneTree

const TICK_CAP_SEC := 180.0

func _initialize() -> void:
	var seeds := int(_arg("seeds", "300"))
	print("=== Project Rift — M5 Twinfang headless sim ===")
	print("Godot ", Engine.get_version_info().get("string", "?"), "  | ", seeds, " seeds/cell")
	print("")
	_prove_determinism()
	print("")

	var rows: Array = []
	var matchups := [
		{"enc": "warden", "aspect": "tempo"},
		{"enc": "warden", "aspect": "venomancer"},
		{"enc": "executioner", "aspect": "tempo"},
		{"enc": "executioner", "aspect": "venomancer"},
	]
	var skills := [
		{"label": "expert", "lat": 0},
		{"label": "good", "lat": 6},
		{"label": "sloppy", "lat": 14},
	]
	print("encounter    aspect       skill    win-rate   avg TTK(win)  avg Flow  boss-heal   losses")
	print("---------------------------------------------------------------------------------------------")
	for m in matchups:
		for sk in skills:
			var wins := 0
			var ttk_sum := 0.0
			var flow_sum := 0.0
			var rupt_sum := 0.0
			var env_sum := 0.0
			var psn_sum := 0.0
			var causes := {}
			var dsum := {}
			for seed in range(1, seeds + 1):
				var r := _run_one(seed, String(m["enc"]), String(m["aspect"]), int(sk["lat"]))
				r["enc"] = m["enc"]; r["aspect"] = m["aspect"]; r["skill"] = sk["label"]; r["seed"] = seed
				rows.append(r)
				var rd: Dictionary = r.get("diag", {})
				for k in rd:
					dsum[k] = int(dsum.get(k, 0)) + int(rd[k])
				flow_sum += float(r["avg_flow"])
				rupt_sum += float(r["ruptures"])
				env_sum += float(r["envenoms"])
				psn_sum += float(r["poison_dmg"])
				if r["won"]:
					wins += 1; ttk_sum += float(r["ttk_sec"])
				else:
					var c := String(r["loss_cause"])
					causes[c] = int(causes.get(c, 0)) + 1
			var wr := 100.0 * float(wins) / float(seeds)
			var avg := (ttk_sum / float(wins)) if wins > 0 else 0.0
			print("%-12s %-11s %-7s  %6.1f%%   %8.1fs   %5.2f  rupt%4.1f env%4.1f psn%5.0f  %s" % [
				m["enc"], m["aspect"], sk["label"], wr, avg,
				flow_sum / float(seeds), rupt_sum / float(seeds),
				env_sum / float(seeds), psn_sum / float(seeds), _fmt(causes)])
			if not dsum.is_empty():
				print("              strike beats/run: %s" % _fmt_diag(dsum, seeds))
		print("")

	_write_csv(_arg("out", "res://out/twinfang_results.csv"), rows)
	print("wrote %d rows -> %s" % [rows.size(), ProjectSettings.globalize_path(_arg("out", "res://out/twinfang_results.csv"))])
	quit()

func _encounter(name: String) -> EncounterRes:
	return TwinfangContent.make_executioner() if name == "executioner" else TwinfangContent.make_warden()

func _run_one(seed: int, enc_name: String, aspect: String, latency: int) -> Dictionary:
	var cfg := TwinfangContent.make_config()
	var tcfg := TwinfangContent.make_twinfang_config()
	var s := TwinfangContent.make_state(seed, aspect, cfg, tcfg, _encounter(enc_name))
	var pol := s.seats[0].policy as TwinfangPolicy
	pol.latency_ticks = latency
	pol.rng = DetRng.new(seed * 2749 + 1337)   # separate reproducible beat-read stream
	return _run(s)

func _run(s: CombatState) -> Dictionary:
	var cap := int(TICK_CAP_SEC / s.dt)
	var flow_acc := 0.0
	var flow_samples := 0
	var ruptures := 0
	var envenoms := 0
	var poison_dmg := 0.0
	while not s.over and s.tick < cap:
		var seat := s.seats[0]
		if seat.policy != null and seat.alive():
			var a := seat.policy.act(CombatCore.observe(s, seat))
			if not a.is_empty():
				s.enqueue(s.tick + 1, seat, a)
		CombatCore.update(s)
		for ev in s.events:                       # drained view events — diagnostics only
			match String(ev.get("t", "")):
				"rupture": ruptures += 1
				"poison": poison_dmg += float(ev.get("amt", 0))
				"finisher":
					if String(ev.get("id", "")) == "envenom":
						envenoms += 1
		s.events.clear()
		flow_acc += float(seat.vars.get("flow", 0))
		flow_samples += 1
	if not s.over:
		s.loss_cause = "timeout"
	# enrage-window deaths get their own label (a DPS-check loss, not a fumble)
	if s.loss_cause == "player_death" and s.encounter.enrage_at > 0.0 and s.time() >= s.encounter.enrage_at:
		s.loss_cause = "enraged"
	return {
		"won": s.won,
		"ttk_sec": s.time(),
		"boss_hp_left": s.boss.hp,
		"boss_healed": s.boss.heal_total,
		"avg_flow": (flow_acc / float(flow_samples)) if flow_samples > 0 else 0.0,
		"ruptures": ruptures,
		"envenoms": envenoms,
		"poison_dmg": poison_dmg,
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
	var a := _run_one(1, "warden", "tempo", 0)
	var b := _run_one(1, "warden", "tempo", 0)
	var c := _run_one(2, "warden", "tempo", 0)
	var repro: bool = (a["checksum"] == b["checksum"]) and (a["ttk_sec"] == b["ttk_sec"])
	print("determinism check (Warden / Tempo):")
	print("  seed 1 == seed 1  -> %s   (checksum %d, TTK %.3fs, result %s)" % [
		("PASS" if repro else "FAIL"), a["checksum"], a["ttk_sec"], ("win" if a["won"] else a["loss_cause"])])
	print("  seed 1 vs seed 2  -> %s" % ("differ (good)" if a["checksum"] != c["checksum"] else "IDENTICAL (suspect!)"))
	# venomancer path exercises contagion RNG + poison ticks — check it too
	var d := _run_one(3, "executioner", "venomancer", 0)
	var e := _run_one(3, "executioner", "venomancer", 0)
	print("  venomancer seed 3 == seed 3 -> %s   (checksum %d, %s)" % [
		("PASS" if d["checksum"] == e["checksum"] else "FAIL"), d["checksum"],
		("win" if d["won"] else d["loss_cause"])])

func _write_csv(path: String, rows: Array) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("cannot open %s" % path); return
	f.store_line("enc,aspect,skill,seed,won,ttk_sec,boss_hp_left,boss_healed,avg_flow,loss_cause,checksum")
	for r in rows:
		f.store_line("%s,%s,%s,%d,%d,%.3f,%.1f,%.1f,%.3f,%s,%d" % [
			r["enc"], r["aspect"], r["skill"], r["seed"], (1 if r["won"] else 0),
			r["ttk_sec"], r["boss_hp_left"], r["boss_healed"], r["avg_flow"], r["loss_cause"], r["checksum"]])
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
