## PoseRig2D — the 2D cutout-puppet twin of PoseRig (stage3d). A rig is a hierarchy
## of Node2D "joints" dressed with two-tone DRAWN limb shapes (no textures — vector
## cutouts, Darkest-Dungeon-style side view), animated by the same grammar as the 3D
## stage: named poses (per-joint rotation + position offsets), eased blending, action
## SEQUENCES, a stage-driven WINDUP overlay (the telegraph made body language),
## breathing and impact-jolt layers, and per-part glow/flash. Pure view layer.
## Rigs are BUILT FACING +X (right); the stage flips the boss with scale.x = -1.
## Real cutout art later (textured Polygon2D / Skeleton2D) replaces Limb draws only.
class_name PoseRig2D
extends Actor2D

## One drawn body part: capsule (tapered limb), circle, blade, or poly. Drawn with
## a dark shadow pass under a flat fill — cheap cel look that reads at stage size.
class Limb extends Node2D:
	var kind := "capsule"                  # capsule | circle | blade | poly
	var a := Vector2.ZERO                  # capsule from / blade base
	var b := Vector2(20, 0)                # capsule to  / blade tip
	var w1 := 8.0                          # radius at a (or circle radius / blade half-width)
	var w2 := 6.0                          # radius at b
	var col := Color.WHITE
	var pts := PackedVector2Array()        # poly kind
	var glow_col := Color.WHITE            # resting additive glow (0 energy = off)
	var glow := 0.0
	var flash := 0.0                       # transient overlay, decayed by the rig
	var flash_col := Color.WHITE

	func _draw() -> void:
		var shadow := Color(0, 0, 0, 0.35)
		match kind:
			"capsule":
				_capsule(a, b, w1 + 2.0, w2 + 2.0, shadow, Vector2(0, 2))
				_capsule(a, b, w1, w2, col, Vector2.ZERO)
			"circle":
				draw_circle(a + Vector2(0, 2), w1 + 2.0, shadow)
				draw_circle(a, w1, col)
			"blade":
				var d := (b - a).normalized()
				var n := Vector2(-d.y, d.x) * w1
				var p := PackedVector2Array([a + n, b + d * 2.0, a - n])
				draw_colored_polygon(p, col)
			"poly":
				if pts.size() >= 3:
					var sh := PackedVector2Array()
					for v in pts:
						sh.append(v + Vector2(0, 2.5))
					draw_colored_polygon(sh, shadow)
					draw_colored_polygon(pts, col)
		# resting glow + transient flash, additively over the fill
		var g := maxf(glow, flash)
		if g > 0.01:
			var gc := flash_col if flash > glow else glow_col
			gc.a = clampf(g, 0.0, 1.0) * 0.85
			match kind:
				"capsule": _capsule(a, b, w1 + 1.0, w2 + 1.0, gc, Vector2.ZERO)
				"circle": draw_circle(a, w1 + 1.0, gc)
				"blade":
					var d2 := (b - a).normalized()
					var n2 := Vector2(-d2.y, d2.x) * (w1 + 1.0)
					draw_colored_polygon(PackedVector2Array([a + n2, b + d2 * 3.0, a - n2]), gc)
				"poly":
					if pts.size() >= 3:
						draw_colored_polygon(pts, gc)

	func _capsule(p1: Vector2, p2: Vector2, r1: float, r2: float, c: Color, off: Vector2) -> void:
		draw_circle(p1 + off, r1, c)
		draw_circle(p2 + off, r2, c)
		var d := (p2 - p1).normalized()
		var n1 := Vector2(-d.y, d.x) * r1
		var n2 := Vector2(-d.y, d.x) * r2
		draw_colored_polygon(PackedVector2Array(
			[p1 + off + n1, p2 + off + n2, p2 + off - n2, p1 + off - n1]), c)

var _joints: Dictionary = {}       # name -> Node2D
var _rest: Dictionary = {}         # name -> rest local position
var _parts: Dictionary = {}        # name -> Limb (glow/flash targets)
var _poses: Dictionary = {}        # name -> {joint: [rot_rad, Vector2]}

var _from: Dictionary = {}
var _to_pose: String = "idle"
var _t: float = 0.0
var _dur: float = 0.3
var _easing: String = "out"
var _hold: float = 0.0
var _seq: Array = []
var base_pose: String = "idle"
var recover_dur: float = 0.45

var windup_pose: String = ""
var windup_amt: float = 0.0

var breaths: Array = []            # {joint, amp_deg, freq, phase, pos: Vector2}
var breath_scale: float = 1.0
var highlight_y: float = -350.0    # where the gaze marker floats
var _jolt: float = 0.0
var _jolt_dir := Vector2.ZERO
var _time: float = 0.0
var _hl: Node2D = null

func _ready() -> void:
	_build()
	_define_poses()
	if not _poses.has("idle"):
		pose("idle", {})
	for jn in _joints:
		_from[jn] = _pose_val(base_pose, jn)
	_to_pose = base_pose
	_t = 999.0
	_dur = 0.001

func _build() -> void:
	pass

func _define_poses() -> void:
	pass

# ============================================================ build helpers
func joint(parent: Node2D, jname: String, pos: Vector2) -> Node2D:
	var j := Node2D.new()
	j.name = jname
	j.position = pos
	parent.add_child(j)
	_joints[jname] = j
	_rest[jname] = pos
	return j

func limb(j: Node2D, kind: String, a: Vector2, b: Vector2, w1: float, w2: float,
		col: Color, part := "") -> Limb:
	var l := Limb.new()
	l.kind = kind
	l.a = a
	l.b = b
	l.w1 = w1
	l.w2 = w2
	l.col = col
	j.add_child(l)
	if part != "":
		_parts[part] = l
	return l

func poly(j: Node2D, points: PackedVector2Array, col: Color, part := "") -> Limb:
	var l := Limb.new()
	l.kind = "poly"
	l.pts = points
	l.col = col
	j.add_child(l)
	if part != "":
		_parts[part] = l
	return l

## {joint: [rot_deg, px, py]} — offsets from rest; unlisted joints sit at rest.
func pose(pname: String, data: Dictionary) -> void:
	var c := {}
	for jn in data:
		var arr: Array = data[jn]
		c[jn] = [deg_to_rad(float(arr[0])),
			Vector2(float(arr[1]), float(arr[2])) if arr.size() >= 3 else Vector2.ZERO]
	_poses[pname] = c

func breath(jname: String, amp_deg: float, freq: float, phase := 0.0, pos := Vector2.ZERO) -> void:
	breaths.append({"joint": jname, "amp": amp_deg, "freq": freq, "phase": phase, "pos": pos})

# ============================================================ runtime API
func set_pose(pname: String, dur := 0.22, easing := "out", hold := 0.0) -> void:
	for jn in _joints:
		_from[jn] = _sample(jn)
	_to_pose = pname
	_t = 0.0
	_dur = maxf(dur, 0.001)
	_easing = easing
	_hold = hold

func seq(steps: Array) -> void:
	_seq = steps.duplicate()
	_next_step()

func _next_step() -> void:
	if _seq.is_empty():
		return
	var st: Dictionary = _seq.pop_front()
	set_pose(String(st.get("pose", base_pose)), float(st.get("dur", 0.18)),
		String(st.get("ease", "out")), float(st.get("hold", 0.0)))

func rest_in(pname: String, dur := 0.6) -> void:
	_seq = []
	base_pose = pname
	set_pose(pname, dur, "io")

func set_windup(pname: String, amt: float) -> void:
	windup_pose = pname
	windup_amt = clampf(amt, 0.0, 1.0)

func clear_windup() -> void:
	windup_amt = 0.0

func jolt(amt: float) -> void:
	_jolt = maxf(_jolt, amt)
	_jolt_dir = Vector2(randf_range(-1, 1), randf_range(-0.4, 0.4))

## The boss's gaze (raid): a floating gold diamond over this actor's head.
func set_highlight(on: bool) -> void:
	if on and _hl == null:
		_hl = Node2D.new()
		_hl.position = Vector2(0, highlight_y)
		_hl.draw.connect(func():
			var c := Color("ffdc93")
			_hl.draw_colored_polygon(PackedVector2Array([Vector2(0, -9), Vector2(7, 0),
				Vector2(0, 9), Vector2(-7, 0)]), c)
			c.a = 0.4
			_hl.draw_arc(Vector2.ZERO, 13.0, 0.0, TAU, 20, c, 2.0, true))
		add_child(_hl)
	elif not on and _hl != null:
		_hl.queue_free()
		_hl = null

func flash_part(part: String, col: Color, amt := 1.0) -> void:
	var l: Limb = _parts.get(part)
	if l != null:
		l.flash_col = col
		l.flash = maxf(l.flash, amt)
		l.queue_redraw()

func part_glow(part: String, col: Color, amt: float) -> void:
	var l: Limb = _parts.get(part)
	if l != null:
		l.glow_col = col
		l.glow = amt
		l.queue_redraw()

# ============================================================ per-frame solve
func _process(delta: float) -> void:
	_time += delta
	_t += delta
	var pr := clampf(_t / _dur, 0.0, 1.0)
	if pr >= 1.0 and _t >= _dur + _hold:
		if not _seq.is_empty():
			_next_step()
		elif _to_pose != base_pose:
			set_pose(base_pose, recover_dur, "io")
	var e := _ease_val(pr, _easing)

	for jn in _joints:
		var from: Array = _from.get(jn, [0.0, Vector2.ZERO])
		var to: Array = _pose_val(_to_pose, jn)
		var r := lerp_angle(float(from[0]), float(to[0]), e)
		var p: Vector2 = (from[1] as Vector2).lerp(to[1], e)
		if windup_amt > 0.001 and windup_pose != "":
			var wv := _pose_val(windup_pose, jn)
			r = lerp_angle(r, float(wv[0]), windup_amt)
			p = p.lerp(wv[1], windup_amt)
		var n: Node2D = _joints[jn]
		n.rotation = r
		n.position = (_rest[jn] as Vector2) + p

	for b in breaths:
		var n2: Node2D = _joints.get(b["joint"])
		if n2 == null:
			continue
		var w := sin(_time * float(b["freq"]) + float(b["phase"])) * breath_scale
		n2.rotation += deg_to_rad(float(b["amp"])) * w
		n2.position += (b["pos"] as Vector2) * w

	if _jolt > 0.001 and _joints.has("root"):
		var rn: Node2D = _joints["root"]
		rn.position += _jolt_dir * _jolt * 5.0 * sin(_time * 63.0)
		_jolt = maxf(0.0, _jolt - delta * 5.0)

	for part in _parts:
		var l: Limb = _parts[part]
		if l.flash > 0.0:
			l.flash = maxf(0.0, l.flash - delta * 4.5)
			l.queue_redraw()

func _sample(jn: String) -> Array:
	var n: Node2D = _joints[jn]
	return [n.rotation, n.position - (_rest[jn] as Vector2)]

func _pose_val(pname: String, jn: String) -> Array:
	var p: Dictionary = _poses.get(pname, {})
	return p.get(jn, [0.0, Vector2.ZERO])

static func _ease_val(t: float, kind: String) -> float:
	match kind:
		"in":
			return t * t * t
		"io":
			return t * t * (3.0 - 2.0 * t)
		"snap":
			var u := 1.0 - t
			return 1.0 - u * u * u * u * u
		"back":
			var s := 1.70158
			var v := t - 1.0
			return 1.0 + v * v * ((s + 1.0) * v + s)
		_:
			var w := 1.0 - t
			return 1.0 - w * w * w
