## AspectCard — an aspect choice presented as a wide ceremonial banner: a glass slab
## with a glyph medallion on the left, the aspect's name in tracked Cinzel beside a
## rule-line, the playstyle description in Spectral beneath, and a chevron that
## ignites on hover. Emits `chosen` on click.
class_name AspectCard
extends GlassPanel

signal chosen

var title: String
var desc: String
var icon_id: String
var _accent: Color
var _tex: Texture2D
var _hovered := false
var _hover := 0.0
var _pulse := 0.0
var _desc_lbl: Label

func _init(p_title: String, p_desc: String, accent: Color, p_icon: String = "") -> void:
	title = p_title
	desc = p_desc
	icon_id = p_icon
	_accent = accent
	super._init("CARD", accent)
	custom_minimum_size = Vector2(680, 104)
	mouse_filter = Control.MOUSE_FILTER_STOP
	if icon_id != "":
		_tex = RuneIcons.tex(icon_id)

func _ready() -> void:
	super._ready()
	_desc_lbl = Label.new()
	_desc_lbl.text = desc
	_desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_lbl.add_theme_font_override("font", UiKit.body(400))
	_desc_lbl.add_theme_font_size_override("font_size", UiKit.SIZE["BODY"] - 1)
	_desc_lbl.add_theme_color_override("font_color", Palette.TEXT)
	_desc_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	_desc_lbl.offset_left = 108.0
	_desc_lbl.offset_right = -56.0
	_desc_lbl.offset_top = 42.0
	_desc_lbl.offset_bottom = -8.0
	_desc_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_desc_lbl)

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		_hovered = true
		set_active(true)
	elif what == NOTIFICATION_MOUSE_EXIT:
		_hovered = false
		set_active(false)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		chosen.emit()

func _process(delta: float) -> void:
	_pulse += delta * 2.6
	var target := 1.0 if _hovered else 0.0
	if absf(target - _hover) > 0.002:
		_hover += (target - _hover) * clampf(delta * 12.0, 0.0, 1.0)
		pivot_offset = size * 0.5
		scale = Vector2.ONE * (1.0 + 0.02 * _hover)
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y
	# medallion
	var mc := Vector2(54.0, h * 0.5)
	var mr := 30.0 + 1.5 * _hover
	draw_circle(mc, mr, Palette.FILL_BOT)
	var halo := _accent
	halo.a = 0.12 + 0.12 * _hover + 0.04 * sin(_pulse)
	draw_circle(mc, mr * 1.22, halo)
	UiKit.gilded_ring(self, mc, mr, 2.0, 36)
	if _tex != null:
		var isz := mr * 1.15
		var irect := Rect2(mc - Vector2(isz, isz) * 0.5, Vector2(isz, isz))
		draw_texture_rect(_tex, Rect2(irect.position + Vector2(0, 1), irect.size), false, UiKit.TEXT_SHADOW)
		draw_texture_rect(_tex, irect, false, _accent.lightened(0.15 + 0.2 * _hover))

	# name + rule-line in the accent
	var dfont := UiKit.display(700, 2)
	var nsz := UiKit.SIZE["HEADER"]
	UiKit.text_shadowed(self, dfont, Vector2(108.0, 30.0), title.to_upper(),
		HORIZONTAL_ALIGNMENT_LEFT, w - 170.0, nsz, Palette.GOLD.lerp(Palette.GOLD_BRIGHT, 0.4))
	var tw := dfont.get_string_size(title.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, nsz).x
	draw_line(Vector2(118.0 + tw, 24.0), Vector2(minf(w - 60.0, 118.0 + tw + 150.0), 24.0),
		Color(_accent.r, _accent.g, _accent.b, 0.55), 1.2, true)

	# hover chevron
	var ch := "▶"
	var ccol := Palette.GOLD_BRIGHT if _hovered else Palette.GOLD_DIM
	ccol.a = 0.5 + 0.5 * _hover
	UiKit.text_shadowed(self, UiKit.display(650), Vector2(w - 42.0, h * 0.5 + 6.0), ch,
		HORIZONTAL_ALIGNMENT_LEFT, 30.0, UiKit.SIZE["SUBHEAD"], ccol)
	# accent keel along the left edge
	draw_rect(Rect2(0, 8, 3, h - 16), Color(_accent.r, _accent.g, _accent.b, 0.55 + 0.3 * _hover))
