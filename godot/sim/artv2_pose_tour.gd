## artv2_pose_tour.gd — the C5 pose/contact tour: one contact-sheet screenshot
## of the painted Duelist frozen mid-verb across the whole vocabulary. Slots:
## idle · windup(light)@0.5 · windup(light)@1.0 · windup(heavy)@0.6 (replacement
## frame, SCRUBBED) · swing(heavy) (release flash) · parry (evade_react) ·
## hit(big) · die. Also prints the missing-assets fallback check.
##   godot --path godot --rendering-driver opengl3 --resolution 1920x1080 \
##     --script res://sim/artv2_pose_tour.gd -- --out=/abs/dir
extends SceneTree

var out_dir := "user://shots_pose"
var frame := -1
var actors: Array = []
const SHOT_FRAME := 90
# DIE leads (C5.1): the death fall sweeps ~400px LEFT of its slot — first slot
# falls into empty margin instead of lying across a neighbor (Bill's visibility goal)
const LABELS := ["DIE", "IDLE", "WINDUP 0.5", "WINDUP 1.0", "WINDUP HEAVY 0.6 (frame)",
	"SWING HEAVY (frame)", "PARRY", "HIT"]

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr("--out=".length())
	DirAccess.make_dir_recursive_absolute(out_dir)
	var bg := ColorRect.new()
	bg.color = Color(0.16, 0.17, 0.20)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	print("fallback: try_make('zzz_no_such_class') == null -> %s" % (PaintedActor2D.try_make("zzz_no_such_class") == null))
	for i in LABELS.size():
		var act := PaintedActor2D.try_make("duelist")
		if act == null:
			print("POSE TOUR: FAIL — duelist adapter did not build")
			quit(1)
			return
		act.position = Vector2(420.0 + float(i) * 195.0, 640.0)
		act.scale = Vector2.ONE * 1.35
		root.add_child(act)
		actors.append(act)
		var lb := Label.new()
		lb.text = LABELS[i]
		lb.add_theme_font_size_override("font_size", 14)
		lb.position = Vector2(350.0 + float(i) * 195.0, 690.0)
		lb.size = Vector2(200, 40)
		lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		root.add_child(lb)

func _process(_delta: float) -> bool:
	frame += 1
	if frame < 2 or actors.is_empty():
		return false
	# scrubbed windups: fed EVERY frame, like the stage does
	(actors[2] as Actor2D).windup("light", 0.5)
	(actors[3] as Actor2D).windup("light", 1.0)
	(actors[4] as Actor2D).windup("heavy", 0.6)
	if frame == SHOT_FRAME - 45:
		(actors[0] as Actor2D).die()
	if frame == SHOT_FRAME - 6:
		(actors[7] as Actor2D).hit_react(true)
	if frame == SHOT_FRAME - 5:
		(actors[6] as Actor2D).evade_react()
	if frame == SHOT_FRAME - 3:
		(actors[5] as Actor2D).swing("heavy")
	if frame == SHOT_FRAME:
		var img := root.get_texture().get_image()
		var path := out_dir.path_join("duelist_pose_sheet.png")
		img.save_png(path)
		print("  shot: ", path)
		print("POSE TOUR DONE (8 verbs)")
		quit(0)
	return false
