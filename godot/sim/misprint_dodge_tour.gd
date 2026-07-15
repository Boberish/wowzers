## Non-headless visual gate for the isolated Misprint dodge proof.
## Drives the real 30 Hz CombatController/HUD deterministically one tick at a
## time, then freezes render-only for exact pose captures.
extends SceneTree

var out_dir := "user://shots_misprint"
var hud: Control
var actor: MisprintDodgeActor2D
var phase := 0
var render_wait := 0
var pending_name := ""
var normal_targets := [0, 1, 2, 4, 6, 8, 9]
var normal_i := 0
var normal_start_tick := -1
var stress_starts: Array[int] = []
var ticks_in_phase := 0
var fails := 0

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.substr("--out=".length())
	DirAccess.make_dir_recursive_absolute(out_dir)
	MisprintDodgeProof.enabled = true
	ArtV2.actors = false
	ArtV2.scene = "stack_atrium"
	ArtV2.dash = false
	ArtV2.vfx = false
	hud = (load("res://game/raid_main.tscn") as PackedScene).instantiate()
	root.add_child(hud)

func _chk(name: String, ok: bool) -> void:
	print("MISPRINT TOUR CHECK %s: %s" % ["OK" if ok else "FAIL", name])
	if not ok:
		fails += 1

func _shot(name: String) -> void:
	var image := root.get_texture().get_image()
	var path := out_dir.path_join(name + ".png")
	image.save_png(path)
	print("  shot: ", path)

func _queue_shot(name: String) -> void:
	pending_name = name
	render_wait = 2

func _start(mode: String) -> void:
	hud.call("_launch", "tank", "", "mistral")
	_apply_clean_view()
	hud.set_process(false)
	var ctrl: CombatController = hud.get("_ctrl")
	ctrl.set_process(false)
	if mode == "high_flow":
		ctrl.state.encounter.melee["rhythm"] = 0.32
		ctrl.state.encounter.melee["jig"] = 0.0
		ctrl.state.encounter.melee["phrases"] = [{
			"name": "misprint_high_flow", "weight": 1.0, "rest": 0.32,
			"steps": [{"kind": "flurry", "n": 6,
				"gaps": [0.26, 0.26, 0.26, 0.26, 0.26]}],
		}]
	# Return the human seat to the deterministic policy so every pose starts from
	# a real queued action and a reducer-emitted duel_answer.
	var policy := DuelistPolicy.new()
	policy.latency_ticks = 0
	policy.rng = DetRng.new(20260715 if mode == "normal" else 20260716)
	ctrl.state.seats[0].policy = policy
	actor = hud._stage2d.actors[0] as MisprintDodgeActor2D
	ticks_in_phase = 0

func _apply_clean_view() -> void:
	var ui: Control = hud.get("_ui") as Control
	var stage: RaidStage2D = hud.get("_stage2d") as RaidStage2D
	if ui == null:
		return
	for child in ui.get_children():
		if child is CanvasItem and child != stage:
			(child as CanvasItem).visible = false

func _step_tick() -> void:
	var ctrl: CombatController = hud.get("_ctrl")
	# Keep the proof on dodge instead of the policy's optional parry-greed branch.
	# This is view-test setup only; the real action still crosses the input queue.
	ctrl.state.seats[0].vars["wind"] = 2.5
	ctrl._process(1.0 / 30.0)
	hud._process(1.0 / 30.0)
	ticks_in_phase += 1

func _process(_delta: float) -> bool:
	if pending_name != "":
		render_wait -= 1
		if render_wait <= 0:
			_shot(pending_name)
			pending_name = ""
		return false
	match phase:
		0:
			_start("normal")
			phase = 1
			_queue_shot("00_normal_ready")
		1:
			_step_tick()
			var snap: Dictionary = actor.debug_snapshot()
			if int(snap["starts"]) > 0:
				normal_start_tick = int(snap["start_tick"])
				phase = 2
				normal_i = 0
			if ticks_in_phase > 1800:
				_chk("normal live Mistral produces a landed dodge", false)
				phase = 3
		2:
			var target := int(normal_targets[normal_i])
			var snap: Dictionary = actor.debug_snapshot()
			var age := int(snap["age"])
			if age < target:
				_step_tick()
				return false
			_chk("normal pose age %d reached exactly" % target, age == target)
			_queue_shot("01_normal_age_%02d" % target)
			normal_i += 1
			if normal_i >= normal_targets.size():
				phase = 3
		3:
			_start("high_flow")
			stress_starts = []
			phase = 4
			_queue_shot("02_high_flow_ready")
		4:
			var before := int(actor.debug_snapshot()["starts"])
			_step_tick()
			var snap: Dictionary = actor.debug_snapshot()
			if int(snap["starts"]) > before:
				stress_starts.append(int(snap["start_tick"]))
				if stress_starts.size() == 2:
					_queue_shot("03_high_flow_next_success")
			if stress_starts.size() >= 3:
				var gap1 := stress_starts[1] - stress_starts[0]
				var gap2 := stress_starts[2] - stress_starts[1]
				_chk("high-flow cadence overlaps ten-tick recovery", gap1 < 10 or gap2 < 10)
				_chk("high-flow restart is immediate pose 02", snap["age"] == 0 and snap["frame"] == 1)
				phase = 5
				_queue_shot("04_high_flow_live")
			if ticks_in_phase > 1200:
				_chk("high-flow produced three real dodge answers", false)
				phase = 5
		5:
			var snap: Dictionary = actor.debug_snapshot()
			_chk("normal sequence start tick recorded", normal_start_tick >= 0)
			_chk("proof actor still alive in real Mistral HUD", actor != null and hud._screen == "combat")
			_chk("prototype never enables production ArtV2 actor", not ArtV2.actors)
			print("MISPRINT DODGE TOUR: %s -> %s" % ["ALL OK" if fails == 0 else "FAIL — %d" % fails, out_dir])
			MisprintDodgeProof.enabled = false
			quit(0 if fails == 0 else 1)
			return true
	return false
