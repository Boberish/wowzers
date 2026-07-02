## CombatStage3D — the physical fight. A transparent 3D SubViewport layered between
## the painted Gilded-Reliquary backdrop and the HUD: knight and boss stand on an
## obsidian dais, lit by a warm key + steel rim + rift underglow. PURE VIEW —
## driven entirely by the same two feeds the HUD already uses:
##   · sync(s, obs, p) each frame — the boss's wind-up pose deepens exactly with the
##     live telegraph (classic swings by size, M7 strings beat-by-beat on alternating
##     fists, heals fold inward), the knight raises guard over the defense window,
##     enrage/death/victory latch from state.
##   · on_event(ev) — the combat event stream becomes acting: abilities are swung,
##     parries recoil the boss, dodge grades read on the body, staggers rock it.
## Zero engine knowledge lives here beyond reading state; real art later swaps the
## rig subclasses, not this director.
class_name CombatStage3D
extends SubViewportContainer

const PLAYER_POS := Vector3(-1.05, 0.0, 0.55)
const BOSS_POS := Vector3(0.80, 0.0, -1.00)
const CAM_POS := Vector3(-2.60, 2.15, 4.35)
const CAM_LOOK := Vector3(0.42, 1.38, -0.60)

var player_rig: BulwarkRig
var boss_rig: GatekeeperRig

var _vp: SubViewport
var _world: Node3D
var _cam: Camera3D
var _aspect := "warden"
var _boss_id := ""
var _t := 0.0
var _kick := 0.0             # camera punch (decays)
var _shake := 0.0            # camera noise (decays)
var _pending: Array = []     # scheduled one-shots: {t, kind, ...}
var _cur_beats: Array = []   # last-synced string beats (strike_landed lookup)
var _string_live := false
var _guard_amt := 0.0
var _fort_on := false
var _enrage_on := false
var _over_done := false
var _melee_gap := 0.0
var _soft_gpu := false       # WSLg/llvmpipe: software GL — degrade to stay playable

const ABILITY_FX := {
	"cleave": {"kind": "slash"}, "rampage": {"kind": "slam"},
	"bloodthirst": {"kind": "thrust"}, "vindicate": {"kind": "thrust"},
	"avalanche": {"kind": "slam"}, "shockwave": {"kind": "slam"},
	"fortify": {"kind": "cast"},
}

func _init(aspect: String, boss_id: String) -> void:
	_aspect = aspect
	_boss_id = boss_id
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stretch = true

func _ready() -> void:
	# Software GL (WSLg gives Mesa llvmpipe — the CPU rasterizes every pixel):
	# render the 3D world at half resolution, no MSAA, no shadow map. On a real
	# GPU (native Windows/Linux) this never triggers and full quality stays on.
	var adapter := RenderingServer.get_video_adapter_name().to_lower()
	_soft_gpu = adapter.contains("llvmpipe") or adapter.contains("softpipe") \
		or adapter.contains("swiftshader")

	_vp = SubViewport.new()
	_vp.transparent_bg = true
	_vp.own_world_3d = true
	_vp.msaa_3d = Viewport.MSAA_DISABLED if _soft_gpu else Viewport.MSAA_4X
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_vp.gui_disable_input = true
	if _soft_gpu:
		stretch_shrink = 2          # 3D at half res, upscaled — 4x fewer pixels
	add_child(_vp)

	_world = Node3D.new()
	_vp.add_child(_world)

	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.15, 0.145, 0.21)
	env.ambient_light_energy = 1.1
	we.environment = env
	_world.add_child(we)

	_cam = Camera3D.new()
	_cam.fov = 40.0
	_cam.position = CAM_POS
	_world.add_child(_cam)
	_cam.look_at_from_position(CAM_POS, CAM_LOOK)

	# key / rim / rift underglow
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-38, -26, 0)
	key.light_color = Color(0.97, 0.94, 0.87)
	key.light_energy = 1.05
	key.shadow_enabled = not _soft_gpu   # shadow map is brutal on a CPU rasterizer
	_world.add_child(key)
	var rim := OmniLight3D.new()
	rim.position = Vector3(2.2, 3.0, -3.4)
	rim.light_color = Color(0.56, 0.72, 0.90)
	rim.light_energy = 3.4
	rim.omni_range = 11.0
	_world.add_child(rim)
	var rift := OmniLight3D.new()
	rift.position = Vector3(-0.2, 0.35, 0.3)
	rift.light_color = Color(0.85, 0.36, 0.22)
	rift.light_energy = 1.0
	rift.omni_range = 4.5
	_world.add_child(rift)

	_build_dais()
	_build_motes()

	player_rig = BulwarkRig.new(_aspect)
	player_rig.position = PLAYER_POS
	_world.add_child(player_rig)
	player_rig.look_at(Vector3(BOSS_POS.x, 0, BOSS_POS.z), Vector3.UP)

	boss_rig = GatekeeperRig.new()
	boss_rig.position = BOSS_POS
	_world.add_child(boss_rig)
	boss_rig.variant(_boss_id)
	boss_rig.look_at(Vector3(PLAYER_POS.x, 0, PLAYER_POS.z), Vector3.UP)

	if _soft_gpu:                       # no shadow map -> ground the actors with blobs
		_blob_shadow(PLAYER_POS, 0.55)
		_blob_shadow(BOSS_POS, 1.15 * boss_rig.scale.x)

func _blob_shadow(pos: Vector3, r: float) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = 0.01
	mi.mesh = cm
	var m := PoseRig.mat(Color(0, 0, 0, 0.38), 1.0, 0.0)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = m
	mi.position = Vector3(pos.x, 0.012, pos.z)
	_world.add_child(mi)

func _build_dais() -> void:
	var obsidian := PoseRig.mat(Color(0.10, 0.10, 0.145), 0.32, 0.55)
	var dais := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 3.3
	cm.bottom_radius = 3.55
	cm.height = 0.16
	dais.mesh = cm
	dais.material_override = obsidian
	dais.position = Vector3(0, -0.08, 0.2)
	_world.add_child(dais)
	# gilded rim ring
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 3.16
	tm.outer_radius = 3.26
	ring.mesh = tm
	ring.material_override = PoseRig.mat(Color("6f5330"), 0.5, 0.8, Color("e6b463"), 0.35)
	ring.position = Vector3(0, 0.005, 0.2)
	_world.add_child(ring)
	# (no scar mesh — the crimson rift underglow light smoulders the floor instead;
	# a flat emissive plane read as a sticker on camera)

func _build_motes() -> void:
	var pz := CPUParticles3D.new()
	pz.amount = 42
	pz.lifetime = 7.0
	pz.preprocess = 7.0
	pz.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	pz.emission_box_extents = Vector3(3.4, 1.8, 3.0)
	pz.position = Vector3(0, 1.7, 0)
	pz.direction = Vector3(0, 1, 0)
	pz.spread = 180.0
	pz.gravity = Vector3(0, 0.05, 0)
	pz.initial_velocity_min = 0.02
	pz.initial_velocity_max = 0.12
	var mm := SphereMesh.new()
	mm.radius = 0.011
	mm.height = 0.022
	var m := PoseRig.mat(Color(0, 0, 0), 1.0, 0.0, Color("e6b463"), 1.4)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mm.material = m
	pz.mesh = mm
	_world.add_child(pz)

# ============================================================ per-frame state feed
func sync(s: CombatState, obs: Dictionary, p: Seat) -> void:
	if s == null or _cam == null:
		return
	# fight over: latch the ending tableau
	if s.over and not _over_done:
		_over_done = true
		if s.won:
			boss_rig.die()
			player_rig.win()
			_kick = 1.2
		else:
			player_rig.die()
			boss_rig.win()
		return
	if _over_done:
		return

	# --- boss wind-up = the telegraph, made flesh ---
	var tg: Dictionary = obs.get("telegraph", {})
	var beats: Array = tg.get("strikes", []) if not tg.is_empty() else []
	_cur_beats = beats
	_string_live = not beats.is_empty()
	if tg.is_empty():
		boss_rig.set_windup(boss_rig.windup_pose if boss_rig.windup_pose != "" else "windup_light",
			maxf(0.0, boss_rig.windup_amt - 0.12))
	elif _string_live:
		var cur := -1
		for i in beats.size():
			if not bool(beats[i].get("resolved", false)):
				cur = i
				break
		if cur < 0:
			boss_rig.clear_windup()
		else:
			var b: Dictionary = beats[cur]
			var seg_start := 0.0 if cur == 0 else float(beats[cur - 1].get("at", 0.0))
			var seg_len := maxf(0.05, float(b.get("at", 0.0)) - seg_start)
			var frac := clampf(1.0 - float(b.get("remaining", 0.0)) / seg_len, 0.0, 1.0)
			boss_rig.windup(_beat_kind(cur, int(b.get("size", 1))), pow(frac, 1.25))
	else:
		var dur := float(s.telegraph.dur_ticks) * s.dt
		var frac2 := clampf(1.0 - float(tg.get("remaining", 0.0)) / maxf(dur, 0.001), 0.0, 1.0)
		var kind := "light"
		if bool(tg.get("heal", false)):
			kind = "heal"
		elif int(tg.get("size", 0)) >= 3:
			kind = "crush"
		elif int(tg.get("size", 0)) == 2:
			kind = "heavy"
		# a Feint keeps its size's honest wind-up — the lie IS the animation
		boss_rig.windup(kind, pow(frac2, 1.35))

	# --- knight guard stance over the defense-active window ---
	var guarding := p.dodging_until_tick > s.tick
	_guard_amt = clampf(_guard_amt + (14.0 if guarding else -7.0) * get_process_delta_time(), 0.0, 1.0)
	player_rig.set_windup("guard", _guard_amt)

	# Fortify / DR active: the shield emblem burns
	var fort := p.dr > 0.0 and s.tick < p.dr_until_tick
	if fort != _fort_on:
		_fort_on = fort
		player_rig.part_glow("emblem", player_rig.accent, 2.4 if fort else 0.0)

	var enr := s.encounter.enrage_at > 0.0 and s.time() >= s.encounter.enrage_at
	if enr != _enrage_on:
		_enrage_on = enr
		boss_rig.set_enrage(enr)

func _beat_kind(idx: int, size: int) -> String:
	if size >= 3:
		return "crush"
	if size == 2:
		return "heavy"
	return "jab_l" if idx % 2 == 1 else "jab_r"

# ============================================================ event stream -> acting
func on_event(ev: Dictionary) -> void:
	if _over_done or boss_rig == null:
		return
	match String(ev.get("t", "")):
		"ability_fired":
			if bool(ev.get("player", false)):
				_player_ability(String(ev.get("id", "")))
		"negate":
			if not bool(ev.get("player", false)):
				return
			if bool(ev.get("feint", false)):
				player_rig.stumble_react()          # guarded a Feint: BAITED
				_shake = maxf(_shake, 0.8)
			elif _string_live:
				pass                                 # string beats: grade react already played at the press
			else:
				player_rig.negate_react(_aspect == "warden")
				boss_rig.recoil()
				_spark(_boss_chest(), Color("ffdc93"), false)
				_kick = maxf(_kick, 1.0)
		"defend":
			pass                                     # guard stance is state-driven in sync()
		"hurt":
			if not bool(ev.get("player", false)):
				return
			var amt := float(ev.get("amt", 0))
			var size := int(ev.get("size", 0))
			player_rig.hit_react(amt >= 70.0)
			_shake = maxf(_shake, clampf(amt / 90.0, 0.25, 1.4))
			_spark(_player_chest(), Color("d0413a"), amt >= 70.0)
			if size > 0 and not _string_live:
				boss_rig.swing("crush" if size >= 3 else ("heavy" if size == 2 else "light"))
			elif size == 0 and not _string_live and boss_rig.windup_amt < 0.3 and _melee_gap <= 0.0:
				boss_rig.melee_swipe()               # Devourer chip: lazy backhand
				_melee_gap = 0.7
		"strike_landed":
			var i := int(ev.get("idx", 0))
			if i >= 0 and i < _cur_beats.size():
				var b: Dictionary = _cur_beats[i]
				if not bool(b.get("feint", false)):
					boss_rig.swing(_beat_kind(i, int(b.get("size", 1))).replace("windup_", ""))
		"strike_graded":
			if not bool(ev.get("player", false)):
				return
			match int(ev.get("grade", 0)):
				StrikeRes.Grade.PERFECT:
					player_rig.dodge_react(true)
					_after_img()
				StrikeRes.Grade.GOOD:
					player_rig.dodge_react(true)
				StrikeRes.Grade.GRAZE:
					player_rig.graze_react()
				StrikeRes.Grade.BAITED:
					player_rig.stumble_react()
					_shake = maxf(_shake, 0.7)
				StrikeRes.Grade.READ:
					player_rig.brace_react()
		"dodge_whiff":
			if bool(ev.get("player", false)):
				player_rig.stumble_react()
		"read":
			if bool(ev.get("player", false)):
				player_rig.brace_react()
		"staggered":
			boss_rig.stagger_anim()
			_ring(BOSS_POS + Vector3(0, 0.05, 0), Color("8fb8e0"), 2.2)
			_kick = maxf(_kick, 1.1)
		"boss_heal":
			boss_rig.heal_flash()
			_heal_swirl(_boss_chest())
		"boss_hit":
			# ability impacts are scheduled with the swing (see _player_ability);
			# this catches kit-side extras (riposte reflect, boon procs)
			if float(ev.get("amt", 0)) >= 40.0 and _pending.is_empty():
				boss_rig.flinch(false)

func _player_ability(id: String) -> void:
	var info := player_rig.act(id)
	var delay := float(info.get("delay", 0.15))
	var kind := String(info.get("kind", "slash"))
	var col := _ability_color(id)
	if kind == "cast":
		_pending.append({"t": delay, "kind": "cast_fx", "col": col})
		return
	var reps := int(info.get("repeats", 1))
	var gap := float(info.get("gap", 0.0))
	for i in reps:
		_pending.append({"t": delay + gap * i, "kind": "impact", "col": col,
			"slam": kind == "slam"})

func _ability_color(id: String) -> Color:
	match id:
		"bloodthirst": return Color("d0413a")
		"shockwave": return Color("8fb8e0")
		"vindicate": return player_rig.accent
		"avalanche": return Color("e0862f")
		_: return Color("ffdc93")

# ============================================================ camera + scheduler
func _process(delta: float) -> void:
	_t += delta
	_melee_gap = maxf(0.0, _melee_gap - delta)
	# scheduled one-shots
	var keep: Array = []
	for job in _pending:
		job["t"] = float(job["t"]) - delta
		if float(job["t"]) > 0.0:
			keep.append(job)
			continue
		match String(job["kind"]):
			"impact":
				var col: Color = job["col"]
				_spark(_boss_chest(), col, bool(job.get("slam", false)))
				_flash_orb(_boss_chest(), col)
				boss_rig.flinch(bool(job.get("slam", false)))
				if bool(job.get("slam", false)):
					_ring(BOSS_POS + Vector3(0, 0.05, 0), col, 1.8)
					_kick = maxf(_kick, 0.75)
				else:
					_kick = maxf(_kick, 0.35)
			"cast_fx":
				_ring(PLAYER_POS + Vector3(0, 0.05, 0), job["col"], 1.2)
			"free":
				var n: Node = job.get("node")
				if is_instance_valid(n):
					n.queue_free()
	_pending = keep

	# camera: slow breathe-drift + impact punch + noise shake
	if _cam != null:
		_kick = maxf(0.0, _kick - delta * 3.2)
		_shake = maxf(0.0, _shake - delta * 2.6)
		var sway := Vector3(sin(_t * 0.33) * 0.06, sin(_t * 0.47) * 0.035, cos(_t * 0.26) * 0.05)
		var noise := Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * _shake * 0.035
		var toward := (CAM_LOOK - CAM_POS).normalized() * _kick * 0.22
		_cam.position = CAM_POS + sway + noise + toward
		_cam.look_at(CAM_LOOK + noise * 0.5)
		_cam.fov = 42.0 - _kick * 2.5

func _boss_chest() -> Vector3:
	return BOSS_POS + Vector3(0, 1.75 * boss_rig.scale.y, -0.3)

func _player_chest() -> Vector3:
	return PLAYER_POS + Vector3(0, 1.25, 0.2)

# ============================================================ 3D VFX
func _spark(pos: Vector3, col: Color, big: bool) -> void:
	var pz := CPUParticles3D.new()
	pz.position = pos
	pz.one_shot = true
	pz.explosiveness = 1.0
	pz.amount = 34 if big else 20
	pz.lifetime = 0.55
	pz.direction = Vector3(0, 1, 0)
	pz.spread = 180.0
	pz.initial_velocity_min = 2.2 if big else 1.6
	pz.initial_velocity_max = 5.4 if big else 3.6
	pz.gravity = Vector3(0, -7.0, 0)
	pz.scale_amount_min = 0.6
	pz.scale_amount_max = 1.5
	var mm := SphereMesh.new()
	mm.radius = 0.030
	mm.height = 0.060
	var m := PoseRig.mat(col, 1.0, 0.0, col, 2.6)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	mm.material = m
	pz.mesh = mm
	var g := Gradient.new()
	g.set_color(0, col)
	g.set_color(1, Color(col.r, col.g, col.b, 0.0))
	pz.color_ramp = g
	_world.add_child(pz)
	pz.emitting = true
	_pending.append({"t": 1.1, "kind": "free", "node": pz})

## a bright core flash that swells and dies — sells the moment of contact
func _flash_orb(pos: Vector3, col: Color) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.16
	sm.height = 0.32
	mi.mesh = sm
	var m := PoseRig.mat(col, 1.0, 0.0, col, 4.0)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mi.material_override = m
	mi.position = pos
	_world.add_child(mi)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(mi, "scale", Vector3.ONE * 2.6, 0.16).from(Vector3.ONE * 0.4)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.16)
	tw.chain().tween_callback(mi.queue_free)

func _ring(pos: Vector3, col: Color, radius: float) -> void:
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = radius * 0.9
	tm.outer_radius = radius
	mi.mesh = tm
	var m := PoseRig.mat(col, 1.0, 0.0, col, 2.4)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = m
	mi.position = pos
	mi.scale = Vector3.ONE * 0.2
	_world.add_child(mi)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(mi, "scale", Vector3(1.0, 0.6, 1.0), 0.34).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.34)
	tw.chain().tween_callback(mi.queue_free)

func _heal_swirl(pos: Vector3) -> void:
	var pz := CPUParticles3D.new()
	pz.position = pos - Vector3(0, 0.9, 0)
	pz.one_shot = true
	pz.explosiveness = 0.6
	pz.amount = 26
	pz.lifetime = 1.1
	pz.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	pz.emission_sphere_radius = 0.85
	pz.direction = Vector3(0, 1, 0)
	pz.spread = 24.0
	pz.initial_velocity_min = 0.7
	pz.initial_velocity_max = 1.5
	pz.gravity = Vector3(0, 1.8, 0)
	var mm := SphereMesh.new()
	mm.radius = 0.026
	mm.height = 0.052
	var col := Color("83c98d")
	var m := PoseRig.mat(col, 1.0, 0.0, col, 2.4)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.vertex_color_use_as_albedo = true
	mm.material = m
	pz.mesh = mm
	var g := Gradient.new()
	g.set_color(0, col)
	g.set_color(1, Color(col.r, col.g, col.b, 0.0))
	pz.color_ramp = g
	_world.add_child(pz)
	pz.emitting = true
	_pending.append({"t": 1.8, "kind": "free", "node": pz})

## a brief ghost of the knight where it stood — sells a PERFECT dodge
func _after_img() -> void:
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.32
	cm.height = 1.7
	mi.mesh = cm
	var m := PoseRig.mat(player_rig.accent, 1.0, 0.0, player_rig.accent, 1.6)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(player_rig.accent.r, player_rig.accent.g, player_rig.accent.b, 0.35)
	mi.material_override = m
	mi.position = PLAYER_POS + Vector3(0, 0.95, 0)
	_world.add_child(mi)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.28)
	tw.tween_property(mi, "scale", Vector3.ONE * 1.15, 0.28)
	tw.chain().tween_callback(mi.queue_free)
