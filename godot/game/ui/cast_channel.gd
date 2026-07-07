## CastChannel — the healer's benediction bar. While a heal is channelling: the spell's
## rune sits in a small gilded medallion, the spell name burns on an engraved plaque
## with the target beside it, and a jeweled glass channel fills gold with a travelling
## shimmer and lit diamond end-gems. When the cast RESOLVES, the channel releases a
## golden bloom (expanding frame + glow at the mouth); a cancelled cast just fades.
## Invisible while idle — it never clutters. Pure view; the HUD feeds the fields.
##
## The whole instrument SCALES with the control's height (s = size.y / 60): the classic
## healers keep their 60-tall bar pixel-for-pixel; the Well places it far taller and
## every element — medallion, channel, window, type — grows with it.
class_name CastChannel
extends Control

## Emitted when the channel is clicked — the Well/DRAW release press rides this.
signal tapped

var active: bool = false
var frac: float = 0.0
var label: String = ""
var target: String = ""
var accent: Color = Palette.GOLD
var spell_id: String = "":
	set(v):
		if v != spell_id:
			spell_id = v
			_tex = RuneIcons.tex(v)

## Optional graded RELEASE window (the Well/DRAW; -1 = none, other healers unchanged):
## a marked zone at the channel's end + a bright centre sliver (the Still Point).
## `show_idle_track` keeps the empty channel + window faintly visible between casts,
## so the window can be learned before the cast is live.
var zone_lo: float = -1.0
var mark_lo: float = -1.0
var mark_hi: float = -1.0
var show_idle_track: bool = false

func _gui_input(event: InputEvent) -> void:
	if zone_lo >= 0.0 and event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		tapped.emit()

var _tex: Texture2D
var _pulse: float = 0.0
var _bloom: float = 0.0
var _was_active: bool = false
var _last_frac: float = 0.0

func _process(delta: float) -> void:
	_pulse += delta * 3.6
	if _was_active and not active and _last_frac >= 0.85:
		_bloom = 1.0                       # the blessing lands
	_was_active = active
	if active:
		_last_frac = frac
	_bloom = maxf(0.0, _bloom - delta * 2.6)
	queue_redraw()

func _draw() -> void:
	if not active and _bloom <= 0.0 and not (show_idle_track and zone_lo >= 0.0):
		return
	var w := size.x
	var s := clampf(size.y / 60.0, 1.0, 2.4)
	var bar := Rect2(54.0 * s, 26.0 * s, w - 70.0 * s, 22.0 * s)

	# the seat: a glass pill under the whole instrument (medallion + plaque + channel),
	# so the bar never floats bare over the scene. Quieter while idle.
	var pill := StyleBoxFlat.new()
	pill.bg_color = Color(Palette.FILL_TOP.r, Palette.FILL_TOP.g, Palette.FILL_TOP.b, 0.80 if active else 0.55)
	pill.set_corner_radius_all(12)
	pill.border_color = Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.55)
	pill.set_border_width_all(1)
	pill.shadow_color = Color(0, 0, 0, 0.45)
	pill.shadow_size = 7
	pill.shadow_offset = Vector2(0, 3)
	draw_style_box(pill, Rect2(2, 2, w - 4, size.y - 4))
	draw_line(Vector2(12, 4.5), Vector2(w - 12, 4.5),
		Color(Palette.GOLD_BRIGHT.r, Palette.GOLD_BRIGHT.g, Palette.GOLD_BRIGHT.b, 0.12), 1.0)

	# idle track (the Well/DRAW): the empty channel + the release window, readable
	# between casts — the window is learned before the cast is ever live.
	if not active and _bloom <= 0.0:
		draw_rect(bar.grow(1.0), Color(0, 0, 0, 0.45), false, 1.0)
		draw_rect(bar, Color(0.05, 0.06, 0.09, 0.85))
		UiKit.grad_rect(self, Rect2(bar.position, Vector2(bar.size.x, bar.size.y * 0.45)),
			Color(0, 0, 0, 0.35), Color(0, 0, 0, 0.0))
		_draw_window(bar, s, 0.55, false)
		draw_rect(bar, Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.40), false, 1.0)
		return

	if active:
		# spell medallion — a soft accent light behind the gilded ring
		var mc := Vector2(26.0 * s, 37.0 * s)
		var mr := 17.0 * s
		UiKit.glow(self, mc, mr * 2.2, Color(accent.r, accent.g, accent.b, 0.24 + 0.10 * sin(_pulse * 2.0)))
		draw_circle(mc, mr, Palette.FILL_BOT)
		UiKit.gilded_ring(self, mc, mr, 2.0 * s, 32)
		if _tex != null:
			var isz := mr * 1.2
			var irect := Rect2(mc - Vector2(isz, isz) * 0.5, Vector2(isz, isz))
			draw_texture_rect(_tex, Rect2(irect.position + Vector2(0, 1), irect.size), false, UiKit.TEXT_SHADOW)
			draw_texture_rect(_tex, irect, false, accent.lightened(0.2))

		# header: the spell on a lit plaque, the target beside it
		var pr := UiKit.engraved_plaque(self, Vector2(bar.position.x + 48.0 * s, 9.0 * s), label, true,
			int(round(10.0 * s)))
		if target != "":
			UiKit.text_shadowed(self, ThemeDB.fallback_font, Vector2(pr.end.x + 8.0 * s, 13.0 * s),
				"→  " + target, HORIZONTAL_ALIGNMENT_LEFT, w - pr.end.x - 12.0 * s,
				int(round(float(UiKit.SIZE["CAPTION"]) * s)), Palette.TEXT)

		# the jeweled channel: dark socket, gradient fill, gloss, a GLOWING leading edge
		var fw := bar.size.x * clampf(frac, 0.0, 1.0)
		draw_rect(bar.grow(1.0), Color(0, 0, 0, 0.5), false, 1.0)
		draw_rect(bar, Color(0.035, 0.03, 0.055))
		UiKit.grad_rect(self, Rect2(bar.position, Vector2(bar.size.x, bar.size.y * 0.45)),
			Color(0, 0, 0, 0.40), Color(0, 0, 0, 0.0))
		if fw > 1.0:
			UiKit.grad_rect(self, Rect2(bar.position, Vector2(fw, bar.size.y)),
				accent.lightened(0.14), accent.darkened(0.45))
			draw_rect(Rect2(bar.position + Vector2(1, 1), Vector2(maxf(fw - 2.0, 0.0), bar.size.y * 0.30)),
				Color(1, 1, 1, 0.13))
			UiKit.glow(self, Vector2(bar.position.x + fw, bar.position.y + bar.size.y * 0.5),
				bar.size.y * 1.0, Color(accent.lightened(0.4).r, accent.lightened(0.4).g,
				accent.lightened(0.4).b, 0.45))
			draw_rect(Rect2(bar.position.x + fw - 2.0, bar.position.y + 1.0, 2.0, bar.size.y - 2.0),
				accent.lightened(0.55))
		# bevel frame (lit top-left)
		draw_line(bar.position, Vector2(bar.end.x, bar.position.y),
			Color(Palette.GOLD.r, Palette.GOLD.g, Palette.GOLD.b, 0.85), 1.5, true)
		draw_line(bar.position, Vector2(bar.position.x, bar.end.y),
			Color(Palette.GOLD.r, Palette.GOLD.g, Palette.GOLD.b, 0.5), 1.5, true)
		draw_line(Vector2(bar.position.x, bar.end.y), bar.end,
			Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.6), 1.5, true)
		draw_line(Vector2(bar.end.x, bar.position.y), bar.end,
			Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.6), 1.5, true)
		# quarter ticks engraved into the floor
		for i in range(1, 4):
			var tx := bar.position.x + bar.size.x * float(i) / 4.0
			draw_line(Vector2(tx, bar.end.y - 6.0 * s), Vector2(tx, bar.end.y - 2.0 * s), Palette.BG0, 2.0 * s, true)
		# the graded release window over the live channel
		_draw_window(bar, s, 1.0, true)
		# travelling shimmer over the filled portion
		if fw > 12.0:
			var sx := bar.position.x + fmod(_pulse * 42.0, fw - 8.0)
			var sh := accent.lightened(0.5)
			sh.a = 0.30
			draw_rect(Rect2(sx, bar.position.y + 2.0, 6.0 * s, bar.size.y - 4.0), sh)
		# the PLAYHEAD needle (graded bar only): where you are, right now — white on the
		# approach, gold the instant it crosses into the release window.
		if zone_lo >= 0.0:
			var px := bar.position.x + fw
			var in_zone := frac >= zone_lo
			var nc := Palette.GOLD_BRIGHT if in_zone else Color(0.93, 0.96, 1.0)
			var ng := nc
			ng.a = 0.30
			draw_line(Vector2(px, bar.position.y - 6.0 * s), Vector2(px, bar.end.y + 4.0 * s), ng, 6.0 * s * 0.6, true)
			draw_line(Vector2(px, bar.position.y - 6.0 * s), Vector2(px, bar.end.y + 4.0 * s), nc, 2.2, true)
			var tri := PackedVector2Array([Vector2(px, bar.position.y - 2.0),
				Vector2(px - 4.5 * s, bar.position.y - 9.0 * s), Vector2(px + 4.5 * s, bar.position.y - 9.0 * s)])
			draw_colored_polygon(tri, nc)
		# diamond end-gems, lit while channelling
		_gem(Vector2(bar.position.x - 8.0 * s, bar.position.y + bar.size.y * 0.5), 6.5 * s, true)
		_gem(Vector2(bar.end.x + 8.0 * s, bar.position.y + bar.size.y * 0.5), 6.5 * s, frac > 0.95)

	# the release bloom — the heal lands
	if _bloom > 0.0:
		var b := 1.0 - _bloom
		var fl := Palette.GOLD_BRIGHT
		fl.a = 0.30 * _bloom
		draw_rect(bar, fl)
		var ring := accent.lightened(0.3)
		ring.a = 0.6 * _bloom
		draw_rect(Rect2(bar.position - Vector2((3.0 + 14.0 * b) * s, (3.0 + 10.0 * b) * s),
			bar.size + Vector2((6.0 + 28.0 * b) * s, (6.0 + 20.0 * b) * s)), ring, false, 1.6)
		var mouth := Vector2(bar.end.x + 8.0 * s, bar.position.y + bar.size.y * 0.5)
		UiKit.glow(self, mouth, (14.0 + 34.0 * b) * s, Color(Palette.WIN.r, Palette.WIN.g, Palette.WIN.b, 0.55 * _bloom))
		UiKit.glow(self, mouth, (7.0 + 14.0 * b) * s,
			Color(Palette.GOLD_BRIGHT.r, Palette.GOLD_BRIGHT.g, Palette.GOLD_BRIGHT.b, 0.5 * _bloom))

## The graded release window: a steel glass zone at the channel's end (CLEAN) with an
## entry gate + brackets, and THE STILL POINT — a bright gold sliver crowned by a diamond
## gem. `a` scales the alpha (faint on the idle track); when the live needle is INSIDE
## the zone the whole window flares — release NOW. Big bars earn engraved captions.
func _draw_window(bar: Rect2, s: float, a: float, live: bool) -> void:
	if zone_lo < 0.0:
		return
	var zx := bar.position.x + bar.size.x * clampf(zone_lo, 0.0, 1.0)
	var zone := Rect2(zx, bar.position.y + 1.0, bar.end.x - zx, bar.size.y - 2.0)
	var hot := live and frac >= zone_lo
	var st := Palette.STEEL
	# the zone glass — a cool vertical gradient that flares while the needle is inside
	var za := (0.46 + 0.10 * sin(_pulse * 5.0) if hot else 0.28) * a
	UiKit.grad_rect(self, zone, Color(st.r, st.g, st.b, za), Color(st.r, st.g, st.b, za * 0.35))
	if hot:
		UiKit.glow(self, zone.get_center(), zone.size.x * 0.75,
			Color(st.r, st.g, st.b, 0.30 * a))
	if live:
		# a slow shimmer breathing through the zone glass
		var sx := zone.position.x + fmod(_pulse * 22.0, maxf(zone.size.x - 5.0, 1.0))
		var sc := st.lightened(0.4)
		sc.a = 0.22 * a
		draw_rect(Rect2(sx, zone.position.y, 4.0, zone.size.y), sc)
	# the entry gate: hairline + top/bottom brackets opening into the window
	var gc := Color(st.r, st.g, st.b, (1.0 if hot else 0.85) * a)
	draw_line(Vector2(zx, bar.position.y - 3.0 * s), Vector2(zx, bar.end.y + 3.0 * s), gc, 2.0, true)
	draw_line(Vector2(zx, bar.position.y - 3.0 * s), Vector2(zx + 7.0 * s, bar.position.y - 3.0 * s), gc, 2.0, true)
	draw_line(Vector2(zx, bar.end.y + 3.0 * s), Vector2(zx + 7.0 * s, bar.end.y + 3.0 * s), gc, 2.0, true)
	# THE STILL POINT: halo → gold sliver → the crowning gem
	if mark_lo >= 0.0 and mark_hi > mark_lo:
		var g := Palette.GOLD_BRIGHT
		var mx := bar.position.x + bar.size.x * clampf(mark_lo, 0.0, 1.0)
		var mw := maxf(2.0 * s, bar.size.x * (mark_hi - mark_lo))
		draw_rect(Rect2(mx - 3.0 * s, bar.position.y, mw + 6.0 * s, bar.size.y),
			Color(g.r, g.g, g.b, 0.16 * a))
		draw_rect(Rect2(mx, bar.position.y, mw, bar.size.y), Color(g.r, g.g, g.b, (0.95 if hot else 0.80) * a))
		var gem_c := Vector2(mx + mw * 0.5, bar.position.y - 8.0 * s)
		UiKit.glow(self, gem_c, 9.0 * s, Color(g.r, g.g, g.b, (0.36 + 0.16 * sin(_pulse * 2.2)) * a))
		_gold_gem(gem_c, 4.5 * s, a)
	# captions — the big graded bar only (the Well); classic healers never see these
	if s > 1.4:
		UiKit.engraved_plaque(self, Vector2(zx + zone.size.x * 0.5, bar.end.y + 13.0), "RELEASE WINDOW", hot, 9)
		if hot:
			var rc := Palette.GOLD_BRIGHT
			rc.a = (0.75 + 0.25 * sin(_pulse * 6.0)) * a
			UiKit.text_shadowed(self, UiKit.display(700, 2), Vector2(zx - 96.0, bar.position.y - 10.0),
				"RELEASE ▸", HORIZONTAL_ALIGNMENT_RIGHT, 90.0, UiKit.SIZE["LABEL"], rc)

func _gold_gem(at: Vector2, r: float, a: float) -> void:
	var pts := PackedVector2Array([at + Vector2(0, -r), at + Vector2(r * 0.75, 0),
		at + Vector2(0, r), at + Vector2(-r * 0.75, 0)])
	var body := Palette.GOLD
	body.a = a
	draw_colored_polygon(pts, body)
	var rim := Palette.GOLD_BRIGHT
	rim.a = a
	draw_line(pts[0], pts[1], rim, 1.2, true)
	draw_line(pts[3], pts[0], rim, 1.2, true)
	var dim := Palette.GOLD_DIM
	dim.a = a
	draw_line(pts[1], pts[2], dim, 1.2, true)
	draw_line(pts[2], pts[3], dim, 1.2, true)
	draw_circle(at + Vector2(-r * 0.2, -r * 0.3), r * 0.25, Color(1, 1, 1, 0.75 * a))

func _gem(at: Vector2, r: float, lit: bool) -> void:
	var pts := PackedVector2Array([at + Vector2(0, -r), at + Vector2(r * 0.75, 0),
		at + Vector2(0, r), at + Vector2(-r * 0.75, 0)])
	draw_colored_polygon(pts, accent.darkened(0.15) if lit else Color(0.08, 0.09, 0.12))
	draw_line(pts[0], pts[1], Palette.GOLD if lit else Palette.GOLD_DIM, 1.2, true)
	draw_line(pts[1], pts[2], Palette.GOLD_DIM, 1.2, true)
	draw_line(pts[2], pts[3], Palette.GOLD_DIM, 1.2, true)
	draw_line(pts[3], pts[0], Palette.GOLD if lit else Palette.GOLD_DIM, 1.2, true)
	if lit:
		draw_circle(at + Vector2(-r * 0.2, -r * 0.28), r * 0.22, Color(1, 1, 1, 0.75))
