## MisprintDodgeActor2D — isolated whole-pose dodge proof.
##
## The real reducer emits `duel_answer`; RaidStage2D forwards that committed
## event through Actor2D.graded_react(), and sync_tick() advances the pixels from
## CombatState.tick. No wall-clock tween owns pose timing. The five active cards
## therefore hold for exactly 1/1/2/2/4 simulation ticks at every render rate.
class_name MisprintDodgeActor2D
extends Actor2D

const FRAME_PATHS := [
	"res://prototypes/misprint_dodge/frames/dodge_frame_01.png",
	"res://prototypes/misprint_dodge/frames/dodge_frame_02.png",
	"res://prototypes/misprint_dodge/frames/dodge_frame_03.png",
	"res://prototypes/misprint_dodge/frames/dodge_frame_04.png",
	"res://prototypes/misprint_dodge/frames/dodge_frame_05.png",
	"res://prototypes/misprint_dodge/frames/dodge_frame_06.png",
]
const LOGICAL_CANVAS := Vector2(554.0, 467.0)
const ART_SCALE := 0.66
const TRAVEL_PX := 86.0
const ACTIVE_TICKS := 10
const CORAL := Color(0.96, 0.33, 0.25, 0.42)
const COBALT := Color(0.12, 0.34, 0.86, 0.38)

## Root travel by active age. The card art supplies the body deformation; this
## supplies the 70–100 px screen move the handoff explicitly keeps out of art.
const TRAVEL := [0.0, 0.28, 0.68, 1.0, 1.06, 1.0, 0.82, 0.58, 0.32, 0.12, 0.0]

var _frames: Array[Texture2D] = []
var _visual: Node2D
var _main: Sprite2D
var _coral: Sprite2D
var _cobalt: Sprite2D
var _tick := 0
var _start_tick := -1
var _frame_i := 0
var _age := -1
var _start_count := 0

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
	_coral = _make_card(CORAL, -2)
	_cobalt = _make_card(COBALT, -1)
	_main = _make_card(Color.WHITE, 0)
	_set_frame(0)
	_set_echo(false)
	return true

func _make_card(tint: Color, z: int) -> Sprite2D:
	var card := Sprite2D.new()
	card.centered = false
	# The handed-off files differ by one pixel (553–554 × 466–467). Keep every
	# source byte untouched and register all six into one 554×467 logical card.
	# Top-left registration preserves the generated sheet's shared baseline.
	card.position = Vector2(-LOGICAL_CANVAS.x * 0.5, -LOGICAL_CANVAS.y)
	card.self_modulate = tint
	card.z_index = z
	_visual.add_child(card)
	return card

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
		_visual.position.x = 0.0
		_set_frame(0)
		_set_echo(false)
		return
	var next_frame := 1
	if age == 0:
		next_frame = 1
	elif age == 1:
		next_frame = 2
	elif age <= 3:
		next_frame = 3
	elif age <= 5:
		next_frame = 4
	else:
		next_frame = 5
	_set_frame(next_frame)
	_visual.position.x = TRAVEL_PX * float(TRAVEL[age])
	# Departure and first clearance only. Visibility is tick-owned, so a slow
	# renderer cannot accidentally stretch the echoes into gameplay timing.
	_set_echo(age == 1 or age == 2)

func _set_frame(frame_i: int) -> void:
	_frame_i = clampi(frame_i, 0, _frames.size() - 1)
	var tex := _frames[_frame_i]
	_main.texture = tex
	_coral.texture = tex
	_cobalt.texture = tex

func _set_echo(on: bool) -> void:
	_coral.visible = on
	_cobalt.visible = on
	# Opposed registration slips: compact, behind the body, and nowhere near the
	# answer instrument. They move with the same root/card and add no particles.
	_coral.position = Vector2(-LOGICAL_CANVAS.x * 0.5 - 8.0, -LOGICAL_CANVAS.y + 2.0)
	_cobalt.position = Vector2(-LOGICAL_CANVAS.x * 0.5 + 7.0, -LOGICAL_CANVAS.y - 2.0)

## Headless proof surface — pixels remain private; tests read only presentation
## bookkeeping and imported dimensions.
func debug_snapshot() -> Dictionary:
	var sizes: Array = []
	for tex in _frames:
		sizes.append(Vector2i(tex.get_width(), tex.get_height()))
	return {
		"tick": _tick,
		"start_tick": _start_tick,
		"age": _age,
		"frame": _frame_i,
		"travel": _visual.position.x,
		"echo": _coral.visible and _cobalt.visible,
		"starts": _start_count,
		"sizes": sizes,
	}
