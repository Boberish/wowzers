## screenshot_ledger.gd — render the Ledger page to check the item effects show. WSLg:
##   godot --path godot --script res://sim/screenshot_ledger.gd -- --out=/absolute/dir
extends SceneTree

var out_dir := "user://shots"
var hud: Node = null
var frames := 0
var set_up := false

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
			img.save_png(out_dir.path_join("ledger.png"))
			print("shot: ledger (screen=%s)" % hud._screen)
			quit()
		return false
	if not set_up:
		set_up = true
		hud._seat_key = "tank"
		hud._aspect = "warden"
		hud._start_map_run()                        # loads the gear/oath state
		hud._offer_oath_then("riftmaw", func(): pass)   # the Ledger page (riftmaw has oath rows)
		frames = 14
	return false
