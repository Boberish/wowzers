## The GRIMOIRE — the in-combat spellbook as a two-page reliquary tome instead of
## a text list. Left page: your ABILITIES as rune-socket rows (glyph in a gilded
## mini-socket, Cinzel name, keybind chip, stat line, wrapped tip). Right page:
## your drafted BOONS as rarity-gemmed entries (Haiku quiet · Sonnet gold ·
## Opus burning — same canon as the tarot cards), scrollable for long runs.
## A dim veil sits behind; clicking it (or the class's S toggle) closes the tome.
##
## Usage:
##     _book = Grimoire.new("BULWARK — WARDEN", abilities, boons, Palette.STEEL)
##     _book.closed.connect(func(): _toggle_book())
##     _ui.add_child(_book)
## `abilities`: [{icon, name, key, stats, tip}] · `boons`: Draft 2.0 pool dicts.
class_name Grimoire
extends Control

signal closed

var _title := ""
var _abilities: Array = []
var _boons: Array = []
var _accent: Color = Palette.GOLD
var _t := 0.0
var _tome: Control

func _init(title: String, abilities: Array, boons: Array, accent: Color) -> void:
	_title = title
	_abilities = abilities
	_boons = boons
	_accent = accent
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP     # the veil eats clicks (and closes)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		closed.emit()

func _process(delta: float) -> void:
	if _t < 0.3:
		_t += delta
		var e := clampf(_t / 0.18, 0.0, 1.0)
		e = 1.0 - (1.0 - e) * (1.0 - e)
		if _tome != null:
			_tome.scale = Vector2.ONE * (0.94 + 0.06 * e)
			_tome.modulate.a = e
		queue_redraw()

func _draw() -> void:
	# the veil: the fight dims while you read
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.55 * clampf(_t / 0.18, 0.0, 1.0)))

func _ready() -> void:
	var W := 980.0
	var H := 600.0
	_tome = Control.new()
	_tome.set_anchors_preset(Control.PRESET_CENTER)
	_tome.offset_left = -W * 0.5
	_tome.offset_top = -H * 0.5
	_tome.offset_right = W * 0.5
	_tome.offset_bottom = H * 0.5
	_tome.pivot_offset = Vector2(W * 0.5, H * 0.5)
	_tome.mouse_filter = Control.MOUSE_FILTER_STOP    # clicks on the tome don't close it
	_tome.draw.connect(_draw_tome)
	add_child(_tome)

	# ---- left page: ABILITIES ----
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 10)
	_placef(left, 36, 92, W * 0.5 - 26, H - 46)
	_tome.add_child(left)
	for a in _abilities:
		left.add_child(_ability_row(a))

	# ---- right page: BOONS (scrolls — long runs stack deep) ----
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_placef(scroll, W * 0.5 + 26, 92, W - 36, H - 46)
	_tome.add_child(scroll)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 12)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(right)
	if _boons.is_empty():
		var none := Label.new()
		none.text = "The pages wait.\nWin a fight, draft a boon — it is inscribed here."
		none.add_theme_font_size_override("font_size", UiKit.SIZE["BODY"])
		none.add_theme_color_override("font_color", Palette.TEXT_DIM)
		right.add_child(none)
	for b in _boons:
		right.add_child(_boon_row(b))

func _placef(n: Control, x0: float, y0: float, x1: float, y1: float) -> void:
	n.set_anchors_preset(Control.PRESET_TOP_LEFT)
	n.offset_left = x0
	n.offset_top = y0
	n.offset_right = x1
	n.offset_bottom = y1

## one ability: [socketed glyph] NAME ......... [key]  /  stats  /  tip
func _ability_row(a: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var sock := Control.new()
	sock.custom_minimum_size = Vector2(46, 46)
	sock.draw.connect(func():
		var r := Rect2(2, 2, 42, 42)
		var pts := PackedVector2Array([Vector2(10, 2), Vector2(36, 2), Vector2(44, 10),
			Vector2(44, 36), Vector2(36, 44), Vector2(10, 44), Vector2(2, 36), Vector2(2, 10)])
		sock.draw_colored_polygon(pts, Palette.FILL_BOT)
		for i in 8:
			sock.draw_line(pts[i], pts[(i + 1) % 8],
				Palette.GOLD if i < 4 else Palette.GOLD_DIM, 1.3, true)
		var tex := RuneIcons.tex(String(a.get("icon", "")))
		if tex != null:
			sock.draw_texture_rect(tex, Rect2(r.position + Vector2(7, 7), Vector2(28, 28)),
				false, _accent))
	row.add_child(sock)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 1)
	row.add_child(col)
	var head := HBoxContainer.new()
	col.add_child(head)
	var nm := Label.new()
	nm.text = String(a.get("name", "")).to_upper()
	nm.add_theme_font_override("font", UiKit.display(650, 1))
	nm.add_theme_font_size_override("font_size", UiKit.SIZE["SUBHEAD"])
	nm.add_theme_color_override("font_color", Palette.TEXT)
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(nm)
	var key := Label.new()
	key.text = "[ %s ]" % String(a.get("key", ""))
	key.add_theme_font_override("font", UiKit.display(650))
	key.add_theme_font_size_override("font_size", UiKit.SIZE["CAPTION"])
	key.add_theme_color_override("font_color", Palette.GOLD)
	head.add_child(key)
	if String(a.get("stats", "")) != "":
		var st := Label.new()
		st.text = String(a["stats"])
		st.add_theme_font_size_override("font_size", UiKit.SIZE["CAPTION"])
		st.add_theme_color_override("font_color", Palette.GOLD_DIM.lightened(0.25))
		col.add_child(st)
	var tip := Label.new()
	tip.text = String(a.get("tip", ""))
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.add_theme_font_size_override("font_size", UiKit.SIZE["CAPTION"])
	tip.add_theme_color_override("font_color", Palette.TEXT_DIM)
	col.add_child(tip)
	return row

## one drafted boon: rarity gem + title (rarity-tinted) + wrapped desc
func _boon_row(b: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var rar := String(b.get("rarity", "haiku"))
	var rcol := Palette.rarity_color(rar)
	var gem := Control.new()
	gem.custom_minimum_size = Vector2(18, 40)
	gem.draw.connect(func():
		var c := Vector2(9, 16)
		var pts := PackedVector2Array([c + Vector2(0, -8), c + Vector2(6, 0),
			c + Vector2(0, 8), c + Vector2(-6, 0)])
		gem.draw_colored_polygon(pts, rcol)
		gem.draw_circle(c + Vector2(-1.5, -2.5), 1.6, Color(1, 1, 1, 0.7)))
	row.add_child(gem)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 1)
	row.add_child(col)
	var head := HBoxContainer.new()
	col.add_child(head)
	var t := Label.new()
	t.text = String(b.get("title", b.get("id", "?")))
	t.add_theme_font_override("font", UiKit.display(650, 1))
	t.add_theme_font_size_override("font_size", UiKit.SIZE["BODY"] + 1)
	t.add_theme_color_override("font_color", rcol if rar != "haiku" else Palette.TEXT)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)
	var ty := Label.new()
	ty.text = String(b.get("type", "")).to_upper()
	ty.add_theme_font_size_override("font_size", UiKit.SIZE["MICRO"])
	ty.add_theme_color_override("font_color", Palette.type_color(String(b.get("type", ""))))
	head.add_child(ty)
	var d := Label.new()
	d.text = String(b.get("desc", ""))
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.add_theme_font_size_override("font_size", UiKit.SIZE["CAPTION"])
	d.add_theme_color_override("font_color", Palette.TEXT_DIM)
	col.add_child(d)
	return row

## the tome itself: leather-dark plate, gilded frame, centre spine, page plaques
func _draw_tome() -> void:
	var W := _tome.size.x
	var H := _tome.size.y
	var plate := StyleBoxFlat.new()
	plate.bg_color = Color(0.043, 0.037, 0.066, 0.97)
	plate.set_corner_radius_all(12)
	plate.border_color = Palette.GOLD_DIM
	plate.set_border_width_all(2)
	_tome.draw_style_box(plate, Rect2(0, 0, W, H))
	_tome.draw_rect(Rect2(3, 3, W - 6, H * 0.10), Color(1, 1, 1, 0.03))
	UiKit.filigree_corner(_tome, Vector2(10, 10), Vector2(1, 1), 14.0)
	UiKit.filigree_corner(_tome, Vector2(W - 10, 10), Vector2(-1, 1), 14.0)
	UiKit.filigree_corner(_tome, Vector2(10, H - 10), Vector2(1, -1), 14.0)
	UiKit.filigree_corner(_tome, Vector2(W - 10, H - 10), Vector2(-1, -1), 14.0)
	# the spine
	_tome.draw_line(Vector2(W * 0.5, 20), Vector2(W * 0.5, H - 20), Color(0, 0, 0, 0.6), 5.0, true)
	_tome.draw_line(Vector2(W * 0.5, 20), Vector2(W * 0.5, H - 20), Palette.GOLD_DIM, 1.4, true)
	UiKit.gilded_pip(_tome, Vector2(W * 0.5, 20), 4.0, true, Palette.GOLD)
	UiKit.gilded_pip(_tome, Vector2(W * 0.5, H - 20), 4.0, true, Palette.GOLD)
	# header: the class title across the top, page plaques over each column
	UiKit.text_shadowed(_tome, UiKit.display(750, 2), Vector2(0, 40), _title,
		HORIZONTAL_ALIGNMENT_CENTER, W, UiKit.SIZE["HEADER"], _accent)
	UiKit.engraved_plaque(_tome, Vector2(W * 0.25, 68), "ABILITIES", false)
	UiKit.engraved_plaque(_tome, Vector2(W * 0.75, 68), "BOONS · %d INSCRIBED" % _boons.size(), false)
	# footer
	UiKit.text_shadowed(_tome, ThemeDB.fallback_font, Vector2(0, H - 14), "S — close the tome",
		HORIZONTAL_ALIGNMENT_CENTER, W, UiKit.SIZE["MICRO"], Palette.TEXT_DIM)
