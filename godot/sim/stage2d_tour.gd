## stage2d_tour.gd — boots the Twinfang HUD straight into a live 2D-stage fight
## (Tempo vs The Executioner) with the real TwinfangPolicy piloting the seat, so
## Perfect strikes, dodges, Kicks and string-dodges fire naturally, and saves a
## PNG contact sheet for visual verification without a human at the keyboard.
## Run (needs a display, e.g. WSLg — NOT --headless):
##   godot --path godot --script res://sim/stage2d_tour.gd --resolution 1920x1080 -- --out=/absolute/dir
extends SceneTree

var out_dir := "user://shots2d"
var hud: Node = null
var frame := -1
var shots: Dictionary = {}
var last_frame := 0

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr("--out=".length())
	DirAccess.make_dir_recursive_absolute(out_dir)
	hud = (load("res://game/twinfang_main.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	for f in range(40, 620, 40):
		shots[f] = "shot_%03d" % f
	last_frame = 630

func _process(_delta: float) -> bool:
	frame += 1
	if frame == 1:                 # hud._ready has run — safe to start the fight
		hud._start_run("tempo", "executioner")
		var pol := TwinfangPolicy.new()
		pol.rng = DetRng.new(20260702)
		hud._ctrl.state.seats[0].policy = pol
	if shots.has(frame):
		var img := root.get_texture().get_image()
		var path := out_dir.path_join(String(shots[frame]) + ".png")
		img.save_png(path)
		print("  shot: ", path)
	return frame >= last_frame
