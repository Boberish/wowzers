## WellGauge — the reworked healer's instrument (MENDER-PLAN). A plain view Control fed
## observe() fields each frame + verdict events via on_event; never touches combat state.
## Composed as ONE reliquary console — a glass slab with a recessed water POOL:
##   • THE WELL: charges as lit liquid spheres set into metal sockets — layered depth,
##     specular gloss, refraction rim-light, a drifting light-mote; orbs fill/drain as
##     water and the newest one glows. Empty vessel = a crimson-breathing DRY.
##   • THE CURRENT (draw): a stream of chevrons the light visibly flows through.
##   • THE TARGET BAR: the ally under your hands — a hero health bar with gradient
##     fill, leading-edge glow, HP numerals, the ghost landing, and (brim) the gilded
##     POUR gate crowned by a gem.
##   • The verdict banner rises OVER the cast channel (never covers the charges);
##     grade history lives as fading diamonds in the header.
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
		"well_clean": _flash("CLEAN — the current rises", Palette.WATER)
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
	var h := size.y

	# ---- the glass slab: the whole instrument sits on ONE console, not floating rows ----
	var slab := StyleBoxFlat.new()
	slab.bg_color = Color(Palette.FILL_TOP.r, Palette.FILL_TOP.g, Palette.FILL_TOP.b, 0.92)
	slab.set_corner_radius_all(12)
	slab.border_color = Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.8)
	slab.set_border_width_all(1)
	slab.shadow_color = Color(0, 0, 0, 0.55)
	slab.shadow_size = 9
	slab.shadow_offset = Vector2(0, 4)
	draw_style_box(slab, Rect2(0, 0, w, h))
	UiKit.grad_rect(self, Rect2(1, h * 0.55, w - 2, h * 0.45 - 1), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.30))
	# top sheen + the Well's water signature breathing along the crown
	draw_line(Vector2(12, 2.5), Vector2(w - 12, 2.5),
		Color(Palette.GOLD_BRIGHT.r, Palette.GOLD_BRIGHT.g, Palette.GOLD_BRIGHT.b, 0.16), 1.0)
	var crown := Palette.WATER
	crown.a = 0.10 + 0.05 * sin(_pulse * 1.4)
	UiKit.grad_rect(self, Rect2(10, 1, w - 20, 7), crown, Color(crown.r, crown.g, crown.b, 0.0))
	UiKit.filigree_corner(self, Vector2(0, 0), Vector2(1, 1), 10.0)
	UiKit.filigree_corner(self, Vector2(w, 0), Vector2(-1, 1), 10.0)
	UiKit.filigree_corner(self, Vector2(0, h), Vector2(1, -1), 10.0)
	UiKit.filigree_corner(self, Vector2(w, h), Vector2(-1, -1), 10.0)

	# ---- header: title · spec line · the grade-history diamonds ----
	UiKit.text_shadowed(self, UiKit.display(700, 2), Vector2(16, 16), "THE WELL",
		HORIZONTAL_ALIGNMENT_LEFT, -1, UiKit.SIZE["LABEL"], Palette.GOLD)
	var sub := "BRIM · land the pour in the gold" if aspect == "brim" else "DRAW · release in the window"
	UiKit.text_shadowed(self, UiKit.body(500), Vector2(102, 16), sub,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.TEXT_DIM)
	var hx := w - 16.0
	for k in range(_hist.size() - 1, -1, -1):
		var hc: Color = _hist[k]["col"]
		hc.a = 0.25 + 0.75 * float(k + 1) / float(maxi(_hist.size(), 1))
		if k == _hist.size() - 1:
			UiKit.glow(self, Vector2(hx, 11.0), 9.0, Color(hc.r, hc.g, hc.b, 0.5 * hc.a))
		var pts := PackedVector2Array([Vector2(hx, 6.0), Vector2(hx + 4.0, 11.0),
			Vector2(hx, 16.0), Vector2(hx - 4.0, 11.0)])
		draw_colored_polygon(pts, hc)
		hx -= 12.0
	# engraved divider under the header
	draw_line(Vector2(16, 22.0), Vector2(w - 16, 22.0), Palette.BG0, 2.0, true)
	draw_line(Vector2(16, 23.0), Vector2(w - 16, 23.0),
		Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.5), 1.0, true)

	# ---- THE WELL: a recessed pool holding the water orbs ----
	var pool := Rect2(14, 26, 448, 34)
	var dry := charges == 0
	_draw_pool(pool, dry)
	var r := 13.5
	var cy := pool.position.y + pool.size.y * 0.5
	var x0 := pool.position.x + 21.0
	var step := 37.0
	for i in range(charges_max):
		_orb(Vector2(x0 + float(i) * step, cy), r, clampf(_shown - float(i), 0.0, 1.0),
			i, i == charges - 1, dry)
	# the count, cut big beside the pool with a soft water light behind it
	var cx := pool.end.x + 16.0
	if dry:
		var dc := Palette.BLOOD.lightened(0.45 + 0.35 * sin(_pulse * 4.0))
		UiKit.glow(self, Vector2(cx + 26.0, cy), 30.0, Color(Palette.BLOOD.r, Palette.BLOOD.g, Palette.BLOOD.b, 0.30))
		UiKit.text_shadowed(self, UiKit.display(800, 2), Vector2(cx, cy + 8.0), "DRY",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 22, dc)
		UiKit.text_shadowed(self, UiKit.body(500), Vector2(cx + 60.0, cy + 7.0), "0 / %d" % charges_max,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.TEXT_DIM)
	else:
		UiKit.glow(self, Vector2(cx + 20.0, cy), 26.0, Color(Palette.WATER.r, Palette.WATER.g, Palette.WATER.b, 0.16))
		UiKit.text_shadowed(self, UiKit.display(800), Vector2(cx, cy + 9.0), str(charges),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Palette.WATER.lightened(0.30))
		UiKit.text_shadowed(self, UiKit.display(500), Vector2(cx + (34.0 if charges > 9 else 20.0), cy + 8.0),
			"/ %d ◍" % charges_max, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Palette.TEXT_DIM)

	# ---- THE CURRENT (draw): the stream of chevrons ----
	var yy := pool.end.y + 2.0
	if aspect == "draw":
		var ccy := yy + 9.0
		UiKit.engraved_plaque(self, Vector2(56, ccy), "THE CURRENT", current > 0, 9)
		var px0 := 112.0
		var chw := 15.0
		var chh := 13.0
		for i in range(current_max):
			var x := px0 + float(i) * (chw + 7.0)
			var lit := i < current
			var tone := float(i) / float(maxi(current_max - 1, 1))
			var col := Palette.WATER_DEEP.lerp(Palette.WATER.lightened(0.25), 0.35 + 0.65 * tone) if lit \
				else Color(0.13, 0.18, 0.23)
			var pts2 := PackedVector2Array([
				Vector2(x, ccy - chh * 0.5), Vector2(x + chw * 0.55, ccy - chh * 0.5),
				Vector2(x + chw, ccy), Vector2(x + chw * 0.55, ccy + chh * 0.5),
				Vector2(x, ccy + chh * 0.5), Vector2(x + chw * 0.45, ccy)])
			draw_colored_polygon(pts2, col)
			if lit:
				# the current FLOWS — a light travels the lit chevrons
				var fl := fmod(_pulse * 2.2, float(maxi(current, 1)))
				if fl >= float(i) and fl < float(i) + 1.0:
					UiKit.glow(self, Vector2(x + chw * 0.6, ccy), 14.0,
						Color(Palette.WATER.r, Palette.WATER.g, Palette.WATER.b, 0.55))
				draw_line(pts2[1], pts2[2], Palette.WATER.lightened(0.45), 1.2, true)
				draw_line(pts2[2], pts2[3], Color(Palette.WATER_DEEP.r, Palette.WATER_DEEP.g, Palette.WATER_DEEP.b, 0.9), 1.2, true)
			else:
				draw_line(pts2[1], pts2[2], Color(0.24, 0.30, 0.36, 0.7), 1.0, true)
		if current > 0:
			UiKit.text_shadowed(self, UiKit.display(650, 1),
				Vector2(px0 + float(current_max) * (chw + 7.0) + 10.0, ccy + 4.0),
				"+%d%% CAST SPEED" % int(current * 6), HORIZONTAL_ALIGNMENT_LEFT, -1, 12,
				Palette.WATER.lightened(0.35))
		yy += 20.0

	# ---- THE TARGET BAR: the ally under your hands, writ large ----
	var bar_h := 34.0 if aspect == "draw" else 40.0
	var bx := 16.0
	var bw := w - 32.0
	var name_y := yy + 12.0
	var by := yy + 18.0
	var br := Rect2(bx, by, bw, bar_h)
	if t_show:
		var hpc := _hp_color(_disp_frac)
		# name + the glint mark
		UiKit.text_shadowed(self, UiKit.display(650, 1), Vector2(bx + 2.0, name_y), t_name.to_upper(),
			HORIZONTAL_ALIGNMENT_LEFT, bw * 0.45, UiKit.SIZE["LABEL"],
			Palette.GOLD_BRIGHT if t_glint else Palette.TEXT)
		if t_glint:
			var ga := Palette.GOLD_BRIGHT
			ga.a = 0.60 + 0.35 * sin(_pulse * 3.2)
			UiKit.text_shadowed(self, UiKit.display(650, 1), Vector2(bx + 200.0, name_y),
				"✦ GLINTING", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, ga)
		_hero_bar(br, hpc)
		# recent-damage trail (pale, slow-falling)
		if _lag_frac > _disp_frac + 0.001:
			draw_rect(Rect2(bx + bw * _disp_frac, by + 2.0, bw * (_lag_frac - _disp_frac), bar_h - 4.0),
				Color(0.95, 0.85, 0.8, 0.26))
		# the in-flight heal's landing (the ghost pour) + the landing hairline
		if t_ghost > _disp_frac:
			var gx := bx + bw * _disp_frac
			var gw2 := bw * (clampf(t_ghost, 0.0, 1.0) - _disp_frac)
			var gc := Palette.GOLD_BRIGHT
			gc.a = 0.34 + 0.14 * sin(_pulse * 5.0)
			UiKit.grad_rect(self, Rect2(gx, by + 2.0, gw2, bar_h - 4.0),
				gc, Color(gc.r, gc.g, gc.b, gc.a * 0.35))
			var lx := gx + gw2
			UiKit.glow(self, Vector2(lx, by + bar_h * 0.5), bar_h * 0.8,
				Color(Palette.GOLD_BRIGHT.r, Palette.GOLD_BRIGHT.g, Palette.GOLD_BRIGHT.b, 0.35))
			draw_line(Vector2(lx, by), Vector2(lx, by + bar_h), Color(1, 0.98, 0.85, 0.9), 2.0, true)
			var tri := PackedVector2Array([Vector2(lx, by - 1.0),
				Vector2(lx - 4.0, by - 7.0), Vector2(lx + 4.0, by - 7.0)])
			draw_colored_polygon(tri, Color(1, 0.98, 0.85, 0.9))
		# the POUR gate (brim): gold wash densest at the hairline, gate + gem + plaque
		if t_band > 0.0:
			var open := _disp_frac < t_band
			var g := Palette.GOLD_BRIGHT
			var bwx := bx + bw * clampf(t_band, 0.0, 1.0)
			UiKit.grad_rect_h(self, Rect2(bwx, by + 2.0, br.end.x - bwx - 1.0, bar_h - 4.0),
				Color(g.r, g.g, g.b, 0.24), Color(g.r, g.g, g.b, 0.06))
			var la := 0.85 + (0.15 * sin(_pulse * 2.6) if open else 0.0)
			if open:
				UiKit.glow(self, Vector2(bwx, by + bar_h * 0.5), bar_h * 0.9, Color(g.r, g.g, g.b, 0.28))
			draw_line(Vector2(bwx, by - 4.0), Vector2(bwx, by + bar_h + 4.0), Color(g.r, g.g, g.b, la), 2.5, true)
			draw_line(Vector2(bwx, by - 4.0), Vector2(bwx + 7.0, by - 4.0), Color(g.r, g.g, g.b, la), 2.0, true)
			draw_line(Vector2(bwx, by + bar_h + 4.0), Vector2(bwx + 7.0, by + bar_h + 4.0),
				Color(g.r, g.g, g.b, la), 2.0, true)
			var gem_c := Vector2(bwx, by - 9.0)
			if open:
				UiKit.glow(self, gem_c, 11.0, Color(g.r, g.g, g.b, 0.40))
			_gold_gem(gem_c, 4.5)
			UiKit.engraved_plaque(self, Vector2(bwx + 42.0, by - 9.0), "POUR ▸", open, 9)
		# HP numerals inside the glass
		UiKit.text_shadowed(self, UiKit.display(700), Vector2(bx + 12.0, by + bar_h * 0.5 + 6.0),
			str(int(round(_disp_hp))), HORIZONTAL_ALIGNMENT_LEFT, bw - 24.0,
			UiKit.SIZE["SUBHEAD"], Palette.GOLD_BRIGHT)
		UiKit.text_shadowed(self, UiKit.display(500), Vector2(bx + 12.0, by + bar_h * 0.5 + 5.0),
			"/ %d   ·   %d%%" % [t_hpmax, int(round(_disp_frac * 100.0))],
			HORIZONTAL_ALIGNMENT_RIGHT, bw - 24.0, UiKit.SIZE["CAPTION"], Palette.TEXT_DIM.lightened(0.15))
		# a glinting ally wears a breathing gold aura
		if t_glint:
			var au := Palette.GOLD_BRIGHT
			au.a = 0.30 + 0.22 * sin(_pulse * 3.2)
			draw_rect(br.grow(2.5), au, false, 2.0)
	else:
		_hero_bar(br, Palette.WATER_DEEP.darkened(0.2))
		UiKit.text_shadowed(self, UiKit.body(500), Vector2(bx, by + bar_h * 0.5 + 5.0),
			"— hover an ally to aim the %s —" % ("pour" if aspect == "brim" else "draw"),
			HORIZONTAL_ALIGNMENT_CENTER, bw, 13, Palette.TEXT_DIM)

	# ---- the verdict banner: rises ABOVE the cast channel — never covers the charges
	# or the live channel/window ----
	if _banner_t > 0.0:
		var a := clampf(_banner_t / 0.4, 0.0, 1.0)
		var pop := clampf((1.4 - _banner_t) * 9.0, 0.0, 1.0)     # fast grow-in
		var bc := Vector2(w * 0.5, -136.0 + 6.0 * (1.0 - pop))
		var f := UiKit.display(800, 2)
		var fs := 21
		var tw := f.get_string_size(_banner, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		UiKit.glow(self, bc, (60.0 + tw * 0.55) * pop,
			Color(_banner_col.r, _banner_col.g, _banner_col.b, 0.34 * a))
		var chip := StyleBoxFlat.new()
		chip.bg_color = Color(Palette.BG0.r, Palette.BG0.g, Palette.BG0.b, 0.90 * a)
		chip.border_color = Color(_banner_col.r, _banner_col.g, _banner_col.b, a)
		chip.set_border_width_all(1)
		chip.set_corner_radius_all(8)
		chip.shadow_color = Color(0, 0, 0, 0.5 * a)
		chip.shadow_size = 6
		var cr := Rect2(bc.x - tw * 0.5 - 18.0, bc.y - 15.0, tw + 36.0, 30.0)
		draw_style_box(chip, cr)
		UiKit.text_shadowed(self, f, Vector2(cr.position.x, bc.y + 7.0), _banner,
			HORIZONTAL_ALIGNMENT_CENTER, cr.size.x, fs, Color(_banner_col.lerp(Color.WHITE, 0.15), a))

## The recessed water pool the orbs live in — deep gradient, inner shadow, a slow
## light band drifting across the surface. DRY breathes crimson.
func _draw_pool(pool: Rect2, dry: bool) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.BG0
	sb.set_corner_radius_all(9)
	draw_style_box(sb, pool)
	var wd := Palette.WATER_DEEP
	UiKit.grad_rect(self, Rect2(pool.position.x + 2, pool.position.y + 2, pool.size.x - 4, pool.size.y - 4),
		Color(wd.r, wd.g, wd.b, 0.34), Color(wd.r, wd.g, wd.b, 0.10))
	# drifting light on the water
	var lw := 70.0
	var lx := pool.position.x + 4.0 + fmod(_pulse * 26.0, pool.size.x - lw - 8.0)
	UiKit.grad_rect_h(self, Rect2(lx, pool.position.y + 2, lw * 0.5, pool.size.y - 4),
		Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.045))
	UiKit.grad_rect_h(self, Rect2(lx + lw * 0.5, pool.position.y + 2, lw * 0.5, pool.size.y - 4),
		Color(1, 1, 1, 0.045), Color(1, 1, 1, 0.0))
	# inner top shadow + bottom lip
	UiKit.grad_rect(self, Rect2(pool.position.x + 2, pool.position.y + 2, pool.size.x - 4, 6),
		Color(0, 0, 0, 0.45), Color(0, 0, 0, 0.0))
	draw_line(Vector2(pool.position.x + 8, pool.end.y - 1.5), Vector2(pool.end.x - 8, pool.end.y - 1.5),
		Color(1, 1, 1, 0.05), 1.0)
	if dry:
		var dr := Palette.BLOOD
		dr.a = 0.10 + 0.08 * sin(_pulse * 4.0)
		draw_rect(Rect2(pool.position.x + 2, pool.position.y + 2, pool.size.x - 4, pool.size.y - 4), dr)

## One charge — a lit liquid sphere set into a metal socket. fill 0..1 (eased).
## All motion is client-side cosmetic (self-hashed phases — no RNG).
func _orb(c: Vector2, r: float, fill: float, i: int, newest: bool, dry: bool) -> void:
	var water := Palette.WATER
	var deep := Palette.WATER_DEEP
	# the socket: a dark seat with a lit bottom lip (set INTO the pool, not floating on it)
	draw_circle(c, r + 2.5, Color(0.02, 0.03, 0.05, 0.9))
	draw_arc(c, r + 2.0, 0.35, PI - 0.35, 16, Color(1, 1, 1, 0.06), 1.2, true)
	draw_arc(c, r + 2.0, PI + 0.35, TAU - 0.35, 16, Color(0, 0, 0, 0.55), 1.5, true)
	if fill >= 0.999:
		# under-glow — the water is LIT from within
		var glow_a := 0.22 + 0.06 * sin(_pulse * 1.8 + float(i) * 0.7) + 0.30 * (_gain_t if newest else 0.0)
		if newest:
			glow_a += 0.10
		UiKit.glow(self, c, r * 2.5, Color(water.r, water.g, water.b, glow_a))
		# the liquid sphere: layered depth toward the virtual light (top-left)
		draw_circle(c, r - 0.8, deep.darkened(0.25))
		draw_circle(c + Vector2(-r * 0.13, -r * 0.18), r * 0.86, deep.lerp(water, 0.50))
		draw_circle(c + Vector2(-r * 0.24, -r * 0.33), r * 0.56,
			water.lerp(Color(0.72, 0.92, 1.0), 0.12 + 0.06 * sin(_pulse * 1.8 + float(i) * 0.7)))
		# refraction rim-light along the bottom-right of the glass
		draw_arc(c, r - 1.6, 0.25, 1.35, 12, Color(water.lightened(0.4).r, water.lightened(0.4).g,
			water.lightened(0.4).b, 0.50), 1.6, true)
		# specular: a soft bloom + one hard catch-light
		UiKit.glow(self, c + Vector2(-r * 0.32, -r * 0.38), r * 0.85, Color(1, 1, 1, 0.35))
		draw_circle(c + Vector2(-r * 0.34, -r * 0.42), r * 0.13, Color(1, 1, 1, 0.85))
		# one drifting light-mote deep in the water
		var ph := fmod(_pulse * 0.22 + float(i) * 0.43, 1.0)
		UiKit.glow(self, Vector2(c.x + sin(float(i) * 2.6 + ph * 4.4) * r * 0.30,
			c.y + r * 0.55 - ph * r * 0.95), 2.6, Color(0.75, 0.93, 1.0, 0.22 * (1.0 - ph) + 0.05))
	elif fill > 0.06:
		# partial orb: liquid pooled below a bright meniscus (gradient water, no cartoon)
		var d := r - 2.0
		var lvl := c.y + d - 2.0 * d * clampf(fill, 0.0, 1.0)
		var dy := clampf((lvl - c.y) / d, -0.98, 0.98)
		var half := d * sqrt(maxf(1.0 - dy * dy, 0.001))
		if half >= 3.0:
			var depth := (c.y + d) - lvl
			var pts := PackedVector2Array()
			var cols := PackedColorArray()
			var top_c := deep.lerp(water, 0.62)
			var bot_c := deep.darkened(0.30)
			var n := 8
			for k in range(n + 1):
				var t := float(k) / float(n)
				var amp := minf(1.2, depth * 0.25) * sin(PI * t)
				pts.append(Vector2(c.x - half + 2.0 * half * t,
					lvl + amp * sin(_pulse * 2.6 + float(i) * 1.9 + t * 6.0)))
				cols.append(top_c)
			var a0 := asin(dy)
			var a1 := PI - a0
			var m := 10
			for k in range(1, m):
				var ang := lerpf(a0, a1, float(k) / float(m))
				pts.append(c + Vector2(cos(ang), sin(ang)) * d)
				cols.append(bot_c)
			draw_polygon(pts, cols)
			# the meniscus: a bright waterline with a faint light above it
			for k in range(n):
				draw_line(pts[k], pts[k + 1], water.lightened(0.40), 1.3, true)
			UiKit.glow(self, Vector2(c.x, lvl - 1.0), half * 0.8,
				Color(water.r, water.g, water.b, 0.16))
		else:
			draw_circle(Vector2(c.x, c.y + d - 2.0), 2.0, deep.lerp(water, 0.5))
	else:
		# spent orb: dark glass with the faintest residue shimmer at the bottom
		draw_circle(c, r - 0.8, Color(deep.r, deep.g, deep.b, 0.16))
		draw_arc(c, r * 0.55, 0.8, PI - 0.8, 10, Color(water.r, water.g, water.b, 0.12), 1.0, true)
	# the metal ring: cool steel with a gold glint where the light catches (top-left)
	var lit := fill > 0.5
	var ring_base := Color(0.30, 0.38, 0.46, 0.9) if lit else Color(0.20, 0.25, 0.31, 0.7)
	if dry:
		ring_base = ring_base.lerp(Palette.BLOOD, 0.35 + 0.30 * sin(_pulse * 4.0))
	draw_arc(c, r + 0.8, 0.0, TAU, 26, ring_base, 1.3, true)
	if lit:
		draw_arc(c, r + 0.8, PI * 1.05, PI * 1.75, 10, Palette.GOLD.lightened(0.1), 1.4, true)
		draw_arc(c, r + 0.8, PI * 1.30, PI * 1.52, 6, Palette.GOLD_BRIGHT, 1.6, true)

## The hero health bar: dark socket, vertical-gradient fill, gloss, glowing leading
## edge, two-tone bevel frame, diamond finials at both mouths.
func _hero_bar(br: Rect2, hpc: Color) -> void:
	# outer contour + socket
	draw_rect(br.grow(1.0), Color(0, 0, 0, 0.55), false, 1.0)
	draw_rect(br, Color(0.035, 0.03, 0.055))
	UiKit.grad_rect(self, Rect2(br.position, Vector2(br.size.x, br.size.y * 0.45)),
		Color(0, 0, 0, 0.40), Color(0, 0, 0, 0.0))
	# fill
	var f := clampf(_disp_frac if t_show else 0.0, 0.0, 1.0)
	if f > 0.004:
		var fw := br.size.x * f
		UiKit.grad_rect(self, Rect2(br.position, Vector2(fw, br.size.y)),
			hpc.lightened(0.20), hpc.darkened(0.40))
		draw_rect(Rect2(br.position + Vector2(1, 1), Vector2(maxf(fw - 2.0, 0.0), br.size.y * 0.30)),
			Color(1, 1, 1, 0.13))
		if f < 0.995:
			UiKit.glow(self, Vector2(br.position.x + fw, br.position.y + br.size.y * 0.5),
				br.size.y * 0.9, Color(hpc.lightened(0.4).r, hpc.lightened(0.4).g, hpc.lightened(0.4).b, 0.40))
			draw_rect(Rect2(br.position.x + fw - 2.0, br.position.y + 1.0, 2.0, br.size.y - 2.0),
				hpc.lightened(0.5))
	# bevel frame (lit top-left) + finials
	draw_line(br.position, Vector2(br.end.x, br.position.y), Color(Palette.GOLD.r, Palette.GOLD.g, Palette.GOLD.b, 0.85), 1.5, true)
	draw_line(br.position, Vector2(br.position.x, br.end.y), Color(Palette.GOLD.r, Palette.GOLD.g, Palette.GOLD.b, 0.5), 1.5, true)
	draw_line(Vector2(br.position.x, br.end.y), br.end, Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.6), 1.5, true)
	draw_line(Vector2(br.end.x, br.position.y), br.end, Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.6), 1.5, true)
	_gold_gem(Vector2(br.position.x - 6.0, br.position.y + br.size.y * 0.5), 5.0)
	_gold_gem(Vector2(br.end.x + 6.0, br.position.y + br.size.y * 0.5), 5.0)

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
