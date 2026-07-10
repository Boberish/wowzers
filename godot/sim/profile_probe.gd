## Probe for the Profile save aggregate (REFIT P4 save unification): headless
## disk-inertness + fixed root, the run-seed stream's closed form, facade round-trips
## (GearStore / WellBinds), canonical serialization, the version gate,
## and roster copy-isolation.
##   godot --headless --path godot --script res://sim/profile_probe.gd
extends SceneTree
func _initialize() -> void:
	var fails: Array = []

	# [1] headless profile: fresh, versioned, FIXED seed root (reproducible batch runs)
	Profile.reset_for_test()
	var p := Profile.current()
	_chk(fails, "fresh version", int(p.data["version"]) == Profile.VERSION)
	_chk(fails, "headless fixed root", int((p.data["runs"] as Dictionary)["root"]) == Profile.HEADLESS_ROOT)
	_chk(fails, "fresh last_seed -1", p.last_run_seed() == -1)

	# [2] the run-seed stream: closed-form off (root, counter), advances, records
	var want0 := int((Profile.HEADLESS_ROOT * 1000003 + 0 * 7919 + 1) & 0x7FFFFFFF)
	var want1 := int((Profile.HEADLESS_ROOT * 1000003 + 1 * 7919 + 1) & 0x7FFFFFFF)
	var s0 := p.next_run_seed()
	var s1 := p.next_run_seed()
	_chk(fails, "seed 0 closed form", s0 == want0)
	_chk(fails, "seed 1 closed form", s1 == want1)
	_chk(fails, "seeds differ", s0 != s1)
	_chk(fails, "last_seed records", p.last_run_seed() == s1)

	# [3] facades share the one live profile (headless: pure memory, no user:// touch)
	GearStore.save_unlocks({"riftmaw": ["visor", "coil"]})
	var unlocks := GearStore.load_unlocks()
	_chk(fails, "gear round-trip", Array(unlocks.get("riftmaw", [])) == ["visor", "coil"])
	WellBinds.save_binds({"left": "mend", "bogus_chord": "flash"})
	var wb := WellBinds.load_binds()
	_chk(fails, "binds override kept", String(wb["left"]) == "mend")
	_chk(fails, "binds bogus chord dropped", not wb.has("bogus_chord"))
	_chk(fails, "binds defaults fill", String(wb["middle"]) == "cascade")

	# [4] canonical round-trip: same state → same bytes, through from_json and back
	p.set_roster({"healer": {"cls": "well", "aspect": "brim"}})
	var blob := p.canonical()
	var p2 := Profile.from_json(blob)
	_chk(fails, "canonical round-trip", p2.canonical() == blob)
	_chk(fails, "roster survives", String((p2.roster()["healer"] as Dictionary)["cls"]) == "well")

	# [5] version gate: a wrong-version blob loads as a FRESH profile (prior died w/ V#8 —
	# the gate now proves itself on the gear domain)
	var old := Profile.from_json('{"version":0,"gear":{"riftmaw":["visor"]}}')
	_chk(fails, "version gate", old.gear_unlocks().is_empty())

	# [6] corruption tolerance: right version, wrong domain shapes → fresh defaults
	var corrupt := Profile.from_json('{"version":1,"gear":"not-a-dict","binds":{"well":{"left":"mend"}},"runs":[1,2]}')
	_chk(fails, "corrupt domain dropped", corrupt.gear_unlocks().is_empty())
	_chk(fails, "good domain kept", String((corrupt.binds("well") as Dictionary).get("left", "")) == "mend")
	_chk(fails, "corrupt runs healed", corrupt.next_run_seed() >= 0)

	# [7] copy isolation: mutating a returned domain never writes through
	var r := p.roster()
	r["tank"] = {"cls": "hacked", "aspect": "x"}
	_chk(fails, "roster copy isolated", not p.roster().has("tank"))

	# [8] WorldSave delegates here: headless load is fresh, canonical stays stable
	var w := WorldSave.load_save()
	w.mark_cleared("gildfields", 3)
	_chk(fails, "worldsave canon", w.canonical() == WorldSave.from_json(w.canonical()).canonical())

	Profile.reset_for_test()
	for f in fails:
		print("  CHECK FAIL: %s" % f)
	print("PROFILE PROBE: %s (%d checks)" % ["ALL OK" if fails.is_empty() else "FAIL", _n])
	quit(0 if fails.is_empty() else 1)

var _n := 0
func _chk(fails: Array, name: String, ok: bool) -> void:
	_n += 1
	if not ok:
		fails.append(name)
