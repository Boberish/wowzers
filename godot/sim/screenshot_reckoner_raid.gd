## screenshot_reckoner_raid.gd — visual probe for THE RECKONER (6th class) on the game HUD:
## the class-select (6 cards) + the Reckoner combat band (HP + RAGE orbs, the WIND/APEX
## swing instrument with the Momentum tachometer + Poise-Break meter, and the
## Overswing/Ultraswing/Onslaught/Signature rune rail), both aspects.
## Needs a display (WSLg — NOT --headless):
##   godot --path godot --script res://sim/screenshot_reckoner_raid.gd -- --out=/absolute/dir
extends SceneTree

var out_dir := "user://shots"
var idx := -1
var phase := 0
var cur: Node = null
var waited := 0
var settle := 0
var last_tick := -1
var pol: Policy = null
var steps: Array = []

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr("--out=".length())
	DirAccess.make_dir_recursive_absolute(out_dir)
	steps = [
		{"name": "reckoner_class_select", "scene": "res://game/raid_main.tscn",
			"setup": func(h): h._show_class_select(), "ticks": 0},
		{"name": "reckoner_raid_colossus", "scene": "res://game/raid_main.tscn",
			"setup": func(h): h._launch("blade", "colossus"), "ticks": 300},
		{"name": "reckoner_raid_berserker", "scene": "res://game/raid_main.tscn",
			"setup": func(h): h._launch("blade", "berserker"), "ticks": 380},
	]

func _drive_player() -> void:
	var ctrl = cur.get("_ctrl")
	if ctrl == null or ctrl.state == null or ctrl.state.over:
		return
	if ctrl.state.tick == last_tick:
		return
	last_tick = ctrl.state.tick
	var seat: Seat = ctrl.player() if ctrl.has_method("player") else ctrl.state.seats[0]
	if pol != null and seat != null and seat.alive():
		var a: Dictionary = pol.act(CombatCore.observe(ctrl.state, seat))
		if not a.is_empty():
			ctrl.human(a)

func _process(_d: float) -> bool:
	match phase:
		0:
			idx += 1
			if idx >= steps.size():
				print("RECKONER RAID TOUR DONE -> ", out_dir)
				return true
			if cur != null:
				cur.queue_free()
				cur = null
			cur = (load(String(steps[idx]["scene"])) as PackedScene).instantiate()
			root.add_child(cur)
			waited = 0
			settle = 0
			phase = 1
		1:
			var st: Dictionary = steps[idx]
			(st["setup"] as Callable).call(cur)
			pol = ReckonerPolicy.new() if int(st["ticks"]) > 0 else null
			if pol != null:
				if "latency_ticks" in pol:
					pol.latency_ticks = 3
				if "rng" in pol:
					pol.rng = DetRng.new(9137)
			last_tick = -1
			phase = 2
		2:
			var st: Dictionary = steps[idx]
			waited += 1
			_drive_player()
			var ctrl = cur.get("_ctrl")
			var t: int = (ctrl.state.tick if ctrl != null and ctrl.state != null else 0)
			if t >= int(st["ticks"]) or waited > 5400:
				phase = 3
		3:
			settle += 1
			_drive_player()
			if settle > 14:
				phase = 4
		4:
			var img := root.get_texture().get_image()
			var path := out_dir.path_join(String(steps[idx]["name"]) + ".png")
			img.save_png(path)
			print("  shot: ", path)
			phase = 0
	return false
