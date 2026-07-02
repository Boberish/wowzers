## Headless RAID sim (R0 — see RAID-PLAN.md): four FULL-fidelity seats of different
## classes (Bulwark tank / Twinfang + Voidcaller dps / Mender healer), one shared
## CombatState, threat + taunt live. Proves determinism, prints win-rate bands by
## uniform party skill, and probes that THREAT is load-bearing (tank without its
## taunt → stolen-aggro deaths).
##
##   godot --headless --path godot --script res://sim/raid_sim.gd -- --seeds=300
extends SceneTree

const TICK_CAP_SEC := 240.0

func _initialize() -> void:
	var seeds := int(_arg("seeds", "200"))
	print("=== Project Rift — R0 raid sim (Vorathek, the Riftmaw) ===")
	print("Godot ", Engine.get_version_info().get("string", "?"), "  | ", seeds, " seeds/cell")
	print("party: Bulwark(warden) / Twinfang(venomancer) / Voidcaller(disruptor) / Mender(tidecaller)")
	print("")
	_prove_determinism()
	print("")

	var skills := [
		{"label": "expert", "slack": 0.0, "lat": 0, "hlat": 0},
		{"label": "good", "slack": 0.06, "lat": 6, "hlat": 6},
		{"label": "sloppy", "slack": 0.12, "lat": 14, "hlat": 18},
	]
	var rows: Array = []
	print("skill    win-rate   avg TTK(win)   taunts/run  kicks/run  boss-healed/run  losses")
	print("--------------------------------------------------------------------------------------")
	for sk in skills:
		var wins := 0
		var ttk_sum := 0.0
		var taunt_sum := 0
		var kick_sum := 0
		var healed_sum := 0.0
		var causes := {}
		for seed in range(1, seeds + 1):
			var r := _run_one(seed, sk, true)
			r["skill"] = sk["label"]; r["seed"] = seed; r["probe"] = "taunt"
			rows.append(r)
			taunt_sum += int(r["taunts"])
			kick_sum += int(r["kicks"])
			healed_sum += float(r["boss_healed"])
			if r["won"]:
				wins += 1; ttk_sum += float(r["ttk_sec"])
			else:
				var c := String(r["loss_cause"])
				causes[c] = int(causes.get(c, 0)) + 1
		var wr := 100.0 * float(wins) / float(seeds)
		var avg := (ttk_sum / float(wins)) if wins > 0 else 0.0
		print("%-7s  %6.1f%%   %8.1fs      %6.2f      %6.2f     %8.1f       %s" % [
			sk["label"], wr, avg, float(taunt_sum) / float(seeds),
			float(kick_sum) / float(seeds), healed_sum / float(seeds), _fmt(causes)])
	print("")
	_prove_threat_gate(seeds)

	_write_csv(_arg("out", "res://out/raid_results.csv"), rows)
	print("")
	print("wrote %d rows -> %s" % [rows.size(),
		ProjectSettings.globalize_path(_arg("out", "res://out/raid_results.csv"))])
	quit()

## The threat probe: same party, same seeds, but the tank never taunts. If threat is
## load-bearing, the Baleful Curse turns the boss loose on the dps and losses climb.
func _prove_threat_gate(seeds: int) -> void:
	var sk := {"label": "good", "slack": 0.06, "lat": 6, "hlat": 6}
	var wins_on := 0
	var wins_off := 0
	var dps_deaths_on := 0
	var dps_deaths_off := 0
	for seed in range(1, seeds + 1):
		var a := _run_one(seed, sk, true)
		var b := _run_one(seed, sk, false)
		if a["won"]: wins_on += 1
		if b["won"]: wins_off += 1
		dps_deaths_on += int(a["dps_deaths"])
		dps_deaths_off += int(b["dps_deaths"])
	print("threat gate probe (good party, %d seeds): taunt ON %.1f%% (dps deaths %.2f/run)  |  taunt OFF %.1f%% (dps deaths %.2f/run)" % [
		seeds, 100.0 * wins_on / seeds, float(dps_deaths_on) / seeds,
		100.0 * wins_off / seeds, float(dps_deaths_off) / seeds])
	print("  -> the taunt should carry a visible share of the win rate; if ON == OFF, threat isn't biting")

func _run_one(seed: int, sk: Dictionary, use_challenge: bool) -> Dictionary:
	var s := RaidContent.make_state(seed, RaidContent.make_riftmaw())
	var tank := s.seats[0]
	var blade := s.seats[1]
	var caster := s.seats[2]
	var healer := s.seats[3]
	var tp := tank.policy as RaidTankPolicy
	tp.reaction_slack = float(sk["slack"])
	tp.rng = DetRng.new(seed * 2749 + 1337)
	tp.use_challenge = use_challenge
	var bp := blade.policy as TwinfangPolicy
	bp.latency_ticks = int(sk["lat"])
	bp.rng = DetRng.new(seed * 2749 + 2338)
	var cp := caster.policy as VoidcallerPolicy
	cp.latency_ticks = int(sk["lat"])
	cp.rng = DetRng.new(seed * 2749 + 3339)
	(healer.policy as MenderPolicy).latency_ticks = int(sk["hlat"])
	return _run(s)

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
	var dps_deaths := 0
	for seat in s.seats:
		if seat.role == "dps" and not seat.alive():
			dps_deaths += 1
	return {
		"won": s.won,
		"ttk_sec": s.time(),
		"boss_hp_left": s.boss.hp,
		"boss_healed": s.boss.heal_total,
		"taunts": int(s.seats[0].vars.get("taunts", 0)),
		"kicks": int(s.seats[2].vars.get("kicks", 0)),
		"dps_deaths": dps_deaths,
		"loss_cause": s.loss_cause,
		"checksum": s.checksum,
	}

func _prove_determinism() -> void:
	var sk := {"label": "expert", "slack": 0.0, "lat": 0, "hlat": 0}
	var a := _run_one(1, sk, true)
	var b := _run_one(1, sk, true)
	var c := _run_one(2, sk, true)
	var repro: bool = (a["checksum"] == b["checksum"]) and (a["ttk_sec"] == b["ttk_sec"])
	print("determinism check (4 full-fidelity mixed-class seats, threat live):")
	print("  seed 1 == seed 1  -> %s   (checksum %d, TTK %.3fs, result %s)" % [
		("PASS" if repro else "FAIL"), a["checksum"], a["ttk_sec"],
		("win" if a["won"] else a["loss_cause"])])
	print("  seed 1 vs seed 2  -> %s" % ("differ (good)" if a["checksum"] != c["checksum"] else "IDENTICAL (suspect!)"))

func _write_csv(path: String, rows: Array) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("cannot open %s" % path); return
	f.store_line("skill,seed,probe,won,ttk_sec,boss_hp_left,boss_healed,taunts,kicks,dps_deaths,loss_cause,checksum")
	for r in rows:
		f.store_line("%s,%d,%s,%d,%.3f,%.1f,%.1f,%d,%d,%d,%s,%d" % [
			r["skill"], r["seed"], r["probe"], (1 if r["won"] else 0), r["ttk_sec"],
			r["boss_hp_left"], r["boss_healed"], r["taunts"], r["kicks"],
			r["dps_deaths"], r["loss_cause"], r["checksum"]])
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
