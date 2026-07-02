## screenshot_strings.gd — M7 visual probe: boots the Duelist (Flourish string) and
## Rendmaw (Rending Barrage) and screenshots the dial MID-STRING, so the beat pips,
## feint pip, grade colours and prompt ladder can be eyeballed without a human.
## Needs a display (WSLg — NOT --headless):
##   godot --path godot --script res://sim/screenshot_strings.gd -- --out=/absolute/dir
extends SceneTree

var out_dir := "user://shots"
var idx := -1
var phase := 0            # 0 spawn · 1 setup · 2 wait-for-string · 3 hold · 4 capture
var cur: Node = null
var hold := 0
var waited := 0
var last_tick := -1
var pol: Policy = null    # probe-side player policy (CombatController nulls the seat's own)
var steps: Array = []

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr("--out=".length())
	DirAccess.make_dir_recursive_absolute(out_dir)
	steps = [
		{"name": "m7_duelist_flourish", "scene": "res://game/bulwark_main.tscn",
			"setup": func(h): h._start_run("warden", "duelist"), "ability": &"flourish",
			"policy": func(): return BulwarkPolicy.new(), "delay": 75},
		{"name": "m7_rendmaw_barrage", "scene": "res://game/mender_main.tscn",
			"setup": func(h): h._start_run("tidecaller", "rendmaw"), "ability": &"barrage",
			"policy": func(): return MenderPolicy.new(), "delay": 80},
	]

## Drive the player seat with its own attached policy (perfect play, rng-less =
## perfect reads) so the fight survives long enough to photograph a live string —
## and so answered beats show their grade pips.
func _drive_player() -> void:
	var ctrl = cur.get("_ctrl")
	if ctrl == null or ctrl.state == null or ctrl.state.over:
		return
	if ctrl.state.tick == last_tick:
		return                       # act once per SIM tick, like the sims — never double-press
	last_tick = ctrl.state.tick
	var seat: Seat = ctrl.state.seats[0]
	if pol != null and seat.alive():
		var a: Dictionary = pol.act(CombatCore.observe(ctrl.state, seat))
		if not a.is_empty():
			ctrl.human(a)

func _process(_d: float) -> bool:
	match phase:
		0:
			idx += 1
			if idx >= steps.size():
				print("M7 STRINGS TOUR DONE -> ", out_dir)
				return true
			if cur != null:
				cur.queue_free()
				cur = null
			var st: Dictionary = steps[idx]
			cur = (load(String(st["scene"])) as PackedScene).instantiate()
			root.add_child(cur)
			waited = 0
			phase = 1
		1:
			var st: Dictionary = steps[idx]
			(st["setup"] as Callable).call(cur)
			pol = (st["policy"] as Callable).call()
			last_tick = -1
			phase = 2
		2:
			# wait for THE string telegraph to go live (safety-capped at ~60s of frames)
			var st: Dictionary = steps[idx]
			waited += 1
			_drive_player()
			var ctrl = cur.get("_ctrl")
			var live: bool = ctrl != null and ctrl.state != null \
				and ctrl.state.telegraph != null \
				and ctrl.state.telegraph.ability.id == StringName(st["ability"])
			if live or waited > 3600:
				phase = 3
		3:
			# capture MID-string, by sim time not frames (WSLg fps varies): shoot at
			# ~55% of the wind-up; if the string ended first, re-arm for the next cast
			_drive_player()
			var ctrl2 = cur.get("_ctrl")
			if ctrl2 == null or ctrl2.state == null:
				phase = 2
			else:
				var tgl = ctrl2.state.telegraph
				var st2: Dictionary = steps[idx]
				if waited > 3600:
					phase = 4
				elif tgl == null or tgl.ability.id != StringName(st2["ability"]):
					phase = 2
				elif ctrl2.state.tick - tgl.start_tick >= int(0.55 * float(tgl.dur_ticks)):
					phase = 4
		4:
			var img := root.get_texture().get_image()
			var path := out_dir.path_join(String(steps[idx]["name"]) + ".png")
			img.save_png(path)
			print("  shot: ", path)
			phase = 0
	return false
