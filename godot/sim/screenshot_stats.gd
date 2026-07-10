## screenshot_stats.gd — visual probe for THE FULL REPORT (StatsPage, STATS PAGE v2).
## Boots the RAID (tank seat + AI raiders), drives a partial fight so the meter / diag /
## boon_meter / series fill, burst-kills the boss to reach the end screen, opens the FULL
## REPORT, and screenshots it for the player seat and then an ally seat. Needs a display
## (WSLg — NOT --headless; headless can't render custom _draw):
##   godot --path godot --script res://sim/screenshot_stats.gd -- --out=/absolute/dir
extends SceneTree

var out_dir := "user://shots"
var phase := 0            # 0 boot · 1 setup · 2 run · 3 kill+wait-end · 4 open-report · 5 shoot-you · 6 focus-ally · 7 shoot-ally · 8 done
var cur: Node = null
var pol: Policy = null
var waited := 0
var settle := 0
var last_tick := -1

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr("--out=".length())
	DirAccess.make_dir_recursive_absolute(out_dir)

func _drive() -> void:
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

func _page() -> Node:
	# the StatsPage lives under _ui -> ScrollContainer -> StatsPage
	var ui = cur.get("_ui")
	if ui == null:
		return null
	for c in ui.get_children():
		if c is ScrollContainer and c.get_child_count() > 0:
			return c.get_child(0)
	return null

func _shoot(name: String) -> void:
	var img := root.get_texture().get_image()
	var path := out_dir.path_join(name + ".png")
	img.save_png(path)
	print("  shot: ", path)

func _process(_d: float) -> bool:
	match phase:
		0:
			cur = (load("res://game/raid_main.tscn") as PackedScene).instantiate()
			root.add_child(cur)
			phase = 1
		1:
			cur._launch("tank")
			pol = DuelistPolicy.new()
			if "rng" in pol:
				pol.rng = DetRng.new(4242)
			last_tick = -1
			waited = 0
			phase = 2
		2:
			waited += 1
			_drive()
			var ctrl = cur.get("_ctrl")
			var t: int = (ctrl.state.tick if ctrl != null and ctrl.state != null else 0)
			if t >= 900 or waited > 5400:
				phase = 3
				settle = 0
		3:
			# burst-kill the boss, then wait for the end screen to settle in
			settle += 1
			if settle == 1:
				var ctrl = cur.get("_ctrl")
				CombatCore.damage_boss(ctrl.state, ctrl.state.seats[0], ctrl.state.boss.hp + 10.0)
			_drive()
			if (String(cur.get("_screen")) == "end" and settle > 40) or settle > 900:
				phase = 4
				settle = 0
		4:
			cur._show_stats_page(func(): pass)
			settle = 0
			phase = 5
		5:
			settle += 1
			if settle > 20:
				_shoot("stats_report_you")
				phase = 6
		6:
			var page := _page()
			if page != null and cur.get("_ctrl").state.seats.size() > 1:
				page.set("_focus_i", 1)      # an ally seat (blade)
				page.queue_redraw()
			settle = 0
			phase = 7
		7:
			settle += 1
			if settle > 20:
				_shoot("stats_report_ally")
				phase = 8
		8:
			print("STATS TOUR DONE -> ", out_dir)
			return true
	return false
