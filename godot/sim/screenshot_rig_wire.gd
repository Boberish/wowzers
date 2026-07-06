## screenshot_rig_wire.gd — visual probe for the Combo-rig WIRING screen (the WHEN/THEN
## board). Confirms the option cards show the full name + WRAPPED blurb (no clipped text).
## Needs a display (WSLg — NOT --headless):
##   godot --path godot --script res://sim/screenshot_rig_wire.gd -- --out=/absolute/dir
extends SceneTree

var out_dir := "user://shots"
var cur: Node = null
var phase := 0
var waited := 0

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr("--out=".length())
	DirAccess.make_dir_recursive_absolute(out_dir)

func _process(_d: float) -> bool:
	match phase:
		0:
			cur = (load("res://game/raid_main.tscn") as PackedScene).instantiate()
			root.add_child(cur)
			phase = 1
		1:
			# drive the HUD to an Alchemist caster, give it a run, open the rig board.
			cur._launch("caster", "brew")
			cur._seat_key = "caster"
			cur._caster_cls = "alchemist"
			cur._aspect = "brew"
			cur._run = RunState.start_alchemist("brew", 7)
			cur._show_rig_wire(func(): pass)
			waited = 0
			phase = 2
		2:
			waited += 1
			if waited > 6:
				var img := root.get_texture().get_image()
				var path := out_dir.path_join("rig_wire_alchemist.png")
				img.save_png(path)
				print("  shot: ", path)
				return true
	return false
