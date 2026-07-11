## screenshot_lane.gd — TEMP. THE NO-STROBE PROOF: consecutive frames + state moments of
## THE RHYTHM LANE in fight-1 (forge swarm t1). The lane must appear in EVERY shot:
## armed (comet approaching) · gap (hollow next-ETA comet) · paused (boss winds up).
##   godot --path godot --rendering-driver opengl3 --script res://sim/screenshot_lane.gd -- --out=/abs/dir
extends SceneTree

var out_dir := "user://shots"
var cur: Node = null
var pol: Policy = null
var phase := 0
var last_tick := -1
var got := {}
var consec := 0

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr("--out=".length())
	DirAccess.make_dir_recursive_absolute(out_dir)

func _shoot(name: String) -> void:
	if got.has(name):
		return
	got[name] = true
	root.get_texture().get_image().save_png(out_dir.path_join(name + ".png"))
	print("  shot: ", name)

func _process(_d: float) -> bool:
	match phase:
		0:
			cur = (load("res://game/raid_main.tscn") as PackedScene).instantiate()
			root.add_child(cur)
			phase = 1
		1:
			cur._launch("tank", "duelist")
			pol = DuelistPolicy.new()
			pol.latency_ticks = 4
			pol.rng = DetRng.new(777)
			phase = 2
		2:
			var ctrl = cur.get("_ctrl")
			if ctrl == null or ctrl.state == null:
				return false
			var s = ctrl.state
			if s.tick != last_tick:
				last_tick = s.tick
				var seat = ctrl.player()
				if pol != null and seat != null and seat.alive():
					var a = pol.act(CombatCore.observe(s, seat))
					if not a.is_empty():
						ctrl.human(a)
			# consecutive burst early (catches any strobe frame-to-frame)
			if s.tick > 40 and consec < 5:
				_shoot("consec%d" % consec)
				consec += 1
			# state moments
			var me = ctrl.player()
			if me != null:
				var lane: Dictionary = CombatCore.observe(s, me).get("rhythm_lane", {})
				if not lane.is_empty() and s.telegraph == null:
					if bool(lane.get("armed", false)) and int(lane.get("size", 1)) >= 2:
						_shoot("heavy_bar")
					elif not bool(lane.get("armed", false)):
						_shoot("rhythm_next")
				# AAA slam proof: fire, let it render a couple frames, THEN shoot
				if s.tick >= 120 and not got.has("fired_p") and cur._band != null and cur._band.slam != null:
					got["fired_p"] = true
					cur._band.slam.slam("PERFECT PARRY  ×3", "perfect")
				elif got.has("fired_p") and s.tick >= 126 and not got.has("slam_perfect"):
					_shoot("slam_perfect")
				if s.tick >= 260 and not got.has("fired_h") and cur._band != null and cur._band.slam != null:
					got["fired_h"] = true
					cur._band.slam.slam("HIT", "hit")
				elif got.has("fired_h") and s.tick >= 266 and not got.has("slam_hit"):
					_shoot("slam_hit")
			if got.size() >= 10 or s.over or s.tick > 3600:
				phase = 3
		3:
			print("LANE SHOTS DONE -> ", out_dir, "  ", got.keys())
			return true
	return false
