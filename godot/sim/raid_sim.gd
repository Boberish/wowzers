## Headless RAID sim — all four Seals (see MASTER-PLAN §RAID SEALS): four
## FULL-fidelity seats (Bulwark tank / Twinfang + Voidcaller dps / Mender healer),
## one shared CombatState, threat + taunt live. Proves determinism per Seal, prints
## win-rate bands by uniform party skill with Seal-specific diagnostics (kick-chain
## verses, doom beats, add waves, hotfix healing), and probes that THREAT is
## load-bearing on the classic Seal.
##
##   godot --headless --path godot --script res://sim/raid_sim.gd -- --seeds=200
##   optional: --boss=riftmaw|mistral|gemini|mythos (default: all)
extends SceneTree

const TICK_CAP_SEC := 300.0
const SKILLS := [
	{"label": "expert", "slack": 0.0, "lat": 0, "hlat": 0},
	{"label": "good", "slack": 0.06, "lat": 6, "hlat": 6},
	{"label": "sloppy", "slack": 0.12, "lat": 14, "hlat": 18},
]

func _initialize() -> void:
	var seeds := int(_arg("seeds", "200"))
	var seed0 := int(_arg("seed0", "1"))   # seed shard offset (scripts/psim.sh); 1 = a full run
	var only := _arg("boss", "")
	var bosses: Array = ["riftmaw", "mistral", "gemini", "mythos"] if only == "" else [only]
	print("=== Project Rift — raid sim (the Seals) ===")
	print("Godot ", Engine.get_version_info().get("string", "?"), "  | ", seeds, " seeds/cell")
	print("party: Bulwark(warden) / Twinfang(venomancer) / Voidcaller(disruptor) / Mender(tidecaller)")
	print("")
	if seed0 == 1:                         # shard 0 only (probes are seed-independent diagnostics)
		for b in bosses:
			_prove_determinism(String(b))
	print("")

	var rows: Array = []
	for b in bosses:
		var enc := RaidContent.encounter_by_id(String(b))
		print("--- %s  (%d HP, enrage %.0fs) ---" % [enc.name, enc.hp, enc.enrage_at])
		# healer-engagement cols: hlMana = healer's MIN mana over the fight (% of pool),
		# hlOver = share of its healing that was OVERHEAL (wasted), hlIdle = % of the
		# healer's decision ticks it had NOTHING worth casting. Low hlOver+low hlIdle+
		# a mana floor that actually dips = the healer's resource is a real constraint;
		# hlMana pinned near 100 with high hlIdle = the fight doesn't pressure the healer.
		print("skill    win-rate   avg TTK(win)  taunts  kicks  healed  scaled  beatmiss  adds  hlMana hlOver hlIdle  losses")
		for sk in SKILLS:
			var wins := 0
			var ttk_sum := 0.0
			var agg := {"taunts": 0.0, "kicks": 0.0, "healed": 0.0, "buff": 0.0,
				"miss": 0.0, "adds": 0.0, "hmana": 0.0, "hover": 0.0, "hidle": 0.0}
			var causes := {}
			for seed in range(seed0, seed0 + seeds):
				var r := _run_one(String(b), seed, sk, true)
				r["skill"] = sk["label"]; r["seed"] = seed; r["boss"] = b; r["probe"] = "taunt"
				rows.append(r)
				agg["taunts"] += float(int(r["taunts"]))
				agg["kicks"] += float(int(r["kicks"]))
				agg["healed"] += float(r["boss_healed"])
				agg["buff"] += float(r["dmg_buff"])
				agg["miss"] += float(int(r["beat_miss"]))
				agg["adds"] += float(int(r["adds_killed"]))
				agg["hmana"] += float(r["hl_mana_pct"])
				agg["hover"] += float(r["hl_over_pct"])
				agg["hidle"] += float(r["hl_idle_pct"])
				if r["won"]:
					wins += 1; ttk_sum += float(r["ttk_sec"])
				else:
					var c := String(r["loss_cause"])
					causes[c] = int(causes.get(c, 0)) + 1
			var wr := 100.0 * float(wins) / float(seeds)
			var avg := (ttk_sum / float(wins)) if wins > 0 else 0.0
			var n := float(seeds)
			print("%-7s  %6.1f%%   %8.1fs    %5.2f  %5.2f  %6.1f  %5.2f    %6.2f  %4.2f  %5.0f%% %5.0f%% %5.0f%%  %s" % [
				sk["label"], wr, avg, agg["taunts"] / n, agg["kicks"] / n, agg["healed"] / n,
				agg["buff"] / n, agg["miss"] / n, agg["adds"] / n,
				agg["hmana"] / n, agg["hover"] / n, agg["hidle"] / n, _fmt(causes)])
		print("")
	if seed0 == 1 and (only == "" or only == "riftmaw"):
		_prove_threat_gate(mini(seeds, 200))

	_write_csv(_arg("out", "res://out/raid_results.csv"), rows)
	print("")
	print("wrote %d rows -> %s" % [rows.size(),
		ProjectSettings.globalize_path(_arg("out", "res://out/raid_results.csv"))])
	quit()

## The threat probe: same party, same seeds, but the tank never taunts. If threat is
## load-bearing, the Baleful Curse turns the boss loose on the dps and losses climb.
func _prove_threat_gate(seeds: int) -> void:
	var sk: Dictionary = SKILLS[1]
	var wins_on := 0
	var wins_off := 0
	var dps_deaths_on := 0
	var dps_deaths_off := 0
	for seed in range(1, seeds + 1):
		var a := _run_one("riftmaw", seed, sk, true)
		var b := _run_one("riftmaw", seed, sk, false)
		if a["won"]: wins_on += 1
		if b["won"]: wins_off += 1
		dps_deaths_on += int(a["dps_deaths"])
		dps_deaths_off += int(b["dps_deaths"])
	print("threat gate probe (riftmaw, good party, %d seeds): taunt ON %.1f%% (dps deaths %.2f/run)  |  taunt OFF %.1f%% (dps deaths %.2f/run)" % [
		seeds, 100.0 * wins_on / seeds, float(dps_deaths_on) / seeds,
		100.0 * wins_off / seeds, float(dps_deaths_off) / seeds])
	print("  -> the taunt should carry a visible share of the win rate; if ON == OFF, threat isn't biting")

func _run_one(boss: String, seed: int, sk: Dictionary, use_challenge: bool) -> Dictionary:
	var s := RaidContent.make_state(seed, RaidContent.encounter_by_id(boss))
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
	# healer-engagement sampling (read-only — does not touch the sim, so checksums
	# stay byte-identical): min mana over the fight + how often the healer idled.
	var healer := _healer_seat(s)
	var mana_max := (healer.resource_max if healer != null else 900.0)
	var mana_min := (healer.resource if healer != null else 0.0)
	var h_idle := 0
	var h_acts := 0
	while not s.over and s.tick < cap:
		for seat in s.seats:
			if seat.policy != null and seat.alive():
				var a := seat.policy.act(CombatCore.observe(s, seat))
				if seat == healer:
					h_acts += 1
					if a.is_empty():
						h_idle += 1
				if not a.is_empty():
					s.enqueue(s.tick + 1, seat, a)
		CombatCore.update(s)
		if healer != null:
			mana_min = minf(mana_min, healer.resource)
	if not s.over:
		s.loss_cause = "timeout"
	var dps_deaths := 0
	var beat_miss := 0
	for seat in s.seats:
		if seat.role == "dps" and not seat.alive():
			dps_deaths += 1
		beat_miss += int(seat.diag.get("miss", 0))
	var adds_killed := s.boss.adds_spawned.size() - (1 if s.boss.add_i >= 0 else 0)
	# healer output from the meter (eff vs overheal) → % wasted; mana floor as % of pool.
	var hrow: Dictionary = s.meter.get(s.seats.find(healer), {})
	var h_eff := float(hrow.get("heal_total", 0.0))
	var h_over := float(hrow.get("over_total", 0.0))
	var h_total := h_eff + h_over
	return {
		"won": s.won,
		"ttk_sec": s.time(),
		"boss_hp_left": s.boss.hp,
		"boss_healed": s.boss.heal_total,
		"dmg_buff": s.boss.dmg_buff,           # scaled: landed empower verses × buff
		"taunts": int(s.seats[0].vars.get("taunts", 0)),
		"kicks": int(s.seats[2].vars.get("kicks", 0)),
		"beat_miss": beat_miss,                # missed string beats, all four seats
		"adds_killed": adds_killed,
		"dps_deaths": dps_deaths,
		"hl_mana_pct": 100.0 * mana_min / maxf(1.0, mana_max),
		"hl_over_pct": (100.0 * h_over / h_total) if h_total > 0.0 else 0.0,
		"hl_idle_pct": 100.0 * float(h_idle) / float(maxi(1, h_acts)),
		"hl_eff": h_eff,
		"loss_cause": s.loss_cause,
		"checksum": s.checksum,
	}

## The single healer seat (role == "healer"); null if a comp ever runs without one.
func _healer_seat(s: CombatState) -> Seat:
	for seat in s.seats:
		if seat.role == "healer":
			return seat
	return null

func _prove_determinism(boss: String) -> void:
	var sk: Dictionary = SKILLS[0]
	var a := _run_one(boss, 1, sk, true)
	var b := _run_one(boss, 1, sk, true)
	var c := _run_one(boss, 2, sk, true)
	var repro: bool = (a["checksum"] == b["checksum"]) and (a["ttk_sec"] == b["ttk_sec"])
	print("determinism %-8s seed1==seed1 -> %s  (checksum %d, TTK %.3fs, %s) · seed1 vs seed2 -> %s" % [
		boss, ("PASS" if repro else "FAIL"), a["checksum"], a["ttk_sec"],
		("win" if a["won"] else a["loss_cause"]),
		("differ (good)" if a["checksum"] != c["checksum"] else "IDENTICAL (suspect!)")])

func _write_csv(path: String, rows: Array) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("cannot open %s" % path); return
	f.store_line("boss,skill,seed,probe,won,ttk_sec,boss_hp_left,boss_healed,dmg_buff,taunts,kicks,beat_miss,adds_killed,dps_deaths,hl_mana_pct,hl_over_pct,hl_idle_pct,hl_eff,loss_cause,checksum")
	for r in rows:
		f.store_line("%s,%s,%d,%s,%d,%.3f,%.1f,%.1f,%.2f,%d,%d,%d,%d,%d,%.1f,%.1f,%.1f,%.1f,%s,%d" % [
			r["boss"], r["skill"], r["seed"], r["probe"], (1 if r["won"] else 0), r["ttk_sec"],
			r["boss_hp_left"], r["boss_healed"], r["dmg_buff"], r["taunts"], r["kicks"],
			r["beat_miss"], r["adds_killed"], r["dps_deaths"],
			r["hl_mana_pct"], r["hl_over_pct"], r["hl_idle_pct"], r["hl_eff"],
			r["loss_cause"], r["checksum"]])
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
