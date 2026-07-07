## Headless Twinfang balance sim. Proves determinism, then runs the ported encounters
## (The Warden, The Executioner) for both Aspects across a skill sweep (reaction latency),
## printing win-rate bands + kill times + loss causes, and writing a CSV. This is the
## "the melee DPS works" milestone: an AI blade drives the rhythm, kicks the heals, and
## out-paces bosses built to grind it out — and skill (rhythm accuracy) moves TTK.
##
##   godot --headless --path godot --script res://sim/twinfang_sim.gd -- --seeds=300
extends SceneTree

const TICK_CAP_SEC := 180.0

var _open_default := true   # --open=off runs the whole sim as classic Twinfang (byte-identical baseline)

func _initialize() -> void:
	var seeds := int(_arg("seeds", "300"))
	var seed0 := int(_arg("seed0", "1"))   # seed shard offset (scripts/psim.sh); 1 = a full run
	_open_default = _arg("open", "on") != "off"
	print("*** DEPRECATED (2026-07-05): the SOLO bosses (Warden/Executioner) are retired 'old")
	print("*** trash' — do NOT tune the Tempo rework here. The GATE is res://sim/raid_sim.gd")
	print("*** (Seals: Mistral/Gemini/Mythos), Tempo blade via `--blade=tempo`. Kept only as a")
	print("*** fast local mechanics/determinism check for the shared kit. ***")
	print("")
	print("=== Project Rift — M5 Twinfang headless sim ===")
	print("Godot ", Engine.get_version_info().get("string", "?"), "  | ", seeds, " seeds/cell")
	print("")
	if seed0 == 1: _prove_determinism()
	print("")
	if seed0 == 1: _prove_verb_mods(seeds)
	print("")
	if seed0 == 1: _prove_opening(seeds)
	print("")
	if seed0 == 1: _prove_creed(seeds)
	print("")
	if seed0 == 1: _prove_modules(seeds)
	print("")
	if seed0 == 1: _prove_fermata(seeds)
	print("")
	if seed0 == 1: _prove_cards(seeds)

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
			for seed in range(seed0, seed0 + seeds):
				var r := _run_one(seed, String(m["enc"]), String(m["aspect"]), int(sk["lat"]), {}, _open_default)
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
				var sg := _fmt_strikes(dsum, seeds)
				if sg != "":
					print("              strike grades/run: %s" % sg)
				var op := _fmt_open(dsum, seeds)
				if op != "":
					print("              openings/run:    %s" % op)
		print("")

	_write_csv(_arg("out", "res://out/twinfang_results.csv"), rows)
	print("wrote %d rows -> %s" % [rows.size(), ProjectSettings.globalize_path(_arg("out", "res://out/twinfang_results.csv"))])
	quit()

func _encounter(name: String) -> EncounterRes:
	return TwinfangContent.make_executioner() if name == "executioner" else TwinfangContent.make_warden()

func _run_one(seed: int, enc_name: String, aspect: String, latency: int,
		boons: Dictionary = {}, open_on: bool = true, creed := "drumline", mods := {}) -> Dictionary:
	var cfg := TwinfangContent.make_config()
	var tcfg := TwinfangContent.make_twinfang_config()
	tcfg.open_enabled = open_on   # THE OPENING A/B: off = classic Twinfang (byte-identical baseline)
	var s := TwinfangContent.make_state(seed, aspect, cfg, tcfg, _encounter(enc_name), boons, creed, mods)
	var pol := s.seats[0].policy as TwinfangPolicy
	pol.latency_ticks = latency
	pol.rng = DetRng.new(seed * 2749 + 1337)   # separate reproducible beat-read stream
	var r := _run(s)
	r["verb_procs"] = int(s.seats[0].vars.get("verb_procs", 0))
	return r

## Phase B probe: the Rhythm mod pieces change the fight and stay deterministic.
## Paired seeds on the Executioner (venom @sloppy) — boonless vs a modded build.
func _prove_verb_mods(seeds: int) -> void:
	var n := mini(seeds, 120)
	var mods := {"tfTrigEvade": true, "tfTrigSpender": true, "tfPayLash": true,
		"tfPayEnergy": true, "tfPropTwinStep": true}
	var bw := 0
	var mw := 0
	var procs := 0.0
	for seed in range(1, n + 1):
		var a := _run_one(seed, "executioner", "venomancer", 14)
		var b := _run_one(seed, "executioner", "venomancer", 14, mods)
		procs += float(b["verb_procs"])
		if a["won"]: bw += 1
		if b["won"]: mw += 1
	var d1 := _run_one(17, "executioner", "venomancer", 14, mods)
	var d2 := _run_one(17, "executioner", "venomancer", 14, mods)
	var det: bool = d1["checksum"] == d2["checksum"]
	print("rhythm-mods probe (Executioner / venom @sloppy, %d paired seeds):" % n)
	print("  boonless %.1f%%   modded %.1f%%   procs/run %.1f   det %s  -> %s" % [
		100.0 * bw / n, 100.0 * mw / n, procs / n, ("PASS" if det else "FAIL"),
		("PASS" if (mw >= bw and procs > 0.0 and det) else "FAIL")])
	print("")

## THE OPENING probe: A/B the vulnerability-window verb ON vs OFF (Tempo / Executioner)
## across the skill sweep. Proves it engages (peaks land), moves DPS (faster TTK on),
## preserves the gradient (expert punishes the peak, sloppy misses the window), and stays
## deterministic. Off == classic Twinfang (the byte-identical baseline verified separately).
func _prove_opening(seeds: int) -> void:
	var n := mini(seeds, 120)
	print("THE OPENING probe (Tempo / Executioner, %d paired seeds — off vs on):" % n)
	print("  skill    off-win  on-win   off-TTK  on-TTK   peaks/run hits/run whiff/run")
	for row in [{"l": "expert", "v": 0}, {"l": "good", "v": 6}, {"l": "sloppy", "v": 14}]:
		var lat := int(row["v"])
		var offw := 0; var onw := 0
		var offttk := 0.0; var onttk := 0.0; var offn := 0; var onn := 0
		var pk := 0.0; var ht := 0.0; var wf := 0.0
		for seed in range(1, n + 1):
			var a := _run_one(seed, "executioner", "tempo", lat, {}, false)
			var b := _run_one(seed, "executioner", "tempo", lat, {}, true)
			if a["won"]: offw += 1; offttk += float(a["ttk_sec"]); offn += 1
			if b["won"]: onw += 1; onttk += float(b["ttk_sec"]); onn += 1
			var bd: Dictionary = b.get("diag", {})
			pk += float(bd.get("open_peak", 0)); ht += float(bd.get("open_hit", 0))
			wf += float(bd.get("open_whiff", 0))
		print("  %-7s  %5.1f%%  %5.1f%%   %6.1fs  %6.1fs   %6.2f   %6.2f   %6.2f" % [
			row["l"], 100.0 * offw / n, 100.0 * onw / n,
			(offttk / offn if offn > 0 else 0.0), (onttk / onn if onn > 0 else 0.0),
			pk / n, ht / n, wf / n])
	var d1 := _run_one(17, "executioner", "tempo", 6, {}, true)
	var d2 := _run_one(17, "executioner", "tempo", 6, {}, true)
	print("  determinism (openings on): %s" % ("PASS" if d1["checksum"] == d2["checksum"] else "FAIL"))

## TEMPO REWORK probe: the CREED risk gradient (Tempo / Executioner). Drumline (steady, −2
## Flow/slip) vs Flourish (glass, Flow→0/slip but +50% Flow value). Proves the two feel
## different across skill — glass rewards clean play and punishes sloppy — and stays det.
func _prove_creed(seeds: int) -> void:
	var n := mini(seeds, 120)
	print("CREED probe (Tempo / Executioner, %d seeds — the risk gradient):" % n)
	print("  skill    drumline-win  flourish-win   drum-TTK  flour-TTK   slips/run(flour)")
	for row in [{"l": "expert", "v": 0}, {"l": "good", "v": 6}, {"l": "sloppy", "v": 14}]:
		var lat := int(row["v"])
		var dw := 0; var fw := 0; var dt := 0.0; var ft := 0.0; var dn := 0; var fn := 0; var slips := 0.0
		for seed in range(1, n + 1):
			var d := _run_one(seed, "executioner", "tempo", lat, {}, true, "drumline")
			var f := _run_one(seed, "executioner", "tempo", lat, {}, true, "flourish")
			if d["won"]: dw += 1; dt += float(d["ttk_sec"]); dn += 1
			if f["won"]: fw += 1; ft += float(f["ttk_sec"]); fn += 1
			slips += float((f.get("diag", {}) as Dictionary).get("slip", 0))
		print("  %-7s  %6.1f%%      %6.1f%%     %6.1fs   %6.1fs      %6.2f" % [
			row["l"], 100.0 * dw / n, 100.0 * fw / n,
			(dt / dn if dn > 0 else 0.0), (ft / fn if fn > 0 else 0.0), slips / n])
	var a := _run_one(17, "executioner", "tempo", 6, {}, true, "flourish")
	var b := _run_one(17, "executioner", "tempo", 6, {}, true, "flourish")
	print("  determinism (flourish): %s" % ("PASS" if a["checksum"] == b["checksum"] else "FAIL"))
	var lg1 := _run_one(17, "executioner", "tempo", 6, {}, true, "largo")
	var lg2 := _run_one(17, "executioner", "tempo", 6, {}, true, "largo")
	print("  LARGO (slow & sharp): won %s  ttk %.1fs  determinism %s" % [str(lg1["won"]), float(lg1["ttk_sec"]), ("PASS" if lg1["checksum"] == lg2["checksum"] else "FAIL")])

## TEMPO REWORK probe: the MODULES engage + stay deterministic (Tempo / Executioner @good).
## None (base) vs The Edge (tighter window, bigger Perfects) vs The Deathmark (mark → detonate).
func _prove_modules(seeds: int) -> void:
	var n := mini(seeds, 100)
	print("MODULE probe (Tempo / Executioner @EXPERT — Overdrive needs sustained max Flow, %d seeds):" % n)
	var cells := [{"l": "none", "m": {}}, {"l": "overdrive", "m": {"overdrive": true}}]
	for c in cells:
		var w := 0; var ttk := 0.0; var wn := 0; var fv := 0.0
		for seed in range(1, n + 1):
			var r := _run_one(seed, "executioner", "tempo", 0, {}, true, "drumline", c["m"])
			if r["won"]: w += 1; ttk += float(r["ttk_sec"]); wn += 1
			fv += float((r.get("diag", {}) as Dictionary).get("fever", 0))
		print("  %-10s win %5.1f%%  ttk %5.1fs  fevers/run %.2f" % [
			c["l"], 100.0 * w / n, (ttk / wn if wn > 0 else 0.0), fv / n])
	var d1 := _run_one(9, "executioner", "tempo", 6, {}, true, "drumline", {"overdrive": true})
	var d2 := _run_one(9, "executioner", "tempo", 6, {}, true, "drumline", {"overdrive": true})
	print("  determinism (overdrive): %s" % ("PASS" if d1["checksum"] == d2["checksum"] else "FAIL"))

## FERMATA (§13) probe: the hold-release aspect engages (releases land, unravels stay rare),
## the coil creeds/modules/boons move the fight, and every path stays deterministic. Base fermata
## runs on the "drumline" creed (a neutral baseline — no coil-specific creed effects).
func _prove_fermata(seeds: int) -> void:
	var n := mini(seeds, 100)
	print("FERMATA probe (Tempo-family / Executioner @good — the hold-release aspect, %d seeds):" % n)
	var cells := [
		{"l": "base",     "c": "drumline",  "m": {},                    "b": {}},
		{"l": "patient",  "c": "patient",   "m": {},                    "b": {}},
		{"l": "fleeting", "c": "fleeting",  "m": {},                    "b": {}},
		{"l": "longnight","c": "longnight", "m": {},                    "b": {}},
		{"l": "tutti",    "c": "tutti",     "m": {},                    "b": {}},
		{"l": "dance",    "c": "drumline",  "m": {"shadowdance": true}, "b": {}},
		{"l": "mark",     "c": "drumline",  "m": {"mark": true},        "b": {"eviPlus": true}},
		{"l": "roll",     "c": "drumline",  "m": {},                    "b": {"stretto": true, "refrain": true}},
		{"l": "ride",     "c": "drumline",  "m": {},                    "b": {"coldCut": true, "theBrink": true, "killingWhisper": true}},
		{"l": "rest",     "c": "drumline",  "m": {},                    "b": {"composure": true, "firstNote": true}},
		{"l": "unseen",   "c": "patient",   "m": {},                    "b": {"unseenBlade": true}},
		{"l": "veil",     "c": "drumline",  "m": {},                    "b": {"vanish": true, "restlessDark": true}},
		{"l": "crit",     "c": "drumline",  "m": {},                    "b": {"hone": true, "heartseeker": true, "serrated": true}},
	]
	print("  cell       skill    win     ttk     bull/run  perf/run  snap/run")
	for c in cells:
		for sk in [{"l": "expert", "v": 0}, {"l": "good", "v": 6}, {"l": "sloppy", "v": 14}]:
			var w := 0; var ttk := 0.0; var wn := 0; var bull := 0.0; var perf := 0.0; var snp := 0.0
			for seed in range(1, n + 1):
				var r := _run_one(seed, "executioner", "fermata", int(sk["v"]), c["b"], true, String(c["c"]), c["m"])
				if r["won"]: w += 1; ttk += float(r["ttk_sec"]); wn += 1
				var rd: Dictionary = r.get("diag", {})
				bull += float(rd.get("s_bull", 0)); perf += float(rd.get("s_perfect", 0)); snp += float(rd.get("snap", 0))
			print("  %-9s %-7s %5.1f%%  %5.1fs   %6.2f    %6.2f     %6.2f" % [
				c["l"], sk["l"], 100.0 * w / n, (ttk / wn if wn > 0 else 0.0), bull / n, perf / n, snp / n])
	var fatb := {"unseenBlade": true, "theBrink": true, "coldCut": true, "killingWhisper": true, "twinEcho": true, "refrain": true}
	var d1 := _run_one(9, "executioner", "fermata", 6, fatb, true, "patient", {"mark": true})
	var d2 := _run_one(9, "executioner", "fermata", 6, fatb, true, "patient", {"mark": true})
	print("  determinism (fat fermata build): %s" % ("PASS" if d1["checksum"] == d2["checksum"] else "FAIL"))
	var b1 := _run_one(4, "executioner", "fermata", 6, {}, true, "drumline")
	var b2 := _run_one(4, "executioner", "fermata", 6, {}, true, "drumline")
	print("  determinism (base fermata):      %s" % ("PASS" if b1["checksum"] == b2["checksum"] else "FAIL"))

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

## THE OPENING per-run averages (peak / hit-window / whiffed-dump).
func _fmt_open(d: Dictionary, seeds: int) -> String:
	var parts: Array = []
	for k in ["open_peak", "open_hit", "open_whiff"]:
		if d.has(k):
			parts.append("%s %.2f" % [k.substr(5), float(d[k]) / float(seeds)])
	return " · ".join(parts)

## TEMPO REWORK · new-slate probe: representative card builds engage + stay deterministic
## (Tempo / Executioner @good). Bare vs crit vs greed/flow vs window vs eviscerate packages.
func _prove_cards(seeds: int) -> void:
	var n := mini(seeds, 100)
	print("NEW-SLATE probe (Tempo / Executioner @good, %d seeds — the reworked draft):" % n)
	var cells := [
		{"l": "bare", "b": {}},
		{"l": "crit", "b": {"hone": true, "heartseeker": true, "serrated": true, "assassinsNote": true}},
		{"l": "greed", "b": {"tightrope": true, "shatterfall": true, "doubleTime": true, "flowCap": true}},
		{"l": "window", "b": {"wideTempo": true, "fencersLine": true, "rubato": true}},
		{"l": "evisc", "b": {"eviPlus": true, "overkill": true, "staccato": true, "execute": true}},
		{"l": "strike", "b": {"pressAdvantage": true, "coldOpen": true, "throughline": true}},
		{"l": "guard", "b": {"understudy": true, "battleHymn": true}},
	]
	for c in cells:
		var w := 0; var ttk := 0.0; var wn := 0; var bull := 0.0
		for seed in range(1, n + 1):
			var r := _run_one(seed, "executioner", "tempo", 6, c["b"])
			if r["won"]: w += 1; ttk += float(r["ttk_sec"]); wn += 1
			bull += float((r.get("diag", {}) as Dictionary).get("s_bull", 0))
		print("  %-8s win %5.1f%%  ttk %5.1fs  bullseyes/run %.2f" % [
			c["l"], 100.0 * w / n, (ttk / wn if wn > 0 else 0.0), bull / n])
	var mix := {"hone": true, "heartseeker": true, "serrated": true, "assassinsNote": true,
		"tightrope": true, "doubleTime": true, "wideTempo": true, "overkill": true, "staccato": true,
		"execute": true, "rubato": true, "throughline": true, "understudy": true}
	var d1 := _run_one(9, "executioner", "tempo", 6, mix)
	var d2 := _run_one(9, "executioner", "tempo", 6, mix)
	print("  determinism (fat mixed build): %s" % ("PASS" if d1["checksum"] == d2["checksum"] else "FAIL"))

## Strike-timing grade averages per run (the graded window §2c: Bullseye/Perfect/Good/Miss).
func _fmt_strikes(d: Dictionary, seeds: int) -> String:
	var parts: Array = []
	for k in ["s_bull", "s_perfect", "s_good", "s_miss"]:
		if d.has(k):
			parts.append("%s %.1f" % [k.substr(2), float(d[k]) / float(seeds)])
	return " · ".join(parts)

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
	var repro: bool = (a["checksum"] == b["checksum"]) and (a["ttk_sec"] == b["ttk_sec"])
	print("determinism check:")
	print("  Warden/Tempo  seed 1 == seed 1  -> %s   (checksum %d, TTK %.3fs, result %s)" % [
		("PASS" if repro else "FAIL"), a["checksum"], a["ttk_sec"], ("win" if a["won"] else a["loss_cause"])])
	# Cross-seed divergence uses VENOMANCER: its contagion RNG threads the seed, so runs
	# genuinely diverge. (An expert Tempo/Warden clear is now FLAWLESS — the boss never
	# heals and no hit lands — so its boss-HP checksum is legitimately seed-independent,
	# making it a poor divergence probe. Same-seed reproducibility still holds everywhere,
	# and sloppy Tempo / all Venom cells vary across seeds — the seed IS threaded.)
	var c := _run_one(1, "executioner", "venomancer", 6)
	var c2 := _run_one(2, "executioner", "venomancer", 6)
	print("  Venom         seed 1 vs seed 2  -> %s" % (
		"differ (good)" if c["checksum"] != c2["checksum"] else "IDENTICAL (suspect!)"))
	# venomancer path exercises contagion RNG + poison ticks — reproducibility check
	var d := _run_one(3, "executioner", "venomancer", 0)
	var e := _run_one(3, "executioner", "venomancer", 0)
	print("  Venom         seed 3 == seed 3  -> %s   (checksum %d, %s)" % [
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
