## screenshot_fermata_raid.gd — visual probe for FERMATA (Twinfang's hold-release spec) on
## THE HUD: confirms the rhythm bar renders the coil charge ring + coil cues without glitches.
## Drives a few live beats, then manually holds a coil so the shot catches the ring mid-charge
## and, in the second shot, the white-hot SHARP ring. Needs a display (WSLg — NOT --headless):
##   godot --path godot --script res://sim/screenshot_fermata_raid.gd -- --out=/absolute/dir
extends SceneTree

var out_dir := "user://shots"
var idx := -1
var phase := 0
var cur: Node = null
var waited := 0
var settle := 0
var hold_ticks := 0
var steps: Array = []

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr("--out=".length())
	DirAccess.make_dir_recursive_absolute(out_dir)
	# warm the fight, then hold a coil for N ticks so the ring is caught fills/sharp.
	steps = [
		{"name": "fermata_coil_charging", "warm": 150, "hold": 5},   # ~0.17s coiled → ring ~half
		{"name": "fermata_coil_sharp",    "warm": 150, "hold": 14},  # ~0.47s coiled → white-hot sharp
	]

func _ctrl():
	return cur.get("_ctrl") if cur != null else null

func _blade() -> Seat:
	var c = _ctrl()
	if c == null or c.state == null:
		return null
	return c.state.seats[1]

func _process(_d: float) -> bool:
	match phase:
		0:
			idx += 1
			if idx >= steps.size():
				print("FERMATA RAID SHOTS DONE -> ", out_dir)
				return true
			if cur != null:
				cur.queue_free(); cur = null
			cur = (load("res://game/raid_main.tscn") as PackedScene).instantiate()
			root.add_child(cur)
			waited = 0; settle = 0; hold_ticks = 0
			phase = 1
		1:
			cur._launch("blade", "fermata")
			phase = 2
		2:
			# warm the fight with the AI so there's Flow/combo on the HUD, then drop the policy.
			var c = _ctrl()
			var seat := _blade()
			if c != null and c.state != null and not c.state.over and seat != null and seat.policy != null and seat.alive():
				var a: Dictionary = seat.policy.act(CombatCore.observe(c.state, seat))
				if not a.is_empty():
					c.human(a)
			waited += 1
			if waited >= int(steps[idx]["warm"]):
				var s := _blade()
				if s != null:
					s.policy = null                       # stop the AI — we hold the coil ourselves
				# start a coil (mid-air, since resets don't matter for the ring shot)
				c.human({"type": "ability", "id": "coil"})
				phase = 3
		3:
			hold_ticks += 1
			if hold_ticks >= int(steps[idx]["hold"]):
				phase = 4
		4:
			settle += 1
			if settle > 3:
				phase = 5
		5:
			var img := root.get_texture().get_image()
			var path := out_dir.path_join(String(steps[idx]["name"]) + ".png")
			img.save_png(path)
			print("  shot: ", path, "  (coiling=", _blade().vars.get("coiling", false),
				" sharp=", _blade().vars.get("sharp", false), ")")
			phase = 0
	return false
