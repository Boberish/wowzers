## Headless contract probe for the isolated Misprint pose-card animation.
extends SceneTree

var fails := 0

func _chk(name: String, ok: bool) -> void:
	print("MISPRINT CHECK %s: %s" % ["OK" if ok else "FAIL", name])
	if not ok:
		fails += 1

func _initialize() -> void:
	MisprintDodgeProof.pushed_motion = false
	var actor := MisprintDodgeActor2D.try_make()
	_chk("five runtime cards load", actor != null)
	if actor == null:
		quit(1)
		return
	root.add_child(actor)
	var snap: Dictionary = actor.debug_snapshot()
	var sizes: Array = snap["sizes"]
	_chk("fixed production canvas", sizes == [Vector2i(768, 768), Vector2i(768, 768),
		Vector2i(768, 768), Vector2i(768, 768), Vector2i(768, 768)])

	actor.sync_tick(100)
	actor.graded_react("parry", StrikeRes.Grade.PERFECT)
	_chk("parry cannot start dodge proof", int(actor.debug_snapshot()["starts"]) == 0)
	actor.graded_react("dodge", StrikeRes.Grade.MISS)
	_chk("miss cannot start dodge proof", int(actor.debug_snapshot()["starts"]) == 0)
	actor.graded_react("dodge", StrikeRes.Grade.GOOD)
	_chk("landed dodge starts immediately", actor.debug_snapshot()["frame"] == 1 \
		and actor.debug_snapshot()["age"] == 0 and actor.debug_snapshot()["starts"] == 1)

	var expected_frames := [1, 1, 2, 2, 2, 2, 3, 3, 4, 4]
	var expected_echo := [false, false, true, true, false, false, false, false, false, false]
	for age in 10:
		actor.sync_tick(100 + age)
		snap = actor.debug_snapshot()
		_chk("age %d frame %d" % [age, expected_frames[age]], int(snap["frame"]) == expected_frames[age])
		_chk("age %d echo one-tick gate" % age, bool(snap["echo"]) == expected_echo[age])
		if age == 2:
			_chk("baseline treatment has no motion trails", not bool(snap["pushed"]) \
				and int(snap["trails"]) == 0)
	_chk("travel stays inside brief", float(actor.debug_snapshot()["travel"]) >= 0.0 \
		and float(actor.debug_snapshot()["travel"]) <= MisprintDodgeActor2D.TRAVEL_PX * 1.06)
	actor.sync_tick(110)
	snap = actor.debug_snapshot()
	_chk("ten active ticks return to ready", snap["frame"] == 0 and snap["age"] == -1 \
		and is_zero_approx(float(snap["travel"])) and not bool(snap["echo"]))

	actor.sync_tick(120)
	actor.graded_react("weave", StrikeRes.Grade.PERFECT)
	actor.sync_tick(124)
	actor.graded_react("weave", StrikeRes.Grade.PERFECT)
	snap = actor.debug_snapshot()
	_chk("high-flow success cancels into immediate new pose", snap["starts"] == 3 \
		and snap["start_tick"] == 124 and snap["age"] == 0 and snap["frame"] == 1)

	MisprintDodgeProof.pushed_motion = true
	var pushed := MisprintDodgeActor2D.try_make()
	root.add_child(pushed)
	pushed.sync_tick(200)
	pushed.graded_react("dodge", StrikeRes.Grade.GOOD)
	pushed.sync_tick(201)
	snap = pushed.debug_snapshot()
	_chk("pushed treatment owns four blurred trails", bool(snap["pushed"]) \
		and int(snap["trails"]) == 4)
	_chk("pushed treatment uses exaggerated root ease", is_equal_approx(float(snap["root_ease_s"]), 0.12))
	MisprintDodgeProof.motion_ease_s = 0.08
	MisprintDodgeProof.trail_count = 2
	MisprintDodgeProof.trail_spread = 0.55
	MisprintDodgeProof.trail_opacity = 0.65
	MisprintDodgeProof.blur_px = 2.5
	pushed.sync_tick(202)
	snap = pushed.debug_snapshot()
	_chk("live knobs update the active actor without restart", int(snap["trails"]) == 2 \
		and is_equal_approx(float(snap["root_ease_s"]), 0.08) \
		and is_equal_approx(float(snap["trail_spread"]), 0.55) \
		and is_equal_approx(float(snap["trail_opacity"]), 0.65) \
		and is_equal_approx(float(snap["blur_px"]), 2.5))
	MisprintDodgeProof.motion_ease_s = 0.12
	MisprintDodgeProof.trail_count = 4
	MisprintDodgeProof.trail_spread = 1.0
	MisprintDodgeProof.trail_opacity = 1.0
	MisprintDodgeProof.blur_px = 6.0
	pushed.sync_tick(210)
	_chk("pushed trails clear on READY", int(pushed.debug_snapshot()["trails"]) == 0)
	MisprintDodgeProof.pushed_motion = false

	# The stage seam is guarded and fail-safe: OFF gets the current actor; ON gets
	# the prototype for duelist only. No production factory priority is changed.
	var spec := RaidNet.make_spec(20260715, {}, "mistral")
	var state := RaidNet.build(spec, "tank")
	MisprintDodgeProof.enabled = false
	MisprintDodgeProof.pushed_motion = false
	var legacy := RaidStage2D.new()
	root.add_child(legacy)
	legacy.setup(state, {})
	_chk("selector OFF keeps production actor", not (legacy.actors[0] is MisprintDodgeActor2D))
	legacy.queue_free()
	MisprintDodgeProof.enabled = true
	var proof := RaidStage2D.new()
	root.add_child(proof)
	proof.setup(state, {})
	_chk("selector ON replaces Duelist in isolated stage", proof.actors[0] is MisprintDodgeActor2D)
	_chk("other seats remain production actors", not (proof.actors[1] is MisprintDodgeActor2D) \
		and not (proof.actors[2] is MisprintDodgeActor2D) and not (proof.actors[3] is MisprintDodgeActor2D))
	MisprintDodgeProof.enabled = false
	print("MISPRINT DODGE PROBE: %s" % ("ALL OK" if fails == 0 else "FAIL — %d" % fails))
	quit(0 if fails == 0 else 1)
