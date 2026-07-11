## VerdictSlam — the tank's AAA answer feedback (Bill 2026-07-11). Every graded press
## SLAMS the verdict at attention height, full theatrics by grade:
##   PERFECT — huge blazing gold: punch-scale text, a 12-ray burst, twin expanding
##             rings, and a running STREAK counter ("PERFECT ×4").
##   GOOD    — solid gold pop.  GRAZE — steel, smaller (you barely made it).
##   HIT     — the miss: crimson slam + a red EDGE VIGNETTE pulse + screen shake
##             (wired by the band) — eating a bar must never feel ambiguous.
##   BAITED  — purple mock (you pressed a feint).  READ — calm purple nod.
## Full-rect, mouse-transparent, pure view. Fed by StrikeJudge's `verdict` signal.
class_name VerdictSlam
extends Control

var _txt := ""
var _col := Color.WHITE
var _big := false
var _t := 0.0                 ## life remaining (seconds)
var _life := 1.15
var _streak := 0              ## consecutive PERFECTs
var _vign := 0.0              ## edge vignette pulse (the miss)
var _vign_col := Palette.CRIMSON
var _pulse := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# anchors are set by the BUILDER before add_child (the place-then-add law)

func _process(delta: float) -> void:
	_pulse += delta * 6.0
	_t = maxf(0.0, _t - delta)
	_vign = maxf(0.0, _vign - delta * 1.8)
	if _t > 0.0 or _vign > 0.0:
		queue_redraw()

## One verdict lands. `grade_family`: "perfect" | "good" | "graze" | "hit" | "baited" | "read"
func slam(txt: String, family: String) -> void:
	_txt = txt
	_t = _life
	_big = false
	match family:
		"perfect":
			_streak += 1
			_col = Palette.GOLD_BRIGHT
			_big = true
			if _streak >= 2:
				_txt = "%s  ×%d" % [txt, _streak]
		"good":
			_streak = 0
			_col = Palette.GOLD
		"graze":
			_streak = 0
			_col = Palette.STEEL
		"hit":
			_streak = 0
			_col = Palette.CRIMSON
			_big = true
			_vign = 1.0
			_vign_col = Palette.CRIMSON
		"baited":
			_streak = 0
			_col = Palette.RELIC
			_big = true
			_vign = 0.6
			_vign_col = Palette.RELIC
		_:
			_streak = 0
			_col = Palette.RELIC

func _draw() -> void:
	var w := size.x
	var h := size.y
	# ---- edge vignette pulse (the miss bleeds at the frame) ----
	if _vign > 0.0:
		var va := 0.34 * _vign
		var d := 90.0 + 50.0 * (1.0 - _vign)
		var c0 := Color(_vign_col.r, _vign_col.g, _vign_col.b, va)
		var c1 := Color(_vign_col.r, _vign_col.g, _vign_col.b, 0.0)
		# four gradient wedges via per-vertex colours
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, d), Vector2(0, d)]),
			PackedColorArray([c0, c0, c1, c1]))
		draw_polygon(PackedVector2Array([Vector2(0, h), Vector2(w, h), Vector2(w, h - d), Vector2(0, h - d)]),
			PackedColorArray([c0, c0, c1, c1]))
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(0, h), Vector2(d, h), Vector2(d, 0)]),
			PackedColorArray([c0, c0, c1, c1]))
		draw_polygon(PackedVector2Array([Vector2(w, 0), Vector2(w, h), Vector2(w - d, h), Vector2(w - d, 0)]),
			PackedColorArray([c0, c0, c1, c1]))

	if _t <= 0.0:
		return
	var f := _t / _life                       # 1 -> 0
	var appear := clampf((1.0 - f) / 0.12, 0.0, 1.0)   # first ~0.14s: punch in
	var fade := clampf(_t / 0.30, 0.0, 1.0)            # last 0.3s: fade out
	var punch := 1.0 + 0.55 * (1.0 - appear) * (1.0 - appear)
	var at := Vector2(w * 0.5, h * 0.34 - 26.0 * (1.0 - f))
	var col := _col
	col.a = fade

	# rings + rays for the big ones
	if _big and appear >= 1.0:
		var ring_f := 1.0 - f
		var rcol := col
		rcol.a = fade * 0.7 * f
		draw_arc(at, 34.0 + 130.0 * ring_f, 0.0, TAU, 48, rcol, 3.0, true)
		rcol.a = fade * 0.4 * f
		draw_arc(at, 20.0 + 200.0 * ring_f, 0.0, TAU, 48, rcol, 2.0, true)
		if _col == Palette.GOLD_BRIGHT:
			for k in 12:
				var a := TAU * float(k) / 12.0 + ring_f * 0.4
				var dvec := Vector2(cos(a), sin(a))
				var ray := col
				ray.a = fade * 0.8 * f
				draw_line(at + dvec * (40.0 + 90.0 * ring_f),
					at + dvec * (58.0 + 130.0 * ring_f), ray, 2.4, true)

	# the slam text: shadowed, punch-scaled via font size
	var base_size := 46 if _big else 30
	var fs := int(round(float(base_size) * punch))
	var font := UiKit.display(800, 1)
	var half_w := w * 0.5
	# hard shadow
	var sh := Color(0, 0, 0, 0.75 * fade)
	draw_string(font, at + Vector2(-half_w, 3.0), _txt, HORIZONTAL_ALIGNMENT_CENTER, w, fs, sh)
	draw_string(font, at + Vector2(-half_w, 0.0), _txt, HORIZONTAL_ALIGNMENT_CENTER, w, fs, col)
	# specular top-line on the big gold ones
	if _big and _col == Palette.GOLD_BRIGHT:
		var spec := Color(1, 1, 1, 0.35 * fade)
		draw_string(font, at + Vector2(-half_w, -1.5), _txt, HORIZONTAL_ALIGNMENT_CENTER, w, fs, spec)
