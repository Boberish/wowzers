## stage3d_tour.gd — boots the Bulwark HUD straight into a live 3D-stage fight
## (Warden vs Gatekeeper) with the real BulwarkPolicy AI piloting the seat, so
## parries, dodges and abilities fire naturally, and saves a contact sheet of PNGs
## so the stage's look and acting can be verified without a human at the keyboard.
## Run (needs a display, e.g. WSLg — NOT --headless):
##   godot --path godot --script res://sim/stage3d_tour.gd --resolution 1920x1080 -- --out=/absolute/dir
extends SceneTree

var out_dir := "user://shots3d"
var hud: Node = null
var frame := -1
var shots: Dictionary = {}       # frame -> name
var last_frame := 0

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr("--out=".length())
	DirAccess.make_dir_recursive_absolute(out_dir)

	hud = (load("res://game/bulwark_main.tscn") as PackedScene).instantiate()
	root.add_child(hud)

	for f in range(40, 620, 40):
		shots[f] = "shot_%03d" % f
	last_frame = 630

func _process(_delta: float) -> bool:
	frame += 1
	if frame == 1:                 # hud._ready has run by now — safe to start the fight
		hud._start_run("warden", "gatekeeper")
		# hand the seat to the real AI: it parries / dodges strings / plays the kit,
		# so the tour photographs genuine acting instead of a punching bag
		var pol := BulwarkPolicy.new()
		pol.rng = DetRng.new(20260702)
		hud._ctrl.state.seats[0].policy = pol
	if shots.has(frame):
		var img := root.get_texture().get_image()
		var path := out_dir.path_join(String(shots[frame]) + ".png")
		img.save_png(path)
		print("  shot: ", path)
	return frame >= last_frame
