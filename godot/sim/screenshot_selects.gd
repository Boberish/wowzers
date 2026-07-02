## screenshot_selects.gd — fast visual probe of all five class entry screens (the
## shared BossSelect "pick a fight" selector). WSLg (NOT --headless):
##   godot --path godot --script res://sim/screenshot_selects.gd -- --out=/absolute/dir
extends SceneTree

var out_dir := "user://shots"
var idx := -1
var frames := 0
var cur: Node = null
var steps: Array = []

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr("--out=".length())
	DirAccess.make_dir_recursive_absolute(out_dir)
	steps = [
		{"name": "sel_bulwark", "scene": "res://game/bulwark_main.tscn"},
		{"name": "sel_mender", "scene": "res://game/mender_main.tscn"},
		{"name": "sel_twinfang", "scene": "res://game/twinfang_main.tscn"},
		{"name": "sel_voidcaller", "scene": "res://game/voidcaller_main.tscn"},
		{"name": "sel_bloomweaver", "scene": "res://game/bloomweaver_main.tscn"},
	]

func _process(_d: float) -> bool:
	if frames > 0:
		frames -= 1
		if frames == 0:
			var img := root.get_texture().get_image()
			var path := out_dir.path_join(String(steps[idx]["name"]) + ".png")
			img.save_png(path)
			print("  shot: ", path)
		return false
	idx += 1
	if idx >= steps.size():
		print("SELECTS TOUR DONE -> ", out_dir)
		return true
	if cur != null:
		cur.queue_free()
		cur = null
	cur = (load(String(steps[idx]["scene"])) as PackedScene).instantiate()
	root.add_child(cur)
	frames = 14
	return false
