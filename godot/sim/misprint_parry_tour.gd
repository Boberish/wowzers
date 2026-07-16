## Non-headless visual gate for the isolated parry + compact-dashboard study.
extends SceneTree

var out_dir := "user://shots_misprint_parry"
var hud: Control
var actor: MisprintDodgeActor2D
var phase := 0
var wait_frames := 0
var pending_name := ""
var age_targets := [-1, 0, 2, 4, 6]
var shot_names := ["00_ready", "01_load", "02_contact", "03_riposte", "04_recover"]

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.substr("--out=".length())
	DirAccess.make_dir_recursive_absolute(out_dir)
	MisprintDodgeProof.enabled = true
	MisprintDodgeProof.pushed_motion = false
	ArtV2.actors = false
	ArtV2.scene = "misprint_biocooling"
	ArtV2.dash = true
	ArtV2.vfx = false
	hud = (load("res://game/raid_main.tscn") as PackedScene).instantiate()
	root.add_child(hud)

func _capture(name: String) -> void:
	var path := out_dir.path_join(name + ".png")
	root.get_texture().get_image().save_png(path)
	print("  shot: ", path)

func _process(_delta: float) -> bool:
	if phase == 0:
		hud.call("_launch", "tank", "", "mistral")
		var ui: Control = hud.get("_ui") as Control
		for child in ui.get_children():
			if child is BossIntro:
				child.queue_free()
		hud.set_process(false)
		var ctrl: CombatController = hud.get("_ctrl")
		ctrl.set_process(false)
		actor = hud._stage2d.actors[0] as MisprintDodgeActor2D
		actor.sync_tick(100)
		phase = 1
		return false
	if wait_frames > 0:
		wait_frames -= 1
		return false
	if pending_name != "":
		_capture(pending_name)
		pending_name = ""
		phase += 1
		return false
	var index := phase - 1
	if index >= age_targets.size():
		print("MISPRINT PARRY TOUR: ALL OK -> ", out_dir)
		MisprintDodgeProof.enabled = false
		quit(0)
		return true
	var target := int(age_targets[index])
	if target >= 0:
		if target == 0:
			# Use the real stage event seam: the same duel_answer path used in play.
			var ctrl: CombatController = hud.get("_ctrl")
			hud._stage2d.on_event({"t": "duel_answer", "seat": ctrl.state.seats[0],
				"kind": "parry", "grade": StrikeRes.Grade.PERFECT})
		actor.sync_tick(100 + target)
	pending_name = shot_names[index]
	wait_frames = 3
	return false
