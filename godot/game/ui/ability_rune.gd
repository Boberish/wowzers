## A circular ability button: a struck gilded COIN (domed metal body + gold rim + wet
## specular, dimming when uncastable), an embossed glyph, a radial cooldown veil, a
## charged halo, a hover ignite ring, and a keybind PLAQUE (small gilded chip at the
## coin's foot). Emits `pressed`; the HUD also drives it from number keys.
class_name AbilityRune
extends Control

signal pressed

var label: String = ""
var key_num: int = 1
var key_label: String = ""         # overrides the number (e.g. "SPC" for guard)
var icon_id: String = ""           # RuneIcons id for the glyph (e.g. "cleave"); "" = text-only
var accent: Color = Palette.GOLD   # rim/glow tint when usable
var affordable: bool = true
var usable: bool = true            # off GCD / not on cooldown
var cd_frac: float = 0.0          # 0 = ready, 1 = full cooldown
var _pulse: float = 0.0
var _hover: float = 0.0           # eased 0..1 hover emphasis
var _hovered: bool = false
var _press_k: float = 0.0         # press-down kick, decays
var _glow: GlowCore
var _coin: ColorRect
var _tex: Texture2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(76, 76)
	# struck metal coin behind the face (dome + gold bevel rim + specular)
	_coin = UiKit.coin(self, accent)
	# charged-button halo: additive glow, on only when castable
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
	var on := affordable and usable
	if _glow != null:
		_glow.set_base((0.9 if on else 0.0) + 0.4 * _hover)
	if _coin != null:
		(_coin.material as ShaderMaterial).set_shader_parameter("enabled", 1.0 if on else 0.5)
	queue_redraw()

func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - 3.0
	var on := affordable and usable

	# cooldown veil: dark remaining sector over the coin + a bright burn-down edge
	if cd_frac > 0.002:
		var top := -PI / 2.0
		var end := top + TAU * clampf(cd_frac, 0.0, 1.0)
		var poly := PackedVector2Array()
		poly.append(c)
		var steps := 22
		for i in range(steps + 1):
			var a := top + (end - top) * float(i) / float(steps)
			poly.append(c + Vector2(cos(a), sin(a)) * r)
		draw_colored_polygon(poly, Color(0, 0, 0, 0.58))
		draw_line(c, c + Vector2(cos(end), sin(end)) * r, Palette.GOLD_BRIGHT, 1.5, true)

	# hover ignite: a bright rim ring + faint outer halo ring
	if _hover > 0.01:
		var hc := accent.lightened(0.3)
		hc.a = 0.75 * _hover
		draw_arc(c, r - 0.5, 0.0, TAU, 48, hc, 2.0, true)
		hc.a = 0.22 * _hover
		draw_arc(c, r + 3.0, 0.0, TAU, 48, hc, 1.5, true)
	# press kick: quick collapsing ring
	if _press_k > 0.01:
		var pk := Palette.GOLD_BRIGHT
		pk.a = 0.6 * _press_k
		draw_arc(c, r * (1.0 + 0.18 * (1.0 - _press_k)), 0.0, TAU, 40, pk, 2.0, true)

	var col := Palette.TEXT if on else Palette.TEXT_DIM
	if _tex != null:
		var isz := 33.0 + 2.0 * _hover
		var irect := Rect2(c.x - isz * 0.5, c.y - isz * 0.5 - 7.0, isz, isz)
		var itint := accent if on else Palette.TEXT_DIM.darkened(0.15)
		draw_texture_rect(_tex, Rect2(irect.position + Vector2(0, 1), irect.size), false, UiKit.TEXT_SHADOW)
		draw_texture_rect(_tex, irect, false, itint)
		UiKit.text_shadowed(self, UiKit.display(600), Vector2(c.x - r, c.y + r * 0.42), label.to_upper(),
			HORIZONTAL_ALIGNMENT_CENTER, 2.0 * r, UiKit.SIZE["MICRO"], col)
	else:
		UiKit.text_shadowed(self, UiKit.display(600), Vector2(c.x - r, c.y + 5.0), label.to_upper(),
			HORIZONTAL_ALIGNMENT_CENTER, 2.0 * r, UiKit.SIZE["LABEL"], col)

	# keybind plaque: a small gilded chip seated at the coin's foot
	var keytxt := key_label if key_label != "" else str(key_num)
	var kw := maxf(18.0, 11.0 * float(keytxt.length()) + 8.0)
	var krect := Rect2(c.x - kw * 0.5, size.y - 17.0, kw, 15.0)
	var chip := StyleBoxFlat.new()
	chip.bg_color = Color(Palette.BG0.r, Palette.BG0.g, Palette.BG0.b, 0.92)
	chip.border_color = Palette.GOLD_DIM if not _hovered else Palette.GOLD
	chip.set_border_width_all(1)
	chip.set_corner_radius_all(4)
	draw_style_box(chip, krect)
	UiKit.text_shadowed(self, UiKit.display(650), Vector2(krect.position.x, krect.position.y + 11.0),
		keytxt, HORIZONTAL_ALIGNMENT_CENTER, kw, UiKit.SIZE["MICRO"],
		Palette.GOLD if on else Palette.GOLD_DIM)
