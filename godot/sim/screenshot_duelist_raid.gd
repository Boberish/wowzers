## screenshot_duelist_raid.gd — visual probe for THE DUELIST (dodge tank) on the game HUD:
## the DuelistBand (HP + FLOW/AGGRO orb + WIND bubble + ◆ pips + DODGE/PARRY/DUMP/EN GARDE runes)
## + the DuelistGauge, driven by DuelistPolicy so shots catch parries/counters/flow mid-fight.
## Needs a display (WSLg — NOT --headless):
##   godot --path godot --rendering-driver opengl3 --script res://sim/screenshot_duelist_raid.gd -- --out=/absolute/dir
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
		{"name": "duelist_raid", "scene": "res://game/raid_main.tscn",
			"setup": func(h): h._launch("tank", "duelist"), "ticks": 360},
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
				print("DUELIST RAID TOUR DONE -> ", out_dir)
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
			pol = DuelistPolicy.new() if int(st["ticks"]) > 0 else null
			if pol != null:
				pol.latency_ticks = 2
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
			if settle > 8:
				phase = 4
		4:
			var img := root.get_texture().get_image()
			var path := out_dir.path_join(String(steps[idx]["name"]) + ".png")
			img.save_png(path)
			print("  shot: ", path)
			phase = 0
	return false
