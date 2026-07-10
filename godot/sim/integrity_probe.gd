## Probe for the net-layer integrity hash (audit 07-03 option b, protocol v14):
## RaidNet.integrity() must be pure (reading never mutates), identical across two
## replicas of the same spec, and must CATCH the drift classes the engine checksum
## misses — a seat-side HP nudge and a diverged rng stream — while `state.checksum`
## stays untouched by all of it (sim baselines byte-identical by construction).
##   godot --headless --path godot --script res://sim/integrity_probe.gd
extends SceneTree
func _initialize() -> void:
	var spec := RaidNet.make_spec(12345, {}, "riftmaw")
	var a := RaidNet.build(spec)
	var b := RaidNet.build(spec)
	for i in 90:   # advance both replicas identically past a few checksum cadences
		RaidNet.step(a, [])
		RaidNet.step(b, [])

	# [1] two replicas of the same spec agree; [2] reading is pure (hash twice)
	var ok1 := RaidNet.integrity(a) == RaidNet.integrity(b)
	var ok2 := RaidNet.integrity(a) == RaidNet.integrity(a) and a.checksum == b.checksum

	# [3] seat-side drift the engine checksum CANNOT see -> integrity catches it
	var cs_before := a.checksum
	(a.seats[2] as Seat).hp -= 1.0
	var ok3 := RaidNet.integrity(a) != RaidNet.integrity(b) and a.checksum == cs_before
	(a.seats[2] as Seat).hp += 1.0

	# [4] rng-stream divergence -> integrity catches it, checksum still blind
	b.rng.next_u32()
	var ok4 := RaidNet.integrity(a) != RaidNet.integrity(b) and a.checksum == b.checksum

	print("  [1] replicas agree:              %s" % ok1)
	print("  [2] hashing is pure:             %s" % ok2)
	print("  [3] seat drift caught (cs blind): %s" % ok3)
	print("  [4] rng drift caught (cs blind):  %s" % ok4)
	print("INTEGRITY PROBE: %s" % ("ALL OK" if ok1 and ok2 and ok3 and ok4 else "FAIL"))
	quit(0 if (ok1 and ok2 and ok3 and ok4) else 1)
