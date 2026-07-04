## screenshot_arming.gd — visual probe of the OVERCLOCK arming dial (THE KILL SWITCH
## cash-out). WSLg (NOT --headless):
##   godot --path godot --script res://sim/screenshot_arming.gd --resolution 1920x1080 -- --out=/abs/dir
extends SceneTree
var out_dir := "user://shots"
var frames := 0
var shot := false

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr("--out=".length())
	DirAccess.make_dir_recursive_absolute(out_dir)

func _process(_d: float) -> bool:
	if not shot:
		var bg := ColorRect.new()
		bg.color = Color(0.04, 0.05, 0.06)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		root.add_child(bg)
		var ap := ArmingPanel.new()
		ap.charge = 62
		ap.boss_name = "MISTRAL-7B"
		ap.set_anchors_preset(Control.PRESET_FULL_RECT)
		root.add_child(ap)
		shot = true
		frames = 22
		return false
	frames -= 1
	if frames == 0:
		root.get_texture().get_image().save_png(out_dir.path_join("arming.png"))
		print("shot -> ", out_dir)
		return true
	return false
