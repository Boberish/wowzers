## raid_stage_tour.gd — boots THE RIFT into a live all-AI raid (the local seat's
## policy is restored, so all four raiders play) and saves a PNG contact sheet of
## the all-together 2D stage: lineup, boss wind-ups, kicks, volleys, deaths.
## Run (needs a display, e.g. WSLg — NOT --headless):
##   godot --path godot --script res://sim/raid_stage_tour.gd --resolution 1920x1080 -- --out=/absolute/dir
extends SceneTree

var out_dir := "user://shotsraid"
var hud: Node = null
var frame := -1
var shots: Dictionary = {}
var last_frame := 0

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr("--out=".length())
	DirAccess.make_dir_recursive_absolute(out_dir)
	hud = (load("res://game/raid_main.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	for f in range(40, 820, 60):
		shots[f] = "shot_%03d" % f
	last_frame = 830

func _process(_delta: float) -> bool:
	frame += 1
	if frame == 1:
		hud._launch("tank", "warden")
		# hand the local seat back to AI: a full AI raid acts every seat
		var s: CombatState = hud._ctrl.state
		s.seats[0].policy = RaidNet.make_policy("tank", 20260702)
	if shots.has(frame):
		var img := root.get_texture().get_image()
		img.save_png(out_dir.path_join(String(shots[frame]) + ".png"))
		print("  shot: ", out_dir.path_join(String(shots[frame]) + ".png"))
	return frame >= last_frame
