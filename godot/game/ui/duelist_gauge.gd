## DuelistGauge — the dodge tank's instrument (S4): the WIND bubble (fatigue leash) + the ◆ COMBO
## pips (banked by perfect parries, spent by ⚡ DUMP). The FLOW / AGGRO meter rides the band's
## resource orb; this gauge carries the two smaller readouts. Pure view (no gameplay).
class_name DuelistGauge
extends ClassGauge

func _init() -> void:
	pulse_rate = 4.0

var wind: float = 10.0
var wind_max: float = 10.0
var combo: int = 0:
	set(v):
		if v > combo:
			_pop = 1.0          # a ◆ banked — punch the pips
		combo = v
var combo_max: int = 5
var fumbling: bool = false
var _pop: float = 0.0          ## pip-bank punch, decays per frame
# ART V2 / C6B (set ONLY by the dash host; default off ⇒ legacy byte-identical):
# WIND becomes the CENTRAL PRIMARY painted bar with EXACTLY the five smaller combo
# sockets directly below it (§2.3.1 E / I3-A revision 2). Fills/pips stay code-drawn.
var v2_skin: DashSkin = null
var v2_compact_stack := false ## isolated C6 compact anatomy: sockets top, Wind bottom

func _draw() -> void:
	var v2 := v2_skin != null
	# --- WIND: a slim GLASS bubble bar (AAA pass: seated, gradient fill, sheen, gold frame);
	#     C6B: the painted resource shell hosts it as THE central primary bar ---
	var bw := size.x * (0.92 if v2 else 0.62)
	var bx := size.x * 0.5 - bw * 0.5
	var by := (size.y - 52.0) if v2 and v2_compact_stack else size.y * (0.05 if v2 else 0.34)
	var wh := 10.0
	var well := Rect2(bx, by, bw, wh)
	if v2:
		var srect := Rect2(bx, by, bw,
			48.0 if v2_compact_stack else maxf(36.0, size.y * 0.48))
		v2_skin.hshell(self, "shell_resource", srect, DashSkin.CAPS_RESOURCE)
		well = v2_skin.sliced_opening("shell_resource", srect, DashSkin.CAPS_RESOURCE, DashSkin.OPEN_RESOURCE)
		bx = well.position.x
		by = well.position.y
		bw = well.size.x
		wh = well.size.y
		draw_rect(well, Palette.BG0)
	else:
		draw_rect(Rect2(bx + 1.0, by + 2.0, bw, wh), Color(0, 0, 0, 0.4))   # seat shadow
		draw_rect(well, Palette.BG0)
	var frac := clampf(wind / maxf(1.0, wind_max), 0.0, 1.0)
	var wc: Color = Palette.CRIMSON if fumbling else Palette.STEEL
	if not fumbling and frac < 0.25:
		wc = Palette.GOLD_DIM                       # low wind warning tint
	if fumbling:
		UiKit.glow(self, Vector2(bx + bw * 0.5, by + wh * 0.5), bw * 0.4,
			Color(Palette.CRIMSON.r, Palette.CRIMSON.g, Palette.CRIMSON.b, 0.25 + 0.15 * sin(pulse * 3.0)))
	UiKit.grad_rect(self, Rect2(bx, by, bw * frac, wh), wc.lightened(0.25), wc.darkened(0.25))
	if frac > 0.02:
		draw_rect(Rect2(bx + bw * frac - 1.5, by, 1.5, wh), wc.lightened(0.6))   # leading edge
	draw_rect(Rect2(bx, by, bw, wh * 0.35), Color(1, 1, 1, 0.10))                # glass sheen
	if v2:
		UiKit.text_shadowed(self, UiKit.display(600, 2), Vector2(bx + 6.0, by + wh * 0.5 + 4.0),
			"WIND", HORIZONTAL_ALIGNMENT_LEFT, 80.0, UiKit.SIZE["MICRO"],
			Palette.GOLD_DIM.lightened(0.25))
	else:
		draw_rect(well, Palette.GOLD_DIM, false, 1.0)

	# --- ◆ COMBO pips (banked by perfect parries) — gem-set now; the newest banks with a PUNCH.
	#     C6B: each pip sits in its painted octagon socket, ~25% smaller (I3-A revision) ---
	_pop = maxf(0.0, _pop - 0.05)
	var y2 := (20.0 if v2_compact_stack else size.y * 0.76) if v2 else size.y * 0.72
	var n := maxi(1, combo_max)
	var spacing := minf(size.x / float(n + 1),
		(46.0 if v2_compact_stack else clampf(size.y * 0.43, 35.0, 52.0)) if v2 else 30.0)
	for i in range(n):
		var x := size.x * 0.5 + (float(i) - float(n - 1) / 2.0) * spacing
		var lit := i < combo
		var col: Color = Palette.GOLD_BRIGHT if lit else Palette.BG0
		if lit and combo >= combo_max:
			col.a = 0.6 + 0.35 * sin(pulse * 2.0)    # full bank pulses (ready to DUMP)
		var r := 6.5 if v2 else 9.0
		if v2:
			var stex: Texture2D = v2_skin.t["socket_combo"]
			var ssw := minf((30.0 if v2_compact_stack else clampf(size.y * 0.34, 28.0, 42.0)), spacing * 0.86)
			var ssh := ssw * float(stex.get_height()) / float(stex.get_width())
			draw_texture_rect(stex, Rect2(x - ssw * 0.5, y2 - ssh * 0.5, ssw, ssh), false)
			r = ssw * 0.23
		if lit and i == combo - 1 and _pop > 0.0:
			r += 7.0 * _pop                          # the fresh ◆ lands big and settles
			var halo := Palette.GOLD_BRIGHT
			halo.a = 0.5 * _pop
			draw_arc(Vector2(x, y2), r + 5.0, 0.0, TAU, 20, halo, 2.0, true)
		if lit:
			UiKit.glow(self, Vector2(x, y2), r * 1.6, Color(Palette.GOLD_BRIGHT.r, Palette.GOLD_BRIGHT.g, Palette.GOLD_BRIGHT.b, 0.22))
		if lit or not v2:                            # an empty painted socket IS the empty read
			_diamond(Vector2(x, y2), r, col, lit)
	# --- DRY WIND warning: too tired to answer = say it out loud ---
	if not fumbling and wind < 2.6:
		var wcol := Palette.CRIMSON
		wcol.a = 0.55 + 0.4 * sin(pulse * 3.0)
		if v2:
			# Keep the warning inside the Wind instrument. Painting above the node
			# crossed the answer frame once C6C joined the two islands closely.
			UiKit.text_shadowed(self, UiKit.display(650, 1),
				Vector2(bx + 90.0, by + wh * 0.5 + 4.0), "WINDED — BREATHE",
				HORIZONTAL_ALIGNMENT_RIGHT, maxf(80.0, bw - 96.0), UiKit.SIZE["CAPTION"], wcol)
		else:
			# Default-off/legacy placement stays byte-identical.
			UiKit.text_shadowed(self, UiKit.display(650, 1), Vector2(0.0, size.y * 0.34 - 16.0),
				"WINDED — BREATHE", HORIZONTAL_ALIGNMENT_CENTER, size.x, UiKit.SIZE["CAPTION"], wcol)

func _diamond(c: Vector2, r: float, col: Color, lit: bool = false) -> void:
	var pts := PackedVector2Array([
		c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
	var sp := PackedVector2Array()
	for p in pts:
		sp.append(p + Vector2(1.0, 1.8))
	draw_colored_polygon(sp, Color(0, 0, 0, 0.4))
	draw_colored_polygon(pts, col)
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]),
		Palette.GOLD if lit else Palette.GOLD_DIM, 1.2, true)
	if lit:
		draw_circle(c + Vector2(-r * 0.28, -r * 0.36), 1.6, Color(1, 1, 1, 0.65))
