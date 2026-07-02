## CombatStage2D — the physical fight, in side-view 2D. The rogue (left) and the
## headsman (right) stand as cutout puppets between the painted Gilded-Reliquary
## backdrop and the HUD, driven by the same two feeds as the 3D stage:
##   · sync(s, obs, p) — the boss's coil deepens with the live telegraph (Rend low,
##     Decapitate overhead, Blood Ritual = planted axe + raised hand [KICK IT],
##     Wither = the pointing curse, Judgment Cuts beat-by-beat, the feint coiling
##     identically — that's the lie); the rogue's idle bounces on the strike beat
##     and its Flow tier lights scarf/eye/daggers.
##   · on_event(ev) — abilities/dodges/kicks/staggers acted out + 2D VFX (slash
##     arcs, sparks, dodge afterimages, curse bolt, kick star, heal swirl).
## Pure view. Real cutout art later replaces the rig classes, not this director.
class_name CombatStage2D
extends Control

var player_rig: TwinfangRig2D
var boss_rig: ExecutionerRig2D

var _world: Node2D
var _fxl: Node2D              # VFX layer above the puppets
var _aspect := "tempo"
var _boss_id := ""
var _punch := 0.0             # world zoom-kick (decays)
var _pending: Array = []      # scheduled one-shots
var _cur_beats: Array = []
var _string_live := false
var _last_kind := ""          # last classic windup kind (curse attribution)
var _perfect_next := 0.0      # "perfect" fired; the next strike acts the X-cross
var _evade_amt := 0.0
var _over_done := false

func _init(aspect: String, boss_id: String) -> void:
	_aspect = aspect
	_boss_id = boss_id
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	_world = Node2D.new()
	add_child(_world)
	player_rig = TwinfangRig2D.new(_aspect)
	player_rig.scale = Vector2.ONE * 1.12    # readability vs the towering boss
	boss_rig = ExecutionerRig2D.new()
	boss_rig.scale = Vector2(-1, 1)          # built facing +X; the boss faces LEFT
	_world.add_child(boss_rig)
	_world.add_child(player_rig)             # rogue draws over the boss on overlap
	boss_rig.variant(_boss_id)
	_fxl = Node2D.new()
	_world.add_child(_fxl)
	resized.connect(_layout)
	_layout()

func _layout() -> void:
	player_rig.position = size * Vector2(0.31, 0.760)
	boss_rig.position = size * Vector2(0.672, 0.760)

func _draw() -> void:
	# grounding: soft contact shadows under each fighter
	for e in [[player_rig.position, 92.0], [boss_rig.position, 175.0]]:
		var p: Vector2 = e[0]
		var r: float = e[1]
		draw_set_transform(p, 0.0, Vector2(1.0, 0.28))
		draw_circle(Vector2.ZERO, r, Color(0, 0, 0, 0.34))
		draw_circle(Vector2.ZERO, r * 0.62, Color(0, 0, 0, 0.30))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# ============================================================ per-frame state feed
func sync(s: CombatState, obs: Dictionary, p: Seat) -> void:
	if s == null or player_rig == null:
		return
	if s.over and not _over_done:
		_over_done = true
		if s.won:
			boss_rig.die()
			player_rig.win()
			_punch = 1.2
		else:
			player_rig.die()
			boss_rig.win()
		return
	if _over_done:
		return

	# --- boss coil = the telegraph ---
	var tg: Dictionary = obs.get("telegraph", {})
	var beats: Array = tg.get("strikes", []) if not tg.is_empty() else []
	_cur_beats = beats
	_string_live = not beats.is_empty()
	if tg.is_empty():
		boss_rig.windup_amt = maxf(0.0, boss_rig.windup_amt - 0.12)
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
			boss_rig.windup(_beat_kind(cur), pow(frac, 1.25))
	else:
		var dur := float(s.telegraph.dur_ticks) * s.dt
		var frac2 := clampf(1.0 - float(tg.get("remaining", 0.0)) / maxf(dur, 0.001), 0.0, 1.0)
		var kind := "light"
		if bool(tg.get("heal", false)) or bool(tg.get("interruptible", false)):
			kind = "channel"                 # Blood Ritual — the kickable one
		elif int(tg.get("size", 0)) >= 2:
			kind = "heavy"
		elif int(tg.get("size", 0)) == AbilityRes.Size.NONE:
			kind = "curse"                   # Wither — unavoidable pointing curse
		_last_kind = kind
		boss_rig.windup(kind, pow(frac2, 1.35))

	# --- rogue: dodge-window lean + Flow made visible ---
	var evading := p.dodging_until_tick > s.tick
	_evade_amt = clampf(_evade_amt + (14.0 if evading else -8.0) * get_process_delta_time(), 0.0, 0.55)
	player_rig.set_windup("evade", _evade_amt)
	player_rig.flow_glow(int(obs.get("tier", 0)),
		float(obs.get("flow", 0)) / maxf(1.0, float(obs.get("flow_max", 6))))

	var enr := s.encounter.enrage_at > 0.0 and s.time() >= s.encounter.enrage_at
	boss_rig.set_enrage(enr)

func _beat_kind(idx: int) -> String:
	return "cut_hi" if idx % 2 == 0 else "cut_lo"

# ============================================================ event stream -> acting
func on_event(ev: Dictionary) -> void:
	if _over_done or boss_rig == null:
		return
	match String(ev.get("t", "")):
		"perfect":
			if bool(ev.get("player", false)):
				_perfect_next = 0.3          # the strike committing this tick is a Perfect
		"ability_fired":
			if bool(ev.get("player", false)):
				_player_ability(String(ev.get("id", "")))
		"negate":
			# the dodge VERB answered a swing: full backdash; the boss still commits
			if bool(ev.get("player", false)) and not _string_live:
				player_rig.evade_react()
				_ghost(player_rig.position + Vector2(20, -140))
				boss_rig.swing("heavy" if int(ev.get("size", 0)) >= 2 else "light")
				_punch = maxf(_punch, 0.8)
		"strike_graded":
			if not bool(ev.get("player", false)):
				return
			match int(ev.get("grade", 0)):
				StrikeRes.Grade.PERFECT:
					player_rig.hop_react(true)
					_ghost(player_rig.position + Vector2(14, -140))
				StrikeRes.Grade.GOOD:
					player_rig.hop_react(true)
				StrikeRes.Grade.GRAZE:
					player_rig.graze_react()
				StrikeRes.Grade.BAITED:
					player_rig.stumble_react()
				StrikeRes.Grade.READ:
					player_rig.brace_react()
		"dodge_whiff":
			if bool(ev.get("player", false)):
				player_rig.stumble_react()
		"strike_landed":
			var i := int(ev.get("idx", 0))
			if i >= 0 and i < _cur_beats.size() and not bool(_cur_beats[i].get("feint", false)):
				boss_rig.swing(_beat_kind(i))
		"hurt":
			if not bool(ev.get("player", false)):
				return
			var amt := float(ev.get("amt", 0))
			if amt < 8.0:
				return                        # enrage per-tick chip: no acting spam
			var sz := int(ev.get("size", 0))
			player_rig.hit_react(amt >= 70.0)
			_spark(_rogue_chest(), Color("d0413a"), amt >= 70.0)
			if _string_live:
				pass                          # strike_landed already swings the axe
			elif sz > 0:
				boss_rig.swing("heavy" if sz >= 2 else "light")
			elif _last_kind == "curse":
				boss_rig.curse_release()
				_bolt(_boss_hand(), _rogue_chest(), Color("8a5bd6"))
		"flow_lost":
			if bool(ev.get("player", false)):
				player_rig.slump_react()
		"staggered":
			boss_rig.stagger_anim()
			_star(_boss_chest(), Color("b48ee8"))
			_punch = maxf(_punch, 1.0)
		"boss_heal":
			boss_rig.heal_flash()
			_swirl(_boss_chest(), Color("d0413a"))
		"poison":
			_spark(_boss_chest() + Vector2(randf_range(-30, 30), randf_range(-40, 30)),
				Color("7fd44a"), false)
		_:
			pass

func _player_ability(id: String) -> void:
	var perfect := _perfect_next > 0.0 and id == "strike"
	_perfect_next = 0.0
	var info := player_rig.act(id, perfect)
	var delay := float(info.get("delay", 0.10))
	var kind := String(info.get("kind", "slash"))
	if kind == "venom":
		_pending.append({"t": delay, "kind": "venom_fx"})
		return
	var reps := int(info.get("repeats", 1))
	var gap := float(info.get("gap", 0.0))
	for i in reps:
		_pending.append({"t": delay + gap * i, "kind": "impact", "hit": kind})

# ============================================================ scheduler + camera punch
func _process(delta: float) -> void:
	_perfect_next = maxf(0.0, _perfect_next - delta)
	var keep: Array = []
	for job in _pending:
		job["t"] = float(job["t"]) - delta
		if float(job["t"]) > 0.0:
			keep.append(job)
			continue
		match String(job["kind"]):
			"impact":
				var hit := String(job.get("hit", "slash"))
				var pos := _boss_chest() + Vector2(randf_range(-14, 14), randf_range(-24, 18))
				match hit:
					"perfect":
						_arc(pos, player_rig.accent, true)
						_spark(pos, player_rig.accent, true)
						boss_rig.flinch(false)
						_punch = maxf(_punch, 0.5)
					"cross":
						_arc(pos, Color("ffdc93"), true)
						_arc(pos + Vector2(6, 8), Color("ffdc93"), false)
						_spark(pos, Color("ffdc93"), true)
						boss_rig.flinch(true)
						_punch = maxf(_punch, 0.7)
					"kick":
						_star(pos, Color("b48ee8"))
						boss_rig.flinch(false)
						_punch = maxf(_punch, 0.4)
					"coup":
						_arc(pos, player_rig.accent, true)
						_spark(pos, player_rig.accent, true)
						_ring(boss_rig.position, player_rig.accent)
						boss_rig.flinch(true)
						_punch = maxf(_punch, 1.1)
					_:
						_arc(pos, Color("ffdc93"), randf() > 0.5)
						_spark(pos, Color("ffdc93"), false)
						boss_rig.flinch(false)
						_punch = maxf(_punch, 0.25)
			"venom_fx":
				_spark(_boss_chest(), Color("7fd44a"), true)
			"free":
				var n: Node = job.get("node")
				if is_instance_valid(n):
					n.queue_free()
	_pending = keep

	# world zoom-punch toward the space between the fighters
	_punch = maxf(0.0, _punch - delta * 3.4)
	var sc := 1.0 + 0.022 * _punch
	var pivot := (player_rig.position + boss_rig.position) * 0.5 if player_rig != null else size * 0.5
	_world.scale = Vector2.ONE * sc
	_world.position = pivot - pivot * sc

func _rogue_chest() -> Vector2:
	return player_rig.position + Vector2(14, -165)

func _boss_chest() -> Vector2:
	return boss_rig.position + Vector2(-55, -330) * boss_rig.scale.y

func _boss_hand() -> Vector2:
	return boss_rig.position + Vector2(-150, -300) * boss_rig.scale.y

# ============================================================ 2D VFX
## a bright crescent slash that flares and dies
func _arc(pos: Vector2, col: Color, up: bool) -> void:
	var n := Node2D.new()
	n.position = pos
	n.rotation = randf_range(-0.5, 0.2) + (0.0 if up else 2.6)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	n.material = add
	n.draw.connect(func():
		n.draw_arc(Vector2.ZERO, 46.0, -2.4, -0.2, 20, col, 9.0, true)
		n.draw_arc(Vector2.ZERO, 34.0, -2.2, -0.5, 16, Color(1, 1, 1, 0.7), 4.0, true))
	_fxl.add_child(n)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(n, "scale", Vector2.ONE * 1.7, 0.18).from(Vector2.ONE * 0.6)
	tw.tween_property(n, "modulate:a", 0.0, 0.18)
	tw.chain().tween_callback(n.queue_free)

func _spark(pos: Vector2, col: Color, big: bool) -> void:
	var pz := CPUParticles2D.new()
	pz.position = pos
	pz.emitting = false
	pz.one_shot = true
	pz.explosiveness = 1.0
	pz.amount = 26 if big else 14
	pz.lifetime = 0.5
	pz.direction = Vector2.UP
	pz.spread = 180.0
	pz.initial_velocity_min = 120.0
	pz.initial_velocity_max = 320.0 if big else 220.0
	pz.gravity = Vector2(0, 500.0)
	pz.scale_amount_min = 2.0
	pz.scale_amount_max = 3.6
	pz.color = col
	var g := Gradient.new()
	g.set_color(0, col)
	g.set_color(1, Color(col.r, col.g, col.b, 0.0))
	pz.color_ramp = g
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	pz.material = m
	_fxl.add_child(pz)
	pz.emitting = true
	_pending.append({"t": 0.9, "kind": "free", "node": pz})

## a fading silhouette where the rogue stood — sells the dash
func _ghost(pos: Vector2) -> void:
	var col := player_rig.accent
	var n := Node2D.new()
	n.position = pos
	n.draw.connect(func():
		var c := Color(col.r, col.g, col.b, 0.5)
		n.draw_circle(Vector2(8, -32), 14, c)
		for e in [[Vector2(0, -18), Vector2(4, 40), 15.0], [Vector2(4, 40), Vector2(2, 100), 11.0]]:
			n.draw_circle(e[0], e[2], c)
			n.draw_circle(e[1], e[2] * 0.8, c)
			n.draw_line(e[0], e[1], c, e[2] * 1.7))
	_fxl.add_child(n)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(n, "modulate:a", 0.0, 0.26)
	tw.tween_property(n, "position:x", pos.x - 26.0, 0.26)
	tw.chain().tween_callback(n.queue_free)

## the kick / interrupt impact star
func _star(pos: Vector2, col: Color) -> void:
	var n := Node2D.new()
	n.position = pos
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	n.material = add
	n.draw.connect(func():
		var pts := PackedVector2Array()
		for i in 12:
			var r := 44.0 if i % 2 == 0 else 16.0
			pts.append(Vector2(cos(TAU * i / 12.0), sin(TAU * i / 12.0)) * r)
		n.draw_colored_polygon(pts, col)
		n.draw_circle(Vector2.ZERO, 10, Color(1, 1, 1, 0.9)))
	_fxl.add_child(n)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(n, "scale", Vector2.ONE * 1.6, 0.2).from(Vector2.ONE * 0.5)
	tw.tween_property(n, "modulate:a", 0.0, 0.2)
	tw.chain().tween_callback(n.queue_free)

## a jagged curse bolt from the boss's pointing hand to the rogue
func _bolt(from: Vector2, to: Vector2, col: Color) -> void:
	var ln := Line2D.new()
	var d := to - from
	var nrm := Vector2(-d.y, d.x).normalized()
	ln.add_point(from)
	ln.add_point(from + d * 0.35 + nrm * randf_range(-26, 26))
	ln.add_point(from + d * 0.7 + nrm * randf_range(-26, 26))
	ln.add_point(to)
	ln.width = 5.0
	ln.default_color = col
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	ln.material = m
	_fxl.add_child(ln)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(ln, "modulate:a", 0.0, 0.22).from(1.0)
	tw.tween_property(ln, "width", 1.0, 0.22)
	tw.chain().tween_callback(ln.queue_free)

## expanding ground shock ellipse (coup landing)
func _ring(pos: Vector2, col: Color) -> void:
	var n := Node2D.new()
	n.position = pos
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	n.material = add
	n.draw.connect(func():
		n.draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.3))
		n.draw_arc(Vector2.ZERO, 60.0, 0.0, TAU, 40, col, 6.0, true)
		n.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE))
	_fxl.add_child(n)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(n, "scale", Vector2.ONE * 2.6, 0.3).from(Vector2.ONE * 0.4)
	tw.tween_property(n, "modulate:a", 0.0, 0.3)
	tw.chain().tween_callback(n.queue_free)

## crimson motes drawn INTO the boss — it drinks the ritual back
func _swirl(pos: Vector2, col: Color) -> void:
	var pz := CPUParticles2D.new()
	pz.position = pos
	pz.emitting = false
	pz.one_shot = true
	pz.explosiveness = 0.55
	pz.amount = 22
	pz.lifetime = 0.8
	pz.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	pz.emission_sphere_radius = 120.0
	pz.spread = 180.0
	pz.initial_velocity_min = 10.0
	pz.initial_velocity_max = 30.0
	pz.radial_accel_min = -420.0
	pz.radial_accel_max = -300.0
	pz.scale_amount_min = 2.0
	pz.scale_amount_max = 3.0
	pz.color = col
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	pz.material = m
	_fxl.add_child(pz)
	pz.emitting = true
	_pending.append({"t": 1.2, "kind": "free", "node": pz})
