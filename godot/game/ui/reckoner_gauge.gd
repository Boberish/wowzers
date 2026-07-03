## The Reckoner's swing instrument — the WIND channel that becomes a contracting APEX
## ring, flanked by a Momentum tachometer (left) and a Poise-Break meter (right) that
## cracks toward a STAGGER. Pure view; the HUD feeds it the observe() fields each frame,
## and pushes a held verdict via react() from the combat event stream.
##   phase: 0 WIND · 1 STRIKE(apex) · 2 ULTRASWING · 3 onslaught-wind · 4 onslaught-strike.
class_name ReckonerGauge
extends Control

var aspect: String = "colossus"
var phase: int = 0
# WIND (ticks)
var since_wind: int = 0
var wind_len: int = 27
var even_lo: int = 9
var heavy_lo: int = 18
var over_lo: int = 23
var over_armed: bool = false
# APEX (ticks)
var to_apex: int = 999
var apex_total: int = 12
var true_half: int = 1
# meters
var momentum: float = 0.0
var momentum_max: float = 8.0
var poise: float = 0.0
var poise_max: float = 100.0
var stagger: bool = false

var _flash: float = 0.0
var _verdict: String = ""
var _vcol: Color = Palette.GOLD_BRIGHT
var _pulse: float = 0.0

## Held verdict pop, called from the HUD's event drain: true/over/clash/stagger/ultra/onslaught.
func react(kind: String) -> void:
	_verdict = kind.to_upper()
	_flash = 1.0
	match kind:
		"true", "perfect": _vcol = Palette.PERFECT
		"over": _vcol = Palette.HEAVY
		"clash": _vcol = Palette.GOLD_BRIGHT
		"stagger": _vcol = Palette.STEEL
		"ultra": _vcol = Palette.KICK
		"onslaught": _vcol = Palette.PERFECT
		_: _vcol = Palette.GOLD_BRIGHT

func _process(delta: float) -> void:
	_pulse += delta * 3.0
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 1.9)
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 60.0 or h < 30.0:
		return
	_draw_momentum(Vector2(12.0, h * 0.5), h * 0.40)
	_draw_poise(Vector2(w - 24.0, 10.0), Vector2(12.0, h - 22.0))

	var cx := w * 0.5
	var label := "WIND — COMMIT"
	var lcol := Palette.TEXT_DIM
	if phase == 1: label = "STRIKE — THE APEX"
	elif phase == 2: label = "ULTRASWING"; lcol = Palette.KICK
	elif phase == 4: label = "ONSLAUGHT — STRIKE"; lcol = Palette.PERFECT
	elif phase == 3: label = "ONSLAUGHT — WIND"; lcol = Palette.PERFECT
	UiKit.text_shadowed(self, UiKit.display(600, 2), Vector2(cx - 160.0, 14.0), label,
		HORIZONTAL_ALIGNMENT_CENTER, 320.0, UiKit.SIZE["MICRO"], lcol)

	if phase == 0 or phase == 3:
		_draw_wind(Vector2(cx - w * 0.28, h * 0.36), Vector2(w * 0.56, 38.0))
	else:
		_draw_apex(Vector2(cx, h * 0.58), minf(h * 0.34, 44.0))

	if _flash > 0.0 and _verdict != "":
		var a := clampf(_flash, 0.0, 1.0)
		UiKit.text_shadowed(self, UiKit.display(750, 2), Vector2(cx - 190.0, h * 0.50 - 13.0),
			_verdict, HORIZONTAL_ALIGNMENT_CENTER, 380.0, UiKit.SIZE["LABEL"],
			Color(_vcol.r, _vcol.g, _vcol.b, a))

func _draw_wind(pos: Vector2, sz: Vector2) -> void:
	var wl := maxf(1.0, float(wind_len))
	var qf := clampf(float(even_lo) / wl, 0.0, 1.0)
	var ef := clampf(float(heavy_lo) / wl, 0.0, 1.0)
	var ov := clampf(float(over_lo) / wl, 0.0, 1.0)
	var zones: Array = [[0.0, qf, Palette.STEEL, "QUICK"], [qf, ef, Palette.GOLD, "EVEN"]]
	if over_armed:
		zones.append([ef, ov, Palette.HEAVY, "HEAVY"])
		zones.append([ov, 1.0, Palette.CRIMSON, "OVER"])
	else:
		zones.append([ef, 1.0, Palette.HEAVY, "HEAVY"])
	for z in zones:
		var x0 := pos.x + sz.x * float(z[0])
		var x1 := pos.x + sz.x * float(z[1])
		draw_rect(Rect2(x0 + 1.0, pos.y, maxf(1.0, (x1 - x0) - 2.0), sz.y), z[2], true)
		if (float(z[1]) - float(z[0])) > 0.12:
			UiKit.text_shadowed(self, UiKit.display(600, 1),
				Vector2((x0 + x1) * 0.5 - 40.0, pos.y + sz.y * 0.5 - 6.0), String(z[3]),
				HORIZONTAL_ALIGNMENT_CENTER, 80.0, UiKit.SIZE["MICRO"], Color(0, 0, 0, 0.8))
	UiKit.gilded_ring(self, pos + sz * 0.5, 0.0, 0.0, 4)   # frame corners (radius 0 = just filigree)
	var frac := clampf(float(since_wind) / wl, 0.0, 1.02)
	var nx := pos.x + sz.x * frac
	draw_rect(Rect2(nx - 2.0, pos.y - 6.0, 4.0, sz.y + 12.0), Palette.GOLD_BRIGHT, true)

func _draw_apex(c: Vector2, R: float) -> void:
	draw_arc(c, R, 0.0, TAU, 40, Palette.EDGE, 3.0, true)
	var total := maxf(1.0, float(apex_total))
	var prog := clampf(1.0 - float(to_apex) / total, 0.0, 1.12)
	var r2 := R * maxf(0.06, 1.0 - minf(prog, 1.1))
	var near := absi(to_apex) <= true_half
	var col := Palette.PERFECT if near else (Palette.CRIMSON if prog > 1.0 else Palette.GOLD)
	draw_arc(c, R * 0.14, 0.0, TAU, 24,
		Color(Palette.PERFECT.r, Palette.PERFECT.g, Palette.PERFECT.b, 0.55), 2.0, true)
	draw_arc(c, r2, 0.0, TAU, 40, col, 5.0, true)
	if near:
		UiKit.text_shadowed(self, UiKit.display(750, 2), Vector2(c.x - 60.0, c.y - 9.0), "NOW",
			HORIZONTAL_ALIGNMENT_CENTER, 120.0, UiKit.SIZE["LABEL"], Palette.PERFECT)

func _draw_momentum(center: Vector2, halfh: float) -> void:
	var n := maxi(1, int(round(momentum_max)))
	var lit := int(floor(momentum))
	var step := (halfh * 2.0) / float(n)
	for i in n:
		var y := center.y + halfh - step * (float(i) + 0.5)
		draw_rect(Rect2(center.x, y - step * 0.35, 10.0, step * 0.7),
			Palette.MOMENTUM if i < lit else Palette.EDGE, true)
	UiKit.text_shadowed(self, UiKit.display(600, 1), Vector2(center.x - 8.0, center.y + halfh + 4.0),
		"MOM", HORIZONTAL_ALIGNMENT_LEFT, 44.0, UiKit.SIZE["MICRO"], Palette.TEXT_DIM)

func _draw_poise(pos: Vector2, sz: Vector2) -> void:
	draw_rect(Rect2(pos, sz), Palette.BG1, true)
	var f := clampf(poise / maxf(1.0, poise_max), 0.0, 1.0)
	var fh := sz.y * f
	var col := Palette.STEEL
	if stagger:
		col = Palette.GOLD_BRIGHT
	elif f > 0.75:
		col = Palette.STEEL.lightened(0.2 + 0.2 * sin(_pulse * 4.0))
	draw_rect(Rect2(pos.x, pos.y + sz.y - fh, sz.x, fh), col, true)
	if stagger:
		UiKit.text_shadowed(self, UiKit.display(700, 2), Vector2(pos.x - 74.0, pos.y - 3.0),
			"STAGGER", HORIZONTAL_ALIGNMENT_RIGHT, 68.0, UiKit.SIZE["MICRO"], Palette.GOLD_BRIGHT)
	else:
		UiKit.text_shadowed(self, UiKit.display(600, 1), Vector2(pos.x - 44.0, pos.y + sz.y + 4.0),
			"POISE", HORIZONTAL_ALIGNMENT_RIGHT, 52.0, UiKit.SIZE["MICRO"], Palette.TEXT_DIM)
