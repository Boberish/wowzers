## screenshot_healer_frames.gd — visual probe for the RAID-FRAME MEGA UPGRADE:
## XL triage cards on the healer seat (shield crest + ward countdown, HoT icon
## chips with sweeps + seconds, debuff seal timer, hazard incoming slice), the
## "raid" variant cards on a martial seat, and the Bloomweaver growth chips.
## Interesting states are FORCE-STAGED onto live state right before the shot so
## every element is guaranteed in frame (offline, view-only probe).
## Needs a display (WSLg — NOT --headless):
##   godot --path godot --script res://sim/screenshot_healer_frames.gd -- --out=/absolute/dir
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
		{"name": "frames_well_xl", "scene": "res://game/raid_main.tscn",
			"setup": func(h): h._launch("healer", "brim"),
			"policy": func(): return WellPolicy.new(),
			"ticks": 380, "pre": func(h): _stage_states(h)},
		{"name": "frames_bloom_xl", "scene": "res://game/raid_main.tscn",
			"setup": func(h): h._launch("healer", "wildgrove"),
			"policy": func(): return BloomweaverPolicy.new(),
			"ticks": 460, "pre": func(h): _stage_states(h)},
		{"name": "frames_tank_raid_variant", "scene": "res://game/raid_main.tscn",
			"setup": func(h): h._launch("tank", "warden"),
			"policy": func(): return null,     # idle tank eats hits → the AI healer works
			"ticks": 460, "pre": func(_h): pass},
	]

## Force every frame element visible: ward on the tank (crest + extension +
## countdown), renew HoTs mid-flight, a DoT with its timer, a bloodied ally.
func _stage_states(h: Node) -> void:
	var ctrl = h.get("_ctrl")
	if ctrl == null or ctrl.state == null:
		return
	var s: CombatState = ctrl.state
	var tank: Seat = s.seats[0]
	tank.hp = minf(tank.hp, tank.hp_max * 0.62)
	tank.absorb = 64.0
	tank.absorb_owner_i = 3
	tank.ward_until_tick = s.tick + 130
	for si in [1, 2]:
		var u: Seat = s.seats[si]
		if not u.alive():
			continue
		u.hots.append({"tick": 12.0, "every": 45, "acc": 12, "left": 180 + si * 45,
			"caster_i": 3, "src": &"renew"})
	var dpsu: Seat = s.seats[1]
	dpsu.debuff = {"id": &"riftrot", "tick": 2.0, "every": 30, "acc": 6, "left": 150}
	var low: Seat = s.seats[2]
	if low.alive():
		low.hp = low.hp_max * 0.33
	# freeze the healer's hands so the staged DoT isn't cleansed before the shot
	var me: Seat = s.seats[3]
	me.gcd_until_tick = s.tick + 200
	me.cooldowns["dispel"] = s.tick + 600
	me.cooldowns["saprot"] = s.tick + 600
	h.set("_hover_seat", tank)     # gold-lit target + filigree on the hover

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
				print("HEALER FRAMES TOUR DONE -> ", out_dir)
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
			if pol != null and ("latency_ticks" in pol):
				pol.latency_ticks = 3
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
