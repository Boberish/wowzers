## Headless Bulwark balance sim. Proves determinism, then runs the ported encounters
## (Gatekeeper, Warcaller) for both Aspects across a skill sweep, printing win-rate
## bands + kill times + loss causes, and writing a CSV. Also runs the 2-seat ally
## path once to prove the group-damage line works for future co-op/AI allies.
##
##   godot --headless --path godot --script res://sim/bulwark_sim.gd -- --seeds=300
extends SceneTree

const TICK_CAP_SEC := 240.0

func _initialize() -> void:
	var seeds := int(_arg("seeds", "300"))
	var seed0 := int(_arg("seed0", "1"))   # seed shard offset (scripts/psim.sh); 1 = a full run
	var out_path := _arg("out", "res://out/bulwark_results.csv")
	print("=== Project Rift — M1 Bulwark headless sim ===")
	print("Godot ", Engine.get_version_info().get("string", "?"), "  | ", seeds, " seeds/cell")
	print("")

	if seed0 == 1: _prove_determinism()
	print("")

	var rows: Array = []
	var matchups := [
		{"enc": "gatekeeper", "aspect": "warden"},
		{"enc": "gatekeeper", "aspect": "juggernaut"},
		{"enc": "warcaller", "aspect": "warden"},
		{"enc": "warcaller", "aspect": "juggernaut"},
		{"enc": "colossus", "aspect": "warden"},
		{"enc": "colossus", "aspect": "juggernaut"},
		{"enc": "devourer", "aspect": "warden"},
		{"enc": "devourer", "aspect": "juggernaut"},
		{"enc": "duelist", "aspect": "warden"},
		{"enc": "duelist", "aspect": "juggernaut"},
	]
	var skills := [
		{"label": "expert", "slack": 0.0},
		{"label": "good", "slack": 0.06},
		{"label": "loose", "slack": 0.12},
	]
	print("encounter   aspect       skill    win-rate   avg TTK(win)  boss-heal  losses")
	print("------------------------------------------------------------------------------------")
	for m in matchups:
		for sk in skills:
			var wins := 0
			var ttk_sum := 0.0
			var heal_sum := 0.0
			var causes := {}
			var dsum := {}
			for seed in range(seed0, seed0 + seeds):
				var r := _run_one(seed, String(m["enc"]), String(m["aspect"]), float(sk["slack"]))
				r["enc"] = m["enc"]; r["aspect"] = m["aspect"]; r["skill"] = sk["label"]; r["seed"] = seed
				rows.append(r)
				heal_sum += float(r["boss_healed"])
				var rd: Dictionary = r.get("diag", {})
				for k in rd:
					dsum[k] = int(dsum.get(k, 0)) + int(rd[k])
				if r["won"]:
					wins += 1; ttk_sum += float(r["ttk_sec"])
				else:
					# Death while enraged = lost the DPS race, not a fumbled swing.
					var c := String(r["loss_cause"])
					if c == "player_death" and bool(r.get("enraged", false)):
						c = "enrage"
					causes[c] = int(causes.get(c, 0)) + 1
			var wr := 100.0 * float(wins) / float(seeds)
			var avg := (ttk_sum / float(wins)) if wins > 0 else 0.0
			var heal_avg := heal_sum / float(seeds)
			print("%-11s %-11s %-7s  %6.1f%%   %8.1fs   heal~%-5.0f %s" % [
				m["enc"], m["aspect"], sk["label"], wr, avg, heal_avg, _fmt_causes(causes)])
			if not dsum.is_empty():
				print("             strike beats/run: %s" % _fmt_diag(dsum, seeds))
		print("")

	if seed0 == 1: _prove_ally_path(seeds)
	if seed0 == 1: _prove_feint_gate(seeds)
	if seed0 == 1: _prove_guard_mods(seeds)

	_write_csv(out_path, rows)
	print("wrote %d rows -> %s" % [rows.size(), ProjectSettings.globalize_path(out_path)])
	quit()

func _encounter(name: String) -> EncounterRes:
	match name:
		"warcaller":
			return BulwarkContent.make_warcaller()
		"colossus":
			return BulwarkContent.make_colossus()
		"devourer":
			return BulwarkContent.make_devourer()
		"duelist":
			return BulwarkContent.make_the_duelist()
		_:
			return BulwarkContent.make_gatekeeper()

func _run_one(seed: int, enc_name: String, aspect: String, slack: float,
		perfect_reads: bool = false, boons: Dictionary = {}) -> Dictionary:
	var cfg := BulwarkContent.make_config()
	var bcfg := BulwarkContent.make_bulwark_config()
	var s := BulwarkContent.make_state(seed, aspect, cfg, bcfg, _encounter(enc_name), boons)
	var pol := s.seats[0].policy as BulwarkPolicy
	pol.reaction_slack = slack
	pol.perfect_feint_read = perfect_reads
	pol.rng = DetRng.new(seed * 2749 + 1337)   # separate reproducible read-stream
	var r := _run(s)
	r["guard_procs"] = int(s.seats[0].vars.get("guard_procs", 0))
	return r

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
	# Was the enrage hard-timer live when the fight ended? A death during enrage is a
	# DPS-check failure (you didn't out-race the heal), distinct from eating a swing.
	var enraged: bool = s.encounter.enrage_at > 0.0 and s.time() >= s.encounter.enrage_at
	return {
		"won": s.won,
		"ttk_sec": s.time(),
		"boss_hp_left": s.boss.hp,
		"player_hp_left": s.seats[0].hp,
		"boss_healed": s.boss.heal_total,
		"enraged": enraged,
		"baits": int(s.seats[0].vars.get("baits", 0)),
		"diag": s.diag,
		"loss_cause": s.loss_cause,
		"checksum": s.checksum,
	}

func _prove_determinism() -> void:
	var a := _run_one(1, "gatekeeper", "warden", 0.0)
	var b := _run_one(1, "gatekeeper", "warden", 0.0)
	var c := _run_one(2, "gatekeeper", "warden", 0.0)
	var repro: bool = (a["checksum"] == b["checksum"]) and (a["ttk_sec"] == b["ttk_sec"])
	print("determinism check (Gatekeeper / Warden):")
	print("  seed 1 == seed 1  -> %s   (checksum %d, TTK %.3fs)" % [
		("PASS" if repro else "FAIL"), a["checksum"], a["ttk_sec"]])
	print("  seed 1 vs seed 2  -> %s" % ("differ (good)" if a["checksum"] != c["checksum"] else "IDENTICAL (suspect!)"))
	# The Devourer exercises RNG paths the others don't: continuous-melee next_range,
	# HEAL_BOSS, and the enrage ramp. Verify it's deterministic too.
	var da := _run_one(7, "devourer", "warden", 0.04)
	var db := _run_one(7, "devourer", "warden", 0.04)
	var drepro: bool = (da["checksum"] == db["checksum"]) and (da["ttk_sec"] == db["ttk_sec"])
	print("determinism check (Devourer / Warden, melee+heal+enrage):")
	print("  seed 7 == seed 7  -> %s   (checksum %d, TTK %.3fs, boss healed %.0f)" % [
		("PASS" if drepro else "FAIL"), da["checksum"], da["ttk_sec"], float(da["boss_healed"])])
	# The Duelist exercises the feint punish/reward + the AI's deterministic flinch
	# (loose slack must reproduce the SAME baits every run). Verify at loose skill.
	var ua := _run_one(3, "duelist", "warden", 0.12)
	var ub := _run_one(3, "duelist", "warden", 0.12)
	var urepro: bool = (ua["checksum"] == ub["checksum"]) and (ua["ttk_sec"] == ub["ttk_sec"])
	print("determinism check (Duelist / Warden, feint reads @loose):")
	print("  seed 3 == seed 3  -> %s   (checksum %d, TTK %.3fs)" % [
		("PASS" if urepro else "FAIL"), ua["checksum"], ua["ttk_sec"]])

## Prove the ally / group-damage path: Bulwark tank + a stat-block DPS ally. The boss
## should die faster than solo (the ally chips it down the f(hp%) curve).
func _prove_ally_path(seeds: int) -> void:
	var cfg := BulwarkContent.make_config()
	var bcfg := BulwarkContent.make_bulwark_config()
	var wins := 0
	var ttk_sum := 0.0
	for seed in range(1, seeds + 1):
		var s := BulwarkContent.make_state_with_ally(seed, "warden", cfg, bcfg,
			BulwarkContent.make_gatekeeper(), 20.0)
		(s.seats[0].policy as BulwarkPolicy).reaction_slack = 0.0
		var r := _run(s)
		if r["won"]:
			wins += 1; ttk_sum += float(r["ttk_sec"])
	var wr := 100.0 * float(wins) / float(seeds)
	var avg := (ttk_sum / float(wins)) if wins > 0 else 0.0
	print("ally-path check (Gatekeeper / Warden + 20-dps stat-block ally):")
	print("  win-rate %.1f%%   avg TTK(win) %.1fs   (should beat solo TTK — ally chips the boss)" % [wr, avg])
	print("")

## Prove the Duelist's difficulty actually comes from its FEINT mechanic, not just
## harder generic parry-timing: run loose Warden with fallible reads (flinches into
## baits) vs the SAME loose timing but perfect feint reads. The win-rate gap is the
## share of the gate the feint mechanic itself is carrying.
func _prove_feint_gate(seeds: int) -> void:
	var fallible_wins := 0
	var perfect_wins := 0
	var bait_sum := 0.0
	for seed in range(1, seeds + 1):
		var a := _run_one(seed, "duelist", "warden", 0.12, false)
		var b := _run_one(seed, "duelist", "warden", 0.12, true)
		if a["won"]: fallible_wins += 1
		if b["won"]: perfect_wins += 1
		bait_sum += float(a["baits"])
	var fwr := 100.0 * float(fallible_wins) / float(seeds)
	var pwr := 100.0 * float(perfect_wins) / float(seeds)
	print("feint-gate probe (Duelist / Warden @loose):")
	print("  fallible reads %.1f%%   vs   perfect reads %.1f%%   -> feints carry %.1fpp of the gate" % [
		fwr, pwr, pwr - fwr])
	print("  avg baits/run %.2f   (if this is ~0 or the gap is small, the feint mechanic is inert)" % [
		bait_sum / float(seeds)])
	print("")

## Phase B probe: the slot-verb Guard mods change the fight and stay deterministic.
## Paired seeds on the Duelist @loose — boonless vs a modded build (trigThird +
## trigRead + payReflect + payHeal + Twin Guard). The mods only ADD power, so the
## modded win-rate must never drop; guard_procs proves the payloads actually fire.
func _prove_guard_mods(seeds: int) -> void:
	var mods := {"trigThird": true, "trigRead": true, "payReflect": true,
		"payHeal": true, "propCharge": true}
	var base_wins := 0
	var mod_wins := 0
	var base_ttk := 0.0
	var mod_ttk := 0.0
	var proc_sum := 0.0
	for seed in range(1, seeds + 1):
		var a := _run_one(seed, "duelist", "warden", 0.12)
		var b := _run_one(seed, "duelist", "warden", 0.12, false, mods)
		proc_sum += float(b["guard_procs"])
		if a["won"]:
			base_wins += 1
			base_ttk += float(a["ttk_sec"])
		if b["won"]:
			mod_wins += 1
			mod_ttk += float(b["ttk_sec"])
	var bwr := 100.0 * float(base_wins) / float(seeds)
	var mwr := 100.0 * float(mod_wins) / float(seeds)
	var bavg := (base_ttk / float(base_wins)) if base_wins > 0 else 0.0
	var mavg := (mod_ttk / float(mod_wins)) if mod_wins > 0 else 0.0
	var d1 := _run_one(17, "duelist", "warden", 0.12, false, mods)
	var d2 := _run_one(17, "duelist", "warden", 0.12, false, mods)
	var det: bool = d1["checksum"] == d2["checksum"] and d1["ttk_sec"] == d2["ttk_sec"]
	print("guard-mods probe (Duelist / Warden @loose, boonless vs modded build):")
	print("  boonless %.1f%% (TTK %.1fs)   modded %.1f%% (TTK %.1fs)   -> %s" % [
		bwr, bavg, mwr, mavg,
		("PASS (mods never cost wins)" if mwr >= bwr else "FAIL (modded win-rate DROPPED)")])
	print("  avg guard procs/run %.2f   -> %s" % [proc_sum / float(seeds),
		("PASS (payloads fire)" if proc_sum > 0.0 else "FAIL (proc engine inert)")])
	print("  modded determinism seed 17 == seed 17 -> %s   (checksum %d)" % [
		("PASS" if det else "FAIL"), d1["checksum"]])
	print("")

func _write_csv(path: String, rows: Array) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("cannot open %s (err %d)" % [path, FileAccess.get_open_error()])
		return
	f.store_line("enc,aspect,skill,seed,won,ttk_sec,boss_hp_left,player_hp_left,boss_healed,enraged,loss_cause,checksum")
	for r in rows:
		f.store_line("%s,%s,%s,%d,%d,%.3f,%.1f,%.1f,%.1f,%d,%s,%d" % [
			r["enc"], r["aspect"], r["skill"], r["seed"], (1 if r["won"] else 0),
			r["ttk_sec"], r["boss_hp_left"], r["player_hp_left"], float(r["boss_healed"]),
			(1 if r.get("enraged", false) else 0), r["loss_cause"], r["checksum"]])
	f.close()

## M7 strike-grade averages per run (only printed where a string boss produced any).
func _fmt_diag(d: Dictionary, seeds: int) -> String:
	var parts: Array = []
	for k in ["perfect", "good", "graze", "miss", "baited", "read", "whiff"]:
		if d.has(k):
			parts.append("%s %.2f" % [k, float(d[k]) / float(seeds)])
	return " · ".join(parts)

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
