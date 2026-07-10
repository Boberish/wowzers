## well_sim — balance loop for the reworked direct-cast healer (MENDER-PLAN.md).
## Both aspects (brim/draw) × 3 skill tiers × N seeds against two raid-style encounters.
## Measures the skill gradient (win-rate, kill time, deaths) and the class's economy
## (pours, Glint uptime, charge floor). Determinism proven on shard 0.
##
## Run:  godot --headless --path godot --script res://sim/well_sim.gd -- --seeds=300
## Shard: scripts/psim.sh well_sim 300 8
extends SceneTree

const TICK_CAP_SEC := 260.0

# Representative DECKs (creed + a module + a spread of boons + a wired rig) — exercised by
# --load so the deck bands can be read + proven deterministic. Empty otherwise (base bands).
static func _deck_for(aspect: String) -> Dictionary:
	if aspect == "draw":
		return {"creed": "longdraw", "modules": {"benediction": true}, "rig": {"when": "clean_draw", "then": "mend"}}
	return {"creed": "brink", "modules": {"reservoir": true}, "rig": {"when": "sweet_pour", "then": "gleam"}}

static func _boons_for(aspect: String) -> Dictionary:
	if aspect == "draw":
		return {"strongPull": true, "theMillrace": true, "doubleDraw": true,
			"deepStill": true, "deepWell": true, "shiningHour": true}
	return {"keptLight": true, "wideBrim": true, "secondRing": true, "highTide": true,
		"lowCatch": true, "stillWater": true, "shiningHour": true, "deepWell": true}

## The D6 theme builds (draw only) — exercised by --build=vigil|rapids|eddy so each lane's
## cards are proven deterministic and its skill gradient reads. Empty build ⇒ the base bands.
static func _build_deck(build: String) -> Dictionary:
	match build:
		"vigil":  return {"creed": "patient", "modules": {"vigil": true}, "rig": {"when": "clean_draw", "then": "ward"}}
		"rapids": return {"creed": "narrows", "modules": {}, "rig": {"when": "high_water", "then": "mend"}}
		"eddy":   return {"creed": "eddy", "modules": {}, "rig": {"when": "still_point", "then": "gleam"}}
	return {}

static func _build_boons(build: String) -> Dictionary:
	match build:
		"vigil":  return {"secondHand": true, "rideTremble": true, "loosedAtLast": true, "lastDrops": true, "deepWell": true}
		"rapids": return {"whitewater": true, "shootGap": true, "eddyline": true, "strongPull": true, "flume": true, "theMillrace": true}
		"eddy":   return {"currentReading": true, "deepEddy": true, "deepStill": true, "glassRiver": true, "deepWell": true}
	return {}

func _initialize() -> void:
	var seeds := SimUtil.arg_int("seeds", 200)
	var seed0 := SimUtil.arg_int("seed0", 1)
	var out := SimUtil.arg("out", "")
	var load := SimUtil.arg("load", "0") != "0"   # --load=1 : run the cells with a representative deck
	var build := SimUtil.arg("build", "")          # --build=vigil|rapids|eddy : a D6 theme build (draw)

	if seed0 == 1:
		_prove_determinism()
		_prove_determinism_deck()
		if build != "":
			_prove_determinism_build(build)

	var encs := ["maw", "rot"]
	var aspects := (["draw"] if build != "" else ["brim", "draw"])
	var skills := [
		{"label": "expert", "lat": 0},
		{"label": "good", "lat": 6},
		{"label": "sloppy", "lat": 14},
	]

	var tag := ("  [BUILD=%s]" % build) if build != "" else ("  [LOADED DECK]" if load else "")
	print("\n=== WELL — %d seeds/cell (seed0=%d)%s ===" % [seeds, seed0, tag])
	print("%-8s %-7s %-7s  win%%   ttk    pours/min glint%%  chgFloor deaths skin/min defer" % ["boss", "aspect", "skill"])
	var rows: Array = []
	for enc_name in encs:
		for aspect in aspects:
			var bo: Dictionary = _build_boons(build) if build != "" else (_boons_for(aspect) if load else {})
			var dk: Dictionary = _build_deck(build) if build != "" else (_deck_for(aspect) if load else {})
			for sk in skills:
				var wins := 0
				var ttk_sum := 0.0
				var pours_sum := 0.0
				var glint_sum := 0.0
				var chg_sum := 0.0
				var deaths := 0
				var skin_sum := 0.0
				var defer_sum := 0.0
				for seed in range(seed0, seed0 + seeds):
					var r := _run_one(seed, enc_name, aspect, int(sk["lat"]), bo, dk)
					if r["won"]:
						wins += 1
						ttk_sum += r["ttk_sec"]
					pours_sum += r["pours_per_min"]
					glint_sum += r["glint_pct"]
					chg_sum += r["chg_floor"]
					deaths += r["deaths"]
					skin_sum += r["skins_per_min"]
					defer_sum += r["deferred"]
					rows.append("%s,%s,%s,%d,%d,%.1f,%.3f,%.3f,%d,%d,%.2f,%.0f" % [
						enc_name, aspect, sk["label"], seed, (1 if r["won"] else 0),
						r["ttk_sec"], r["pours_per_min"], r["glint_pct"], r["chg_floor"], r["deaths"],
						r["skins_per_min"], r["deferred"]])
				var n := float(seeds)
				var wr := 100.0 * float(wins) / n
				var ttk := (ttk_sum / float(wins)) if wins > 0 else 0.0
				print("%-8s %-7s %-7s  %5.1f  %5.1f   %6.1f   %5.1f   %5.1f    %d   %5.2f  %5.0f" % [
					enc_name, aspect, sk["label"], wr, ttk,
					pours_sum / n, 100.0 * glint_sum / n, chg_sum / n, deaths,
					skin_sum / n, defer_sum / n])

	if out != "":
		_write_csv(out, rows)
	quit()

func _prove_determinism() -> void:
	print("--- determinism (base, deckless) ---")
	for aspect in ["brim", "draw"]:
		var a := _run_one(1, "maw", aspect, 0)
		var b := _run_one(1, "maw", aspect, 0)
		var repro: bool = a["checksum"] == b["checksum"] and a["ttk_sec"] == b["ttk_sec"]
		var c := _run_one(2, "maw", aspect, 0)
		var diverge: bool = c["checksum"] != a["checksum"]
		print("  %-5s  seed1==seed1 -> %s (checksum %d)   seed1 vs seed2 -> %s" % [
			aspect, ("PASS" if repro else "FAIL"), a["checksum"],
			("differ (good)" if diverge else "IDENTICAL (suspect!)")])

## Prove a FULLY LOADED deck (creed + module + boons + rig) is still deterministic — the
## guarded deck layers must not smuggle in any RNG/wall-clock (the CombatCore law).
func _prove_determinism_deck() -> void:
	print("--- determinism (loaded deck: creed + module + boons + rig) ---")
	for aspect in ["brim", "draw"]:
		var bo := _boons_for(aspect)
		var dk := _deck_for(aspect)
		var a := _run_one(1, "maw", aspect, 0, bo, dk)
		var b := _run_one(1, "maw", aspect, 0, bo, dk)
		var repro: bool = a["checksum"] == b["checksum"] and a["ttk_sec"] == b["ttk_sec"]
		print("  %-5s  deck seed1==seed1 -> %s (checksum %d)" % [
			aspect, ("PASS" if repro else "FAIL"), a["checksum"]])

## Prove a D6 theme build (creed + module + its boons + rig) is deterministic — the reshape's
## new guarded layers must smuggle in no RNG/wall-clock (the CombatCore law).
func _prove_determinism_build(build: String) -> void:
	print("--- determinism (D6 build: %s) ---" % build)
	var bo := _build_boons(build)
	var dk := _build_deck(build)
	var a := _run_one(1, "maw", "draw", 0, bo, dk)
	var b := _run_one(1, "maw", "draw", 0, bo, dk)
	var repro: bool = a["checksum"] == b["checksum"] and a["ttk_sec"] == b["ttk_sec"]
	print("  %-6s build seed1==seed1 -> %s (checksum %d)" % [
		build, ("PASS" if repro else "FAIL"), a["checksum"]])

func _run_one(seed: int, enc_name: String, aspect: String, latency: int,
		boons: Dictionary = {}, deck: Dictionary = {}) -> Dictionary:
	var cfg := WellContent.make_config()
	var wcfg := WellContent.make_well_config()
	var s := WellContent.make_state(seed, aspect, cfg, wcfg, _encounter(enc_name), boons, deck)
	var pol := s.seats[0].policy as WellPolicy
	pol.latency_ticks = latency
	pol.rng = DetRng.new(seed * 2749 + 4441)          # separate reproducible skill stream
	return _run(s, wcfg)

func _run(s: CombatState, wcfg: WellConfig) -> Dictionary:
	var cap := int(TICK_CAP_SEC / s.dt)
	var pours := 0
	var glint_ticks := 0
	var chg_floor := wcfg.charges_max
	var deaths := 0
	var skins := 0
	while not s.over and s.tick < cap:
		var seat := s.seats[0]
		if seat.policy != null and seat.alive():
			var a := seat.policy.act(CombatCore.observe(s, seat))
			if not a.is_empty():
				s.enqueue(s.tick + 1, seat, a)
		CombatCore.update(s)
		# metrics (read-only; must not touch state → checksum stays byte-stable)
		for ev in s.events:
			var t := String(ev.get("t", ""))
			if t == "well_pour" or t == "well_still":
				pours += 1
			elif t == "well_skin":
				skins += 1
			elif t == "revive":
				pass
			elif t == "hurt" and int(ev.get("amt", 0)) > 0 and ev.get("seat") != null \
					and not (ev["seat"] as Seat).alive():
				deaths += 1
		var glinted := false
		for i in s.seats.size():   # GLINT rides the vulnerability stack now (REFIT P4)
			if CombatCore.vuln_until(s, i, &"glint") >= 0:
				glinted = true
				break
		if glinted:
			glint_ticks += 1
		var ch := int(seat.vars.get("charges", 0))
		if ch < chg_floor:
			chg_floor = ch
		s.events.clear()
	var ttk := s.tick * s.dt
	var won := s.over and s.boss.hp <= 0.0
	return {
		"won": won,
		"ttk_sec": ttk,
		"pours_per_min": 60.0 * float(pours) / maxf(1.0, ttk),
		"glint_pct": float(glint_ticks) / maxf(1.0, float(s.tick)),
		"chg_floor": float(chg_floor),
		"deaths": deaths,
		"skins_per_min": 60.0 * float(skins) / maxf(1.0, ttk),
		"deferred": float(s.seats[0].vars.get("skin_deferred", 0.0)),
		"checksum": s.checksum,
	}

func _encounter(name: String) -> EncounterRes:
	if name == "rot":
		return WellContent.make_attrition()
	return WellContent.make_spike()

func _write_csv(path: String, rows: Array) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.store_line("boss,aspect,skill,seed,won,ttk_sec,pours_per_min,glint_pct,chg_floor,deaths,skins_per_min,deferred")
	for r in rows:
		f.store_line(String(r))
	f.close()

