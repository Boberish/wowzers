## artv2_scene_tour.gd — the C2 Scene Profile visual gate. Boots THE RIFT into a
## live all-AI raid with a chosen ART-V2 scene profile and saves PNG sheets, plus
## prints every actor's position at each shot — the FEET-LINE RECORD: positions
## must be numerically identical across profiles (scene layers may not move the
## combat floor contract; RaidStage2D.SLOTS owns the feet).
## Run per profile × resolution (needs a display, e.g. WSLg — NOT --headless):
##   godot --path godot --rendering-driver opengl3 --resolution 1920x1080 \
##     --script res://sim/artv2_scene_tour.gd -- --profile=v2_interior_test --out=/abs/dir
## --profile absent/empty = legacy. Shots are named <profile>_<WxH>_<frame>.png.
extends SceneTree

var out_dir := "user://shots_artv2"
var profile := ""
var hud: Node = null
var frame := -1
var shots: Dictionary = {}
var last_frame := 0

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr("--out=".length())
		elif a.begins_with("--profile="):
			profile = a.substr("--profile=".length())
		elif a == "--actors":
			ArtV2.actors = true   # C4: painted adapters answer Actor2D.make
	DirAccess.make_dir_recursive_absolute(out_dir)
	# the seam under test: set the selector BEFORE the HUD instances — its
	# _ready builds the backdrop through ArtV2.make_scene() -> SceneKit.make()
	ArtV2.scene = profile
	hud = (load("res://game/raid_main.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	for f in [40, 160, 300]:
		shots[f] = true
	last_frame = 310

func _process(_delta: float) -> bool:
	frame += 1
	if frame == 1:
		hud._launch("tank", "")
		var s: CombatState = hud._ctrl.state
		s.seats[0].policy = RaidNet.make_policy("tank", 20260712)
	if shots.has(frame):
		var vp := root.get_visible_rect().size
		var name := "%s_%dx%d_f%03d" % [profile if profile != "" else "legacy",
			int(vp.x), int(vp.y), frame]
		var img := root.get_texture().get_image()
		img.save_png(out_dir.path_join(name + ".png"))
		print("  shot: ", out_dir.path_join(name + ".png"))
		_feet_record()
	if frame >= last_frame:
		var stage = hud._stage
		print("SCENE TOUR DONE — profile '%s' stage=%s" % [
			profile if profile != "" else "legacy",
			"SceneKit" if stage is SceneKit else "StageBackdrop"])
		quit(0)
	return false

## The feet-line record: SLOTS fractions + live actor positions. Diff these lines
## across profile runs at the same resolution — any drift = a C2 law violation.
func _feet_record() -> void:
	var st = hud._stage2d
	if st == null:
		return
	var line := "  FEET f%03d boss=%s" % [frame, st.boss_actor.position.round()]
	for i in st.actors.size():
		line += " a%d=%s" % [i, (st.actors[i] as Node2D).position.round()]
	print(line)
