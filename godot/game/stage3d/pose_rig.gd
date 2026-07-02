## PoseRig — the procedural-animation backbone of the 3D combat stage. A rig is a
## code-built hierarchy of plain Node3D "joints" dressed with primitive meshes, plus
## a library of named POSES (per-joint local rotation + position offsets from the
## build-time rest pose). On top of eased pose-to-pose blending it layers:
##   · SEQUENCES  — anticipation -> action -> recover chains (attacks, reacts)
##   · a WINDUP overlay whose depth the stage drives from combat state each frame
##     (this is how a telegraph becomes readable body language: the wind-up pose
##     deepens exactly as the swing approaches — the timer IS the animation)
##   · breathing / idle sway, and a decaying impact JOLT
## Pure view layer: reads no combat state, holds no gameplay truth. Real art later
## (GLTF + AnimationPlayer) replaces subclasses of this without touching callers.
class_name PoseRig
extends Node3D

var _joints: Dictionary = {}       # name -> Node3D
var _rest: Dictionary = {}         # name -> rest local position
var _parts: Dictionary = {}        # name -> MeshInstance3D (emissive flash targets)
var _poses: Dictionary = {}        # name -> {joint: [Quaternion, Vector3]}

# pose blender
var _from: Dictionary = {}         # joint -> [Quaternion, Vector3] at blend start
var _to_pose: String = "idle"
var _t: float = 0.0
var _dur: float = 0.3
var _easing: String = "out"
var _hold: float = 0.0
var _seq: Array = []               # queued steps: {pose, dur, ease, hold}
var base_pose: String = "idle"     # what the rig relaxes back into
var recover_dur: float = 0.5

# windup overlay (stage-driven, 0..1)
var windup_pose: String = ""
var windup_amt: float = 0.0

# additive layers
var breaths: Array = []            # {joint, axis: Vector3, amp: float(deg), freq, phase, pos: Vector3}
var breath_scale: float = 1.0      # enrage cranks this
var _jolt: float = 0.0
var _jolt_dir: Vector3 = Vector3.ZERO
var _time: float = 0.0
var _flashes: Dictionary = {}      # part -> {col: Color, e: float} (transient, decays)
var _part_base: Dictionary = {}    # part -> {col: Color, e: float} (resting glow, restored after a flash)

func _ready() -> void:
	_build()
	_define_poses()
	if not _poses.has("idle"):
		pose("idle", {})
	# start settled in the base pose
	for jn in _joints:
		_from[jn] = _pose_val(base_pose, jn)
	_to_pose = base_pose
	_t = 999.0
	_dur = 0.001

## Subclasses build the skeleton + meshes here, and author poses here.
func _build() -> void:
	pass

func _define_poses() -> void:
	pass

# ============================================================ build helpers
func joint(parent: Node3D, jname: String, pos: Vector3) -> Node3D:
	var j := Node3D.new()
	j.name = jname
	j.position = pos
	parent.add_child(j)
	_joints[jname] = j
	_rest[jname] = pos
	return j

static func mat(albedo: Color, rough: float = 0.6, metal: float = 0.3,
		emis: Color = Color(0, 0, 0), e_energy: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.roughness = rough
	m.metallic = metal
	if e_energy > 0.0:
		m.emission_enabled = true
		m.emission = emis
		m.emission_energy_multiplier = e_energy
	return m

func _mesh(j: Node3D, mesh: Mesh, m: Material, pos: Vector3, rot_deg: Vector3,
		part: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = m
	mi.position = pos
	mi.rotation_degrees = rot_deg
	j.add_child(mi)
	if part != "":
		_parts[part] = mi
		var sm := m as StandardMaterial3D
		if sm != null and sm.emission_enabled:
			_part_base[part] = {"col": sm.emission, "e": sm.emission_energy_multiplier}
	return mi

func cap(j: Node3D, r: float, h: float, m: Material, pos := Vector3.ZERO,
		rot_deg := Vector3.ZERO, part := "") -> MeshInstance3D:
	var me := CapsuleMesh.new()
	me.radius = r
	me.height = h
	return _mesh(j, me, m, pos, rot_deg, part)

func box(j: Node3D, size: Vector3, m: Material, pos := Vector3.ZERO,
		rot_deg := Vector3.ZERO, part := "") -> MeshInstance3D:
	var me := BoxMesh.new()
	me.size = size
	return _mesh(j, me, m, pos, rot_deg, part)

func sph(j: Node3D, r: float, m: Material, pos := Vector3.ZERO,
		rot_deg := Vector3.ZERO, part := "") -> MeshInstance3D:
	var me := SphereMesh.new()
	me.radius = r
	me.height = r * 2.0
	return _mesh(j, me, m, pos, rot_deg, part)

func cyl(j: Node3D, top_r: float, bot_r: float, h: float, m: Material,
		pos := Vector3.ZERO, rot_deg := Vector3.ZERO, part := "") -> MeshInstance3D:
	var me := CylinderMesh.new()
	me.top_radius = top_r
	me.bottom_radius = bot_r
	me.height = h
	return _mesh(j, me, m, pos, rot_deg, part)

## Author one pose. `data` = {joint: [rx, ry, rz]} or {joint: [rx,ry,rz, px,py,pz]}
## (degrees / meters, offsets from rest). Unlisted joints sit at rest.
func pose(pname: String, data: Dictionary) -> void:
	var c := {}
	for jn in data:
		var a: Array = data[jn]
		var q := Quaternion.from_euler(Vector3(
			deg_to_rad(float(a[0])), deg_to_rad(float(a[1])), deg_to_rad(float(a[2]))))
		var p := Vector3.ZERO
		if a.size() >= 6:
			p = Vector3(float(a[3]), float(a[4]), float(a[5]))
		c[jn] = [q, p]
	_poses[pname] = c

func breath(jname: String, axis: Vector3, amp_deg: float, freq: float,
		phase := 0.0, pos := Vector3.ZERO) -> void:
	breaths.append({"joint": jname, "axis": axis.normalized(), "amp": amp_deg,
		"freq": freq, "phase": phase, "pos": pos})

# ============================================================ runtime API
## Blend to a pose. `easing`: out | in | io | snap | back
func set_pose(pname: String, dur := 0.25, easing := "out", hold := 0.0) -> void:
	for jn in _joints:
		_from[jn] = _sample(jn)
	_to_pose = pname
	_t = 0.0
	_dur = maxf(dur, 0.001)
	_easing = easing
	_hold = hold

## Play a chain of steps [{pose, dur, ease, hold}] then relax to base_pose.
func seq(steps: Array) -> void:
	_seq = steps.duplicate()
	_next_step()

func _next_step() -> void:
	if _seq.is_empty():
		return
	var st: Dictionary = _seq.pop_front()
	set_pose(String(st.get("pose", base_pose)), float(st.get("dur", 0.2)),
		String(st.get("ease", "out")), float(st.get("hold", 0.0)))

## Latch a new resting pose (death). Clears any queued action.
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
	_jolt_dir = Vector3(randf_range(-1, 1), randf_range(-0.3, 0.3), randf_range(-1, 1))

## One-shot emissive flash on a registered part (decays automatically).
func flash_part(part: String, col: Color, energy := 3.0) -> void:
	_flashes[part] = {"col": col, "e": energy}

## Persistent emissive glow on a part (energy 0 turns it off). Becomes the part's
## resting state — what a transient flash_part decays back to.
func part_glow(part: String, col: Color, energy: float) -> void:
	_part_base[part] = {"col": col, "e": energy}
	_apply_glow(part, col, energy)

func _apply_glow(part: String, col: Color, energy: float) -> void:
	var mi: MeshInstance3D = _parts.get(part)
	if mi == null:
		return
	var m := mi.material_override as StandardMaterial3D
	if m == null:
		return
	m.emission_enabled = energy > 0.001
	m.emission = col
	m.emission_energy_multiplier = energy

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
		var from: Array = _from.get(jn, [Quaternion.IDENTITY, Vector3.ZERO])
		var to: Array = _pose_val(_to_pose, jn)
		var q: Quaternion = (from[0] as Quaternion).slerp(to[0], e)
		var p: Vector3 = (from[1] as Vector3).lerp(to[1], e)
		if windup_amt > 0.001 and windup_pose != "":
			var wv := _pose_val(windup_pose, jn)
			q = q.slerp(wv[0], windup_amt)
			p = p.lerp(wv[1], windup_amt)
		var n: Node3D = _joints[jn]
		n.quaternion = q
		n.position = (_rest[jn] as Vector3) + p

	# breathing (additive, after the base solve)
	for b in breaths:
		var n2: Node3D = _joints.get(b["joint"])
		if n2 == null:
			continue
		var w := sin(_time * float(b["freq"]) + float(b["phase"])) * breath_scale
		var amp := deg_to_rad(float(b["amp"])) * w
		n2.quaternion = n2.quaternion * Quaternion(b["axis"] as Vector3, amp)
		n2.position += (b["pos"] as Vector3) * w

	# impact jolt on the root joint
	if _jolt > 0.001 and _joints.has("root"):
		var rn: Node3D = _joints["root"]
		rn.position += _jolt_dir * _jolt * 0.045 * sin(_time * 63.0)
		_jolt = maxf(0.0, _jolt - delta * 5.0)

	# emissive flash decay — settles back to the part's resting glow, not to dark
	for part in _flashes.keys():
		var f: Dictionary = _flashes[part]
		f["e"] = float(f["e"]) - delta * 9.0
		var base: Dictionary = _part_base.get(part, {"col": Color(0, 0, 0), "e": 0.0})
		if float(f["e"]) <= float(base["e"]):
			_apply_glow(part, base["col"], float(base["e"]))
			_flashes.erase(part)
		else:
			_apply_glow(part, f["col"], float(f["e"]))

func _sample(jn: String) -> Array:
	var n: Node3D = _joints[jn]
	return [n.quaternion, n.position - (_rest[jn] as Vector3)]

func _pose_val(pname: String, jn: String) -> Array:
	var p: Dictionary = _poses.get(pname, {})
	return p.get(jn, [Quaternion.IDENTITY, Vector3.ZERO])

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
