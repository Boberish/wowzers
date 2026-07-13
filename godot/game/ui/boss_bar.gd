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
var enrage_in: float = INF     # seconds until enrage; <=0 = ENRAGED; INF = no enrage timer
var sunder: float = 0.0        # tank SUNDER (0 = hidden); the boss's cracking wall
var sunder_max: float = 5.0

## The 1-based phase index for the current boss HP (shared by every HUD; was copy-
## pasted as _phase_num into all six). Pure view helper, mirrors the display logic.
static func phase_index(s: CombatState) -> int:
	var fr := s.boss.hp / s.boss.hp_max
	var n := 1
	for i in s.encounter.phases.size():
		if s.encounter.phases[i].at >= fr:
			n = i + 1
	return n

const BARH := 26.0
# ART V2 / C6B (set ONLY by the dash host; default off ⇒ legacy byte-identical):
# the painted boss shell owns the housing — skip the plate's own flourish arms,
# bevel frame and jeweled end-caps. Name, fill, chip ghost, phase gems/notches,
# SUNDER, HP numerals, phase flash and the enrage clock stay code-drawn.
var v2_naked := false
var _bar: ColorRect
var _chip: float = 1.0
var _chip_hold: float = 0.0
var _last_frac: float = 1.0
var _last_phase: int = 1
var _pflash: float = 0.0       # gold pulse when a phase threshold is crossed
var _t: float = 0.0

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
	_t += delta
	if phase_num > _last_phase:
		_pflash = 1.0            # a threshold broke — the plate registers it
	_last_phase = phase_num
	_pflash = maxf(0.0, _pflash - delta * 1.6)
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
	if arm > 20.0 and not v2_naked:
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

	# --- SUNDER: the tank's cracking wall, tucked over the bar's LEFT end. Fracture pips
	#     fill as won reads crack the boss — while lit, EVERYONE's hits land harder. Hidden
	#     when no tank feeds it (sunder == 0). ---
	if sunder > 0.01:
		var np_s := int(round(maxf(sunder_max, 1.0)))
		var lit_f := sunder / maxf(sunder_max, 1.0)
		for i in np_s:
			var sx := 10.0 + float(i) * 16.0
			var pf := clampf(lit_f * float(np_s) - float(i), 0.0, 1.0)
			var scol := Palette.RAGE.lerp(Palette.CRIMSON, pf)
			if pf > 0.05:
				var gl := scol
				gl.a = 0.18 + 0.14 * sin(_t * 5.0 + float(i))
				draw_circle(Vector2(sx, top - 10.0), 9.0, gl)
			UiKit.gilded_pip(self, Vector2(sx, top - 10.0), 5.0, pf > 0.5, scol)
		UiKit.text_shadowed(self, UiKit.display(600, 1), Vector2(6.0, top - 26.0), "SUNDER",
			HORIZONTAL_ALIGNMENT_LEFT, 120.0, UiKit.SIZE["MICRO"], Palette.CRIMSON.lightened(0.2))

	# --- engraved phase-threshold notches (dark groove + lit gold lip) ---
	for at in phase_ats:
		if float(at) < 0.999:
			var x := size.x * float(at)
			draw_line(Vector2(x, top + 2.0), Vector2(x, top + BARH - 2.0), Palette.BG0, 3.0)
			draw_line(Vector2(x + 1.0, top + 2.0), Vector2(x + 1.0, top + BARH - 2.0), Palette.GOLD_DIM, 1.0)

	# --- 2-tone gilded bevel frame + jeweled end-caps (the painted shell's recessed
	#     window replaces both in C6B) ---
	if not v2_naked:
		draw_line(Vector2(0, top), Vector2(size.x, top), Palette.GOLD_BRIGHT, 1.6, true)
		draw_line(Vector2(0, top), Vector2(0, top + BARH), Palette.GOLD, 1.6, true)
		draw_line(Vector2(0, top + BARH), Vector2(size.x, top + BARH), Palette.GOLD_DIM, 1.6, true)
		draw_line(Vector2(size.x, top), Vector2(size.x, top + BARH), Palette.GOLD_DIM, 1.6, true)
		_gem(Vector2(0, top + BARH * 0.5), 8.0, Palette.CRIMSON_DEEP.lightened(0.1))
		_gem(Vector2(size.x, top + BARH * 0.5), 8.0, Palette.CRIMSON_DEEP.lightened(0.1))

	# --- HP readout centred on the bar, in display numerals ---
	UiKit.text_shadowed(self, UiKit.display(600), Vector2(0, top + 18.0),
		"%d / %d" % [int(round(hp)), int(round(hp_max))],
		HORIZONTAL_ALIGNMENT_CENTER, size.x, UiKit.SIZE["LABEL"], Palette.GOLD_BRIGHT)

	# --- phase-break flash: the whole bar pulses gold as a threshold falls ---
	if _pflash > 0.0:
		var pf := Palette.GOLD_BRIGHT
		pf.a = 0.35 * _pflash
		draw_rect(Rect2(0, top, size.x, BARH), pf)
		pf.a = 0.8 * _pflash
		draw_rect(Rect2(-2, top - 2, size.x + 4, BARH + 4), pf, false, 2.0)

	# --- the enrage clock: the deadliest timer in the game, finally visible ---
	if enrage_in <= 12.0 and enrage_in < INF:
		var ey := size.y + 14.0
		if enrage_in > 0.0:
			var urgency := clampf(1.0 - enrage_in / 12.0, 0.0, 1.0)
			var wc := Palette.CRIMSON.lerp(Palette.HEAVY, 0.35 * (1.0 - urgency))
			wc.a = 0.55 + 0.45 * sin(_t * (3.0 + 5.0 * urgency))
			UiKit.text_shadowed(self, UiKit.display(700, 2), Vector2(0, ey),
				"◆ ENRAGE · %.0fs" % ceilf(enrage_in), HORIZONTAL_ALIGNMENT_CENTER,
				size.x, UiKit.SIZE["CAPTION"], wc)
		else:
			var bc := Palette.CRIMSON
			bc.a = 0.7 + 0.3 * sin(_t * 6.0)
			UiKit.text_shadowed(self, UiKit.display(750, 2), Vector2(0, ey),
				"— ENRAGED —", HORIZONTAL_ALIGNMENT_CENTER, size.x, UiKit.SIZE["LABEL"], bc)
			draw_rect(Rect2(-2, top - 2, size.x + 4, BARH + 4), bc, false, 1.6)
