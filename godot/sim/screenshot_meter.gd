## screenshot_meter.gd — visual probe for the DPS/HPS meter window: boots the RAID
## (tank seat, AI raiders), lets the fight run, and screenshots the meter in COMPACT
## (four raiders ranked) and DETAIL (per-spell) views, then burst-kills the boss and
## shoots the END-SCREEN recap (RecapPanel + frozen meter). Needs a display (WSLg —
## NOT --headless):
##   godot --path godot --script res://sim/screenshot_meter.gd -- --out=/absolute/dir
extends SceneTree

var out_dir := "user://shots"
var idx := -1
var phase := 0            # 0 spawn · 1 setup · 2 run-to-tick · 3 pre-shot settle · 4 capture
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
		{"name": "meter_raid_compact", "scene": "res://game/raid_main.tscn",
			"setup": func(h): h._launch("tank"),
			"policy": func(): return RaidTankPolicy.new(),
			"ticks": 780, "pre": func(_h): MeterPanel.view_state = 0},
		{"name": "meter_raid_detail", "scene": "res://game/raid_main.tscn",
			"setup": func(h): h._launch("tank"),
			"policy": func(): return RaidTankPolicy.new(),
			"ticks": 780, "pre": func(_h): MeterPanel.view_state = 1},
		{"name": "meter_raid_healing", "scene": "res://game/raid_main.tscn",
			"setup": func(h): h._launch("tank"),
			"policy": func(): return RaidTankPolicy.new(),
			"ticks": 780, "pre": func(h):
				MeterPanel.view_state = 0
				h._meter.mode = "heal"},
		{"name": "meter_raid_end", "scene": "res://game/raid_main.tscn",
			"setup": func(h): h._launch("tank"),
			"policy": func(): return RaidTankPolicy.new(),
			"ticks": 780, "pre": func(h):
				var ctrl = h.get("_ctrl")
				CombatCore.damage_boss(ctrl.state, ctrl.state.seats[0], ctrl.state.boss.hp + 10.0),
			"end_screen": true},
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
				print("METER TOUR DONE -> ", out_dir)
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
			pol = (st["policy"] as Callable).call()
			if pol.get("rng") != null or "rng" in pol:
				pol.rng = DetRng.new(4242)
			last_tick = -1
			phase = 2
		2:
			var st: Dictionary = steps[idx]
			waited += 1
			_drive_player()
			var ctrl = cur.get("_ctrl")
			var t: int = (ctrl.state.tick if ctrl != null and ctrl.state != null else 0)
			if t >= int(st["ticks"]) or waited > 5400:
				(st["pre"] as Callable).call(cur)
				phase = 3
		3:
			# settle: end-screen steps wait for the end flow (kill moment -> screen),
			# view flips just need a few frames to redraw
			var st: Dictionary = steps[idx]
			settle += 1
			_drive_player()
			if bool(st.get("end_screen", false)):
				if (String(cur.get("_screen")) == "end" and settle > 40) or settle > 900:
					phase = 4
			elif settle > 12:
				phase = 4
		4:
			var img := root.get_texture().get_image()
			var path := out_dir.path_join(String(steps[idx]["name"]) + ".png")
			img.save_png(path)
			print("  shot: ", path)
			phase = 0
	return false
