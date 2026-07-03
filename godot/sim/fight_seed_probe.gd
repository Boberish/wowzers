## Regression probe for fight_seed() map collision (fixed 2026-07-03): in Topology map
## mode several combat nodes share an enc_index, so folding only (run_seed, enc_index)
## reseeds state.rng identically → the fight plays back verbatim. Fold map_node in;
## a linear run (map == null) must be byte-identical to the old closed form.
##   godot --headless --path godot --script res://sim/fight_seed_probe.gd
extends SceneTree
func _initialize() -> void:
	var r := RunState.new()
	r.run_seed = 12345

	# [1] map == null → EXACT old closed form (linear runs / class sims / draft_sim)
	r.map = null
	r.enc_index = 2
	var expected := (12345 * 1000003 + 2 * 7919 + 1) & 0x7FFFFFFF
	var ok1 := r.fight_seed() == expected

	# [2] map mode: two nodes with the SAME fight index must seed differently
	r.map = RunMap.new()
	r.enc_index = 2; r.map_node = 3
	var a := r.fight_seed()
	r.enc_index = 2; r.map_node = 5
	var b := r.fight_seed()
	var ok2 := a != b

	# [3] deterministic: same (run_seed, enc_index, node) → same seed (co-op / daily seeds)
	r.map_node = 3
	var ok3 := r.fight_seed() == a

	print("  [1] linear == old closed form: %s  (%d vs %d)" % [ok1, r.fight_seed() if false else expected, expected])
	print("  [2] two same-index nodes differ: %s  (node3=%d node5=%d)" % [ok2, a, b])
	print("  [3] same node reproduces:        %s" % ok3)
	print("FIGHT_SEED PROBE: %s" % ("ALL OK" if ok1 and ok2 and ok3 else "FAIL"))
	quit(0 if (ok1 and ok2 and ok3) else 1)
