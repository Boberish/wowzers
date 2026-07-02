## A gilded RUNE-SOCKET ability button — a chamfered obsidian slot cut into the
## rail, in the reliquary language: two-tone gilded bevel (lit top-left, shadowed
## bottom-right), a deep glass face with a big accent-lit glyph, a square radial
## cooldown veil with a burn-down edge, a charged under-glow + a GLEAM SWEEP the
## instant the ability comes back (the "it's ready" glint), hover ignite, press
## dip, a keybind tab notched into the top-right chamfer, and the spell's name
## engraved UNDER the socket (the face stays clean, like a real slot).
##
## Public surface is unchanged from the coin era (label / key_num / key_label /
## icon_id / accent / affordable / usable / cd_frac / `pressed`), so every HUD
## rail upgrades without an edit. States: ready = lit + glowing; on GCD/cd =
## dark + veil; out of resource = desaturated + a pulsing crimson want-line.
class_name AbilityRune
extends Control

signal pressed

var label: String = ""
var key_num: int = 1
var key_label: String = ""         # overrides the number (e.g. "SPC" for guard)
var icon_id: String = ""           # RuneIcons id for the glyph (e.g. "cleave"); "" = text-only
var accent: Color = Palette.GOLD   # glyph/glow tint when usable
var affordable: bool = true
var usable: bool = true            # off GCD / not on cooldown
var cd_frac: float = 0.0          # 0 = ready, 1 = full cooldown

var _pulse: float = 0.0
var _hover: float = 0.0           # eased 0..1 hover emphasis
var _hovered: bool = false
var _press_k: float = 0.0         # press-down kick, decays
var _gleam: float = 0.0           # become-ready glint sweep, decays
var _was_on: bool = true
var _glow: GlowCore
var _tex: Texture2D

const CHAMFER := 9.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(76, 76)
	# charged-socket under-glow: additive, on only when castable
	_glow = GlowCore.new()
	_glow.setup(16.0, accent, 0.42, 0.30, 1.0)
	add_child(_glow)
	if icon_id != "":
		_tex = RuneIcons.tex(icon_id)

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		_hovered = true
	elif what == NOTIFICATION_MOUSE_EXIT:
		_hovered = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_press_k = 1.0
		pressed.emit()

func _process(delta: float) -> void:
	_pulse += delta * 4.5
	_hover += ((1.0 if _hovered else 0.0) - _hover) * clampf(delta * 12.0, 0.0, 1.0)
	_press_k = maxf(0.0, _press_k - delta * 6.0)
	_gleam = maxf(0.0, _gleam - delta * 2.4)
	var on := affordable and usable
	if on and not _was_on:
		_gleam = 1.0                       # the slot RELIGHTS — sell the moment
	_was_on = on
	if _glow != null:
		_glow.set_glow_color(accent)       # HUDs retint accents live (Twinfang strike)
		_glow.set_base((0.9 if on else 0.0) + 0.4 * _hover)
	queue_redraw()

## The socket face: a chamfered square (octagon), centred, 62px.
func _face() -> Rect2:
	return Rect2(size.x * 0.5 - 31.0, 1.0, 62.0, 62.0)

func _oct(fr: Rect2, inset: float = 0.0) -> PackedVector2Array:
	var k := CHAMFER - inset * 0.4
	var x0 := fr.position.x + inset
	var y0 := fr.position.y + inset
	var x1 := fr.end.x - inset
	var y1 := fr.end.y - inset
	return PackedVector2Array([
		Vector2(x0 + k, y0), Vector2(x1 - k, y0), Vector2(x1, y0 + k),
		Vector2(x1, y1 - k), Vector2(x1 - k, y1), Vector2(x0 + k, y1),
		Vector2(x0, y1 - k), Vector2(x0, y0 + k)])

func _draw() -> void:
	var on := affordable and usable
	var fr := _face()
	var c := fr.get_center()
	# the whole socket lifts a breath on hover and dips on press
	draw_set_transform(Vector2(0.0, 1.6 * _press_k - 1.0 * _hover), 0.0, Vector2.ONE)

	# ---- seat shadow + glass face ----
	var seat := _oct(fr.grow(2.0))
	draw_colored_polygon(seat, Color(0, 0, 0, 0.55))
	var face := _oct(fr)
	draw_colored_polygon(face, Palette.FILL_BOT if on else Palette.BG1.darkened(0.18))
	# top gloss (light falls from UiKit.LIGHT_DIR — upper half catches it)
	var gx0 := fr.position.x + 2.0
	var gx1 := fr.end.x - 2.0
	var gy0 := fr.position.y + 2.0
	var gmid := fr.position.y + fr.size.y * 0.42
	var gloss := PackedVector2Array([
		Vector2(gx0 + CHAMFER, gy0), Vector2(gx1 - CHAMFER, gy0),
		Vector2(gx1, gy0 + CHAMFER), Vector2(gx1, gmid), Vector2(gx0, gmid),
		Vector2(gx0, gy0 + CHAMFER)])
	var gc := Palette.FILL_TOP.lightened(0.06)
	gc.a = 0.55 if on else 0.30
	draw_colored_polygon(gloss, gc)

	# ---- the glyph (big — the face belongs to it) ----
	if _tex != null:
		var isz := 40.0 + 2.0 * _hover
		var irect := Rect2(c.x - isz * 0.5, c.y - isz * 0.5, isz, isz)
		# on cooldown/GCD the glyph stays clearly readable — just unlit
		var itint := accent if on else Palette.TEXT_DIM
		if on:
			itint = itint.lerp(Color.WHITE, 0.12 + 0.10 * _hover)
		draw_texture_rect(_tex, Rect2(irect.position + Vector2(0, 2), irect.size), false, Color(0, 0, 0, 0.6))
		draw_texture_rect(_tex, irect, false, itint)
	else:
		UiKit.text_shadowed(self, UiKit.display(650), Vector2(fr.position.x, c.y + 5.0),
			label.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, fr.size.x, UiKit.SIZE["LABEL"],
			Palette.TEXT if on else Palette.TEXT_DIM)

	# ---- cooldown veil: dark radial sector over the SQUARE face + burn-down edge ----
	if cd_frac > 0.002:
		var top := -PI / 2.0
		var end := top + TAU * clampf(cd_frac, 0.0, 1.0)
		var hx := fr.size.x * 0.5 - 1.5
		var hy := fr.size.y * 0.5 - 1.5
		var poly := PackedVector2Array()
		poly.append(c)
		var steps := 26
		for i in range(steps + 1):
			var a := top + (end - top) * float(i) / float(steps)
			var da := Vector2(cos(a), sin(a))
			var reach := minf(hx / maxf(absf(da.x), 0.001), hy / maxf(absf(da.y), 0.001))
			poly.append(c + da * reach)
		draw_colored_polygon(poly, Color(0, 0, 0, 0.48))
		var de := Vector2(cos(end), sin(end))
		var dreach := minf(hx / maxf(absf(de.x), 0.001), hy / maxf(absf(de.y), 0.001))
		draw_line(c, c + de * dreach, Palette.GOLD_BRIGHT, 1.6, true)

	# ---- become-ready gleam: a slanted glint wipes across the relit face ----
	if _gleam > 0.01:
		var sw := 1.0 - _gleam
		var bx := lerpf(fr.position.x - 8.0, fr.end.x + 8.0, sw)
		var ga := 4.0 * _gleam * (1.0 - _gleam)          # peaks mid-sweep
		var band := PackedVector2Array([
			Vector2(bx - 12.0, fr.end.y), Vector2(bx - 2.0, fr.position.y),
			Vector2(bx + 8.0, fr.position.y), Vector2(bx - 2.0, fr.end.y)])
		var bcol := Palette.GOLD_BRIGHT.lerp(Color.WHITE, 0.4)
		bcol.a = 0.34 * ga
		draw_colored_polygon(band, bcol)

	# ---- two-tone gilded bevel (light top-left / shadow bottom-right) ----
	var bright := accent.lerp(Palette.GOLD_BRIGHT, 0.5) if _hover > 0.3 else Palette.GOLD_BRIGHT
	var lit_a := (0.9 if on else 0.45) + 0.1 * _hover
	for i in 8:
		var p1 := face[i]
		var p2 := face[(i + 1) % 8]
		var n := (p1 + p2) * 0.5 - c
		var lit := n.x + n.y < 0.0                       # faces the top-left light
		var ec := (bright if lit else Palette.GOLD_DIM)
		ec.a = lit_a if lit else 0.85
		draw_line(p1, p2, Color(0, 0, 0, 0.8), 3.2, true)
		draw_line(p1, p2, ec, 1.5, true)

	# ---- hover ignite: the socket rim catches fire, faint halo past it ----
	if _hover > 0.01:
		var hcol := accent.lightened(0.3)
		hcol.a = 0.55 * _hover
		var halo := _oct(fr.grow(3.0))
		for i in 8:
			draw_line(halo[i], halo[(i + 1) % 8], hcol, 1.4, true)
	# press kick: a collapsing octagon ring
	if _press_k > 0.01:
		var pk := Palette.GOLD_BRIGHT
		pk.a = 0.6 * _press_k
		var ring := _oct(fr.grow(2.0 + 7.0 * (1.0 - _press_k)))
		for i in 8:
			draw_line(ring[i], ring[(i + 1) % 8], pk, 1.8, true)

	# ---- out of resource (but off cd): a pulsing crimson want-line at the foot ----
	if usable and not affordable:
		var wl := Palette.CRIMSON
		wl.a = 0.45 + 0.25 * sin(_pulse * 2.0)
		draw_line(Vector2(fr.position.x + 12.0, fr.end.y - 4.0),
			Vector2(fr.end.x - 12.0, fr.end.y - 4.0), wl, 2.0, true)

	# ---- keybind tab, notched into the top-right chamfer ----
	var keytxt := key_label if key_label != "" else str(key_num)
	var kw := maxf(17.0, 8.0 * float(keytxt.length()) + 9.0)
	var krect := Rect2(fr.end.x - kw + 5.0, fr.position.y - 3.0, kw, 14.0)
	var chip := StyleBoxFlat.new()
	chip.bg_color = Color(Palette.BG0.r, Palette.BG0.g, Palette.BG0.b, 0.95)
	chip.border_color = Palette.GOLD if (on or _hovered) else Palette.GOLD_DIM
	chip.set_border_width_all(1)
	chip.set_corner_radius_all(3)
	draw_style_box(chip, krect)
	UiKit.text_shadowed(self, UiKit.display(650), Vector2(krect.position.x, krect.position.y + 10.5),
		keytxt, HORIZONTAL_ALIGNMENT_CENTER, kw, UiKit.SIZE["MICRO"],
		Palette.GOLD_BRIGHT if on else Palette.GOLD_DIM)

	# ---- the name, engraved under the socket (the face stays clean) ----
	if _tex != null and label != "":
		var lc := Palette.TEXT if on else Palette.TEXT_DIM
		lc.a = 0.62 + 0.38 * _hover
		UiKit.text_shadowed(self, UiKit.display(600), Vector2(0.0, size.y - 2.0),
			label.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, size.x, UiKit.SIZE["MICRO"], lc)
