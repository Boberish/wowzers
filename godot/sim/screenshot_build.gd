## screenshot_build.gd — render a combat screen with a drafted build to eyeball the
## YOUR-VERB build panel. WSLg (NOT --headless):
##   godot --path godot --script res://sim/screenshot_build.gd -- --out=/absolute/dir
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
			img.save_png(out_dir.path_join("build_panel.png"))
			print("shot: build_panel")
			quit()
		return false
	if not set_up:
		set_up = true
		hud._seat_key = "tank"
		hud._aspect = "warden"
		hud._start_map_run()
		for i in 5:                                # draft a handful of boons
			var picks: Array = Draft.roll_offers(hud._d.run)
			if picks.is_empty():
				break
			Draft.take(hud._d.run, picks[0])
			hud._d.taken_boons.append(picks[0])
		hud._enter_node(hud._d.map.seal_id)          # the MISTRAL fight (builds the panel)
		frames = 16
	return false
