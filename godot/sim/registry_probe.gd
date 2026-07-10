## Probe for the CLASS REGISTRY (REFIT P4): the one class_id → factory table.
## Locks the byte-exact policy seed salts (the old RaidNet.make_policy constants,
## via DetRng.state_hash), the seat-fallback dispatch semantics, seat construction
## (right kit, default aspects), and starter round-trips.
##   godot --headless --path godot --script res://sim/registry_probe.gd
extends SceneTree
func _initialize() -> void:
	var fails: Array = []

	# [1] the table covers the post-purge roster, one seat each
	_chk(fails, "healer pool", ClassRegistry.classes_for_seat("healer") == ["well", "bloomweaver"])
	_chk(fails, "tank pool", ClassRegistry.classes_for_seat("tank") == ["duelist"])
	_chk(fails, "blade pool", ClassRegistry.classes_for_seat("blade") == ["twinfang"])
	_chk(fails, "caster pool", ClassRegistry.classes_for_seat("caster") == ["alchemist"])
	_chk(fails, "seat_of unknown = ''", ClassRegistry.seat_of("voidcaller") == "")

	# [2] policy seed salts are BYTE-EXACT history (lockstep law — never drift)
	var salts := {"duelist": 6737, "twinfang": 2338, "alchemist": 3339, "well": 5531}
	for cls in salts:
		var p := ClassRegistry.make_policy(String(cls), 42)
		var want := DetRng.new(42 * 2749 + int(salts[cls])).state_hash()
		_chk(fails, "%s salt" % cls, p != null and p.rng != null and p.rng.state_hash() == want)
	_chk(fails, "bloomweaver no-rng quirk", ClassRegistry.make_policy("bloomweaver", 42) is BloomweaverPolicy)

	# [3] RaidNet.make_policy seat-fallback semantics (the exact old ladder)
	_chk(fails, "tank default", RaidNet.make_policy("tank", 7) is DuelistPolicy)
	_chk(fails, "healer bloom", RaidNet.make_policy("healer", 7, "bloomweaver") is BloomweaverPolicy)
	_chk(fails, "healer default", RaidNet.make_policy("healer", 7) is WellPolicy)
	_chk(fails, "wrong-seat cls falls back", RaidNet.make_policy("healer", 7, "alchemist") is WellPolicy)

	# [4] seat factories: right kit + default-aspect fill through the dispatchers
	var hb := RaidContent._healer_seat("bloomweaver", "")
	var hw := RaidContent._healer_seat("", "")
	var bl := RaidContent._blade_seat("", "")
	_chk(fails, "bloom seat kit", hb != null and hb.kit is BloomweaverKit)
	_chk(fails, "well seat kit (fallback)", hw != null and hw.kit is WellKit)
	_chk(fails, "blade venomancer default", bl != null and bl.kit is TwinfangKit and bl.vars.has("venom"))

	# [5] starters: registry start_run == the class's own starter, seeds equal
	var r1 := ClassRegistry.start_run("well", "brim", 99)
	var r2 := RunState.start_well("brim", 99)
	_chk(fails, "starter round-trip", r1.char_class == r2.char_class and r1.run_seed == r2.run_seed)
	_chk(fails, "unknown cls -> base starter", ClassRegistry.start_run("ghost", "x", 5).char_class == "duelist")

	for f in fails:
		print("  CHECK FAIL: %s" % f)
	print("REGISTRY PROBE: %s (%d checks)" % ["ALL OK" if fails.is_empty() else "FAIL", _n])
	quit(0 if fails.is_empty() else 1)

var _n := 0
func _chk(fails: Array, name: String, ok: bool) -> void:
	_n += 1
	if not ok:
		fails.append(name)
