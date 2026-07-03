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

	# ================================================================ GEAR-2: OATHS
	# ---- detectors (pure functions over diag/vars) ----
	var so := _mini_state(tune)
	var sw := _tank_seat(BulwarkKit.new("warden", bcfg))
	var al2 := Seat.new()
	al2.role = "dps"
	al2.hp_max = 100.0
	al2.hp = 100.0
	so.seats = [sw, al2]
	oks.append(["oath: zero_deaths kept while all stand",
		Oaths.kept({"kind": "zero_deaths"}, so, sw)])
	al2.hp = 0.0
	oks.append(["oath: zero_deaths breaks on a death (live too)",
		not Oaths.kept({"kind": "zero_deaths"}, so, sw)
		and Oaths.broken_live({"kind": "zero_deaths"}, so, sw)])
	al2.hp = 100.0
	sw.diag = {"curse_dropped": 2, "curse_answered": 2}
	oks.append(["oath: curses kept when every drop is answered",
		Oaths.kept({"kind": "curses"}, so, sw)])
	sw.diag = {"curse_dropped": 2, "curse_answered": 1}
	so.boss.last_curse_tick = so.tick - 100      # window long lapsed
	oks.append(["oath: a lapsed unanswered curse breaks live",
		not Oaths.kept({"kind": "curses"}, so, sw)
		and Oaths.broken_live({"kind": "curses"}, so, sw)])
	sw.diag = {"negate": 5, "chain_break": 0}
	oks.append(["oath: chain_intact wants 5 guards + no breaks",
		Oaths.kept({"kind": "chain_intact", "n": 5}, so, sw)
		and not Oaths.kept({"kind": "chain_intact", "n": 6}, so, sw)])
	sw.diag = {"negate": 9, "chain_break": 1}
	oks.append(["oath: one chain break voids it",
		not Oaths.kept({"kind": "chain_intact", "n": 5}, so, sw)
		and Oaths.broken_live({"kind": "chain_intact", "n": 5}, so, sw)])
	sw.diag = {"perfect": 8}
	oks.append(["oath: perfects_n counts up (never breaks live)",
		Oaths.kept({"kind": "perfects_n", "n": 8}, so, sw)
		and not Oaths.broken_live({"kind": "perfects_n", "n": 8}, so, sw)])
	sw.diag = {"kick_whiff": 0}
	sw.vars["kicks"] = 6
	oks.append(["oath: kicks_clean kept at 6 kicks / 0 whiffs",
		Oaths.kept({"kind": "kicks_clean", "n": 6}, so, sw)])
	sw.diag = {"kick_whiff": 1}
	oks.append(["oath: one whiff voids kicks_clean (live)",
		not Oaths.kept({"kind": "kicks_clean", "n": 6}, so, sw)
		and Oaths.broken_live({"kind": "kicks_clean", "n": 6}, so, sw)])
	al2.diag = {"bloodied_dip": 1}
	oks.append(["oath: an ally's dip voids no_dips",
		not Oaths.kept({"kind": "no_dips"}, so, sw)
		and Oaths.broken_live({"kind": "no_dips"}, so, sw)])

	# ---- purses (PROGRESSION table) ----
	var p1o := Oaths.purse(1, 0)
	var p2o := Oaths.purse(2, 3)
	var p3o := Oaths.purse(3, 2)
	oks.append(["oath: sev-I purse = 1⏣ + 2 pity ticks",
		int(p1o["tokens"]) == 1 and int(p1o["pity"]) == 2 and String(p1o["floor"]) == ""])
	oks.append(["oath: sev-II @stakes 3 = 5⏣ + sonnet floor",
		int(p2o["tokens"]) == 5 and String(p2o["floor"]) == "sonnet"])
	oks.append(["oath: sev-III @stakes 2 = 5⏣ + guaranteed opus",
		int(p3o["tokens"]) == 5 and bool(p3o["opus"])])

	# ---- rarity-first roll: floors, forced opus, pity, ring depth ----
	var un_r := {"riftmaw": ["riftmaw_tooth", "sticky_note", "grace_period"]}
	var rf := DetRng.new(5)
	var all_sonnet := true
	for i in 12:
		var dr := Gear.roll("riftmaw", "bulwark", un_r, rf, 3, 0, {"floor": "sonnet"})
		if String(dr.get("item", "")) != "grace_period":
			all_sonnet = false
	oks.append(["roll: sonnet floor lifts every draw out of haiku", all_sonnet])
	var un_p := {"priest": ["spark_plug", "echo_chamber"]}
	var rp := DetRng.new(6)
	var dopus := Gear.roll("priest", "voidcaller", un_p, rp, 3, 0, {"opus": true})
	oks.append(["roll: a guaranteed-opus bend forces the opus row",
		String(dopus.get("item", "")) == "echo_chamber"])
	var rpity := DetRng.new(7)
	var dpity := Gear.roll("priest", "voidcaller", un_p, rpity, 3, 20, {})
	oks.append(["roll: deep pity (+5pp/tick) reaches opus on its own",
		String(dpity.get("item", "")) == "echo_chamber"])
	var n_r0 := 0
	var n_r3 := 0
	var r0rng := DetRng.new(8)
	var r3rng := DetRng.new(8)
	for i in 200:
		if String(Gear.roll("priest", "voidcaller", un_p, r0rng, 0, 0, {}).get("item", "")) == "echo_chamber":
			n_r0 += 1
		if String(Gear.roll("priest", "voidcaller", un_p, r3rng, 3, 0, {}).get("item", "")) == "echo_chamber":
			n_r3 += 1
	oks.append(["roll: Ring 0 rolls opus more than Ring 3 (%d vs %d /200)" % [n_r0, n_r3],
		n_r0 > n_r3])

	# ---- GEAR-2 item effects ----
	# GRACE PERIOD: the warden chain survives its first break (the mistake still counts)
	var sg := _mini_state(tune)
	var wg := _tank_seat(BulwarkKit.new("warden", bcfg))
	wg.gear = ["grace_period"]
	wg.vars["counter"] = 4
	sg.seats = [wg]
	wg.kit.on_damage_taken(sg, wg, 50.0, &"crush", AbilityRes.Size.CRUSH)
	var g_hold: bool = int(wg.vars["counter"]) == 4 and int(wg.diag.get("chain_break", 0)) == 1
	wg.kit.on_damage_taken(sg, wg, 50.0, &"crush", AbilityRes.Size.CRUSH)
	oks.append(["grace: the chain holds once (mistake still counted)", g_hold])
	oks.append(["grace: the second break lands (4 -> 2)",
		int(wg.vars["counter"]) == 2 and int(wg.diag.get("chain_break", 0)) == 2])
	# GRACE: twinfang Flow survives one landed swing
	var sgf := _mini_state(tune)
	var tf := Seat.new()
	tf.role = "dps"
	tf.hp_max = 100.0
	tf.hp = 100.0
	tf.kit = TwinfangKit.new("tempo", TwinfangConfig.new())
	tf.gear = ["grace_period"]
	tf.vars["flow"] = 3
	sgf.seats = [tf]
	tf.kit.on_damage_taken(sgf, tf, 30.0, &"heavy", AbilityRes.Size.HEAVY)
	var f_hold: bool = int(tf.vars["flow"]) == 3
	tf.kit.on_damage_taken(sgf, tf, 30.0, &"heavy", AbilityRes.Size.HEAVY)
	oks.append(["grace: Flow survives one landed swing, then wipes",
		f_hold and int(tf.vars["flow"]) == 0])
	# GRACE: a voidcaller whiff hands the press back (whiff still counted)
	var sgv := _mini_state(tune)
	var vg := Seat.new()
	vg.role = "dps"
	vg.hp_max = 100.0
	vg.hp = 100.0
	vg.kit = VoidcallerKit.new("disruptor", VoidcallerConfig.new())
	vg.gear = ["grace_period"]
	vg.defense_ready_tick = 260
	sgv.seats = [vg]
	vg.kit._do_interrupt(sgv, vg, "space")     # telegraph null -> whiff
	oks.append(["grace: the whiffed kick comes back (whiff still counted)",
		vg.defense_ready_tick == sgv.tick and int(vg.diag.get("kick_whiff", 0)) == 1])
	# GRACE: one Litany pip stays lit through a decay
	var sgm := _mini_state(tune)
	var mg := Seat.new()
	mg.role = "healer"
	mg.hp_max = 100.0
	mg.hp = 100.0
	mg.kit = MenderKit.new("tidecaller", MenderConfig.new())
	mg.gear = ["grace_period"]
	mg.vars["litany"] = 3
	mg.vars["litany_idle"] = 89                # one tick from the 3.0s decay
	sgm.seats = [mg]
	mg.kit.upkeep(sgm, mg)
	var l_hold: bool = int(mg.vars["litany"]) == 3
	mg.vars["litany_idle"] = 89
	mg.kit.upkeep(sgm, mg)
	oks.append(["grace: a Litany pip stays lit once, then decays",
		l_hold and int(mg.vars["litany"]) == 2])
	# STICKY NOTE: answering the curse fast refunds rage (+ the deed counter ticks)
	var ss := _mini_state(tune)
	ss.threat_enabled = true
	var st := _tank_seat(BulwarkKit.new("warden", bcfg))
	st.gear = ["sticky_note"]
	st.diag = {"curse_dropped": 1}
	ss.seats = [st]
	ss.boss.last_curse_tick = ss.tick - 10
	st.kit.on_action(ss, st, &"challenge")
	oks.append(["sticky: a fast answer refunds 15 rage + counts the deed",
		is_equal_approx(st.resource, 15.0) and int(st.diag.get("curse_answered", 0)) == 1])
	# DEBT COLLECTOR: a 5-link Vindicate staggers the wind-up
	var sd := _mini_state(tune)
	var wd := _tank_seat(BulwarkKit.new("warden", bcfg))
	wd.gear = ["debt_collector"]
	wd.vars["counter"] = 5
	sd.seats = [wd]
	var tgd := Telegraph.new()
	tgd.ability = AbilityRes.new()
	tgd.start_tick = sd.tick
	tgd.dur_ticks = 60
	sd.telegraph = tgd
	wd.kit.on_action(sd, wd, &"vindicate")
	oks.append(["debt: a 5-link cash-out staggers the boss", sd.telegraph == null])
	# ENCORE BELL: Coup rings it — the window holds at the wide anchors for 3 strikes
	var se := _mini_state(tune)
	var te := Seat.new()
	te.role = "dps"
	te.hp_max = 100.0
	te.hp = 100.0
	te.resource = 100.0
	var tek := TwinfangKit.new("tempo", TwinfangConfig.new())
	te.kit = tek
	te.gear = ["encore_bell"]
	te.vars["flow"] = 6
	se.seats = [te]
	tek._coup(se, te)
	oks.append(["encore: the bell rings after Coup (3 wide-window strikes)",
		int(te.vars.get("encore_left", 0)) == 3
		and is_equal_approx(tek._perfect_lo_sec(te), tek.cfg.perfect_start)])
	# ENCORE (Venom side): strikes cost 6 less while it rings
	var sev := _mini_state(tune)
	var tv := Seat.new()
	tv.role = "dps"
	tv.hp_max = 100.0
	tv.hp = 100.0
	tv.resource = 10.0                          # strike costs 12 — only rings with the bell
	var tvk := TwinfangKit.new("venomancer", TwinfangConfig.new())
	tv.kit = tvk
	tv.gear = ["encore_bell"]
	tv.vars["encore_left"] = 2
	tv.vars["last_strike_tick"] = sev.tick - 21
	sev.seats = [tv]
	var struck: bool = tvk._strike(sev, tv)
	oks.append(["encore: Venom strikes cost 6 less while it rings",
		struck and is_equal_approx(tv.resource, 4.0) and int(tv.vars["encore_left"]) == 1])
	# ECHO CHAMBER: a clean kick at full Backlash echoes a free 0.6x Overload
	var sec := _mini_state(tune)
	var ve := Seat.new()
	ve.role = "dps"
	ve.hp_max = 100.0
	ve.hp = 100.0
	var vek := VoidcallerKit.new("disruptor", VoidcallerConfig.new())
	ve.kit = vek
	ve.gear = ["echo_chamber"]
	ve.vars["backlash"] = 5
	sec.seats = [ve]
	var tge := Telegraph.new()
	tge.ability = AbilityRes.new()
	tge.ability.response = AbilityRes.Response.INTERRUPTIBLE
	tge.start_tick = sec.tick
	tge.dur_ticks = 15                          # rem 0.5s <= clean zone
	sec.telegraph = tge
	vek._do_interrupt(sec, ve, "space")
	oks.append(["echo: full-bank clean kick echoes the Overload (stacks kept)",
		sec.boss.hp <= 1000.0 - 204.0 - 100.0 and int(ve.vars["backlash"]) == 5])
	# OVERFLOW SLUICE: spill past a full Reservoir wards the tank at 0.5x
	var ssl := _mini_state(tune)
	var hm := Seat.new()
	hm.role = "healer"
	hm.hp_max = 100.0
	hm.hp = 100.0
	var hmk := MenderKit.new("tidecaller", MenderConfig.new())
	hm.kit = hmk
	hm.gear = ["overflow_sluice"]
	hm.vars["reservoir"] = hmk._res_max()
	var tk2 := _tank_seat(BulwarkKit.new("warden", bcfg))
	ssl.seats = [tk2, hm]
	hmk.on_overheal(ssl, hm, tk2, 100.0)
	oks.append(["sluice: the spill wards the tank (0.5x of 55 conv = 28)",
		is_equal_approx(tk2.absorb, 28.0) and tk2.absorb_owner_i == 1])
	# SCRATCHPAD: rage trickles while a long wind-up thinks
	var ssc := _mini_state(tune)
	var wsc := _tank_seat(BulwarkKit.new("warden", bcfg))
	wsc.gear = ["scratchpad"]
	ssc.seats = [wsc]
	var tgs := Telegraph.new()
	tgs.ability = AbilityRes.new()
	tgs.start_tick = ssc.tick
	tgs.dur_ticks = 200                         # a 6.7s ULTRATHINK-sized wind
	ssc.telegraph = tgs
	wsc.kit.upkeep(ssc, wsc)
	var trickled: float = wsc.resource
	ssc.telegraph = null
	wsc.kit.upkeep(ssc, wsc)
	oks.append(["scratchpad: trickles only while the boss thinks",
		trickled > 0.0 and is_equal_approx(wsc.resource, trickled)])

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
