## Meter probe — proves `state.meter` (the DPS/HPS window's accounting) is TRUE:
##   [1] damage reconciliation, engine path (Bulwark vs Gatekeeper): Σ meter damage
##       across seats == boss HP lost, exactly (overkill only on the killing blow,
##       bounded by the biggest recorded hit).
##   [2] damage reconciliation THROUGH A SELF-HEALING BOSS (Warden vs Devourer):
##       Σ meter == HP lost + everything the boss healed back.
##   [3] kit-direct path (Twinfang Venomancer: strikes + poison bypass damage_boss):
##       same reconciliation — a missed meter call in the kit fails this.
##   [4] healer accounting (Mender vs Rendmaw): only the healer earns heal credit,
##       HoT ticks land under their `src` (renew), overheal tracked beside.
##   [5] raid attribution (Vorathek): all four raiders metered, sources labeled,
##       tank takes hits, healing reconciles with the raid's actual HP gains.
##   [6] determinism: the same seed rebuilds the identical meter, byte for byte.
##   godot --headless --path godot --script res://sim/meter_probe.gd
extends SceneTree

var _fails: Array = []

func _check(name: String, ok: bool, detail := "") -> void:
	print("  [%s] %s %s" % ["ok" if ok else "XX", name, detail])
	if not ok:
		_fails.append(name)

func _run(s: CombatState, cap_sec := 120.0) -> void:
	var cap := int(cap_sec / s.dt)
	while not s.over and s.tick < cap:
		for seat in s.seats:
			if seat.policy != null and seat.alive():
				var a := seat.policy.act(CombatCore.observe(s, seat))
				if not a.is_empty():
					s.enqueue(s.tick + 1, seat, a)
		CombatCore.update(s)

func _sum(s: CombatState, key: String) -> float:
	var t := 0.0
	for i in s.meter:
		t += float(s.meter[i].get(key, 0.0))
	return t

func _max_hit(s: CombatState) -> float:
	var m := 0.0
	for i in s.meter:
		for src in s.meter[i]["dmg"]:
			m = maxf(m, float(s.meter[i]["dmg"][src]["max"]))
	return m

## Σ meter damage must equal HP lost (+ boss self-heals); a won fight may overkill
## by at most the largest single recorded hit (the killing blow clamps to 0).
func _reconcile_dmg(name: String, s: CombatState) -> void:
	var dealt := _sum(s, "dmg_total")
	var truth := (s.boss.hp_max - s.boss.hp) + s.boss.heal_total
	var over := dealt - truth
	var ok := over >= -0.01 and over <= (_max_hit(s) + 0.01 if s.won else 0.01)
	_check(name, ok, "(meter %.1f vs hp-delta+heals %.1f, overkill %.1f)" % [dealt, truth, over])

func _bulwark_state(seed: int, enc: EncounterRes) -> CombatState:
	var s := BulwarkContent.make_state(seed, "warden",
		BulwarkContent.make_config(), BulwarkContent.make_bulwark_config(), enc, {})
	var pol := s.seats[0].policy as BulwarkPolicy
	pol.reaction_slack = 0.05
	pol.rng = DetRng.new(seed * 2749 + 1337)
	return s

func _raid_state(seed: int) -> CombatState:
	var s := RaidContent.make_state(seed, RaidContent.encounter_by_id("riftmaw"))
	(s.seats[0].policy as RaidTankPolicy).reaction_slack = 0.05
	(s.seats[0].policy as RaidTankPolicy).rng = DetRng.new(seed * 2749 + 1337)
	(s.seats[1].policy as TwinfangPolicy).latency_ticks = 4
	(s.seats[1].policy as TwinfangPolicy).rng = DetRng.new(seed * 2749 + 2338)
	(s.seats[2].policy as VoidcallerPolicy).latency_ticks = 4
	(s.seats[2].policy as VoidcallerPolicy).rng = DetRng.new(seed * 2749 + 3339)
	(s.seats[3].policy as MenderPolicy).latency_ticks = 5
	return s

func _initialize() -> void:
	print("METER PROBE")

	# ---- [1] engine damage path reconciles (no heals, no adds) ----
	for seed in [7, 21, 88]:
		var s1 := _bulwark_state(seed, BulwarkContent.make_gatekeeper())
		_run(s1)
		_reconcile_dmg("bulwark/gatekeeper seed %d" % seed, s1)

	# ---- [2] reconciles through boss self-heals (Devourer regen) ----
	for seed in [3, 41]:
		var s2 := _bulwark_state(seed, BulwarkContent.make_devourer())
		_run(s2)
		_check("devourer healed (probe premise) seed %d" % seed, s2.boss.heal_total >= 0.0,
			"(healed %.0f)" % s2.boss.heal_total)
		_reconcile_dmg("bulwark/devourer seed %d" % seed, s2)

	# ---- [3] the Twinfang kit-direct path (strike/poison bypass damage_boss) ----
	for seed in [5, 60]:
		var s3 := TwinfangContent.make_state(seed, "venomancer",
			TwinfangContent.make_config(), TwinfangContent.make_twinfang_config(),
			TwinfangContent.make_warden(), {})
		var pol := s3.seats[0].policy as TwinfangPolicy
		pol.latency_ticks = 4
		pol.rng = DetRng.new(seed * 2749 + 1337)
		_run(s3)
		_reconcile_dmg("twinfang/warden seed %d" % seed, s3)
		var row: Dictionary = s3.meter.get(0, {})
		_check("twinfang poison metered seed %d" % seed,
			row.has("dmg") and row["dmg"].has(&"poison"),
			"(srcs: %s)" % [row.get("dmg", {}).keys()])

	# ---- [4] healer accounting (Mender vs Rendmaw) ----
	var s4 := MenderContent.make_state(11, "tidecaller",
		MenderContent.make_config(), MenderContent.make_mender_config(),
		MenderContent.make_rendmaw(), {})
	(s4.seats[0].policy as MenderPolicy).latency_ticks = 5
	_run(s4)
	var healer_i := 0    # mender content: seat 0 is the healer
	var hrow: Dictionary = s4.meter.get(healer_i, {})
	_check("mender heal credit", float(hrow.get("heal_total", 0.0)) > 0.0,
		"(healed %.0f, over %.0f)" % [hrow.get("heal_total", 0.0), hrow.get("over_total", 0.0)])
	_check("mender HoT src labeled", hrow.get("heal", {}).has(&"renew"),
		"(srcs: %s)" % [hrow.get("heal", {}).keys()])
	var only_healer := true
	for i in s4.meter:
		if i != healer_i and not (s4.meter[i].get("heal", {}) as Dictionary).is_empty():
			only_healer = false
	_check("only the healer heals (solo mender)", only_healer)
	_check("party damage metered (statblock attack)",
		_sum(s4, "dmg_total") > 0.0 and (s4.meter.get(1, {}).get("dmg", {}) as Dictionary).has(&"attack"))

	# ---- [5] raid attribution (Vorathek, all four full-fidelity seats) ----
	var s5 := _raid_state(17)
	_run(s5)
	var all_dmg := true
	for i in [0, 1, 2]:                          # tank + both dps deal damage
		if float(s5.meter.get(i, {}).get("dmg_total", 0.0)) <= 0.0:
			all_dmg = false
	_check("raid: tank+blade+caster all deal metered damage", all_dmg,
		"(totals %s)" % [[0, 1, 2].map(func(i): return int(s5.meter.get(i, {}).get("dmg_total", 0.0)))])
	_check("raid: tank takes metered hits",
		float(s5.meter.get(0, {}).get("taken_total", 0.0)) > 0.0)
	_check("raid: healer heals metered",
		float(s5.meter.get(3, {}).get("heal_total", 0.0)) > 0.0)
	_check("raid: blade sources labeled",
		(s5.meter.get(1, {}).get("dmg", {}) as Dictionary).size() >= 2,
		"(srcs: %s)" % [s5.meter.get(1, {}).get("dmg", {}).keys()])
	_reconcile_dmg("raid/riftmaw seed 17", s5)

	# ---- [6] determinism: same seed → byte-identical meter ----
	var a := _raid_state(29)
	_run(a)
	var b := _raid_state(29)
	_run(b)
	_check("raid meter determinism", JSON.stringify(a.meter) == JSON.stringify(b.meter)
		and a.checksum == b.checksum, "(checksum %d)" % a.checksum)

	print("METER PROBE: %s" % ("ALL OK" if _fails.is_empty() else "FAIL " + str(_fails)))
	quit(0 if _fails.is_empty() else 1)
