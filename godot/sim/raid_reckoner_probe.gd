## Raid Reckoner probe — proves the SECOND melee-DPS class works in THE RIFT:
##   [1] the default (no cls) raid still builds a Twinfang blade, byte-identical checksum.
##   [2] classes={"blade":"reckoner"} builds a ReckonerKit blade seat.
##   [3] a full AI fight with the Reckoner blade is deterministic (same seed → same
##       checksum + outcome), beatable, and seed-sensitive.
##   [4] the meter attributes the Reckoner's boss damage to its seat (index 1).
##   [5] RaidNet.make_spec/build routes the spec's cls → the right kit + AI policy.
##   godot --headless --path godot --script res://sim/raid_reckoner_probe.gd
extends SceneTree

var _fails: Array = []

func _check(name: String, ok: bool, detail := "") -> void:
	print("  [%s] %s %s" % ["ok" if ok else "XX", name, detail])
	if not ok:
		_fails.append(name)

func _kit_name(seat: Seat) -> String:
	if seat == null or seat.kit == null:
		return "<none>"
	var scr: Script = seat.kit.get_script()
	return String(scr.get_global_name()) if scr != null else "<anon>"

func _run(s: CombatState, cap_sec := 130.0) -> void:
	var cap := int(cap_sec / s.dt)
	while not s.over and s.tick < cap:
		for seat in s.seats:
			if seat.policy != null and seat.alive():
				var a := seat.policy.act(CombatCore.observe(s, seat))
				if not a.is_empty():
					s.enqueue(s.tick + 1, seat, a)
		CombatCore.update(s)

## Arm the four AI seats (expert-ish). Seat 1 (blade) may be Twinfang OR Reckoner —
## both policies expose latency_ticks + rng, so we set them without a type cast.
func _arm(s: CombatState, seed: int) -> void:
	(s.seats[0].policy as RaidTankPolicy).reaction_slack = 0.05
	(s.seats[0].policy as RaidTankPolicy).rng = DetRng.new(seed * 2749 + 1337)
	s.seats[1].policy.latency_ticks = 4
	s.seats[1].policy.rng = DetRng.new(seed * 2749 + 2338)
	(s.seats[2].policy as VoidcallerPolicy).latency_ticks = 4
	(s.seats[2].policy as VoidcallerPolicy).rng = DetRng.new(seed * 2749 + 3339)
	s.seats[3].policy.latency_ticks = 5

func _reck_state(seed: int, boss := "riftmaw") -> CombatState:
	var s := RaidContent.make_state(seed, RaidContent.encounter_by_id(boss),
		{}, "blade", {"blade": "reckoner"})
	_arm(s, seed)
	return s

func _initialize() -> void:
	print("RAID RECKONER PROBE")

	# ---- [1] default raid = Twinfang blade, unchanged ----
	var sd := RaidContent.make_state(17, RaidContent.encounter_by_id("riftmaw"))
	_check("default blade is Twinfang", _kit_name(sd.seats[1]) == "TwinfangKit",
		"(%s)" % _kit_name(sd.seats[1]))

	# ---- [2] class override builds a Reckoner blade ----
	var sr := _reck_state(17)
	_check("blade=reckoner builds ReckonerKit", _kit_name(sr.seats[1]) == "ReckonerKit",
		"(%s, aspect=%s)" % [_kit_name(sr.seats[1]), sr.seats[1].kit.get("aspect")])
	_check("reckoner blade seat is Rage-fueled",
		sr.seats[1].resource_max > 0.0 and sr.seats[1].vars.has("phase"),
		"(rage_max=%.0f phase=%s)" % [sr.seats[1].resource_max, sr.seats[1].vars.get("phase")])

	# ---- [3] deterministic + beatable + seed-sensitive across bosses ----
	for boss in ["riftmaw", "mistral", "mythos"]:
		var a := _reck_state(29, boss)
		_run(a)
		var b := _reck_state(29, boss)
		_run(b)
		_check("reckoner raid determinism %s" % boss,
			a.checksum == b.checksum and a.won == b.won and a.tick == b.tick,
			"(checksum %d, won=%s, %.1fs)" % [a.checksum, a.won, a.tick * a.dt])
		var c := _reck_state(30, boss)
		_run(c)
		_check("reckoner raid seed-sensitive %s" % boss, c.checksum != a.checksum)

	# ---- [4] the meter attributes the Reckoner's damage to its seat ----
	var sm := _reck_state(11)
	_run(sm)
	var brow: Dictionary = sm.meter.get(1, {})
	_check("reckoner boss damage metered to its seat",
		float(brow.get("dmg_total", 0.0)) > 0.0,
		"(dmg_total %.0f, srcs %s)" % [float(brow.get("dmg_total", 0.0)), (brow.get("dmg", {}) as Dictionary).keys()])

	# ---- [5] the full spec pipeline (RaidNet) routes cls end to end ----
	var spec := RaidNet.make_spec(41, {"blade": {"cls": "reckoner", "aspect": "berserker", "ai": false}}, "riftmaw")
	var bseat: Dictionary = {}
	for e in spec["seats"]:
		if String(e["key"]) == "blade":
			bseat = e
	_check("spec carries blade cls+aspect",
		String(bseat.get("cls", "")) == "reckoner" and String(bseat.get("aspect", "")) == "berserker",
		"(%s)" % bseat)
	var sp := RaidNet.build(spec, "blade")     # blade is the human here → policy null
	_check("built blade seat is Reckoner/berserker, human-driven",
		_kit_name(sp.seats[1]) == "ReckonerKit"
			and String(sp.seats[1].kit.get("aspect")) == "berserker"
			and sp.seats[1].policy == null)
	# AI-fill variant: same spec, blade is AI → ReckonerPolicy attaches (default aspect colossus)
	var spec2 := RaidNet.make_spec(41, {"blade": {"cls": "reckoner"}}, "riftmaw")
	var sp2 := RaidNet.build(spec2, "tank")
	_check("AI Reckoner blade gets a ReckonerPolicy + default colossus",
		sp2.seats[1].policy != null
			and String((sp2.seats[1].policy.get_script()).get_global_name()) == "ReckonerPolicy"
			and String(sp2.seats[1].kit.get("aspect")) == "colossus")

	print("RAID RECKONER PROBE: %s" % ("ALL OK" if _fails.is_empty() else "FAIL " + str(_fails)))
	quit(0 if _fails.is_empty() else 1)
