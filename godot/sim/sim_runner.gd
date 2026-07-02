## Headless batch balance sim — the backbone of the tuning workflow.
##
## Run it with:
##   godot --headless --path godot --script res://sim/sim_runner.gd -- --seeds=200
## Optional user args (after the `--`):
##   --seeds=N          seeds per config (default 200)
##   --out=/abs/path    CSV output (default: <project>/out/sim_results.csv)
##
## It (1) proves determinism, (2) runs a batch + a small ally-dps sweep and prints
## win-rate bands, and (3) writes one CSV row per (config, seed). Analysis/plots
## then happen in Python/pandas over the CSV (your comfort zone).
extends SceneTree

const TICK_CAP_SEC := 180.0

func _initialize() -> void:
	var seeds := int(_arg("seeds", "200"))
	var out_path := _arg("out", "res://out/sim_results.csv")
	print("=== Project Rift — M0 headless combat sim ===")
	print("Godot ", Engine.get_version_info().get("string", "?"), "  | ", seeds, " seeds/config")
	print("")

	_prove_determinism()
	print("")

	var rows: Array = []
	# A small sweep: same fight, weaker and weaker DPS ally. Win-rate should fall
	# and losses should shift from "never" toward enrage/timeout — proving the
	# tuning pipeline reacts to a single number.
	var sweep := [
		{"label": "ally_dps_30", "dps": 30.0},
		{"label": "ally_dps_26", "dps": 26.0},
		{"label": "ally_dps_22", "dps": 22.0},
		{"label": "ally_dps_18", "dps": 18.0},
		{"label": "ally_dps_14", "dps": 14.0},
	]
	print("config          win-rate   avg TTK(win)   losses (cause histogram)")
	print("-----------------------------------------------------------------------")
	for cell in sweep:
		var wins := 0
		var ttk_sum := 0.0
		var causes := {}
		for seed in range(1, seeds + 1):
			var r := _run_one(seed, float(cell["dps"]))
			r["config"] = cell["label"]
			r["seed"] = seed
			rows.append(r)
			if r["won"]:
				wins += 1
				ttk_sum += float(r["ttk_sec"])
			else:
				var c := String(r["loss_cause"])
				causes[c] = int(causes.get(c, 0)) + 1
		var wr := 100.0 * float(wins) / float(seeds)
		var avg := (ttk_sum / float(wins)) if wins > 0 else 0.0
		print("%-14s  %6.1f%%   %8.1fs      %s" % [cell["label"], wr, avg, _fmt_causes(causes)])

	_write_csv(out_path, rows)
	print("")
	print("wrote %d rows -> %s" % [rows.size(), ProjectSettings.globalize_path(out_path)])
	quit()

## Run a single fight to termination, return a result row.
func _run_one(seed: int, ally_dps: float) -> Dictionary:
	var cfg := M0Content.make_config()
	var enc := M0Content.make_encounter()
	var s := M0Content.make_state(seed, cfg, enc, ally_dps)
	var cap := int(TICK_CAP_SEC / s.dt)
	while not s.over and s.tick < cap:
		# Decision phase: every seat with a policy observes and (maybe) acts. The
		# action is stamped for next tick — the same one-tick input path netcode uses.
		for seat in s.seats:
			if seat.policy != null and seat.alive():
				var a := seat.policy.act(CombatCore.observe(s, seat))
				if not a.is_empty():
					s.enqueue(s.tick + 1, seat, a)
		CombatCore.update(s)
	if not s.over:
		s.loss_cause = "timeout"
	return {
		"won": s.won,
		"ttk_sec": s.time(),
		"boss_hp_left": s.boss.hp,
		"tank_hp_left": s.seats[0].hp,
		"dps_hp_left": s.seats[1].hp,
		"loss_cause": s.loss_cause,
		"checksum": s.checksum,
	}

## Same seed must give an identical checksum; different seeds should differ.
func _prove_determinism() -> void:
	var a := _run_one(1, 30.0)
	var b := _run_one(1, 30.0)
	var c := _run_one(2, 30.0)
	var repro: bool = (a["checksum"] == b["checksum"]) and (a["ttk_sec"] == b["ttk_sec"])
	print("determinism check:")
	print("  seed 1 == seed 1  -> %s   (checksum %d, TTK %.3fs)" % [
		("PASS" if repro else "FAIL"), a["checksum"], a["ttk_sec"]])
	print("  seed 1 vs seed 2  -> %s" % ("differ (good)" if a["checksum"] != c["checksum"] else "IDENTICAL (suspect!)"))

func _write_csv(path: String, rows: Array) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("cannot open %s (err %d)" % [path, FileAccess.get_open_error()])
		return
	f.store_line("config,seed,won,ttk_sec,boss_hp_left,tank_hp_left,dps_hp_left,loss_cause,checksum")
	for r in rows:
		f.store_line("%s,%d,%d,%.3f,%.1f,%.1f,%.1f,%s,%d" % [
			r["config"], r["seed"], (1 if r["won"] else 0), r["ttk_sec"],
			r["boss_hp_left"], r["tank_hp_left"], r["dps_hp_left"], r["loss_cause"], r["checksum"]])
	f.close()

func _fmt_causes(causes: Dictionary) -> String:
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
