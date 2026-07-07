## WellGauge — the reworked healer's instrument (MENDER-PLAN). A plain view Control fed
## observe() fields each frame + verdict events via on_event; never touches combat state.
##   • THE WELL: a row of glass WATER ORBS — the discrete charges as living water:
##     wavy waterlines, rising bubbles, gilded rims; orbs fill and drain smoothly and
##     the newest full orb glows. Empty vessel = DRY.
##   • THE CURRENT (draw): the cast-haste stream — steel pips with a travelling light.
##   • THE TARGET BAR: the ally under your hands, writ large — a jeweled glass health
##     bar with HP numerals, the in-flight heal's ghost landing, and (brim) the gilded
##     POUR window crowned by a gem.
##   • Verdict banner (big, centre-stage) + grade-history gems (POUR/STILL/CLEAN/UNDER/SPILL).
## The cast bar itself is the SHARED healer CastChannel (extended with the release window).
class_name WellGauge
extends Control

# fed each frame by _render_band_well
var aspect: String = "brim"
var charges: int = 12
var charges_max: int = 12
var current: int = 0
var current_max: int = 5
# the target bar
var t_show: bool = false
var t_name: String = ""
var t_frac: float = 0.0
var t_hp: int = 0
var t_hpmax: int = 0
var t_ghost: float = -1.0        ## where the in-flight heal LANDS (-1 = no cast)
var t_band: float = -1.0         ## the brim window start (-1 = no band; draw hides it)
var t_glint: bool = false

# feedback + cosmetic animation state (client-only; never touches combat)
var _banner: String = ""
var _banner_col: Color = Color.WHITE
var _banner_t: float = 0.0
var _hist: Array = []            # [{col}], last 8 verdicts
var _pulse: float = 0.0
var _shown: float = 12.0         # eased charge count — orbs fill/drain as water, not blocks
var _gain_t: float = 0.0         # newest-orb pop when the pulse refills
var _prev_charges: int = -1
var _disp_frac: float = 1.0      # eased target HP fill
var _lag_frac: float = 1.0       # slow-falling recent-damage trail on the target bar
var _disp_hp: float = 0.0
var _last_target: String = ""

var seat_ref: Seat = null

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	_pulse += delta
	if _banner_t > 0.0:
		_banner_t = maxf(0.0, _banner_t - delta)
	# the water level eases toward truth; a refill pops the newest orb
	if _prev_charges >= 0 and charges > _prev_charges:
		_gain_t = 1.0
	_prev_charges = charges
	_gain_t = maxf(0.0, _gain_t - delta * 2.2)
	_shown += (float(charges) - _shown) * clampf(delta * 5.0, 0.0, 1.0)
	if absf(_shown - float(charges)) < 0.01:
		_shown = float(charges)
	# target-bar easing (snap when the target changes — no cross-ally morphing)
	if t_name != _last_target:
		_last_target = t_name
		_disp_frac = t_frac
		_lag_frac = t_frac
		_disp_hp = float(t_hp)
	_disp_frac += (t_frac - _disp_frac) * clampf(delta * 12.0, 0.0, 1.0)
	_disp_hp += (float(t_hp) - _disp_hp) * clampf(delta * 12.0, 0.0, 1.0)
	if t_frac >= _lag_frac:
		_lag_frac = t_frac
	else:
		_lag_frac = maxf(t_frac, _lag_frac - delta * 0.7)
	queue_redraw()

func on_event(ev: Dictionary) -> void:
	if not bool(ev.get("player", false)) and ev.get("seat") != seat_ref:
		return
	match String(ev.get("t", "")):
		"well_pour":  _flash("PERFECT POUR — GLINT!", Palette.GOLD_BRIGHT)
		"well_still": _flash("STILL POINT — GLINT!", Palette.GOLD_BRIGHT)
		"well_clean": _flash("CLEAN — the current rises", Palette.STEEL)
		"well_under": _flash("UNDERCOOKED", Palette.THORN)
		"well_spill": _flash("SPILL — %d wasted" % int(ev.get("amt", 0)), Palette.BLOOD)

func _flash(msg: String, col: Color) -> void:
	_banner = msg
	_banner_col = col
	_banner_t = 1.4
	_hist.push_back({"col": col})
	if _hist.size() > 8:
		_hist.pop_front()

func _draw() -> void:
	var w := size.x

	# --- header: the class line, left · the grade-history gems, right ---
	UiKit.text_shadowed(self, UiKit.display(650, 2), Vector2(8, 14), "THE WELL",
		HORIZONTAL_ALIGNMENT_LEFT, -1, UiKit.SIZE["LABEL"], Palette.GOLD)
	var sub := "— BRIM · land the pour in the gold" if aspect == "brim" \
		else "— DRAW · release in the window"
	UiKit.text_shadowed(self, UiKit.body(500), Vector2(92, 14), sub,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.TEXT_DIM)
	var hx := w - 12.0
	for k in range(_hist.size() - 1, -1, -1):
		var hc: Color = _hist[k]["col"]
		hc.a = 0.30 + 0.70 * float(k + 1) / float(maxi(_hist.size(), 1))
		var pts := PackedVector2Array([Vector2(hx, 5.0), Vector2(hx + 4.0, 10.0),
			Vector2(hx, 15.0), Vector2(hx - 4.0, 10.0)])
		draw_colored_polygon(pts, hc)
		hx -= 12.0

	# --- THE WELL: the vessel of water orbs ---
	var r := 15.0
	var step := 36.0
	var cy := 40.0
	var x0 := 10.0 + r
	var dry := charges == 0
	for i in range(charges_max):
		_orb(Vector2(x0 + float(i) * step, cy), r, clampf(_shown - float(i), 0.0, 1.0),
			i, i == charges - 1, dry)
	# the count, cut big beside the vessel
	var cx := x0 + float(charges_max) * step + 6.0
	if dry:
		var dc := Palette.BLOOD.lightened(0.5 + 0.5 * sin(_pulse * 4.0))
		UiKit.text_shadowed(self, UiKit.display(800, 2), Vector2(cx, cy + 8.0), "DRY",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 22, dc)
		UiKit.text_shadowed(self, UiKit.body(500), Vector2(cx + 58.0, cy + 7.0), "0 / %d ◍" % charges_max,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.TEXT_DIM)
	else:
		UiKit.text_shadowed(self, UiKit.display(800), Vector2(cx, cy + 8.0), str(charges),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Palette.WATER.lightened(0.25))
		UiKit.text_shadowed(self, UiKit.display(500), Vector2(cx + (30.0 if charges > 9 else 18.0), cy + 7.0),
			"/ %d ◍" % charges_max, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Palette.TEXT_DIM)

	# --- THE CURRENT (draw): the haste stream ---
	var yy := cy + r + 9.0
	if aspect == "draw":
		UiKit.engraved_plaque(self, Vector2(48, yy + 6.0), "THE CURRENT", current > 0, 9)
		var px0 := 104.0
		for i in range(current_max):
			var c := Vector2(px0 + float(i) * 22.0, yy + 6.0)
			var on := i < current
			if on:
				# the travelling light — the current visibly FLOWS through the lit pips
				var fl := fmod(_pulse * 2.4, float(maxi(current, 1)))
				if fl >= float(i) and fl < float(i) + 1.0:
					var gl := Palette.STEEL.lightened(0.4)
					gl.a = 0.45
					draw_circle(c, 10.0, gl)
			UiKit.gilded_pip(self, c, 6.5, on, Palette.STEEL)
		if current > 0:
			UiKit.text_shadowed(self, UiKit.display(650, 1),
				Vector2(px0 + float(current_max) * 22.0 + 8.0, yy + 10.0),
				"+%d%% CAST SPEED" % int(current * 6), HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
				Palette.STEEL.lightened(0.15))
		yy += 22.0

	# --- THE TARGET BAR: the ally under your hands, writ large ---
	var bar_h := 30.0 if aspect == "draw" else 38.0
	var bx := 8.0
	var bw := w - 16.0
	var name_y := yy + 11.0
	var by := yy + 17.0
	var br := Rect2(bx, by, bw, bar_h)
	if t_show:
		var hpc := _hp_color(_disp_frac)
		# name + the glint mark + live hp%
		UiKit.text_shadowed(self, UiKit.display(650, 1), Vector2(bx + 2.0, name_y), t_name.to_upper(),
			HORIZONTAL_ALIGNMENT_LEFT, bw * 0.5, UiKit.SIZE["LABEL"],
			Palette.GOLD_BRIGHT if t_glint else Palette.TEXT)
		if t_glint:
			var ga := Palette.GOLD_BRIGHT
			ga.a = 0.60 + 0.35 * sin(_pulse * 3.2)
			UiKit.text_shadowed(self, UiKit.display(650, 1), Vector2(bx + 190.0, name_y),
				"✦ GLINTING — their blade cuts deeper", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, ga)
		# the jeweled glass bar (recessed well + fill + gloss + leading edge + gold bevel)
		UiKit.glass_bar_draw(self, br, _disp_frac, hpc)
		# recent-damage trail (pale, slow-falling)
		if _lag_frac > _disp_frac + 0.001:
			draw_rect(Rect2(bx + bw * _disp_frac, by + 2.0, bw * (_lag_frac - _disp_frac), bar_h - 4.0),
				Color(0.95, 0.85, 0.8, 0.28))
		# the in-flight heal's landing (the ghost pour) + the landing hairline
		if t_ghost > _disp_frac:
			var gx := bx + bw * _disp_frac
			var gw2 := bw * (clampf(t_ghost, 0.0, 1.0) - _disp_frac)
			var gc := Palette.GOLD_BRIGHT
			gc.a = 0.42 + 0.16 * sin(_pulse * 5.0)
			draw_rect(Rect2(gx, by + 2.0, gw2, bar_h - 4.0), gc)
			var lx := gx + gw2
			draw_line(Vector2(lx, by - 2.0), Vector2(lx, by + bar_h + 2.0), Color(1, 0.98, 0.85, 0.9), 2.0, true)
			var tri := PackedVector2Array([Vector2(lx, by - 2.0),
				Vector2(lx - 4.0, by - 8.0), Vector2(lx + 4.0, by - 8.0)])
			draw_colored_polygon(tri, Color(1, 0.98, 0.85, 0.9))
		# the POUR window (brim): gold wash → hairline gate → the crowning gem + plaque
		if t_band > 0.0:
			var open := _disp_frac < t_band          # below the line = a pour is open
			var g := Palette.GOLD_BRIGHT
			var bwx := bx + bw * clampf(t_band, 0.0, 1.0)
			draw_rect(Rect2(bwx, by + 2.0, br.end.x - bwx - 1.0, bar_h - 4.0), Color(g.r, g.g, g.b, 0.16))
			var la := 0.85 + (0.15 * sin(_pulse * 2.6) if open else 0.0)
			draw_line(Vector2(bwx, by - 4.0), Vector2(bwx, by + bar_h + 4.0), Color(g.r, g.g, g.b, la), 2.5, true)
			draw_line(Vector2(bwx, by - 4.0), Vector2(bwx + 7.0, by - 4.0), Color(g.r, g.g, g.b, la), 2.0, true)
			draw_line(Vector2(bwx, by + bar_h + 4.0), Vector2(bwx + 7.0, by + bar_h + 4.0),
				Color(g.r, g.g, g.b, la), 2.0, true)
			var gem_c := Vector2(bwx, by - 9.0)
			if open:
				var gh := g
				gh.a = 0.25 + 0.18 * sin(_pulse * 2.2)
				draw_circle(gem_c, 8.0, gh)
			_gold_gem(gem_c, 4.5)
			UiKit.engraved_plaque(self, Vector2(bwx + 40.0, by - 9.0), "POUR ▸", open, 9)
		# HP numerals inside the glass
		UiKit.text_shadowed(self, UiKit.display(700), Vector2(bx + 10.0, by + bar_h * 0.5 + 6.0),
			str(int(round(_disp_hp))), HORIZONTAL_ALIGNMENT_LEFT, bw - 20.0,
			UiKit.SIZE["SUBHEAD"], Palette.GOLD_BRIGHT)
		UiKit.text_shadowed(self, UiKit.display(500), Vector2(bx + 10.0, by + bar_h * 0.5 + 5.0),
			"/ %d   ·   %d%%" % [t_hpmax, int(round(_disp_frac * 100.0))],
			HORIZONTAL_ALIGNMENT_RIGHT, bw - 20.0, UiKit.SIZE["CAPTION"], Palette.TEXT_DIM.lightened(0.15))
		# a glinting ally wears a breathing gold aura
		if t_glint:
			var au := Palette.GOLD_BRIGHT
			au.a = 0.30 + 0.22 * sin(_pulse * 3.2)
			draw_rect(br.grow(2.5), au, false, 2.0)
	else:
		UiKit.glass_bar_draw(self, br, 0.0, Palette.WATER_DEEP)
		UiKit.text_shadowed(self, UiKit.body(500), Vector2(bx, by + bar_h * 0.5 + 5.0),
			"— hover an ally to aim the %s —" % ("pour" if aspect == "brim" else "draw"),
			HORIZONTAL_ALIGNMENT_CENTER, bw, 13, Palette.TEXT_DIM)

	# --- the verdict banner: centre-stage over the vessel, on its own dark chip ---
	if _banner_t > 0.0:
		var a := clampf(_banner_t / 0.4, 0.0, 1.0)
		var f := UiKit.display(800, 2)
		var fs := 19
		var tw := f.get_string_size(_banner, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		var chip := StyleBoxFlat.new()
		chip.bg_color = Color(Palette.BG0.r, Palette.BG0.g, Palette.BG0.b, 0.88 * a)
		chip.border_color = Color(_banner_col.r, _banner_col.g, _banner_col.b, a)
		chip.set_border_width_all(1)
		chip.set_corner_radius_all(7)
		var cr := Rect2(w * 0.5 - tw * 0.5 - 16.0, cy - 14.0, tw + 32.0, 28.0)
		draw_style_box(chip, cr)
		UiKit.text_shadowed(self, f, Vector2(cr.position.x, cy + 7.0), _banner,
			HORIZONTAL_ALIGNMENT_CENTER, cr.size.x, fs, Color(_banner_col, a))

## One water orb of the vessel. fill 0..1 (eased); the newest full orb glows, a refill
## pops it. All motion is client-side cosmetic (self-hashed phases — no RNG).
func _orb(c: Vector2, r: float, fill: float, i: int, newest: bool, dry: bool) -> void:
	var water := Palette.WATER
	var deep := Palette.WATER_DEEP
	# newest-orb glow sits UNDER the glass
	if newest and fill >= 0.999:
		var h := water.lightened(0.3)
		h.a = 0.20 + 0.12 * sin(_pulse * 2.4) + 0.30 * _gain_t
		draw_circle(c, r + 4.0 + 2.0 * _gain_t, h)
	# glass backing + inner shadow
	draw_circle(c, r, Color(0.07, 0.11, 0.15))
	draw_circle(c + Vector2(0, -r * 0.22), r * 0.74, Color(0, 0, 0, 0.28))
	if fill >= 0.999:
		# full orb: breathing liquid, depth shade, top gloss
		var wc := deep.lerp(water, 0.72 + 0.10 * sin(_pulse * 1.8 + float(i) * 0.7))
		draw_circle(c, r - 1.4, wc)
		draw_circle(c + Vector2(0, r * 0.30), r * 0.52, Color(deep.r, deep.g, deep.b, 0.55))
		draw_circle(c + Vector2(-r * 0.28, -r * 0.32), r * 0.28, Color(1, 1, 1, 0.28))
		_bubbles(c, r, 1.0, i)
	elif fill > 0.06:
		# partial orb: the wavy waterline over the arc of liquid below it. The wave's
		# endpoints sit exactly ON the circle, so the closing arc must skip its own
		# endpoints (duplicate vertices break triangulation); slivers draw as a puddle.
		var d := r - 2.0
		var lvl := c.y + d - 2.0 * d * clampf(fill, 0.0, 1.0)
		var dy := clampf((lvl - c.y) / d, -0.98, 0.98)
		var half := d * sqrt(maxf(1.0 - dy * dy, 0.001))
		if half < 3.0:
			draw_circle(Vector2(c.x, c.y + d - 2.0), 2.2, deep.lerp(water, 0.55))
		else:
			var depth := (c.y + d) - lvl
			var pts := PackedVector2Array()
			var n := 8
			for k in range(n + 1):
				var t := float(k) / float(n)
				var amp := minf(1.4, depth * 0.30) * sin(PI * t)
				pts.append(Vector2(c.x - half + 2.0 * half * t,
					lvl + amp * sin(_pulse * 3.0 + float(i) * 1.9 + t * 6.0)))
			var a0 := asin(dy)
			var a1 := PI - a0
			var m := 10
			for k in range(1, m):
				var ang := lerpf(a0, a1, float(k) / float(m))
				pts.append(c + Vector2(cos(ang), sin(ang)) * d)
			draw_colored_polygon(pts, deep.lerp(water, 0.55))
			for k in range(n):
				draw_line(pts[k], pts[k + 1], water.lightened(0.35), 1.2, true)
			_bubbles(c, r, fill, i)
	# rim: gilded while holding water, dim glass when spent (crimson breath when DRY)
	if fill > 0.5:
		UiKit.gilded_ring(self, c, r + 0.5, 1.8, 20)
	else:
		var rim := Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.55)
		if dry:
			rim = rim.lerp(Palette.BLOOD, 0.5 + 0.5 * sin(_pulse * 4.0))
		draw_arc(c, r + 0.5, 0.0, TAU, 24, rim, 1.4, true)

## Little hollow bubbles rising through an orb's water (phase-hashed per orb — cosmetic).
func _bubbles(c: Vector2, r: float, fill: float, i: int) -> void:
	var top := c.y + r - 2.0 * (r - 3.0) * clampf(fill, 0.0, 1.0)
	for j in range(2):
		var ph := fmod(_pulse * (0.30 + 0.07 * float(j)) + float(i) * 0.37 + float(j) * 0.53, 1.0)
		var byy := lerpf(c.y + r * 0.72, top + 3.0, ph)
		var bxx := c.x + sin(float(i) * 2.6 + float(j) * 4.1 + ph * 5.0) * r * 0.34
		var col := Palette.WATER.lightened(0.45)
		col.a = 0.20 + 0.50 * (1.0 - ph)
		draw_arc(Vector2(bxx, byy), 1.1 + 0.8 * float(j), 0.0, TAU, 10, col, 0.9, true)

func _gold_gem(at: Vector2, r: float) -> void:
	var pts := PackedVector2Array([at + Vector2(0, -r), at + Vector2(r * 0.75, 0),
		at + Vector2(0, r), at + Vector2(-r * 0.75, 0)])
	draw_colored_polygon(pts, Palette.GOLD)
	draw_line(pts[0], pts[1], Palette.GOLD_BRIGHT, 1.2, true)
	draw_line(pts[3], pts[0], Palette.GOLD_BRIGHT, 1.2, true)
	draw_line(pts[1], pts[2], Palette.GOLD_DIM, 1.2, true)
	draw_line(pts[2], pts[3], Palette.GOLD_DIM, 1.2, true)
	draw_circle(at + Vector2(-r * 0.2, -r * 0.3), r * 0.25, Color(1, 1, 1, 0.75))

## the same triage ramp the raid frames speak — green above half, ember below, crimson low
func _hp_color(f: float) -> Color:
	f = clampf(f, 0.0, 1.0)
	if f > 0.5:
		return Palette.RAGE.lerp(Palette.WIN, clampf((f - 0.5) * 2.0, 0.0, 1.0))
	return Palette.CRIMSON.lerp(Palette.RAGE, clampf(f * 2.0, 0.0, 1.0))
