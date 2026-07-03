## screenshot_menu.gd — visual probe of the refreshed front door. WSLg (NOT --headless):
##   godot --path godot --script res://sim/screenshot_menu.gd -- --out=/absolute/dir
extends SceneTree

var out_dir := "user://shots"
var hud: Node = null
var idx := -1
var frames := 0
var steps := ["home", "class", "aspect", "raid"]

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr("--out=".length())
	DirAccess.make_dir_recursive_absolute(out_dir)

func _process(_d: float) -> bool:
	if hud == null:
		hud = (load("res://game/raid_main.tscn") as PackedScene).instantiate()
		root.add_child(hud)
		return false
	if frames > 0:
		frames -= 1
		if frames == 0:
			var img := root.get_texture().get_image()
			img.save_png(out_dir.path_join("menu_" + String(steps[idx]) + ".png"))
			print("  shot: menu_", steps[idx])
		return false
	idx += 1
	if idx >= steps.size():
		print("MENU TOUR DONE -> ", out_dir)
		return true
	match String(steps[idx]):
		"home": hud._show_home()
		"class": hud._show_class_select()
		"aspect": hud._show_aspect_pick("tank")
		"raid": hud._show_raid_select("tank", "warden")
	frames = 12
	return false
