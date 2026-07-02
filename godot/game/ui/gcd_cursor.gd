## GcdCursor — a small ring that rides the mouse cursor and shows when you can act
## again: a gold arc fills as the global cooldown (or an in-progress cast) recharges,
## then a quick bright pulse the instant you're free. Invisible when you can cast, so
## it never clutters — it only appears while you're "busy". Overlay, ignores input.
class_name GcdCursor
extends Control

var frac: float = 1.0            # progress toward castable: 0 = just started, 1 = ready
var _ready_flash: float = 0.0
var _prev: float = 1.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

func _process(delta: float) -> void:
	if _prev < 1.0 and frac >= 1.0:
		_ready_flash = 0.28          # just became castable — pulse
	_prev = frac
	_ready_flash = maxf(0.0, _ready_flash - delta)
	queue_redraw()

func _draw() -> void:
	var m := get_local_mouse_position()
	var r := 17.0
	var top := -PI / 2.0
	if frac < 1.0:
		draw_arc(m, r, 0.0, TAU, 32, Color(0, 0, 0, 0.5), 3.5, true)          # dark backing
		draw_arc(m, r, top, top + TAU * clampf(frac, 0.0, 1.0), 32, Palette.GOLD, 3.5, true)
	if _ready_flash > 0.0:
		var a := _ready_flash / 0.28
		var col := Palette.GOLD_BRIGHT
		col.a = a * 0.9
		draw_arc(m, r + 5.0 * (1.0 - a), 0.0, TAU, 32, col, 2.5, true)        # expanding ready pulse
