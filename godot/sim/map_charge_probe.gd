## Focused probe for THE KILL SWITCH: the ⏻ MapFx branch + the shared RaidMarks applier
## (byte-neutral when absent) + the OVERCLOCK arming math.
##   godot --headless --path godot --script res://sim/map_charge_probe.gd
extends SceneTree

func _initialize() -> void:
	var f := 0
	# ⏻ MapFx branch: signed delta clamped 0..100 + charge_set
	var cp := {"charge": 50}
	MapFx.apply(cp, {"charge": 30}); f += _ok("feed +30 → 80", int(cp["charge"]) == 80)
	MapFx.apply(cp, {"charge": 40}); f += _ok("clamp at 100", int(cp["charge"]) == 100)
	MapFx.apply(cp, {"charge": -120}); f += _ok("clamp floor 0", int(cp["charge"]) == 0)
	MapFx.apply(cp, {"charge_set": 62}); f += _ok("charge_set → 62", int(cp["charge"]) == 62)
	# a cp WITHOUT a charge key is untouched (byte-safe for the solo path)
	var solo := {"fracs": [1.0]}
	MapFx.apply(solo, {"charge": 40}); f += _ok("no charge key → inert", not solo.has("charge"))

	# RaidMarks: byte-NEUTRAL when the mark is absent (the whole byte-identity guarantee)
	var base := _boss_hp("mistral")
	f += _ok("empty mark → boss HP unchanged", is_equal_approx(_marked("mistral", {}), base))
	# SURGE — boss boots wounded (linear)
	f += _ok("SURGE 0.20 → boss at 80%", is_equal_approx(_marked("mistral", {"boss_hp_cut": 0.20}), maxf(1.0, roundf(base * 0.80))))
	f += _ok("SURGE clamps at 0.35", is_equal_approx(_marked("mistral", {"boss_hp_cut": 0.99}), maxf(1.0, roundf(base * (1.0 - RaidMarks.HP_CUT_CAP)))))
	# BOOT-FREEZE — timers start delayed
	var sf := _state("mistral"); var mt0 := sf.boss.melee_timer
	RaidMarks.apply(sf, {"boot_freeze": 90}); f += _ok("BOOT-FREEZE +90 melee timer", sf.boss.melee_timer == mt0 + 90)
	# SHIELD PRIME — an absorb wall on every seat
	var ss := _state("mistral"); RaidMarks.apply(ss, {"party_absorb": 200.0})
	var all_shielded := true
	for u in ss.seats:
		if u.absorb < 200.0:
			all_shielded = false
	f += _ok("SHIELD PRIME 200 absorb on all seats", all_shielded)
	# OVERCLOCK CURSE — the boss hits harder
	var sc := _state("mistral"); RaidMarks.apply(sc, {"boss_dmg_buff": 0.15})
	f += _ok("OVERCLOCK curse → dmg_buff ≥ 0.15", sc.boss.dmg_buff >= 0.15)

	print("MAP CHARGE PROBE: %s" % ("ALL PASS" if f == 0 else "%d FAIL" % f))
	quit(0 if f == 0 else 1)

func _state(enc: String) -> CombatState:
	return RaidContent.make_state(1, RaidContent.encounter_by_id(enc))

func _boss_hp(enc: String) -> float:
	return _state(enc).boss.hp

func _marked(enc: String, mark: Dictionary) -> float:
	var s := _state(enc)
	RaidMarks.apply(s, mark)
	return s.boss.hp

func _ok(msg: String, cond: bool) -> int:
	print("  [%s] %s" % [("PASS" if cond else "FAIL"), msg])
	return 0 if cond else 1
