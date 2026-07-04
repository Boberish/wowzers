## Focused probe for P6 FIGHT-ALTERING MARKS: a carry `mark` sabotages the next Seal's
## boss (it boots wounded), deterministically, and ABSENT a mark the build is unchanged.
##   godot --headless --path godot --script res://sim/map_mark_probe.gd
extends SceneTree

func _initialize() -> void:
	var fails := 0
	var enc := "mistral"                      # a Seal
	# baseline: no carry, full-HP boss
	var full := RaidNet.build(RaidNet.make_spec(42, {}, enc)).boss.hp
	# a mark cuts the boss to 85% on build
	var mark := {"boss_hp_cut": 0.15}
	var cut := RaidNet.build(RaidNet.make_spec(42, {}, enc, {"mark": mark})).boss.hp
	var want := maxf(1.0, roundf(full * 0.85))
	_ok(fails, "mark cuts the boss: full=%d → marked=%d (want %d)" % [int(full), int(cut), int(want)],
		is_equal_approx(cut, want))
	fails = _tally(fails, is_equal_approx(cut, want))
	# determinism: two marked builds land the SAME boss HP (lockstep-safe)
	var cut2 := RaidNet.build(RaidNet.make_spec(42, {}, enc, {"mark": mark})).boss.hp
	fails = _tally(fails, is_equal_approx(cut, cut2))
	print("  [%s] two marked builds identical (%d==%d)" % [_p(is_equal_approx(cut, cut2)), int(cut), int(cut2)])
	# BYTE-IDENTITY: an EMPTY mark (or a carry with no mark) leaves the boss at full HP
	var none := RaidNet.build(RaidNet.make_spec(42, {}, enc, {"mark": {}})).boss.hp
	var carryless := RaidNet.build(RaidNet.make_spec(42, {}, enc, {"fracs": [1, 1, 1, 1]})).boss.hp
	var identical := is_equal_approx(none, full) and is_equal_approx(carryless, full)
	fails = _tally(fails, identical)
	print("  [%s] no-mark build unchanged (empty=%d · carry-no-mark=%d · full=%d)" % [
		_p(identical), int(none), int(carryless), int(full)])
	print("MAP MARK PROBE: %s" % ("ALL PASS" if fails == 0 else "%d FAIL" % fails))
	quit(0 if fails == 0 else 1)

func _ok(_f: int, msg: String, cond: bool) -> void:
	print("  [%s] %s" % [_p(cond), msg])

func _tally(f: int, cond: bool) -> int:
	return f + (0 if cond else 1)

func _p(cond: bool) -> String:
	return "PASS" if cond else "FAIL"
