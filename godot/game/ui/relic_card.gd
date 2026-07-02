## RelicCard — a draft pick presented as a tarot-proportioned relic. A glass CARD slab
## with an engraved double border and filigree corners, a cut type-gem seated in a
## radiant setting at the head, the title in tracked Cinzel, the body in Spectral, and
## a "TAKE" ribbon at the foot. Hovering lifts the card and ignites its edge glow.
## Draft 2.0: the card carries its RARITY (Haiku prints nothing — the quiet default;
## Sonnet/Opus tint the border + caption, Opus adds a pulsing outer ring) and a SYNERGY
## mark (✦ glyphs in the top corners — the offer resonates with your build; the draft
## screen's flavor line explains the glyph). Emits `taken` on click; the HUD applies.
class_name RelicCard
extends GlassPanel

signal taken

var title: String = ""
var body: String = ""
var kind: String = "upgrade"       # "spell" / "upgrade" / "relic" — tints the gem
var rarity: String = "haiku"       # "haiku" / "sonnet" / "opus" — tints the frame
var synergy: bool = false          # slot-0 resonance mark
var _accent: Color
var _rcol: Color
var _hover := 0.0
var _hovered := false
var _pulse := 0.0
var _body_lbl: Label

func _init(p_title: String, p_body: String, p_kind: String,
		p_rarity: String = "haiku", p_synergy: bool = false) -> void:
	title = p_title
	body = p_body
	kind = p_kind
	rarity = p_rarity
	synergy = p_synergy
	_accent = Palette.type_color(p_kind)
	_rcol = Palette.rarity_color(p_rarity)
	super._init("CARD", _rcol if rarity != "haiku" else _accent)
	custom_minimum_size = Vector2(230, 300)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _ready() -> void:
	super._ready()
	# body text as a real Label (autowrap); everything else is drawn
	_body_lbl = Label.new()
	_body_lbl.text = body
	_body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_body_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_body_lbl.add_theme_font_override("font", UiKit.body(400))
	_body_lbl.add_theme_font_size_override("font_size", UiKit.SIZE["BODY"] - 1)
	_body_lbl.add_theme_color_override("font_color", Palette.TEXT)
	_body_lbl.add_theme_color_override("font_shadow_color", UiKit.TEXT_SHADOW)
	_body_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	_body_lbl.offset_left = 18.0
	_body_lbl.offset_right = -18.0
	_body_lbl.offset_top = 118.0
	_body_lbl.offset_bottom = -44.0
	_body_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_body_lbl)

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_ENTER:
		_hovered = true
		set_active(true)
	elif what == NOTIFICATION_MOUSE_EXIT:
		_hovered = false
		set_active(false)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		taken.emit()

func _process(delta: float) -> void:
	_pulse += delta * 3.0
	var target := 1.0 if _hovered else 0.0
	if absf(target - _hover) > 0.002 or rarity == "opus":
		_hover += (target - _hover) * clampf(delta * 12.0, 0.0, 1.0)
		pivot_offset = size * 0.5
		scale = Vector2.ONE * (1.0 + 0.03 * _hover)
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y

	# engraved double border + filigree corners (Sonnet/Opus tint the engraving)
	var inset := 7.0
	var base_b := Palette.GOLD_DIM if rarity == "haiku" else Palette.GOLD_DIM.lerp(_rcol, 0.65)
	var bcol := Color(base_b.r, base_b.g, base_b.b, 0.55 + 0.35 * _hover)
	draw_rect(Rect2(inset, inset, w - inset * 2.0, h - inset * 2.0), bcol, false, 1.2)
	var base_b2 := Palette.GOLD if rarity == "haiku" else Palette.GOLD.lerp(_rcol, 0.5)
	var b2 := Color(base_b2.r, base_b2.g, base_b2.b, 0.20 + 0.5 * _hover)
	draw_rect(Rect2(inset + 3.0, inset + 3.0, w - (inset + 3.0) * 2.0, h - (inset + 3.0) * 2.0), b2, false, 1.0)
	UiKit.filigree_corner(self, Vector2(inset, inset), Vector2(1, 1), 10.0)
	UiKit.filigree_corner(self, Vector2(w - inset, inset), Vector2(-1, 1), 10.0)
	UiKit.filigree_corner(self, Vector2(inset, h - inset), Vector2(1, -1), 10.0)
	UiKit.filigree_corner(self, Vector2(w - inset, h - inset), Vector2(-1, -1), 10.0)

	# Opus: a slow-breathing outer ring — the chase tier announces itself
	if rarity == "opus":
		var pa := 0.22 + 0.14 * (0.5 + 0.5 * sin(_pulse * 0.8))
		draw_rect(Rect2(inset - 3.0, inset - 3.0, w - (inset - 3.0) * 2.0, h - (inset - 3.0) * 2.0),
			Color(_rcol.r, _rcol.g, _rcol.b, pa), false, 2.0)

	# Synergy: resonance glyphs in the top corners (the draft header explains ✦)
	if synergy:
		var sc := Palette.GOLD_BRIGHT
		sc.a = 0.75 + 0.25 * sin(_pulse * 1.4)
		UiKit.text_shadowed(self, UiKit.display(700, 0), Vector2(inset + 8.0, inset + 17.0), "✦",
			HORIZONTAL_ALIGNMENT_LEFT, 30, UiKit.SIZE["CAPTION"] + 2, sc)
		UiKit.text_shadowed(self, UiKit.display(700, 0), Vector2(w - inset - 38.0, inset + 17.0), "✦",
			HORIZONTAL_ALIGNMENT_RIGHT, 30, UiKit.SIZE["CAPTION"] + 2, sc)

	# the type gem in a radiant setting
	var gc := Vector2(w * 0.5, 46.0)
	var gr := 13.0 + 1.5 * _hover
	for i in 8:
		var a := TAU * float(i) / 8.0 + PI / 8.0
		var d := Vector2(cos(a), sin(a))
		draw_line(gc + d * (gr + 3.0), gc + d * (gr + 8.0 + 2.0 * sin(_pulse + float(i))),
			Color(_accent.r, _accent.g, _accent.b, 0.35 + 0.2 * _hover), 1.4, true)
	var pts := PackedVector2Array([gc + Vector2(0, -gr), gc + Vector2(gr * 0.72, 0),
		gc + Vector2(0, gr), gc + Vector2(-gr * 0.72, 0)])
	draw_colored_polygon(pts, _accent.darkened(0.30))
	var mid := PackedVector2Array([gc + Vector2(0, -gr * 0.55), gc + Vector2(gr * 0.40, 0),
		gc + Vector2(0, gr * 0.55), gc + Vector2(-gr * 0.40, 0)])
	draw_colored_polygon(mid, _accent)
	draw_line(pts[0], pts[1], Palette.GOLD, 1.4, true)
	draw_line(pts[1], pts[2], Palette.GOLD_DIM, 1.4, true)
	draw_line(pts[2], pts[3], Palette.GOLD_DIM, 1.4, true)
	draw_line(pts[3], pts[0], Palette.GOLD, 1.4, true)
	draw_circle(gc + Vector2(-gr * 0.22, -gr * 0.3), gr * 0.18, Color(1, 1, 1, 0.8))

	# kind caption (rarity-stamped for Sonnet/Opus) + title
	var caption := kind.to_upper() if rarity == "haiku" else "%s · %s" % [rarity.to_upper(), kind.to_upper()]
	var ccol := _accent if rarity == "haiku" else _rcol
	UiKit.text_shadowed(self, UiKit.display(600, 3), Vector2(0, 78.0), caption,
		HORIZONTAL_ALIGNMENT_CENTER, w, UiKit.SIZE["CAPTION"], ccol)
	UiKit.text_shadowed(self, UiKit.display(700, 1), Vector2(10, 104.0), title,
		HORIZONTAL_ALIGNMENT_CENTER, w - 20, UiKit.SIZE["HEADER"], Palette.GOLD.lerp(Palette.GOLD_BRIGHT, 0.4))

	# TAKE ribbon at the foot
	var ry := h - 30.0
	var rcol := Palette.GOLD_BRIGHT if _hovered else Palette.TEXT_DIM
	var ribbon := "◆  TAKE  ◆" if _hovered else "take"
	draw_line(Vector2(w * 0.22, ry - 5.0), Vector2(w * 0.78, ry - 5.0),
		Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.5), 1.0, true)
	UiKit.text_shadowed(self, UiKit.display(650, 2), Vector2(0, ry + 12.0), ribbon,
		HORIZONTAL_ALIGNMENT_CENTER, w, UiKit.SIZE["CAPTION"], rcol)
