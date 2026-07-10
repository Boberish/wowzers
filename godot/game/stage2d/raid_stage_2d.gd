## RaidStage2D — THE RIFT, all together: the four raiders stand in a staggered
## side-view rank (healer deepest, then caster, blade, tank at the front) facing
## Vorathek the Riftmaw on the right, between the painted backdrop and the HUD.
## Every actor is an Actor2D from the factory — drop art .tscn files in
## res://game/art/actors/ and they replace the placeholder puppets seat by seat.
## Driven by the same two feeds as every stage (sync + the event stream), and it
## works identically under the local driver and the lockstep NetCombatController
## (it only ever READS state — netcode never notices it).
## The boss's current threat victim wears the gaze diamond; wind-ups per cast:
## talon coil / double-crush / jaw-wide Chant (kick it!) / rearing Cataclysm /
## glare Curse / alternating Volley coils.
class_name RaidStage2D
extends Control

const SLOTS := {
	"healer": {"at": Vector2(0.135, 0.775), "scale": 0.92, "dim": 0.84},
	"caster": {"at": Vector2(0.235, 0.780), "scale": 0.96, "dim": 0.92},
	"blade": {"at": Vector2(0.345, 0.785), "scale": 1.0, "dim": 1.0},
	"tank": {"at": Vector2(0.465, 0.790), "scale": 1.06, "dim": 1.0},
}
const BOSS_AT := Vector2(0.72, 0.785)

var actors: Array = []            # index-aligned with s.seats
var boss_actor: Actor2D

var _world: Node2D
var _fxl: Node2D
var _punch := 0.0
var _pending: Array = []
var _last_kind := ""
var _string_live := false         # a string telegraph is winding up THIS frame (set in sync)
var _dead: Dictionary = {}        # seat index -> died latch
var _perfect_next := 0.0
var _melee_gap := 0.0
var _over_done := false
var _seat_keys: Array = []
var _cast: Array = []             # explicit actor specs (gate exams); [] = raid roster
var _enc_id := "riftmaw"          # to restore the boss body after an add wave

func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## Build actors from the fight state (RaidNet seat order: tank blade caster healer).
## `cast` (optional, seat-ordered) overrides the roster for non-raid parties —
## personal GATE exams pass their own specs ({id, key, aspect?, at?}); the boss can
## be recast too (`boss_id`/`boss_var`). Defaults keep every raid pull unchanged.
func setup(s: CombatState, aspects: Dictionary, cast: Array = [],
		boss_id: String = "", boss_var: String = "") -> void:
	_world = Node2D.new()
	add_child(_world)
	boss_actor = Actor2D.make(boss_id if boss_id != "" else "riftmaw")
	boss_actor.scale = Vector2(-1, 1)
	_world.add_child(boss_actor)
	_enc_id = String(s.encounter.id)
	boss_actor.variant(boss_var if boss_var != "" else _enc_id)
	_cast = cast
	_seat_keys = []
	actors = []
	for i in s.seats.size():
		var key: String
		var id: String
		var aspect: String
		if i < cast.size():
			var spec: Dictionary = cast[i]
			key = String(spec.get("key", "tank"))
			id = String(spec.get("id", "duelist"))
			aspect = String(spec.get("aspect", ""))
		else:
			key = RaidNet.SEAT_KEYS[i] if i < RaidNet.SEAT_KEYS.size() else "tank"
			id = {"tank": "duelist", "blade": "twinfang", "caster": "alchemist",
				"healer": "well"}.get(key, "duelist")
			aspect = String(aspects.get(key, ""))
		_seat_keys.append(key)
		var a := Actor2D.make(id, aspect)
		_world.add_child(a)
		actors.append(a)
	_fxl = Node2D.new()
	_world.add_child(_fxl)
	resized.connect(_layout)
	_layout()

func _layout() -> void:
	if boss_actor == null:
		return
	boss_actor.position = size * BOSS_AT
	for i in actors.size():
		var slot: Dictionary = SLOTS.get(_seat_keys[i], SLOTS["tank"])
		var a: Actor2D = actors[i]
		var at: Vector2 = slot["at"]
		if i < _cast.size() and (_cast[i] as Dictionary).has("at"):
			at = (_cast[i] as Dictionary)["at"]
		a.position = size * at
		a.scale = Vector2.ONE * float(slot["scale"])
		var d := float(slot["dim"])
		a.modulate = Color(d, d, d)

func _draw() -> void:
	if boss_actor == null:
		return
	var shadows: Array = [[boss_actor.position, 190.0]]
	for a in actors:
		shadows.append([(a as Node2D).position, 80.0])
	for e in shadows:
		draw_set_transform(e[0], 0.0, Vector2(1.0, 0.26))
		draw_circle(Vector2.ZERO, float(e[1]), Color(0, 0, 0, 0.32))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# ============================================================ per-frame state feed
func sync(s: CombatState) -> void:
	if s == null or boss_actor == null:
		return
	if s.over and not _over_done:
		_over_done = true
		if s.won:
			boss_actor.die()
			for i in actors.size():
				if s.seats[i].alive():
					actors[i].win()
			_punch = 1.2
		else:
			boss_actor.win()
		return
	if _over_done:
		return

	# --- boss coil from the live telegraph ---
	# track string-live explicitly (was inferred from _last_kind=="cut", which never
	# reset — the boss stopped acting between a string's end and the next classic cast)
	_string_live = s.telegraph != null and not s.telegraph.ability.strikes.is_empty()
	if s.telegraph == null:
		boss_actor.windup(_last_kind if _last_kind != "" else "heavy",
			maxf(0.0, (boss_actor as PoseRig2D).windup_amt - 0.12) if boss_actor is PoseRig2D else 0.0)
	elif not s.telegraph.ability.strikes.is_empty():
		var tg := s.telegraph
		var cur := tg.next_strike
		if cur >= tg.ability.strikes.size():
			boss_actor.clear_windup()
		else:
			var st: StrikeRes = tg.ability.strikes[cur]
			var seg_start := 0.0 if cur == 0 else float((tg.ability.strikes[cur - 1] as StrikeRes).at)
			var seg_len := maxf(0.05, st.at - seg_start)
			var el := float(s.tick - tg.start_tick) * s.dt - seg_start
			boss_actor.windup("cut_hi" if cur % 2 == 0 else "cut_lo",
				pow(clampf(el / seg_len, 0.0, 1.0), 1.25))
			_last_kind = "cut"
	else:
		var ab := s.telegraph.ability
		var dur := float(s.telegraph.dur_ticks) * s.dt
		var frac := clampf(float(s.tick - s.telegraph.start_tick) * s.dt / maxf(dur, 0.001), 0.0, 1.0)
		var kind := "curse"
		if ab.effect == AbilityRes.Effect.HEAL_BOSS:
			kind = "channel"
		elif ab.effect == AbilityRes.Effect.NOVA or ab.effect == AbilityRes.Effect.DMG_ALL:
			kind = "nova"
		elif int(ab.size) >= AbilityRes.Size.CRUSH:
			kind = "crush"
		elif int(ab.size) >= AbilityRes.Size.LIGHT:
			kind = "heavy"
		_last_kind = kind
		boss_actor.windup(kind, pow(frac, 1.35))

	# --- raiders: deaths, casting stances, resource glow, the boss's gaze ---
	var victim: Seat = CombatCore._threat_target(s)
	for i in actors.size():
		var seat: Seat = s.seats[i]
		var a: Actor2D = actors[i]
		if not seat.alive():
			if not _dead.has(i):
				_dead[i] = true
				a.die()
			continue
		if not seat.casting.is_empty():
			var cdur := maxf(1.0, float(seat.casting.get("dur_ticks", 1)))
			a.windup("channel", clampf(float(s.tick - int(seat.casting.get("start_tick", s.tick))) / cdur, 0.0, 1.0))
		elif seat.role == "tank" and seat.dodging_until_tick > s.tick:
			a.windup("channel", 1.0)
		else:
			a.clear_windup()
		a.power_glow(clampf(seat.resource / maxf(1.0, seat.resource_max), 0.0, 1.0))
		a.set_highlight(seat == victim)

	boss_actor.set_enrage(s.encounter.enrage_at > 0.0 and s.time() >= s.encounter.enrage_at)

# ============================================================ event stream -> acting
func _actor(ev_seat) -> Actor2D:
	if ev_seat is Seat:
		var s_owner := ev_seat as Seat
		for i in actors.size():
			if i < _state_seats.size() and _state_seats[i] == s_owner:
				return actors[i]
	return null

var _state_seats: Array = []
func bind_seats(seats: Array) -> void:
	_state_seats = seats

func on_event(ev: Dictionary) -> void:
	if _over_done or boss_actor == null:
		return
	var a := _actor(ev.get("seat"))
	match String(ev.get("t", "")):
		"perfect":
			_perfect_next = 0.3
		"ability_fired":
			if a != null:
				_fire(a, String(ev.get("id", "")))
		"negate":
			if a != null:
				a.evade_react()
				_ghost(a.position)
				if not _string_live:
					boss_actor.swing("crush" if int(ev.get("size", 0)) >= 3 else "heavy")
					_punch = maxf(_punch, 0.6)
		"strike_graded":
			if a == null:
				return
			match int(ev.get("grade", 0)):
				StrikeRes.Grade.PERFECT, StrikeRes.Grade.GOOD:
					a.hop_react(true)
				StrikeRes.Grade.GRAZE:
					a.graze_react()
				StrikeRes.Grade.BAITED:
					a.stumble_react()
				StrikeRes.Grade.READ:
					a.brace_react()
		"dodge_whiff":
			if a != null:
				a.stumble_react()
		"strike_landed":
			boss_actor.swing("cut_hi" if int(ev.get("idx", 0)) % 2 == 0 else "cut_lo")
		"hurt":
			if a == null:
				return
			var amt := float(ev.get("amt", 0))
			if amt < 8.0:
				return
			var sz := int(ev.get("size", 0))
			a.hit_react(amt >= 60.0)
			if _string_live:
				pass
			elif sz > 0:
				boss_actor.swing("crush" if sz >= 3 else "heavy")
			elif _last_kind == "curse":
				boss_actor.curse_release()
				_bolt(boss_actor.position + Vector2(-140, -330), a.position + Vector2(0, -150), Color("8a5bd6"))
			elif _melee_gap <= 0.0 and boss_actor is RiftmawRig2D:
				(boss_actor as RiftmawRig2D).melee_swipe()
				_melee_gap = 0.8
		"taunt":
			boss_actor.hit_react(false)
			_star(boss_actor.position + Vector2(-120, -380), Color("d0413a"))
		"staggered":
			boss_actor.stagger_anim()
			_star(_boss_chest(), Color("b48ee8"))
			_punch = maxf(_punch, 1.0)
		"boss_heal":
			boss_actor.heal_flash()
			_swirl(_boss_chest(), Color("d0413a"))
		"heal":
			if a != null:
				_spark(a.position + Vector2(0, -160), Color("83c98d"), false)
		"debuff":
			if a != null:
				_spark(a.position + Vector2(0, -140), Color("8a5bd6"), false)
		"flow_lost":
			if a != null:
				a.slump_react()
		"add_spawn":
			# the boss withdraws — the add takes its body slot (placeholder swap)
			boss_actor.variant(String(ev.get("id", "")))
			boss_actor.stagger_anim()
			_star(_boss_chest(), Color("ffb35c"))
			_punch = maxf(_punch, 1.1)
		"add_down":
			boss_actor.variant(_enc_id)
			boss_actor.stagger_anim()
			_star(_boss_chest(), Color("e8c05a"))
			_punch = maxf(_punch, 1.0)
		_:
			pass

func _fire(a: Actor2D, id: String) -> void:
	var flourish := _perfect_next > 0.0 and id == "strike"
	_perfect_next = 0.0
	var info := a.act(id, flourish)
	var kind := String(info.get("kind", "slash"))
	if kind == "heal" or kind == "cast":
		return                       # support cast: the target's heal event sparkles
	var delay := float(info.get("delay", 0.10))
	var reps := int(info.get("repeats", 1))
	var gap := float(info.get("gap", 0.0))
	for i in reps:
		_pending.append({"t": delay + gap * i, "kind": "impact", "hit": kind,
			"from": a.position})

# ============================================================ scheduler + punch
func _process(delta: float) -> void:
	_perfect_next = maxf(0.0, _perfect_next - delta)
	_melee_gap = maxf(0.0, _melee_gap - delta)
	var keep: Array = []
	for job in _pending:
		job["t"] = float(job["t"]) - delta
		if float(job["t"]) > 0.0:
			keep.append(job)
			continue
		match String(job["kind"]):
			"impact":
				var pos := _boss_chest() + Vector2(randf_range(-20, 20), randf_range(-30, 24))
				var hit := String(job.get("hit", "slash"))
				var col := Color("ffdc93")
				match hit:
					"perfect", "coup": col = Color("7fe0a0")
					"kick": col = Color("b48ee8")
					"cast_bolt": col = Color("b48ee8")
					"venom": col = Color("7fd44a")
				if hit == "cast_bolt":
					_bolt((job.get("from", pos) as Vector2) + Vector2(30, -170), pos, col)
				elif hit == "kick":
					_star(pos, col)
				else:
					_arc(pos, col, randf() > 0.5)
				_spark(pos, col, hit == "slam" or hit == "coup" or hit == "cross")
				boss_actor.hit_react(hit == "slam" or hit == "coup")
				_punch = maxf(_punch, 0.45 if hit == "slam" or hit == "coup" else 0.2)
			"free":
				var n: Node = job.get("node")
				if is_instance_valid(n):
					n.queue_free()
	_pending = keep

	_punch = maxf(0.0, _punch - delta * 3.4)
	if _world != null and boss_actor != null:
		var sc := 1.0 + 0.02 * _punch
		var pivot := size * Vector2(0.55, 0.6)
		_world.scale = Vector2.ONE * sc
		_world.position = pivot - pivot * sc

func _boss_chest() -> Vector2:
	return boss_actor.position + Vector2(-70, -300)

# ============================================================ 2D VFX (shared style)
func _arc(pos: Vector2, col: Color, up: bool) -> void:
	var n := Node2D.new()
	n.position = pos
	n.rotation = randf_range(-0.5, 0.2) + (0.0 if up else 2.6)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	n.material = add
	n.draw.connect(func():
		n.draw_arc(Vector2.ZERO, 44.0, -2.4, -0.2, 20, col, 8.0, true)
		n.draw_arc(Vector2.ZERO, 32.0, -2.2, -0.5, 16, Color(1, 1, 1, 0.7), 4.0, true))
	_fxl.add_child(n)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(n, "scale", Vector2.ONE * 1.7, 0.18).from(Vector2.ONE * 0.6)
	tw.tween_property(n, "modulate:a", 0.0, 0.18)
	tw.chain().tween_callback(n.queue_free)

func _spark(pos: Vector2, col: Color, big: bool) -> void:
	var pz := CPUParticles2D.new()
	pz.position = pos
	pz.one_shot = true
	pz.explosiveness = 1.0
	pz.amount = 24 if big else 12
	pz.lifetime = 0.5
	pz.direction = Vector2.UP
	pz.spread = 180.0
	pz.initial_velocity_min = 110.0
	pz.initial_velocity_max = 300.0 if big else 200.0
	pz.gravity = Vector2(0, 480.0)
	pz.scale_amount_min = 2.0
	pz.scale_amount_max = 3.4
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

func _ghost(pos: Vector2) -> void:
	var n := Node2D.new()
	n.position = pos
	n.draw.connect(func():
		var c := Color(0.6, 0.8, 1.0, 0.4)
		n.draw_circle(Vector2(6, -180), 13, c)
		n.draw_line(Vector2(0, -165), Vector2(3, -60), c, 24.0))
	_fxl.add_child(n)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(n, "modulate:a", 0.0, 0.24)
	tw.tween_property(n, "position:x", pos.x - 22.0, 0.24)
	tw.chain().tween_callback(n.queue_free)

func _star(pos: Vector2, col: Color) -> void:
	var n := Node2D.new()
	n.position = pos
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	n.material = add
	n.draw.connect(func():
		var pts := PackedVector2Array()
		for i in 12:
			var r := 40.0 if i % 2 == 0 else 15.0
			pts.append(Vector2(cos(TAU * i / 12.0), sin(TAU * i / 12.0)) * r)
		n.draw_colored_polygon(pts, col)
		n.draw_circle(Vector2.ZERO, 9, Color(1, 1, 1, 0.9)))
	_fxl.add_child(n)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(n, "scale", Vector2.ONE * 1.5, 0.2).from(Vector2.ONE * 0.5)
	tw.tween_property(n, "modulate:a", 0.0, 0.2)
	tw.chain().tween_callback(n.queue_free)

func _bolt(from: Vector2, to: Vector2, col: Color) -> void:
	var ln := Line2D.new()
	var d := to - from
	var nrm := Vector2(-d.y, d.x).normalized()
	ln.add_point(from)
	ln.add_point(from + d * 0.35 + nrm * randf_range(-24, 24))
	ln.add_point(from + d * 0.7 + nrm * randf_range(-24, 24))
	ln.add_point(to)
	ln.width = 4.5
	ln.default_color = col
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	ln.material = m
	_fxl.add_child(ln)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(ln, "modulate:a", 0.0, 0.2).from(1.0)
	tw.tween_property(ln, "width", 1.0, 0.2)
	tw.chain().tween_callback(ln.queue_free)

func _swirl(pos: Vector2, col: Color) -> void:
	var pz := CPUParticles2D.new()
	pz.position = pos
	pz.one_shot = true
	pz.explosiveness = 0.55
	pz.amount = 20
	pz.lifetime = 0.8
	pz.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	pz.emission_sphere_radius = 130.0
	pz.spread = 180.0
	pz.initial_velocity_min = 10.0
	pz.initial_velocity_max = 28.0
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
