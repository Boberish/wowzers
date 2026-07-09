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
	oks.append(["bell: first upkeep grants +30 rage (+ the 10s hum trickle)",
		is_equal_approx(seat.resource, 30.0 + 3.0 * s.dt)])
	kit.upkeep(s, seat)
	oks.append(["bell: rings exactly once (only the hum keeps trickling)",
		is_equal_approx(seat.resource, 30.0 + 6.0 * s.dt)])
	s.tick = 400                                       # past the 10s hum window
	kit.upkeep(s, seat)
	oks.append(["bell: the hum stops after 10s", is_equal_approx(seat.resource, 30.0 + 6.0 * s.dt)])
	s.tick = 100
	var seat0 := _tank_seat(BulwarkKit.new("warden", bcfg))
	var s0 := _mini_state(tune)
	s0.seats = [seat0]
	seat0.kit.upkeep(s0, seat0)
	oks.append(["bell: gearless control stays at 0", is_equal_approx(seat0.resource, 0.0)])

	# --------------------------------------------- RIFTMAW TOOTH (denied heal +15)
	var s2 := _mini_state(tune)
	var tank2 := _tank_seat(BulwarkKit.new("warden", bcfg))
	tank2.gear = ["riftmaw_tooth"]
	tank2.defense_ready_tick = 500                     # mid-cooldown when the denial lands
	tank2.dodge_ready_tick = 500
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
	oks.append(["tooth: denied heal pays the holder +20 rage", is_equal_approx(tank2.resource, 20.0)])
	oks.append(["tooth: the denial hands the verbs back (defense + dodge reset)",
		tank2.defense_ready_tick == s2.tick and tank2.dodge_ready_tick == s2.tick])
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
	var swan_dmg := is_equal_approx(s3.boss.hp, 1000.0 - 200.0)
	var swan_heal := is_equal_approx(ally.hp, 75.0)
	dying.kit.on_damage_taken(s3, dying, 10.0, &"melee", 0)
	oks.append(["swan: death fires a 200 farewell blast", swan_dmg])
	oks.append(["swan: allies each catch 25 healing", swan_heal])
	oks.append(["swan: sings exactly once", is_equal_approx(s3.boss.hp, 800.0)])

	# ------------------------------------ VERIFICATION STAMP (first negate = gauge)
	var s4 := _mini_state(tune)
	var w4 := _tank_seat(BulwarkKit.new("warden", bcfg))
	w4.gear = ["verify_stamp"]
	s4.seats = [w4]
	var swing := AbilityRes.new()
	w4.defense_ready_tick = 900                        # guard just spent — the stamp hands it back
	w4.kit.on_negate(s4, w4, swing)
	var c1 := int(w4.vars.get("counter", 0))
	oks.append(["stamp: first clean guard banks +4 extra links (warden 1+4)", c1 == bcfg.parry_counter + 4])
	oks.append(["stamp: the first guard resets Guard on the spot", w4.defense_ready_tick == s4.tick])
	w4.kit.on_negate(s4, w4, swing)
	oks.append(["stamp: only the FIRST guard (next adds the normal 1)",
		int(w4.vars.get("counter", 0)) == c1 + bcfg.parry_counter])
	var s4j := _mini_state(tune)
	var j4 := _tank_seat(BulwarkKit.new("juggernaut", bcfg))
	j4.gear = ["verify_stamp"]
	s4j.seats = [j4]
	j4.kit.on_negate(s4j, j4, swing)
	oks.append(["stamp: juggernaut side banks +8 momentum", int(j4.vars.get("momentum", 0)) == 8])

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
	oks.append(["vial: venom kick stacks the lit lane +3", int(ven.get("V", 0)) == 3])
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
	oks.append(["vial: tempo kick pays +2 Flow", int(t5.vars.get("flow", 0)) == 2])

	# (SPARK PLUG + SALT VIAL sub-tests retired 2026-07-10: their host kits — the
	# Voidcaller kick / the Mender dispel — died in THE PURGE.)

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

	# ---- rarity-first roll: floor/clamp + ring depth + pity WEIGHTS ----
	# NOTE (curio v2, 2026-07-05): the interim universal pool has no OPUS-tier curio yet
	# (all shipped curios are haiku/sonnet), so the end-to-end opus-SELECTION path — a
	# bend/pity actually LANDING an opus row — has no live content to hit. It's covered
	# here by the pure rarity_weights + pity math instead; restore a live opus roll when
	# the pool gains its first opus curio (GEAR-CATALOG.md "build the rest later").
	var un_r := {"riftmaw": ["riftmaw_tooth", "hot_reload"]}
	var rf := DetRng.new(5)
	var floor_ok := true
	for i in 12:
		var dr := Gear.roll("riftmaw", "bulwark", un_r, rf, 3, 0, {"floor": "sonnet"})
		if String(GearCatalog.item(String(dr.get("item", ""))).get("rarity", "")) == "haiku":
			floor_ok = false
	oks.append(["roll: sonnet floor never draws below sonnet", floor_ok])
	# a forced-opus bend on an opus-less page CLAMPS to the top tier present (sonnet here)
	var rbend := DetRng.new(6)
	var dclamp := Gear.roll("riftmaw", "bulwark", un_r, rbend, 3, 0, {"opus": true})
	oks.append(["roll: forced-opus bend clamps to the top tier present (sonnet)",
		String(GearCatalog.item(String(dclamp.get("item", ""))).get("rarity", "")) == "sonnet"])
	# ring depth: shallower rings weight opus richer (the pure weight table Gear.roll draws on)
	var w0 := Gear.rarity_weights(0)
	var w3 := Gear.rarity_weights(3)
	oks.append(["roll: shallow rings weight opus richer than deep (%.2f > %.2f)"
		% [float(w0["opus"]), float(w3["opus"])], float(w0["opus"]) > float(w3["opus"])])
	# opus pity ramps the EFFECTIVE opus weight +5pp/tick (the formula Gear.roll applies)
	var wo0: float = minf(1.0, float(w3["opus"]) + 0.05 * 0.0)
	var wo20: float = minf(1.0, float(w3["opus"]) + 0.05 * 20.0)
	oks.append(["roll: deep pity ramps effective opus weight (%.2f -> %.2f)" % [wo0, wo20],
		wo20 > wo0 and is_equal_approx(wo20, 1.0)])

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
	# (twinfang Flow+grace sub-test retired: grace_period is CUT from the v2 catalog and
	# the Tempo kit's Flow-wipe was reworked — this dead-content assertion no longer maps.)
	# (GRACE voidcaller-whiff + mender-Litany sub-tests retired 2026-07-10 — THE PURGE.)
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
	# (ECHO CHAMBER + OVERFLOW SLUICE sub-tests retired 2026-07-10 — THE PURGE.)
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
	var cp := s.seats[2].policy as AlchemistPolicy
	cp.latency_ticks = 4
	cp.rng = DetRng.new(seed * 2749 + 3339)
	var hpw := s.seats[3].policy as WellPolicy
	hpw.latency_ticks = 5
	hpw.rng = DetRng.new(seed * 2749 + 5531)
	var cap := int(150.0 / s.dt)
	while not s.over and s.tick < cap:
		for seat in s.seats:
			if seat.policy != null and seat.alive():
				var a := seat.policy.act(CombatCore.observe(s, seat))
				if not a.is_empty():
					s.enqueue(s.tick + 1, seat, a)
		CombatCore.update(s)
	return s.checksum
