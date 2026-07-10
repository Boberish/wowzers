## Raid Bloomweaver probe — proves the SECOND healer works in THE RIFT:
##   [1] the default (no cls) raid builds the Well healer (the post-purge default).
##   [2] classes={"healer":"bloomweaver"} builds a BloomweaverKit healer seat.
##   [3] a full AI fight with the Bloomweaver healer is deterministic (same seed → same
##       checksum + outcome) and beatable.
##   [4] the meter splits shields from heals: the Bloomweaver's shield_total > 0 (wards
##       eaten) AND its heal bucket carries HoT growth ticks — the honest split.
##   [5] RaidNet.build routes the spec's cls → the right kit + AI policy end to end.
##   godot --headless --path godot --script res://sim/raid_bloom_probe.gd
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

## Wire the standard skill knobs onto a raid state's four AI seats (expert-ish).
func _arm(s: CombatState, seed: int) -> void:
	(s.seats[0].policy as DuelistPolicy).latency_ticks = 6
	(s.seats[0].policy as DuelistPolicy).rng = DetRng.new(seed * 2749 + 6737)
	(s.seats[1].policy as TwinfangPolicy).latency_ticks = 4
	(s.seats[1].policy as TwinfangPolicy).rng = DetRng.new(seed * 2749 + 2338)
	(s.seats[2].policy as AlchemistPolicy).latency_ticks = 4
	(s.seats[2].policy as AlchemistPolicy).rng = DetRng.new(seed * 2749 + 3339)
	s.seats[3].policy.latency_ticks = 5   # Well or Bloomweaver — both expose latency_ticks

func _bloom_state(seed: int, boss := "riftmaw") -> CombatState:
	var s := RaidContent.make_state(seed, RaidContent.encounter_by_id(boss),
		{}, "healer", {"healer": "bloomweaver"})
	_arm(s, seed)
	return s

func _initialize() -> void:
	print("RAID BLOOM PROBE")

	# ---- [1] default raid = the Well healer (post-purge) ----
	var sd := RaidContent.make_state(17, RaidContent.encounter_by_id("riftmaw"))
	_check("default healer is the Well", _kit_name(sd.seats[3]) == "WellKit",
		"(%s)" % _kit_name(sd.seats[3]))

	# ---- [2] class override builds a Bloomweaver healer ----
	var sb := _bloom_state(17)
	_check("healer=bloomweaver builds BloomweaverKit", _kit_name(sb.seats[3]) == "BloomweaverKit",
		"(%s, aspect=%s)" % [_kit_name(sb.seats[3]), sb.seats[3].kit.get("aspect")])
	_check("bloomweaver healer seat is Sap-fueled",
		sb.seats[3].resource_max > 0.0 and sb.seats[3].vars.has("verdance"),
		"(sap_max=%.0f verdance=%s)" % [sb.seats[3].resource_max, sb.seats[3].vars.get("verdance")])

	# ---- [3] deterministic + beatable across bosses ----
	for boss in ["riftmaw", "mistral", "mythos"]:
		var a := _bloom_state(29, boss)
		_run(a)
		var b := _bloom_state(29, boss)
		_run(b)
		_check("bloom raid determinism %s" % boss,
			a.checksum == b.checksum and a.won == b.won and a.tick == b.tick,
			"(checksum %d, won=%s, %.1fs)" % [a.checksum, a.won, a.tick * a.dt])
		# a different seed must diverge (proves it's not a constant)
		var c := _bloom_state(30, boss)
		_run(c)
		_check("bloom raid seed-sensitive %s" % boss, c.checksum != a.checksum)

	# ---- [4] the meter splits shields from heals for the Bloomweaver ----
	var sm := _bloom_state(11)
	_run(sm)
	var hrow: Dictionary = sm.meter.get(3, {})
	var shield := float(hrow.get("shield_total", 0.0))
	var heal := float(hrow.get("heal_total", 0.0))
	_check("bloomweaver shielding metered (SHIELDS bucket)", shield > 0.0,
		"(shield_total %.0f, srcs %s)" % [shield, hrow.get("shield", {}).keys()])
	_check("bloomweaver heals metered separately (Growth HoTs)",
		heal > 0.0 and (hrow.get("heal", {}) as Dictionary).has(&"growth"),
		"(heal_total %.0f, srcs %s)" % [heal, hrow.get("heal", {}).keys()])
	_check("shields NOT lumped into heal bucket",
		not (hrow.get("heal", {}) as Dictionary).has(&"ward"),
		"(heal srcs %s)" % [hrow.get("heal", {}).keys()])

	# ---- [5] the full spec pipeline (RaidNet) routes cls end to end ----
	var spec := RaidNet.make_spec(41, {"healer": {"cls": "bloomweaver", "aspect": "thornveil", "ai": false}}, "riftmaw")
	var hseat: Dictionary = {}
	for e in spec["seats"]:
		if String(e["key"]) == "healer":
			hseat = e
	_check("spec carries healer cls+aspect",
		String(hseat.get("cls", "")) == "bloomweaver" and String(hseat.get("aspect", "")) == "thornveil",
		"(%s)" % hseat)
	var sp := RaidNet.build(spec, "healer")     # healer is the human here → policy null
	_check("built healer seat is Bloomweaver/thornveil, human-driven",
		_kit_name(sp.seats[3]) == "BloomweaverKit"
			and String(sp.seats[3].kit.get("aspect")) == "thornveil"
			and sp.seats[3].policy == null)
	# AI-fill variant: the same spec but healer is AI → BloomweaverPolicy attaches
	var spec2 := RaidNet.make_spec(41, {"healer": {"cls": "bloomweaver"}}, "riftmaw")
	var sp2 := RaidNet.build(spec2, "tank")
	_check("AI Bloomweaver healer gets a BloomweaverPolicy",
		sp2.seats[3].policy != null
			and String((sp2.seats[3].policy.get_script()).get_global_name()) == "BloomweaverPolicy")

	print("RAID BLOOM PROBE: %s" % ("ALL OK" if _fails.is_empty() else "FAIL " + str(_fails)))
	quit(0 if _fails.is_empty() else 1)
