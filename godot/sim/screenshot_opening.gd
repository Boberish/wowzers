## screenshot_opening.gd — boots THE RIFT as the BLADE seat (Tempo) vs a Seal, hands the
## seat to AI so it auto-plays, and captures the raid HUD whenever THE OPENING window is
## live (so the fancy vulnerability bar is caught mid-punish). WSLg — NOT --headless.
##   godot --path godot --script res://sim/screenshot_opening.gd --resolution 1920x1080 -- --out=/absolute/dir
extends SceneTree

var out_dir := "user://shotsopen"
var hud: Node = null
var frame := -1
var shots := 0
var last_shot_f := -999
const MAX_SHOTS := 14

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr("--out=".length())
	DirAccess.make_dir_recursive_absolute(out_dir)
	hud = (load("res://game/raid_main.tscn") as PackedScene).instantiate()
	root.add_child(hud)

func _process(_delta: float) -> bool:
	frame += 1
	if frame == 1:
		hud._launch("blade", "tempo")
		var s: CombatState = hud._ctrl.state
		s.seats[1].policy = RaidNet.make_policy("blade", 20260704)   # blade = seat 1, auto-play
	if frame < 3 or hud._ctrl == null or hud._ctrl.state == null:
		return false
	var s: CombatState = hud._ctrl.state
	var blade: Seat = s.seats[1]
	if not blade.alive() or s.over:
		return shots >= 3 or frame > 2400
	# shoot when the opening window is live (or just resolved), spaced out
	var obs := CombatCore.observe(s, blade)
	var open_live: bool = int(obs.get("open_to", -1)) >= s.tick
	if open_live and frame - last_shot_f >= 6 and shots < MAX_SHOTS:
		var img := root.get_texture().get_image()
		img.save_png(out_dir.path_join("open_%02d.png" % shots))
		print("  shot %d @ frame %d  (open peak in %d ticks)" % [shots, frame, int(obs.get("open_peak", 0)) - s.tick])
		shots += 1
		last_shot_f = frame
	return shots >= MAX_SHOTS or frame > 2400
