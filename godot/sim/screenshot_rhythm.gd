## screenshot_rhythm.gd — TEMP visual probe for THE RHYTHM (BOSS-PLAN §3½) on the game HUD:
## launches THE FIRST DESCENT FIGHT (forge swarm t1) as the Duelist and shoots the moments
## that prove the design: the bar winding up · the in-zone DODGE flash · a real telegraph
## interleaving · the Carapace Snap parry bar. WSLg (NOT --headless):
##   godot --path godot --rendering-driver opengl3 --script res://sim/screenshot_rhythm.gd -- --out=/abs/dir
extends SceneTree

var out_dir := "user://shots"
var cur: Node = null
var pol: Policy = null
var phase := 0
var last_tick := -1
var got := {}          # shot name -> true
const WANT := ["bar_windup", "bar_zone", "telegraph_layer", "snap_parry"]

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr("--out=".length())
	DirAccess.make_dir_recursive_absolute(out_dir)

func _shoot(name: String) -> void:
	if got.has(name):
		return
	got[name] = true
	var img := root.get_texture().get_image()
	var p := out_dir.path_join(name + ".png")
	img.save_png(p)
	print("  shot: ", p)

func _process(_d: float) -> bool:
	match phase:
		0:
			cur = (load("res://game/raid_main.tscn") as PackedScene).instantiate()
			root.add_child(cur)
			phase = 1
		1:
			cur._launch("tank", "duelist", "forge:takeover:swarm:1:301")
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
			# the moments (shot on the RENDER frame, state mid-flight)
			var me = ctrl.player()
			if me != null:
				var obs: Dictionary = CombatCore.observe(s, me)
				var ry: Dictionary = obs.get("rhythm", {})
				if not ry.is_empty() and s.telegraph == null:
					var rem := float(ry.get("remaining", 0.0))
					if rem > 0.30:
						_shoot("bar_windup")
					elif rem <= 0.25 and rem > 0.02:
						_shoot("bar_zone")
				if s.telegraph != null:
					_shoot("telegraph_layer")
					if String(s.telegraph.ability.id) == "f_snap":
						_shoot("snap_parry")
			if got.size() >= WANT.size() or s.over or s.tick > 2700:
				phase = 3
		3:
			print("RHYTHM SHOTS DONE -> ", out_dir, "  (", got.keys(), ")")
			return true
	return false
