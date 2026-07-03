## GEAR-1 regression probe: the Curio drop roll (signature-first, class filter,
## determinism) + every [SIM] item's kit effect fires with the gear on and stays
## DEAD without it, + a full raid fight is deterministic with gear and diverges
## from gearless (gear is live, not cosmetic).
##   godot --headless --path godot --script res://sim/gear_probe.gd
extends SceneTree

func _initialize() -> void:
	var oks: Array = []

	# ---------------------------------------------------------------- the roll
	var rng := DetRng.new(7)
	var d1 := Gear.roll("riftmaw", "bulwark", {}, rng)
	oks.append(["roll: locked signature IS the drop (first)",
		d1.get("item", "") == "riftmaw_tooth" and bool(d1.get("first", false))])
	var d2 := Gear.roll("gatekeeper", "twinfang", {}, rng)
	oks.append(["roll: class-marked row never drops off-class", d2.is_empty()])
	var d3 := Gear.roll("riftmaw", "bulwark", {"riftmaw": ["riftmaw_tooth"]}, rng)
	oks.append(["roll: repeat kill draws the unlocked row (not first)",
		d3.get("item", "") == "riftmaw_tooth" and not bool(d3.get("first", true))])
	var ra := DetRng.new(42)
	var rb := DetRng.new(42)
	var seq_ok := true
	for i in 6:
		var a := Gear.roll("riftmaw", "bulwark", {"riftmaw": ["riftmaw_tooth"]}, ra)
		var b := Gear.roll("riftmaw", "bulwark", {"riftmaw": ["riftmaw_tooth"]}, rb)
		if a.hash() != b.hash():
			seq_ok = false
	oks.append(["roll: same-seed streams draw identically", seq_ok])

	# ------------------------------------------------------- LE CHAT'S BELL (+30)
	var tune := TuningConfig.new()
	var bcfg := BulwarkConfig.new()
	var kit := BulwarkKit.new("warden", bcfg)
	var s := _mini_state(tune)
	var seat := _tank_seat(kit)
	s.seats = [seat]
	seat.gear = ["lechat_bell"]
	kit.upkeep(s, seat)
	oks.append(["bell: first upkeep grants +30 rage", is_equal_approx(seat.resource, 30.0)])
	kit.upkeep(s, seat)
	oks.append(["bell: rings exactly once", is_equal_approx(seat.resource, 30.0)])
	var seat0 := _tank_seat(BulwarkKit.new("warden", bcfg))
	var s0 := _mini_state(tune)
	s0.seats = [seat0]
	seat0.kit.upkeep(s0, seat0)
	oks.append(["bell: gearless control stays at 0", is_equal_approx(seat0.resource, 0.0)])

	# --------------------------------------------- RIFTMAW TOOTH (denied heal +15)
	var s2 := _mini_state(tune)
	var tank2 := _tank_seat(BulwarkKit.new("warden", bcfg))
	tank2.gear = ["riftmaw_tooth"]
	var tcfg := TwinfangConfig.new()
	var blade2 := Seat.new()
	blade2.role = "dps"
	blade2.hp_max = 100.0
	blade2.hp = 100.0
	blade2.kit = TwinfangKit.new("tempo", tcfg)
	s2.seats = [tank2, blade2]
	var heal_ab := AbilityRes.new()
	heal_ab.effect = AbilityRes.Effect.HEAL_BOSS
	var tg := Telegraph.new()
	tg.ability = heal_ab
	tg.start_tick = s2.tick
	tg.dur_ticks = 30
	s2.telegraph = tg
	CombatCore.stagger_boss(s2)
	oks.append(["tooth: denied heal pays the holder +15 rage", is_equal_approx(tank2.resource, 15.0)])
	oks.append(["tooth: a gearless seat gets nothing", is_equal_approx(blade2.resource, 0.0)])

	# ------------------------------------------------- SWAN SONG (death procs once)
	var s3 := _mini_state(tune)
	var dying := _tank_seat(BulwarkKit.new("warden", bcfg))
	dying.gear = ["swan_song"]
	var ally := Seat.new()
	ally.role = "dps"
	ally.hp_max = 100.0
	ally.hp = 50.0
	s3.seats = [dying, ally]
	dying.hp = 0.0
	dying.kit.on_damage_taken(s3, dying, 10.0, &"melee", 0)
	var swan_dmg := is_equal_approx(s3.boss.hp, 1000.0 - 120.0)
	var swan_heal := is_equal_approx(ally.hp, 65.0)
	dying.kit.on_damage_taken(s3, dying, 10.0, &"melee", 0)
	oks.append(["swan: death fires a 120 farewell blast", swan_dmg])
	oks.append(["swan: allies each catch 15 healing", swan_heal])
	oks.append(["swan: sings exactly once", is_equal_approx(s3.boss.hp, 880.0)])

	# ------------------------------------ VERIFICATION STAMP (first negate = gauge)
	var s4 := _mini_state(tune)
	var w4 := _tank_seat(BulwarkKit.new("warden", bcfg))
	w4.gear = ["verify_stamp"]
	s4.seats = [w4]
	var swing := AbilityRes.new()
	w4.kit.on_negate(s4, w4, swing)
	var c1 := int(w4.vars.get("counter", 0))
	oks.append(["stamp: first clean guard banks +2 extra links (warden 1+2)", c1 == bcfg.parry_counter + 2])
	w4.kit.on_negate(s4, w4, swing)
	oks.append(["stamp: only the FIRST guard (next adds the normal 1)",
		int(w4.vars.get("counter", 0)) == c1 + bcfg.parry_counter])
	var s4j := _mini_state(tune)
	var j4 := _tank_seat(BulwarkKit.new("juggernaut", bcfg))
	j4.gear = ["verify_stamp"]
	s4j.seats = [j4]
	j4.kit.on_negate(s4j, j4, swing)
	oks.append(["stamp: juggernaut side banks +4 momentum", int(j4.vars.get("momentum", 0)) == 4])

	# ----------------------------------------------- POWDER VIAL (kick carries it)
	var s5 := _mini_state(tune)
	var vcfgv := TwinfangConfig.new()
	var v5 := Seat.new()
	v5.role = "dps"
	v5.hp_max = 100.0
	v5.hp = 100.0
	v5.resource = 100.0
	v5.kit = TwinfangKit.new("venomancer", vcfgv)
	v5.gear = ["powder_vial"]
	s5.seats = [v5]
	s5.tick = 100
	v5.kit._kick(s5, v5)
	var ven: Dictionary = v5.vars.get("venom", {})
	oks.append(["vial: venom kick stacks the lit lane +2", int(ven.get("V", 0)) == 2])
	var s5t := _mini_state(tune)
	var t5 := Seat.new()
	t5.role = "dps"
	t5.hp_max = 100.0
	t5.hp = 100.0
	t5.resource = 100.0
	t5.kit = TwinfangKit.new("tempo", TwinfangConfig.new())
	t5.gear = ["powder_vial"]
	s5t.seats = [t5]
	s5t.tick = 100
	t5.kit._kick(s5t, t5)
	oks.append(["vial: tempo kick pays +1 Flow", int(t5.vars.get("flow", 0)) == 1])

	# ------------------------------------------- SPARK PLUG (first kick, half cd)
	var s6 := _mini_state(tune)
	var vccfg := VoidcallerConfig.new()
	var c6 := Seat.new()
	c6.role = "dps"
	c6.hp_max = 100.0
	c6.hp = 100.0
	c6.kit = VoidcallerKit.new("disruptor", vccfg)
	c6.gear = ["spark_plug"]
	s6.seats = [c6]
	s6.tick = 100
	var kick_ab := AbilityRes.new()
	kick_ab.response = AbilityRes.Response.INTERRUPTIBLE
	var tg6 := Telegraph.new()
	tg6.ability = kick_ab
	tg6.start_tick = 100
	tg6.dur_ticks = 30
	s6.telegraph = tg6
	c6.kit._do_interrupt(s6, c6, "space")
	var half := s6.tick + CombatCore.to_ticks(c6.kit.defense_cd() * 0.5, tune.fixed_hz)
	oks.append(["plug: first kick refunds half its cooldown", c6.defense_ready_tick == half])

	# ------------------------------------------------- SALT VIAL (dispel heals 25)
	var s7 := _mini_state(tune)
	var mcfg := MenderConfig.new()
	var h7 := Seat.new()
	h7.role = "healer"
	h7.hp_max = 100.0
	h7.hp = 100.0
	h7.resource = 500.0
	h7.kit = MenderKit.new("tidecaller", mcfg)
	h7.gear = ["salt_vial"]
	var sick := Seat.new()
	sick.role = "dps"
	sick.hp_max = 100.0
	sick.hp = 50.0
	sick.debuff = {"id": "rot"}
	s7.seats = [h7, sick]
	h7.kit._resolve_spell(s7, h7, "dispel", sick)
	oks.append(["salt: the cleanse also heals its target 25", is_equal_approx(sick.hp, 75.0)])
	oks.append(["salt: the debuff is gone (dispel unchanged)", sick.debuff.is_empty()])

	# ------------------------- full fight: deterministic WITH gear, and gear is LIVE
	var ga := _riftmaw_run(11, ["lechat_bell", "riftmaw_tooth"])
	var gb := _riftmaw_run(11, ["lechat_bell", "riftmaw_tooth"])
	var g0 := _riftmaw_run(11, [])
	oks.append(["fight: geared run is deterministic (checksum %d)" % ga, ga == gb])
	oks.append(["fight: gear diverges from gearless (live, not cosmetic)", ga != g0])

	# ------------------------------------------------------------------ verdict
	var all_ok := true
	for i in oks.size():
		var row: Array = oks[i]
		all_ok = all_ok and bool(row[1])
		print("  [%2d] %s: %s" % [i + 1, String(row[0]), "OK" if bool(row[1]) else "FAIL"])
	print("GEAR PROBE: %s" % ("ALL OK" if all_ok else "FAIL"))
	quit(0 if all_ok else 1)

func _mini_state(tune: TuningConfig) -> CombatState:
	var s := CombatState.new()
	s.config = tune
	s.boss = BossState.new()
	s.boss.hp = 1000.0
	s.boss.hp_max = 1000.0
	s.encounter = EncounterRes.new()   # empty ability list — _is_feint reads it
	s.tick = 100
	return s

func _tank_seat(kit: BulwarkKit) -> Seat:
	var seat := Seat.new()
	seat.role = "tank"
	seat.hp_max = 100.0
	seat.hp = 100.0
	seat.resource_max = 100.0
	seat.kit = kit
	return seat

## A real Riftmaw pull (raid_sim's exact setup) with the tank carrying `gear`.
func _riftmaw_run(seed: int, gear: Array) -> int:
	var s := RaidContent.make_state(seed, RaidContent.encounter_by_id("riftmaw"))
	var tank := s.seats[0]
	tank.gear = gear.duplicate()
	var tp := tank.policy as RaidTankPolicy
	tp.reaction_slack = 0.10
	tp.rng = DetRng.new(seed * 2749 + 1337)
	var bp := s.seats[1].policy as TwinfangPolicy
	bp.latency_ticks = 4
	bp.rng = DetRng.new(seed * 2749 + 2338)
	var cp := s.seats[2].policy as VoidcallerPolicy
	cp.latency_ticks = 4
	cp.rng = DetRng.new(seed * 2749 + 3339)
	(s.seats[3].policy as MenderPolicy).latency_ticks = 5
	var cap := int(150.0 / s.dt)
	while not s.over and s.tick < cap:
		for seat in s.seats:
			if seat.policy != null and seat.alive():
				var a := seat.policy.act(CombatCore.observe(s, seat))
				if not a.is_empty():
					s.enqueue(s.tick + 1, seat, a)
		CombatCore.update(s)
	return s.checksum
