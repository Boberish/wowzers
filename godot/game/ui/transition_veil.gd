## The screen-swap veil: every `_clear()` flashes a sheet of obsidian that eases
## off over a third of a second, so screens SETTLE IN instead of snapping — the
## cheapest unit of "this is a finished game" there is. A thin gold hairline
## frame breathes once as the veil lifts (the reliquary closing and reopening).
##
## Usage (one line, at the top of a HUD's `_clear()`):
##     TransitionVeil.flash_on(self)
## The veil child is created on first use, lives on the HUD ROOT (not `_ui`, so
## clears never free it) and re-fronts itself every flash. Mouse-transparent,
## purely view-side.
class_name TransitionVeil
extends Control

const HOLD := 0.34            ## seconds from full veil to gone

var _a := 0.0                 ## current veil strength, decays

static func flash_on(root: Control, strength: float = 1.0) -> void:
	var veil: TransitionVeil = null
	for c in root.get_children():
		if c is TransitionVeil:
			veil = c
			break
	if veil == null:
		veil = TransitionVeil.new()
		veil.set_anchors_preset(Control.PRESET_FULL_RECT)
		veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(veil)
	veil.move_to_front()      # above whatever the new screen just built
	veil._a = clampf(strength, 0.0, 1.0)

func _process(delta: float) -> void:
	if _a <= 0.0:
		return
	_a = maxf(0.0, _a - delta / HOLD)
	queue_redraw()

func _draw() -> void:
	if _a <= 0.001:
		return
	var ease_a := _a * _a * (3.0 - 2.0 * _a)     # smoothstep — lingers dark, lifts fast
	draw_rect(Rect2(Vector2.ZERO, size), Color(Palette.BG0.r, Palette.BG0.g, Palette.BG0.b, 0.94 * ease_a))
	# the gold hairline frame, breathing once as the veil lifts
	var f := Palette.GOLD
	f.a = 0.35 * sin(ease_a * PI)
	var m := 26.0 + 40.0 * (1.0 - ease_a)
	draw_rect(Rect2(m, m, size.x - 2.0 * m, size.y - 2.0 * m), f, false, 1.5)
