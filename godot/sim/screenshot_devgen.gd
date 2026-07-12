## screenshot_devgen.gd — eyeball the DEV · BOSS TEST screen (with the GENERATED SETUP
## toggle) and the GENERATED SETUP preview. WSLg (NOT --headless):
##   godot --path godot --script res://sim/screenshot_devgen.gd -- --out=/absolute/dir
extends SceneTree

var out_dir := "user://shots"
var shell: Node = null
var stage := 0
var frames := 0

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr("--out=".length())
	DirAccess.make_dir_recursive_absolute(out_dir)

func _shot(name: String) -> void:
	var img := root.get_texture().get_image()
	img.save_png(out_dir.path_join(name + ".png"))
	print("shot: " + name)

func _process(_d: float) -> bool:
	if shell == null:
		shell = (load("res://game/world_shell.tscn") as PackedScene).instantiate()
		root.add_child(shell)
		frames = 8
		return false
	if frames > 0:
		frames -= 1
		return false
	stage += 1
	match stage:
		1:                                       # the extended boss-test screen, AVG BUILD on
			shell._dev_seat = "well"
			shell._dev_aspect = "draw"
			shell._dev_gen = true
			shell._dev_anchor = "vigil"
			shell._show_boss_test()
			frames = 10
		2:
			_shot("devgen_bosstest")
			shell._dev_seed = 424242             # a fixed seed → a reproducible shot
			shell._show_gen_preview("gemini", "GEMINI ULTRA")
			frames = 10
		3:
			_shot("devgen_preview")
			quit()
	return false
