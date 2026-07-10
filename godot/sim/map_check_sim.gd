## Headless acceptance gate for the Inference Check (MASTER-PLAN §MAPS · deep events).
##   godot --headless --path godot --script res://sim/map_check_sim.gd
## Proves the roll layer is deterministic, machine-agnostic, monotone, clamped, and in
## its tuning bands — WITHOUT ever entering a map fingerprint (the die is its own rng).
extends SceneTree

func _initialize() -> void:
	var fails := 0
	print("=== Project Rift — Inference Check sim ===")
	fails += _die_determinism()
	fails += _monotonicity()
	fails += _clamp()
	fails += _bands()
	fails += _anti_frustration()
	fails += _nudge()
	fails += _gates()
	print("")
	print("MAP CHECK SIM: %s" % ("ALL PASS" if fails == 0 else "%d FAILURES" % fails))
	quit(0 if fails == 0 else 1)

# --- synthetic builds -----------------------------------------------------------
func _ctx(n_guard: int, aspect := "warden", role := "tank", fails := 0,
		frac := 1.0, entropy := 0, inv := {}, flags := {}, tokens := 0) -> Dictionary:
	var bt: Array = []
	for i in n_guard:
		bt.append(["guard"])
	return MapCheck.build_ctx(bt, [], aspect, role, frac, entropy, fails, inv, flags, tokens)

const FORCE := {"verb": "FORCE", "tags": ["guard"], "role": "tank", "aspects": ["warden"],
	"base": 25, "per": 12, "cap": 5}

# --- 1. the die is a pure function -----------------------------------------------
func _die_determinism() -> int:
	var h1 := ""
	var h2 := ""
	for ms in [1, 7, 1000, 0x5EED]:
		for node in range(0, 6):
			for ci in range(0, 4):
				for at in range(0, 3):
					var r := MapCheck.roll(ms, node, ci, at)
					h1 += "%.6f|" % r
					h2 += "%.6f|" % MapCheck.roll(ms, node, ci, at)
	var ok := h1 == h2 and h1.length() > 0
	# a distinct (seed,node,choice,attempt) gives a distinct draw (not all identical)
	var distinct := MapCheck.roll(1, 0, 0, 0) != MapCheck.roll(1, 0, 0, 1) \
		and MapCheck.roll(1, 0, 0, 0) != MapCheck.roll(2, 0, 0, 0)
	# the die is ~uniform: empirical pass-rate over a big matrix tracks p
	var p := 60
	var hitc := 0
	var tot := 0
	for ms in range(1, 401):
		for node in range(0, 6):
			for ci in range(0, 4):
				tot += 1
				if MapCheck.roll(ms, node, ci, 0) < float(p):
					hitc += 1
	var rate := 100.0 * hitc / tot
	var uniform := absf(rate - p) < 3.0
	print("1. die determinism: identical-replay %s · attempt/seed vary %s · uniform(p=60→%.1f%%) %s" % [
		_b(ok), _b(distinct), rate, _b(uniform)])
	return 0 if (ok and distinct and uniform) else 1

# --- 2. monotonic in build strength ----------------------------------------------
func _monotonicity() -> int:
	var last := -1
	var mono := true
	for k in range(0, 8):                     # 0..7 guard boons (cap 5 flattens after)
		var p := int(MapCheck.chance(FORCE, _ctx(k))["p"])
		if p < last:
			mono = false
		last = p
	# aspect + role each add exactly once
	var base_only := int(MapCheck.chance(FORCE, _ctx(0, "jugg", "blade"))["p"])   # no aspect/role
	var with_aspect := int(MapCheck.chance(FORCE, _ctx(0, "warden", "blade"))["p"])
	var with_role := int(MapCheck.chance(FORCE, _ctx(0, "jugg", "tank"))["p"])
	var both := int(MapCheck.chance(FORCE, _ctx(0, "warden", "tank"))["p"])
	var adds := (with_aspect - base_only == 15) and (with_role - base_only == 15) \
		and (both - base_only == 30)
	# SELF reads the LARGEST single-tag cluster, not a sum
	var self_chk := {"tags": ["SELF"], "base": 20, "per": 10, "cap": 5}
	var mixed := MapCheck.build_ctx([["guard"], ["guard"], ["rage"]], [], "warden", "tank", 1.0, 0, 0, {}, {}, 0)
	var self_s := int(MapCheck.chance(self_chk, mixed)["strength"])
	print("2. monotonicity: build-strength %s · aspect/role add once %s · SELF=max-cluster(2) %s" % [
		_b(mono), _b(adds), _b(self_s == 2)])
	return 0 if (mono and adds and self_s == 2) else 1

# --- 3. clamp bounds --------------------------------------------------------------
func _clamp() -> int:
	# a fully-stacked build + max pity + nudge still can't exceed the ceiling (V#8: no prior)
	var maxed := int(MapCheck.chance(FORCE, _ctx(9, "warden", "tank", 9), 3)["p"])
	# a fully off-build (0 tags, wrong aspect/role, on a check with a punishing floor)
	var off := int(MapCheck.chance({"tags": ["momentum"], "base": 25, "floor": 5, "ceil": 95},
		_ctx(0, "warden", "tank"))["p"])
	var ok := maxed <= 95 and off >= 5 and off <= 95
	print("3. clamp: fully-stacked=%d ≤95 %s · off-build=%d ∈[5,95] %s" % [
		maxed, _b(maxed <= 95), off, _b(off >= 5)])
	return 0 if ok else 1

# --- 4. tuning bands (the contract) ----------------------------------------------
func _bands() -> int:
	var off := int(MapCheck.chance(FORCE, _ctx(0, "jugg", "blade"))["p"])          # off-build
	var light := int(MapCheck.chance(FORCE, _ctx(2, "jugg", "blade"))["p"])        # 2 tags only
	var on := int(MapCheck.chance(FORCE, _ctx(3, "warden", "blade"))["p"])         # themed + aspect, generalist seat (the hero-readout 76% case)
	var specialist := int(MapCheck.chance(FORCE, _ctx(3, "warden", "tank"))["p"])  # + the right role steps up
	var off_ok := off >= 20 and off <= 45
	var on_ok := on >= 65 and on <= 85
	var spec_ok := specialist >= 85 and specialist <= 95                          # the specialist reward, never certain
	var spread_ok := on - off >= 30                                               # build MATTERS
	print("4. bands: off=%d [20-45]%s · light=%d · themed+aspect=%d [65-85]%s · +specialist=%d [85-95]%s · spread=%d ≥30%s" % [
		off, _b(off_ok), light, on, _b(on_ok), specialist, _b(spec_ok), on - off, _b(spread_ok)])
	return 0 if (off_ok and on_ok and spec_ok and spread_ok) else 1

# --- 5. comeback pity (anti-frustration) -----------------------------------------
func _anti_frustration() -> int:
	var p0 := int(MapCheck.chance(FORCE, _ctx(1, "jugg", "blade", 0))["p"])
	var p_streak := []
	for f in range(0, 6):
		p_streak.append(int(MapCheck.chance(FORCE, _ctx(1, "jugg", "blade", f))["p"]))
	var rises: bool = int(p_streak[4]) > int(p_streak[0])
	var capped: bool = (int(p_streak[4]) - int(p_streak[0])) == 32 and (int(p_streak[5]) - int(p_streak[0])) == 32   # +8×4 cap 32
	print("5. anti-frustration: fail-streak lifts %d→%d %s · pity capped at +32 %s" % [
		p_streak[0], p_streak[4], _b(rises), _b(capped)])
	return 0 if (rises and capped) else 1

# --- 6. ⚡ nudge -----------------------------------------------------------------
func _nudge() -> int:
	var c := _ctx(2, "jugg", "blade")
	var p0 := int(MapCheck.chance(FORCE, c, 0)["p"])
	var p1 := int(MapCheck.chance(FORCE, c, 1)["p"])
	var p3 := int(MapCheck.chance(FORCE, c, 3)["p"])
	var p9 := int(MapCheck.chance(FORCE, c, 9)["p"])              # over-max clamps at 3 pts
	var ok := (p1 - p0 == 8) and (p3 - p0 == 24) and (p9 == p3)
	var ladder := MapCheck.nudge_ladder(FORCE, _ctx(2, "jugg", "blade", 0, 1.0, 4))
	print("6. nudge: +8/pt %s · caps at 3 pts (%d==%d) %s · ladder(⚡4)=%s" % [
		_b(p1 - p0 == 8), p9, p3, _b(p9 == p3), str(ladder)])
	return 0 if ok else 1

# --- 7. gates --------------------------------------------------------------------
func _gates() -> int:
	var have_key := _ctx(0, "warden", "tank", 0, 1.0, 0, {"api_key": true})
	var no_key := _ctx(0, "warden", "tank")
	var ok := MapCheck.gate_ok({"item": "api_key"}, have_key) \
		and not MapCheck.gate_ok({"item": "api_key"}, no_key) \
		and MapCheck.gate_ok({"tags": ["guard"], "min": 2}, _ctx(2)) \
		and not MapCheck.gate_ok({"tags": ["guard"], "min": 3}, _ctx(2)) \
		and MapCheck.gate_ok({"aspect": "warden"}, _ctx(0, "warden")) \
		and not MapCheck.gate_ok({"aspect": "jugg"}, _ctx(0, "warden")) \
		and MapCheck.gate_ok({"entropy": 3}, _ctx(0, "warden", "tank", 0, 1.0, 3)) \
		and not MapCheck.gate_ok({"entropy": 3}, _ctx(0, "warden", "tank", 0, 1.0, 2)) \
		and MapCheck.gate_ok({"flag": "covered_shift"}, _ctx(0, "warden", "tank", 0, 1.0, 0, {}, {"covered_shift": true}))
	print("7. gates: item/tags/aspect/entropy/flag all resolve %s (prior gate died with V#8)" % _b(ok))
	return 0 if ok else 1

func _b(v: bool) -> String:
	return "PASS" if v else "FAIL"
