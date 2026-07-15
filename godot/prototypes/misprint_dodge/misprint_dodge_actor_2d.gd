## MisprintDodgeActor2D — isolated whole-pose dodge proof.
##
## The real reducer emits `duel_answer`; RaidStage2D forwards that committed
## event through Actor2D.graded_react(), and sync_tick() advances the pixels from
## CombatState.tick owns pose timing. The four active cards hold for exactly
## 2/4/2/2 simulation ticks; render-only root easing softens their travel without
## changing which committed tick owns each silhouette.
class_name MisprintDodgeActor2D
extends Actor2D

const FRAME_PATHS := [
	"res://prototypes/misprint_dodge/frames_good_v2/good_ready.png",
	"res://prototypes/misprint_dodge/frames_good_v2/good_compress.png",
	"res://prototypes/misprint_dodge/frames_good_v2/good_clearance.png",
	"res://prototypes/misprint_dodge/frames_good_v2/good_settle.png",
	"res://prototypes/misprint_dodge/frames_good_v2/good_recover.png",
]
const LOGICAL_CANVAS := Vector2(768.0, 768.0)
const ART_SCALE := 0.66
const TRAVEL_PX := 30.0
const ACTIVE_TICKS := 10
const ROOT_EASE_S := 0.05
const CORAL := Color(0.96, 0.33, 0.25, 0.42)
const COBALT := Color(0.12, 0.34, 0.86, 0.38)
const TRAIL_OFFSETS := [20.0, 44.0, 72.0, 106.0]
const TRAIL_COLORS := [
	Color(0.46, 0.92, 1.0, 0.55),
	Color(0.30, 0.58, 1.0, 0.40),
	Color(0.66, 0.30, 1.0, 0.28),
	Color(1.0, 0.18, 0.48, 0.20),
]
const TRAIL_BLUR_SHADER := """
shader_type canvas_item;

uniform float blur_px = 2.0;

void fragment() {
	vec2 step_x = vec2(TEXTURE_PIXEL_SIZE.x * blur_px, 0.0);
	vec4 blurred = texture(TEXTURE, UV) * 0.34;
	blurred += texture(TEXTURE, UV - step_x) * 0.24;
	blurred += texture(TEXTURE, UV + step_x) * 0.24;
	blurred += texture(TEXTURE, UV - step_x * 2.0) * 0.09;
	blurred += texture(TEXTURE, UV + step_x * 2.0) * 0.09;
	COLOR = blurred * COLOR;
}
"""

## Root travel by active age. The card art supplies the body deformation; this
## supplies the restrained 25–35 px screen move kept out of the approved art.
const TRAVEL := [0.0, 0.10, 0.28, 0.52, 0.76, 1.0, 0.84, 0.64, 0.40, 0.18, 0.0]

var _frames: Array[Texture2D] = []
var _visual: Node2D
var _main: Sprite2D
var _coral: Sprite2D
var _cobalt: Sprite2D
var _trails: Array[Sprite2D] = []
var _tick := 0
var _start_tick := -1
var _frame_i := 0
var _age := -1
var _start_count := 0
var _travel_target := 0.0
var _travel_tween: Tween = null
var _trail_direction := 1.0

static func try_make() -> MisprintDodgeActor2D:
	var actor := MisprintDodgeActor2D.new()
	if actor._build():
		return actor
	actor.free()
	return null

func _build() -> bool:
	for path in FRAME_PATHS:
		if not ResourceLoader.exists(path, "Texture2D"):
			push_warning("Misprint dodge proof: missing frame %s; keeping production actor" % path)
			return false
		var tex := load(path) as Texture2D
		if tex == null:
			return false
		_frames.append(tex)
	_visual = Node2D.new()
	_visual.scale = Vector2.ONE * ART_SCALE
	add_child(_visual)
	for i in TRAIL_OFFSETS.size():
		_trails.append(_make_trail(i))
	# Keep the full local stack non-negative. Negative child z values can fall
	# behind the Stage2D environment canvas rather than merely behind `_main`.
	_coral = _make_card(CORAL, 8)
	_cobalt = _make_card(COBALT, 9)
	_main = _make_card(Color.WHITE, 10)
	_set_frame(0)
	_set_echo(false)
	_set_trails(-1)
	return true

func _make_card(tint: Color, z: int) -> Sprite2D:
	var card := Sprite2D.new()
	card.centered = false
	# Production cards share one fixed 768x768 canvas and Godot-owned root.
	card.position = Vector2(-LOGICAL_CANVAS.x * 0.5, -LOGICAL_CANVAS.y)
	card.self_modulate = tint
	card.z_index = z
	_visual.add_child(card)
	return card

func _make_trail(i: int) -> Sprite2D:
	var trail := _make_card(TRAIL_COLORS[i], 1 + i)
	var shader := Shader.new()
	shader.code = TRAIL_BLUR_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("blur_px", MisprintDodgeProof.blur_px)
	trail.material = material
	return trail

func sync_tick(tick: int) -> void:
	if tick == _tick:
		return
	_tick = tick
	if _start_tick >= 0:
		_apply_age(_tick - _start_tick)

## Only a LANDED dodge/weave starts this proof. A miss, bait, parry, raw key
## press, or cosmetic event cannot fake the animation gate.
func graded_react(kind: String, grade: int) -> void:
	if kind != "dodge" and kind != "weave":
		return
	if grade == StrikeRes.Grade.MISS or grade == StrikeRes.Grade.BAITED:
		return
	_start_tick = _tick
	_start_count += 1
	_apply_age(0) # immediate: compression card owns the success frame

func _apply_age(age: int) -> void:
	_age = age
	if age < 0 or age >= ACTIVE_TICKS:
		_start_tick = -1
		_age = -1
		_move_root(0.0)
		_set_frame(0)
		_set_echo(false)
		_set_trails(-1)
		return
	var next_frame := 1
	if age <= 1:
		next_frame = 1 # COMPRESS — 2 ticks
	elif age <= 5:
		next_frame = 2 # DEEPEST CLEARANCE — 4 ticks
	elif age <= 7:
		next_frame = 3 # LOW SETTLE / OVERSHOOT — 2 ticks
	else:
		next_frame = 4 # NEAR-READY RECOVERY — 2 ticks
	_set_frame(next_frame)
	var next_travel := TRAVEL_PX * float(TRAVEL[age])
	var travel_delta := next_travel - _travel_target
	if absf(travel_delta) > 0.01:
		_trail_direction = signf(travel_delta)
	_move_root(next_travel)
	# Departure and first clearance only. Visibility is tick-owned, so a slow
	# renderer cannot accidentally stretch the echoes into gameplay timing.
	_set_echo(age == 2 or age == 3)
	_set_trails(age)

func _move_root(target_x: float) -> void:
	_travel_target = target_x
	if _travel_tween != null and _travel_tween.is_valid():
		_travel_tween.kill()
	if not is_inside_tree():
		_visual.position.x = target_x
		return
	_travel_tween = create_tween()
	_travel_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var duration := MisprintDodgeProof.motion_ease_s if MisprintDodgeProof.pushed_motion else ROOT_EASE_S
	_travel_tween.tween_property(_visual, "position:x", target_x, duration)

func _set_frame(frame_i: int) -> void:
	_frame_i = clampi(frame_i, 0, _frames.size() - 1)
	var tex := _frames[_frame_i]
	_main.texture = tex
	_coral.texture = tex
	_cobalt.texture = tex
	for trail in _trails:
		trail.texture = tex

func _set_echo(on: bool) -> void:
	_coral.visible = on
	_cobalt.visible = on
	# Opposed registration slips: compact, behind the body, and nowhere near the
	# answer instrument. They move with the same root/card and add no particles.
	_coral.position = Vector2(-LOGICAL_CANVAS.x * 0.5 - 8.0, -LOGICAL_CANVAS.y + 2.0)
	_cobalt.position = Vector2(-LOGICAL_CANVAS.x * 0.5 + 7.0, -LOGICAL_CANVAS.y - 2.0)

func _set_trails(age: int) -> void:
	var on := MisprintDodgeProof.pushed_motion and age >= 1 and age < ACTIVE_TICKS
	for i in _trails.size():
		var trail := _trails[i]
		trail.visible = on and i < clampi(MisprintDodgeProof.trail_count, 0, _trails.size())
		if not trail.visible:
			continue
		var tint := Color(TRAIL_COLORS[i])
		tint.a *= clampf(MisprintDodgeProof.trail_opacity, 0.0, 1.5)
		trail.self_modulate = tint
		var material := trail.material as ShaderMaterial
		if material != null:
			material.set_shader_parameter("blur_px", clampf(MisprintDodgeProof.blur_px, 0.0, 12.0))
		# Each blurred copy hangs farther behind the current travel direction. The
		# alternating Y slip is intentionally excessive so the judgment can find
		# the point where smooth motion turns into a muddy silhouette.
		var spread := clampf(MisprintDodgeProof.trail_spread, 0.0, 1.5)
		var x_slip := -_trail_direction * float(TRAIL_OFFSETS[i]) * spread
		var y_slip := (-4.0 if i % 2 == 0 else 4.0) * (1.0 + float(i) * 0.45) * spread
		trail.position = Vector2(-LOGICAL_CANVAS.x * 0.5 + x_slip, -LOGICAL_CANVAS.y + y_slip)

## Headless proof surface — pixels remain private; tests read only presentation
## bookkeeping and imported dimensions.
func debug_snapshot() -> Dictionary:
	var sizes: Array = []
	for tex in _frames:
		sizes.append(Vector2i(tex.get_width(), tex.get_height()))
	var visible_trails := 0
	for trail in _trails:
		if trail.visible:
			visible_trails += 1
	return {
		"tick": _tick,
		"start_tick": _start_tick,
		"age": _age,
		"frame": _frame_i,
		"travel": _travel_target,
		"render_travel": _visual.position.x,
		"echo": _coral.visible and _cobalt.visible,
		"pushed": MisprintDodgeProof.pushed_motion,
		"trails": visible_trails,
		"root_ease_s": MisprintDodgeProof.motion_ease_s if MisprintDodgeProof.pushed_motion else ROOT_EASE_S,
		"trail_spread": MisprintDodgeProof.trail_spread,
		"trail_opacity": MisprintDodgeProof.trail_opacity,
		"blur_px": MisprintDodgeProof.blur_px,
		"starts": _start_count,
		"sizes": sizes,
	}
