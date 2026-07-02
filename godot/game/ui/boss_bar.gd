## The boss nameplate: an ornate ceremonial plate. The name sits centred in tracked
## Cinzel capitals between gold rule-and-gem flourishes; beneath it a jeweled health
## bar — glossy crimson shader fill with a white damage-chip ghost trail — framed in a
## 2-tone gilded bevel with diamond end-caps, engraved phase notches, and phase gems.
class_name BossBar
extends Control

var boss_name: String = ""
var hp: float = 0.0
var hp_max: float = 1.0
var phase_num: int = 1
var phase_ats: Array = []      # phase .at thresholds (for notch marks)

const BARH := 26.0
var _bar: ColorRect
var _chip: float = 1.0
var _chip_hold: float = 0.0
var _last_frac: float = 1.0

func _ready() -> void:
	_bar = UiKit.make_bar(self, Palette.CRIMSON)
	_bar.show_behind_parent = true   # notches + HP text draw on top of the fill

func _frac() -> float:
	return clampf(hp / hp_max, 0.0, 1.0) if hp_max > 0.0 else 0.0

func _process(delta: float) -> void:
	var frac := _frac()
	# damage-chip ghost: a fresh loss holds the ghost, then it decays down to the new HP;
	# a heal snaps it up instantly.
	if frac < _last_frac:
		_chip_hold = 0.25
	if frac > _chip:
		_chip = frac
	elif _chip > frac:
		if _chip_hold > 0.0:
			_chip_hold -= delta
		else:
			_chip = maxf(frac, _chip - delta * 0.6)
	_last_frac = frac
	if _bar != null:
		_bar.position = Vector2(0, size.y - BARH)
		_bar.size = Vector2(size.x, BARH)
		UiKit.set_bar(_bar, frac, _chip)
	queue_redraw()

## a small cut gem: rotated-square jewel with a gold bezel and a specular glint
func _gem(at: Vector2, r: float, body: Color) -> void:
	var pts := PackedVector2Array([at + Vector2(0, -r), at + Vector2(r, 0),
		at + Vector2(0, r), at + Vector2(-r, 0)])
	draw_colored_polygon(pts, body)
	for i in 4:
		var a := pts[i]
		var b := pts[(i + 1) % 4]
		draw_line(a, b, Palette.GOLD if i < 2 else Palette.GOLD_DIM, 1.4, true)
	draw_circle(at + Vector2(-r * 0.25, -r * 0.3), r * 0.22, Color(1, 1, 1, 0.75))

func _draw() -> void:
	var dfont := UiKit.display(700, 2)
	var top := size.y - BARH
	var cx := size.x * 0.5

	# --- the name, centred, flanked by rule-and-gem flourishes ---
	var nm := boss_name.to_upper()
	var nsz := UiKit.SIZE["TITLE"]
	var tw := dfont.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, nsz).x
	UiKit.text_shadowed(self, dfont, Vector2(0, 22), nm,
		HORIZONTAL_ALIGNMENT_CENTER, size.x, nsz, Palette.GOLD.lerp(Palette.GOLD_BRIGHT, 0.35))
	var ry := 14.0
	var gap := tw * 0.5 + 20.0
	var arm := minf(size.x * 0.5 - gap - 16.0, 90.0)
	if arm > 20.0:
		for s: float in [-1.0, 1.0]:
			var x0 := cx + s * gap
			var x1 := cx + s * (gap + arm)
			draw_line(Vector2(x0, ry), Vector2(x1, ry), Palette.GOLD_DIM, 1.2, true)
			draw_line(Vector2(x0, ry), Vector2(lerpf(x0, x1, 0.6), ry),
				Color(Palette.GOLD.r, Palette.GOLD.g, Palette.GOLD.b, 0.8), 1.2, true)
			_gem(Vector2(x1, ry), 4.5, Palette.CRIMSON_DEEP.lightened(0.15))

	# --- phase gems (lit up to the current phase), tucked over the bar's right end ---
	var np := maxi(phase_ats.size(), 1)
	if np > 1:
		for i in np:
			var px := size.x - 10.0 - float(np - 1 - i) * 16.0
			UiKit.gilded_pip(self, Vector2(px, top - 10.0), 5.0, i < phase_num, Palette.CRIMSON)

	# --- engraved phase-threshold notches (dark groove + lit gold lip) ---
	for at in phase_ats:
		if float(at) < 0.999:
			var x := size.x * float(at)
			draw_line(Vector2(x, top + 2.0), Vector2(x, top + BARH - 2.0), Palette.BG0, 3.0)
			draw_line(Vector2(x + 1.0, top + 2.0), Vector2(x + 1.0, top + BARH - 2.0), Palette.GOLD_DIM, 1.0)

	# --- 2-tone gilded bevel frame around the bar (one virtual light) ---
	draw_line(Vector2(0, top), Vector2(size.x, top), Palette.GOLD_BRIGHT, 1.6, true)
	draw_line(Vector2(0, top), Vector2(0, top + BARH), Palette.GOLD, 1.6, true)
	draw_line(Vector2(0, top + BARH), Vector2(size.x, top + BARH), Palette.GOLD_DIM, 1.6, true)
	draw_line(Vector2(size.x, top), Vector2(size.x, top + BARH), Palette.GOLD_DIM, 1.6, true)

	# --- jeweled end-caps ---
	_gem(Vector2(0, top + BARH * 0.5), 8.0, Palette.CRIMSON_DEEP.lightened(0.1))
	_gem(Vector2(size.x, top + BARH * 0.5), 8.0, Palette.CRIMSON_DEEP.lightened(0.1))

	# --- HP readout centred on the bar, in display numerals ---
	UiKit.text_shadowed(self, UiKit.display(600), Vector2(0, top + 18.0),
		"%d / %d" % [int(round(hp)), int(round(hp_max))],
		HORIZONTAL_ALIGNMENT_CENTER, size.x, UiKit.SIZE["LABEL"], Palette.GOLD_BRIGHT)
