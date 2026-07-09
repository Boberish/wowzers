## SPLIT LAW GUARD probe (WORLD-PLAN pillar #5 / REFIT P4): a zone-context fight spec
## structurally refuses seat_boons (bare-kit law); an instance-context spec carries
## them untouched; and the guarded zone spec normalizes to EXACTLY the bare spec.
##   godot --headless --path godot --script res://sim/splitlaw_probe.gd
extends SceneTree
func _initialize() -> void:
	var boons := {"blade": {"presstheadvantage": true}}

	# [1] zone ctx: boons dropped from every seat
	var z := RaidNet.make_spec(7, {}, "riftmaw", {}, boons, [], "zone")
	var ok1 := true
	for e in z["seats"]:
		if (e as Dictionary).has("boons"):
			ok1 = false

	# [2] instance ctx (the default): boons ride
	var inst := RaidNet.make_spec(7, {}, "riftmaw", {}, boons)
	var ok2 := false
	for e in inst["seats"]:
		if String(e["key"]) == "blade" and (e as Dictionary).has("boons"):
			ok2 = true

	# [3] the guarded zone spec is byte-identical to a bare boonless spec
	var bare := RaidNet.make_spec(7, {}, "riftmaw")
	var ok3 := JSON.stringify(z) == JSON.stringify(bare)

	print("  [1] zone ctx drops seat_boons:      %s" % ok1)
	print("  [2] instance ctx carries seat_boons: %s" % ok2)
	print("  [3] guarded zone == bare spec:       %s" % ok3)
	print("SPLITLAW PROBE: %s" % ("ALL OK" if ok1 and ok2 and ok3 else "FAIL"))
	quit(0 if (ok1 and ok2 and ok3) else 1)
