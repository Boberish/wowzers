## Headless Alchemist ("the Brew") balance sim — the base-minigame harness. Proves
## determinism, then runs the training encounters (The Crucible, The Leech) across a
## skill sweep (reaction latency), printing win-rate bands + kill times + brew
## diagnostics (potency uptime, pours by grade, ruptures + peak-ruptures) and a CSV.
## This is the "AI-pilotable or it doesn't ship" gate (class-design rule #3): the
## seeded policy must brew at 3 tiers with a REAL gradient.
##
##   godot --headless --path godot --script res://sim/alchemist_sim.gd -- --seeds=300
##   sharded: scripts/psim.sh alchemist_sim 300
extends SceneTree

const TICK_CAP_SEC := 180.0

func _initialize() -> void:
	var seeds := int(_arg("seeds", "300"))
	var seed0 := int(_arg("seed0", "1"))   # seed shard offset (scripts/psim.sh); 1 = a full run
	print("=== Project Rift — ALCHEMIST base-minigame sim (the Brew) ===")
	print("Godot ", Engine.get_version_info().get("string", "?"), "  | ", seeds, " seeds/cell")
	print("")
	if seed0 == 1:
		_prove_determinism()
		print("")

	var rows: Array = []
	var matchups := [
		{"enc": "crucible"},
		{"enc": "leech"},
	]
	var skills := [
		{"label": "expert", "lat": 0},
		{"label": "good", "lat": 6},
		{"label": "sloppy", "lat": 14},
	]
	print("encounter    skill    win-rate   avg TTK(win)  avg potency  ruptures(peak)  losses")
	print("--------------------------------------------------------------------------------------")
	for m in matchups:
		for sk in skills:
			var wins := 0
			var ttk_sum := 0.0
			var pot_sum := 0.0
			var causes := {}
			var dsum := {}
			for seed in range(seed0, seed0 + seeds):
				var r := _run_one(seed, String(m["enc"]), int(sk["lat"]))
				r["enc"] = m["enc"]; r["skill"] = sk["label"]; r["seed"] = seed
				rows.append(r)
				var rd: Dictionary = r.get("diag", {})
				for k in rd:
					dsum[k] = int(dsum.get(k, 0)) + int(rd[k])
				pot_sum += float(r["avg_potency"])
				if r["won"]:
					wins += 1; ttk_sum += float(r["ttk_sec"])
				else:
					var c := String(r["loss_cause"])
					causes[c] = int(causes.get(c, 0)) + 1
			var wr := 100.0 * float(wins) / float(seeds)
			var avg := (ttk_sum / float(wins)) if wins > 0 else 0.0
			print("%-12s %-7s  %6.1f%%   %8.1fs     %5.2f      %4.1f (%4.1f)     %s" % [
				m["enc"], sk["label"], wr, avg, pot_sum / float(seeds),
				float(dsum.get("ruptures", 0)) / float(seeds),
				float(dsum.get("rupture_peak", 0)) / float(seeds), _fmt(causes)])
			print("              pours/run: %s" % _fmt_pours(dsum, seeds))
		print("")

	_creed_ab(seeds, seed0)
	_module_ab(seeds, seed0)

	_write_csv(_arg("out", "res://out/alchemist_results.csv"), rows)
	print("wrote %d rows -> %s" % [rows.size(),
		ProjectSettings.globalize_path(_arg("out", "res://out/alchemist_results.csv"))])
	quit()

## SLICE A gate — each Creed must produce a DISTINCT, sane profile AND keep the skill
## gradient (rule #4). Crucible @ expert (lat 0) AND sloppy (lat 14); "" = the byte-identical
## base for reference. Forgiving creeds should help the sloppy tier without gifting the expert.
func _creed_ab(seeds: int, seed0: int) -> void:
	print("CREED A/B — Crucible, %d seeds/cell (expert lat0 · sloppy lat14):" % seeds)
	print("creed          skill    win-rate  avg TTK   avg potency  ruptures(peak)  pours(potent/ok/hot/spoil/fizzle)")
	print("-----------------------------------------------------------------------------------------------------------")
	for cr in ["", "steady_hand", "volatile_mix", "anchorite", "purist"]:
		for sk in [{"lbl": "expert", "lat": 0}, {"lbl": "sloppy", "lat": 14}]:
			var wins := 0
			var ttk_sum := 0.0
			var pot_sum := 0.0
			var dsum := {}
			for seed in range(seed0, seed0 + seeds):
				var r := _run_one(seed, "crucible", int(sk["lat"]), cr)
				var rd: Dictionary = r.get("diag", {})
				for k in rd:
					dsum[k] = int(dsum.get(k, 0)) + int(rd[k])
				pot_sum += float(r["avg_potency"])
				if r["won"]:
					wins += 1; ttk_sum += float(r["ttk_sec"])
			var wr := 100.0 * float(wins) / float(seeds)
			var avg := (ttk_sum / float(wins)) if wins > 0 else 0.0
			var lbl: String = "(base)" if String(cr) == "" else String(cr)
			print("%-14s %-7s %6.1f%%   %7.1fs    %5.2f       %4.1f (%4.1f)     %.1f/%.1f/%.1f/%.1f/%.1f" % [
				lbl, String(sk["lbl"]), wr, avg, pot_sum / float(seeds),
				float(dsum.get("ruptures", 0)) / float(seeds),
				float(dsum.get("rupture_peak", 0)) / float(seeds),
				float(dsum.get("pour_potent", 0)) / float(seeds),
				float(dsum.get("pour_ok", 0)) / float(seeds),
				float(dsum.get("pour_hot", 0)) / float(seeds),
				float(dsum.get("pour_spoiled", 0)) / float(seeds),
				float(dsum.get("pour_fizzle", 0)) / float(seeds)])
	print("")

func _encounter(name: String) -> EncounterRes:
	return AlchemistContent.make_leech() if name == "leech" else AlchemistContent.make_crucible()

func _run_one(seed: int, enc_name: String, latency: int, creed := "", module := "") -> Dictionary:
	var cfg := AlchemistContent.make_config()
	var acfg := AlchemistContent.make_alchemist_config()
	var s := AlchemistContent.make_state(seed, "brew", cfg, acfg, _encounter(enc_name))
	var kit := s.seats[0].kit as AlchemistKit
	if creed != "":
		kit.creed_id = creed                    # SLICE A: swear the posture
	if module != "":
		kit.modules = {module: true}            # SLICE B: install the module
	var pol := s.seats[0].policy as AlchemistPolicy
	pol.latency_ticks = latency
	pol.rng = DetRng.new(seed * 2749 + 4441)   # separate reproducible brew-aim stream
	return _run(s)

func _run(s: CombatState) -> Dictionary:
	var cap := int(TICK_CAP_SEC / s.dt)
	var pot_acc := 0.0
	var pot_samples := 0
	var peak_vessel := 0.0
	while not s.over and s.tick < cap:
		var seat := s.seats[0]
		if seat.policy != null and seat.alive():
			var a := seat.policy.act(CombatCore.observe(s, seat))
			if not a.is_empty():
				s.enqueue(s.tick + 1, seat, a)
		CombatCore.update(s)
		s.events.clear()
		pot_acc += float(seat.vars.get("potency", 0.0))
		pot_samples += 1
		peak_vessel = maxf(peak_vessel, float(seat.vars.get("vessel", 0.0)))
	if not s.over:
		s.loss_cause = "timeout"
	if s.loss_cause == "player_death" and s.encounter.enrage_at > 0.0 and s.time() >= s.encounter.enrage_at:
		s.loss_cause = "enraged"
	return {
		"won": s.won,
		"ttk_sec": s.time(),
		"boss_hp_left": s.boss.hp,
		"avg_potency": (pot_acc / float(pot_samples)) if pot_samples > 0 else 0.0,
		"peak_vessel": peak_vessel,
		"diag": s.diag,
		"loss_cause": s.loss_cause,
		"checksum": s.checksum,
	}

func _prove_determinism() -> void:
	var a := _run_one(1, "crucible", 0)
	var b := _run_one(1, "crucible", 0)
	var repro: bool = (a["checksum"] == b["checksum"]) and (a["ttk_sec"] == b["ttk_sec"])
	print("determinism check:")
	print("  Crucible      seed 1 == seed 1  -> %s   (checksum %d, TTK %.3fs, result %s)" % [
		("PASS" if repro else "FAIL"), a["checksum"], a["ttk_sec"],
		("win" if a["won"] else a["loss_cause"])])
	# cross-seed divergence at a sloppy tier (aim noise + boss jitter thread the seed)
	var c := _run_one(1, "leech", 14)
	var c2 := _run_one(2, "leech", 14)
	print("  Leech@sloppy  seed 1 vs seed 2  -> %s" % (
		"differ (good)" if c["checksum"] != c2["checksum"] else "IDENTICAL (suspect!)"))
	var d := _run_one(3, "leech", 6)
	var e := _run_one(3, "leech", 6)
	print("  Leech@good    seed 3 == seed 3  -> %s   (checksum %d, %s)" % [
		("PASS" if d["checksum"] == e["checksum"] else "FAIL"), d["checksum"],
		("win" if d["won"] else d["loss_cause"])])
	# a CREED run must also be deterministic (the posture modifiers are pure — no rng).
	var g := _run_one(5, "crucible", 6, "volatile_mix")
	var h := _run_one(5, "crucible", 6, "volatile_mix")
	print("  Volatile@good seed 5 == seed 5  -> %s   (checksum %d, %s)" % [
		("PASS" if g["checksum"] == h["checksum"] else "FAIL"), g["checksum"],
		("win" if g["won"] else g["loss_cause"])])
	# a MODULE run too (the Vessel banks float-heavy accumulation — assert it's reproducible).
	var i := _run_one(7, "crucible", 6, "", "reaction_vessel")
	var j := _run_one(7, "crucible", 6, "", "reaction_vessel")
	print("  Vessel@good   seed 7 == seed 7  -> %s   (checksum %d, %s)" % [
		("PASS" if i["checksum"] == j["checksum"] else "FAIL"), i["checksum"],
		("win" if i["won"] else i["loss_cause"])])

## SLICE B gate — each Module must produce a DISTINCT, sane profile and keep determinism.
## "" is the byte-identical base. Third Reagent = a small amp; Fermentation = auto-detonations;
## Reaction-Vessel = the cannon (0 reaction landings between big Rupture dumps).
func _module_ab(seeds: int, seed0: int) -> void:
	print("MODULE A/B — Crucible @ good lat6 (%d seeds/module):" % seeds)
	print("module            win-rate  avg TTK   ruptures(peak)  ferments  catalysts  peak-vessel")
	print("-----------------------------------------------------------------------------------------")
	for mod in ["", "third_reagent", "fermentation", "reaction_vessel"]:
		var wins := 0
		var ttk_sum := 0.0
		var dsum := {}
		var vessel_sum := 0.0
		for seed in range(seed0, seed0 + seeds):
			var r := _run_one(seed, "crucible", 6, "", mod)
			var rd: Dictionary = r.get("diag", {})
			for k in rd:
				dsum[k] = int(dsum.get(k, 0)) + int(rd[k])
			vessel_sum += float(r.get("peak_vessel", 0.0))
			if r["won"]:
				wins += 1; ttk_sum += float(r["ttk_sec"])
		var wr := 100.0 * float(wins) / float(seeds)
		var avg := (ttk_sum / float(wins)) if wins > 0 else 0.0
		var lbl: String = "(base)" if String(mod) == "" else String(mod)
		print("%-17s %6.1f%%   %7.1fs    %4.1f (%4.1f)     %5.1f     %5.1f      %7.0f" % [
			lbl, wr, avg,
			float(dsum.get("ruptures", 0)) / float(seeds),
			float(dsum.get("rupture_peak", 0)) / float(seeds),
			float(dsum.get("ferments", 0)) / float(seeds),
			float(dsum.get("catalysts", 0)) / float(seeds),
			vessel_sum / float(seeds)])
	print("")

## Pour-grade averages per run (the vial gradient: potent/hot should dominate expert,
## fizzle/spoiled should climb as the tier gets sloppy).
func _fmt_pours(d: Dictionary, seeds: int) -> String:
	var parts: Array = []
	for k in ["pour_potent", "pour_hot", "pour_ok", "pour_fizzle", "pour_spoiled"]:
		if d.has(k):
			parts.append("%s %.1f" % [k.substr(5), float(d[k]) / float(seeds)])
	return " · ".join(parts)

func _write_csv(path: String, rows: Array) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("cannot open %s" % path); return
	f.store_line("enc,skill,seed,won,ttk_sec,boss_hp_left,avg_potency,loss_cause,checksum")
	for r in rows:
		f.store_line("%s,%s,%d,%d,%.3f,%.1f,%.3f,%s,%d" % [
			r["enc"], r["skill"], r["seed"], (1 if r["won"] else 0),
			r["ttk_sec"], r["boss_hp_left"], r["avg_potency"], r["loss_cause"], r["checksum"]])
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
