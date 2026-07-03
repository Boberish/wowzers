## screenshot_drop.gd — visual probe of the GEAR-1 drop ceremony + the raid map's
## curio strip / Cooling Paste button. WSLg (NOT --headless):
##   godot --path godot --script res://sim/screenshot_drop.gd -- --out=/absolute/dir
extends SceneTree

var out_dir := "user://shots"
var idx := -1
var frames := 0
var hud: Node = null
var steps: Array = []

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr("--out=".length())
	DirAccess.make_dir_recursive_absolute(out_dir)
	steps = ["drop_first", "drop_full_slots", "map_curios"]

func _process(_d: float) -> bool:
	if frames > 0:
		frames -= 1
		if frames == 0:
			var img := root.get_texture().get_image()
			var path := out_dir.path_join(String(steps[idx]) + ".png")
			img.save_png(path)
			print("  shot: ", path)
		return false
	idx += 1
	if idx >= steps.size():
		print("DROP TOUR DONE -> ", out_dir)
		return true
	if hud == null:
		hud = (load("res://game/raid_main.tscn") as PackedScene).instantiate()
		root.add_child(hud)
		hud._seat_key = "tank"
		hud._aspect = "warden"
		hud._start_map_run()
	match String(steps[idx]):
		"drop_first":
			hud._map_gear = []
			hud._show_drop("riftmaw_tooth", true, hud._show_map)
		"drop_full_slots":
			hud._map_gear = ["riftmaw_tooth", "cooling_paste"]
			hud._map_gear_charges = {"cooling_paste": 2}
			hud._map_tokens = 3
			hud._show_drop("swan_song", false, hud._show_map)
		"map_curios":
			hud._map_wounds[0] = 0.2
			hud._show_map()
	frames = 14
	return false
