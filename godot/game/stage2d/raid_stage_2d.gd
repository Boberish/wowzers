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
var _freeze := 0.0                # hit-stop: seconds the actor world stays frozen
var _vfx: VfxPool = null          # C7 flipbook layer (ArtV2.vfx + delivered assets only)
var _engarde_on: Dictionary = {}  # seat index -> En Garde hold-loop latch (view)
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
var dash_scale := 1.0             ## C6A theater fit (view-only): SLOTS stay the LOCAL
                                  ## spacing grammar; the whole cast scales to the rect

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
	# C7: the flipbook voice pool rides INSIDE _world (topmost) so stage hit-stop
	# holds impact frames with the actors. Missing/partial assets ⇒ make() = null ⇒
	# no pool, and the code-drawn sparks below stay the whole FX story (fail-safe).
	if ArtV2.vfx:
		_vfx = VfxPool.make()
		if _vfx != null:
			_world.add_child(_vfx)
	resized.connect(_layout)
	_layout()

func _layout() -> void:
	if boss_actor == null:
		return
	boss_actor.position = size * BOSS_AT
	boss_actor.scale = Vector2(-dash_scale, dash_scale)
	for i in actors.size():
		var slot: Dictionary = SLOTS.get(_seat_keys[i], SLOTS["tank"])
		var a: Actor2D = actors[i]
		var at: Vector2 = slot["at"]
		if i < _cast.size() and (_cast[i] as Dictionary).has("at"):
			at = (_cast[i] as Dictionary)["at"]
		a.position = size * at
		a.set_meta("home", a.position)   # lunges always return here, even mid-flight
		a.scale = Vector2.ONE * float(slot["scale"]) * dash_scale
		var d := float(slot["dim"])
		a.modulate = Color(d, d, d)

func _draw() -> void:
	if boss_actor == null:
		return
	var shadows: Array = [[boss_actor.position, 190.0 * dash_scale]]
	for a in actors:
		shadows.append([(a as Node2D).position, 80.0 * dash_scale])
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
		# C7: En Garde's NATURAL expiry emits no event — end the hold loop off the
		# committed state (duel_engarde_break also stops it, in on_event below)
		if _vfx != null and _engarde_on.get(i, false) \
				and seat.vars.has("engarde_until") \
				and int(seat.vars.get("engarde_until", 0)) <= s.tick:
			_engarde_on[i] = false
			_vfx.stop_slot("s%d:eg" % i)

	boss_actor.set_enrage(s.encounter.enrage_at > 0.0 and s.time() >= s.encounter.enrage_at)

# ============================================================ event stream -> acting
func _seat_i(ev_seat) -> int:
	if ev_seat is Seat:
		var s_owner := ev_seat as Seat
		for i in actors.size():
			if i < _state_seats.size() and _state_seats[i] == s_owner:
				return i
	return -1

func _actor(ev_seat) -> Actor2D:
	var i := _seat_i(ev_seat)
	return actors[i] if i >= 0 else null

## C7 flipbook anchors (view geometry only): guard/chest height on an actor, scaled
## with its slot; ground = the actor position itself (feet — the stage's contract).
func _guard_of(a: Actor2D) -> Vector2:
	return a.position + Vector2(72.0, -150.0) * absf(a.scale.x)

func _body_of(a: Actor2D) -> Vector2:
	return a.position + Vector2(-6.0, -128.0) * absf(a.scale.x)

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
		# TANK-V3 vocabulary → actor verbs (the pre-rework stage only knew
		# negate/strike_graded; the Duelist's stream/claim model emits these).
		# Additive: other classes keep firing negate/strike_graded above.
		# THE GRADED ANSWER (C5.1): duel_answer carries kind+grade — one unique
		# animation per grade (Actor2D.graded_react; painted actors go further).
		# The raw press echoes (duel_dodge/duel_parry) no longer animate — the
		# graded answer lands the same tick and owns the motion.
		"duel_answer":
			if a != null:
				var g := int(ev.get("grade", 0))
				var kind := String(ev.get("kind", "dodge"))
				a.graded_react(kind, g)
				if g == StrikeRes.Grade.BULLSEYE:
					_ghost(a.position)
					_star(a.position + Vector2(10, -320), Color("ffd76a"))
					_punch = maxf(_punch, 0.5)
				elif g == StrikeRes.Grade.PERFECT or g == StrikeRes.Grade.GOOD:
					_ghost(a.position)
				# C7 flipbooks — the graded ladder tunes SCALE + ADDITIVE LAYERS only
				# (answer timing/legality is engine truth; BAITED/MISS earn nothing).
				# One :act slot per seat: a new committed answer REPLACES a stale tail.
				if _vfx != null:
					var slot := "s%d:act" % _seat_i(ev.get("seat"))
					if (kind == "parry" or kind == "charge") \
							and (g == StrikeRes.Grade.PERFECT or g == StrikeRes.Grade.BULLSEYE):
						# landed parry at the REAL contact point (guard, boss side).
						# CHARGE = the hold/release CHARGED PARRY (d91bb8d) — the same
						# landing, CRUSH-sized: biggest scale, full treatment when full.
						var full := kind == "charge" and bool(ev.get("full", false))
						var sc := 1.18 if g == StrikeRes.Grade.BULLSEYE else 1.0
						if kind == "charge":
							sc = 1.4 if full else 1.25
						_vfx.spawn("parry", _guard_of(a), {"scale": sc,
							"layers": 2 if g == StrikeRes.Grade.BULLSEYE or full else 1}, slot)
					elif kind == "dodge" and (g != StrikeRes.Grade.MISS and g != StrikeRes.Grade.BAITED):
						var dsc := {StrikeRes.Grade.GRAZE: 0.78, StrikeRes.Grade.GOOD: 0.9,
							StrikeRes.Grade.PERFECT: 1.0, StrikeRes.Grade.BULLSEYE: 1.15}
						var dly := {StrikeRes.Grade.GRAZE: 0, StrikeRes.Grade.GOOD: 0,
							StrikeRes.Grade.PERFECT: 1, StrikeRes.Grade.BULLSEYE: 2}
						_vfx.spawn("dodge", _body_of(a), {"scale": float(dsc.get(g, 0.9)),
							"layers": int(dly.get(g, 0)), "flip_h": true}, slot)
					elif kind == "weave" and g != StrikeRes.Grade.MISS and g != StrikeRes.Grade.BAITED:
						# rapid WEAVE cluster: the cheap read — small, base layer only
						_vfx.spawn("dodge", _body_of(a), {"scale": 0.68, "flip_h": true}, slot)
		"duel_fumble", "duel_weave_blown":
			if a != null:
				a.stumble_react()
		"duel_eat":
			if a != null:
				a.brace_react()
		"duel_dump", "duel_counter", "duel_riposte":
			if a != null:
				# C7: the Dump flipbook releases at the blade and TRAVELS at the boss —
				# rotate the authored up-right wave onto the actual firing line.
				if _vfx != null and String(ev.get("t", "")) == "duel_dump":
					var from := _guard_of(a)
					var rot := (_boss_chest() - from).angle() - _vfx.book.travel_rad("dump")
					_vfx.spawn("dump", from, {"layers": 1, "rot": rot},
						"s%d:act" % _seat_i(ev.get("seat")))
				_fire(a, "strike")
		"duel_engarde":
			if a != null and _vfx != null:
				# activation one-shot, then the low-rate hold loop takes the SAME slot
				# (≈ zero idle cost: one sprite at ~2 fps, no particle emitter)
				var i := _seat_i(ev.get("seat"))
				_engarde_on[i] = true
				_vfx.spawn("engarde_activate", a.position, {"layers": 1}, "s%d:eg" % i)
				var act_ms := _vfx.book.ms_per_frame("engarde_activate") \
					* float(_vfx.book.frame_count("engarde_activate"))
				_pending.append({"t": act_ms / 1000.0, "kind": "eg_hold", "seat_i": i})
		"duel_engarde_break":
			if _vfx != null:
				var i := _seat_i(ev.get("seat"))
				_engarde_on[i] = false
				_vfx.stop_slot("s%d:eg" % i)
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
			# C7: a physical contact lands its impact flipbook on the victim — family
			# picked by the EXISTING strike-size truth (LIGHT < HEAVY < CRUSH is the
			# strict footprint/fragment ladder; sz 0 = curse/dot, no contact art)
			if _vfx != null and sz > 0:
				if sz >= AbilityRes.Size.CRUSH:
					_vfx.spawn("impact_crush", a.position, {"layers": 2})
				elif sz >= AbilityRes.Size.HEAVY:
					_vfx.spawn("impact_heavy", _body_of(a), {"layers": 1})
				else:
					_vfx.spawn("impact_light", _body_of(a), {})
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
	# swing-side juice (C7 transplant): a lunge toward the boss + a smear crescent
	# over the arc. View-only, ArtV2.vfx-gated — OFF is byte-identical to before.
	if ArtV2.vfx:
		match kind:
			"slash":
				_lunge(a, 42.0)
				_smear(a.position, Color(1, 1, 1, 0.8), false)
			"perfect":
				_lunge(a, 58.0)
				_smear(a.position, Color("7fe0a0"), true)
			"cross":
				_lunge(a, 72.0)
				_smear(a.position, Color("ffdc93"), true)
			"coup":
				# the pose itself leaps — afterimages ghost the flight path instead
				var mint := Color(0.5, 0.88, 0.63, 0.42)
				var mid := a.position.lerp(_boss_chest(), 0.5) + Vector2(0.0, -110.0)
				_pending.append({"t": 0.07, "kind": "ghostat", "pos": a.position + Vector2(30.0, -30.0), "col": mint})
				_pending.append({"t": 0.15, "kind": "ghostat", "pos": mid, "col": mint})
				_pending.append({"t": 0.22, "kind": "ghostat", "pos": _boss_chest() + Vector2(-50.0, -30.0), "col": mint})
	var delay := float(info.get("delay", 0.10))
	var reps := int(info.get("repeats", 1))
	var gap := float(info.get("gap", 0.0))
	for i in reps:
		_pending.append({"t": delay + gap * i, "kind": "impact", "hit": kind,
			"from": a.position})

## Hit-stop: freeze the actor world (poses, particles) for `sec` while the HUD,
## AnswerChannel and in-flight FX tweens keep running — the impact frame HOLDS.
## Never called for plain strikes: the idle bounce IS the rhythm reference. The
## committed STREAM rides the AnswerChannel (a HUD widget, never under _world),
## so timing truth cannot freeze here by construction.
func hitstop(sec: float) -> void:
	if _world == null:
		return
	_freeze = maxf(_freeze, sec)
	_world.process_mode = Node.PROCESS_MODE_DISABLED

## A short dash toward the boss and back — Darkest-Dungeon attack language.
func _lunge(a: Actor2D, dist: float) -> void:
	if not a.has_meta("home"):
		return
	var prev: Tween = a.get_meta("lunge_tw") if a.has_meta("lunge_tw") else null
	if prev != null and prev.is_valid():
		prev.kill()
	var home: Vector2 = a.get_meta("home")
	var tw := create_tween()
	a.set_meta("lunge_tw", tw)
	tw.tween_property(a, "position", home + Vector2(dist, 0.0), 0.07) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(a, "position", home, 0.20) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

## An additive crescent following the dagger arc — the anime swing-trail that
## sells speed without frames. Fires at act() time from the attacker's position.
func _smear(pos: Vector2, col: Color, big: bool) -> void:
	var n := Node2D.new()
	n.position = pos + Vector2(96.0, -168.0)
	n.rotation = randf_range(-0.25, 0.1)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	n.material = add
	var w := 26.0 if big else 15.0
	n.draw.connect(func():
		n.draw_arc(Vector2.ZERO, 104.0, -2.1, 0.35, 26, col, w, true)
		n.draw_arc(Vector2.ZERO, 88.0, -1.8, 0.15, 20, Color(1, 1, 1, 0.5), w * 0.35, true))
	_fxl.add_child(n)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(n, "scale", Vector2(1.45, 1.05), 0.15).from(Vector2(0.55, 0.9))
	tw.tween_property(n, "rotation", n.rotation + 0.35, 0.15)
	tw.tween_property(n, "modulate:a", 0.0, 0.15).from(0.9)
	tw.chain().tween_callback(n.queue_free)

# ============================================================ scheduler + punch
func _process(delta: float) -> void:
	if _freeze > 0.0:
		_freeze -= delta
		if _freeze <= 0.0 and _world != null:
			_world.process_mode = Node.PROCESS_MODE_INHERIT
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
				# the big-hit read (C7 transplant): white-out the boss and HOLD the
				# impact frame. Plain strikes never hit-stop — the idle bounce is the
				# beat reference (the one juice law that outranks spectacle).
				if ArtV2.vfx:
					if hit == "coup" or hit == "cross" or hit == "slam":
						if boss_actor is PoseRig2D:
							(boss_actor as PoseRig2D).flash_all(Color(1.0, 0.98, 0.92),
								0.7 if hit == "coup" else 0.5)
						hitstop(0.09 if hit == "coup" else 0.06)
					elif hit == "kick":
						hitstop(0.05)
			"ghostat":
				_ghost(job["pos"], job.get("col", Color(0.6, 0.8, 1.0, 0.4)))
			"eg_hold":
				# En Garde activation finished — hand the slot to the low-rate hold
				# loop IF the stance is still live (break/expiry may have beaten us)
				var egi := int(job.get("seat_i", -1))
				if _vfx != null and _engarde_on.get(egi, false) \
						and egi >= 0 and egi < actors.size():
					_vfx.spawn("engarde_hold", (actors[egi] as Actor2D).position,
						{}, "s%d:eg" % egi)
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

func _ghost(pos: Vector2, col := Color(0.6, 0.8, 1.0, 0.4)) -> void:
	var n := Node2D.new()
	n.position = pos
	n.draw.connect(func():
		var c := col
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
