## Probe for THE VULNERABILITY STACK (REFIT P4): one generic "boss takes MORE"
## window list, folded at ONE point into both damage paths. Checks: raid-wide vs
## personal scoping, refresh-not-stack on same (seat, src), distinct sources
## multiplying, expiry + lazy prune, vuln_until read, and empty-stack neutrality.
##   godot --headless --path godot --script res://sim/vuln_probe.gd
extends SceneTree
func _initialize() -> void:
	var fails: Array = []
	var s := RaidNet.build(RaidNet.make_spec(777, {}, "riftmaw"))
	var blade: Seat = s.seats[1]
	var caster: Seat = s.seats[2]

	# [1] empty stack = neutral baseline
	var hp0 := s.boss.hp
	var d0 := CombatCore.damage_boss(s, blade, 1000.0)
	_chk(fails, "baseline lands", d0 > 0.0 and s.boss.hp == hp0 - d0)

	# [2] raid-wide window multiplies EVERY seat's hits
	CombatCore.add_vuln(s, -1, 1.5, s.tick + 300, &"t_raid")
	_chk(fails, "raid-wide x1.5 (blade)", absf(CombatCore.damage_boss(s, blade, 1000.0) - 1.5 * d0) <= 1.0)
	_chk(fails, "raid-wide x1.5 (caster)", absf(CombatCore.vuln_mult(s, 2) - 1.5) < 0.001)

	# [3] personal window scopes to its seat only (and multiplies with raid-wide)
	CombatCore.add_vuln(s, 1, 2.0, s.tick + 300, &"t_personal")
	_chk(fails, "personal scopes to blade", absf(CombatCore.vuln_mult(s, 1) - 3.0) < 0.001)
	_chk(fails, "personal skips caster", absf(CombatCore.vuln_mult(s, 2) - 1.5) < 0.001)

	# [4] same (seat, src) REFRESHES — never self-stacks
	CombatCore.add_vuln(s, 1, 2.5, s.tick + 400, &"t_personal")
	_chk(fails, "refresh not stack", absf(CombatCore.vuln_mult(s, 1) - 1.5 * 2.5) < 0.001)
	_chk(fails, "refresh moved deadline", CombatCore.vuln_until(s, 1, &"t_personal") == s.tick + 400)

	# [5] vuln_until: -1 for a source that holds nothing
	_chk(fails, "vuln_until miss = -1", CombatCore.vuln_until(s, 2, &"t_personal") == -1)

	# [6] expiry: past-deadline windows stop applying AND lazily prune off the list
	s.tick += 500
	_chk(fails, "expired = neutral", absf(CombatCore.vuln_mult(s, 1) - 1.0) < 0.001)
	_chk(fails, "lazy prune emptied", s.boss.vulns.is_empty())
	_chk(fails, "expired vuln_until = -1", CombatCore.vuln_until(s, 1, &"t_raid") == -1)

	# [7] determinism: same ops on a twin state -> same fold
	var s2 := RaidNet.build(RaidNet.make_spec(777, {}, "riftmaw"))
	CombatCore.add_vuln(s2, -1, 1.5, s2.tick + 300, &"t_raid")
	var s3 := RaidNet.build(RaidNet.make_spec(777, {}, "riftmaw"))
	CombatCore.add_vuln(s3, -1, 1.5, s3.tick + 300, &"t_raid")
	_chk(fails, "twin states agree", CombatCore.vuln_mult(s2, 0) == CombatCore.vuln_mult(s3, 0))

	for f in fails:
		print("  CHECK FAIL: %s" % f)
	print("VULN PROBE: %s (%d checks)" % ["ALL OK" if fails.is_empty() else "FAIL", _n])
	quit(0 if fails.is_empty() else 1)

var _n := 0
func _chk(fails: Array, name: String, ok: bool) -> void:
	_n += 1
	if not ok:
		fails.append(name)
