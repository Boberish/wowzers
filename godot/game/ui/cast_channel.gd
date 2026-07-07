## CastChannel — the healer's benediction bar. While a heal is channelling: the spell's
## rune sits in a small gilded medallion, the spell name burns on an engraved plaque
## with the target beside it, and a jeweled glass channel fills gold with a travelling
## shimmer and lit diamond end-gems. When the cast RESOLVES, the channel releases a
## golden bloom (expanding frame + glow at the mouth); a cancelled cast just fades.
## Invisible while idle — it never clutters. Pure view; the HUD feeds the fields.
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
	var bar := Rect2(54.0, 26.0, w - 70.0, 22.0)

	# idle track (the Well/DRAW): the empty channel + the release window, faint —
	# the window stays readable between casts.
	if not active and _bloom <= 0.0:
		draw_rect(bar, Color(0.07, 0.09, 0.11, 0.75))
		_draw_window(bar, 0.45)
		draw_rect(bar, Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.35), false, 1.0)
		return

	if active:
		# spell medallion
		var mc := Vector2(26.0, 37.0)
		var mr := 17.0
		var halo := accent
		halo.a = 0.16 + 0.10 * sin(_pulse * 2.0)
		draw_circle(mc, mr * 1.35, halo)
		draw_circle(mc, mr, Palette.FILL_BOT)
		UiKit.gilded_ring(self, mc, mr, 2.0, 32)
		if _tex != null:
			var isz := mr * 1.2
			var irect := Rect2(mc - Vector2(isz, isz) * 0.5, Vector2(isz, isz))
			draw_texture_rect(_tex, Rect2(irect.position + Vector2(0, 1), irect.size), false, UiKit.TEXT_SHADOW)
			draw_texture_rect(_tex, irect, false, accent.lightened(0.2))

		# header: the spell on a lit plaque, the target beside it
		var pr := UiKit.engraved_plaque(self, Vector2(bar.position.x + 48.0, 9.0), label, true, 10)
		if target != "":
			UiKit.text_shadowed(self, ThemeDB.fallback_font, Vector2(pr.end.x + 8.0, 13.0),
				"→  " + target, HORIZONTAL_ALIGNMENT_LEFT, w - pr.end.x - 12.0,
				UiKit.SIZE["CAPTION"], Palette.TEXT)

		# the jeweled channel
		UiKit.glass_bar_draw(self, bar, clampf(frac, 0.0, 1.0), accent)
		# quarter ticks engraved into the floor
		for i in range(1, 4):
			var tx := bar.position.x + bar.size.x * float(i) / 4.0
			draw_line(Vector2(tx, bar.end.y - 6.0), Vector2(tx, bar.end.y - 2.0), Palette.BG0, 2.0, true)
		# the graded release window over the live channel
		_draw_window(bar, 1.0)
		# travelling shimmer over the filled portion
		var fw := bar.size.x * clampf(frac, 0.0, 1.0)
		if fw > 12.0:
			var sx := bar.position.x + fmod(_pulse * 42.0, fw - 8.0)
			var sh := accent.lightened(0.5)
			sh.a = 0.30
			draw_rect(Rect2(sx, bar.position.y + 2.0, 6.0, bar.size.y - 4.0), sh)
		# diamond end-gems, lit while channelling
		_gem(Vector2(bar.position.x - 8.0, bar.position.y + bar.size.y * 0.5), 6.5, true)
		_gem(Vector2(bar.end.x + 8.0, bar.position.y + bar.size.y * 0.5), 6.5, frac > 0.95)

	# the release bloom — the heal lands
	if _bloom > 0.0:
		var b := 1.0 - _bloom
		var fl := Palette.GOLD_BRIGHT
		fl.a = 0.30 * _bloom
		draw_rect(bar, fl)
		var ring := accent.lightened(0.3)
		ring.a = 0.6 * _bloom
		draw_rect(Rect2(bar.position - Vector2(3.0 + 14.0 * b, 3.0 + 10.0 * b),
			bar.size + Vector2(6.0 + 28.0 * b, 6.0 + 20.0 * b)), ring, false, 1.6)
		var mouth := Vector2(bar.end.x + 8.0, bar.position.y + bar.size.y * 0.5)
		var mg := Palette.WIN
		mg.a = 0.5 * _bloom
		draw_circle(mouth, 7.0 + 20.0 * b, mg)

## The graded release window: a steel zone at the channel's end (CLEAN) + a bright gold
## centre sliver (the STILL POINT). `a` scales the alpha (faint on the idle track).
func _draw_window(bar: Rect2, a: float) -> void:
	if zone_lo < 0.0:
		return
	var zx := bar.position.x + bar.size.x * clampf(zone_lo, 0.0, 1.0)
	draw_rect(Rect2(zx, bar.position.y + 1.0, bar.end.x - zx, bar.size.y - 2.0),
		Color(Palette.STEEL.r, Palette.STEEL.g, Palette.STEEL.b, 0.30 * a))
	draw_line(Vector2(zx, bar.position.y - 2.0), Vector2(zx, bar.end.y + 2.0),
		Color(Palette.STEEL.r, Palette.STEEL.g, Palette.STEEL.b, 0.85 * a), 2.0, true)
	if mark_lo >= 0.0 and mark_hi > mark_lo:
		var mx := bar.position.x + bar.size.x * clampf(mark_lo, 0.0, 1.0)
		var mw := maxf(2.0, bar.size.x * (mark_hi - mark_lo))
		draw_rect(Rect2(mx, bar.position.y, mw, bar.size.y),
			Color(Palette.GOLD_BRIGHT.r, Palette.GOLD_BRIGHT.g, Palette.GOLD_BRIGHT.b, 0.85 * a))

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
