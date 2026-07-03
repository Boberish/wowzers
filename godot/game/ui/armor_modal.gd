## ARMORY-UI — the YOUR SET inspection modal. Opened by clicking any ArmorDoll
## socket (map + REFORGE screens): a dimmed stage with an ornate gilded panel —
## the doll on the left, a scrollable per-slot piece breakdown (every effect line)
## in the middle, and the equipped TRINKET cards + tokens on the right.
## Esc / click-outside / ✕ closes (the HUD owns the Esc routing, mirroring _pause).
class_name ArmorModal
extends Control

signal closed

const PANEL_W := 1180.0
const PANEL_H := 640.0

var _boons: Array
var _gear: Array
var _charges: Dictionary
var _tokens: int
var _crest: String

func _init(taken_boons: Array, gear_ids: Array, gear_charges: Dictionary,
		tokens: int, crest: String = "") -> void:
	_boons = taken_boons
	_gear = gear_ids
	_charges = gear_charges
	_tokens = tokens
	_crest = crest
	set_anchors_preset(Control.PRESET_FULL_RECT)

func _ready() -> void:
	# the dim: swallows every click; clicking it closes
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.74)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(func(ev: InputEvent):
		if ev is InputEventMouseButton and ev.pressed:
			closed.emit())
	add_child(dim)

	var panel := GlassPanel.new("CARD", Palette.GOLD_DIM)
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -PANEL_W / 2.0
	panel.offset_top = -PANEL_H / 2.0
	panel.offset_right = PANEL_W / 2.0
	panel.offset_bottom = PANEL_H / 2.0
	panel.mouse_filter = Control.MOUSE_FILTER_STOP   # clicks inside never reach the dim
	add_child(panel)

	# ---- header: title + crest + tokens + close ----
	var title := Label.new()
	title.text = "YOUR SET"
	title.add_theme_font_override("font", UiKit.display(800, 4))
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Palette.GOLD_BRIGHT)
	title.position = Vector2(36, 22)
	panel.add_child(title)
	if _crest != "":
		var sub := Label.new()
		sub.text = _crest
		sub.add_theme_font_override("font", UiKit.display(600, 2))
		sub.add_theme_font_size_override("font_size", 12)
		sub.add_theme_color_override("font_color", Palette.TEXT_DIM)
		sub.position = Vector2(38, 58)
		panel.add_child(sub)
	var tok := Label.new()
	tok.text = "⏣ %d TOKENS" % _tokens
	tok.add_theme_font_override("font", UiKit.display(650, 2))
	tok.add_theme_font_size_override("font_size", 14)
	tok.add_theme_color_override("font_color", Palette.GOLD if _tokens > 0 else Palette.TEXT_DIM)
	tok.position = Vector2(PANEL_W - 260, 30)
	panel.add_child(tok)
	var x := Button.new()
	x.text = "✕"
	x.custom_minimum_size = Vector2(40, 36)
	x.position = Vector2(PANEL_W - 62, 20)
	x.pressed.connect(func(): closed.emit())
	panel.add_child(x)
	var rule := ColorRect.new()
	rule.color = Color(Palette.GOLD_DIM, 0.5)
	rule.position = Vector2(30, 80)
	rule.size = Vector2(PANEL_W - 60, 1)
	panel.add_child(rule)

	# ---- left: the doll itself (hover cards still live inside the modal) ----
	var doll := ArmorDoll.new()
	doll.show_hint = false
	doll.position = Vector2(40, 130)
	doll.size = Vector2(ArmorDoll.W, ArmorDoll.H)
	panel.add_child(doll)
	doll.set_build(_boons, _gear, _charges)

	# ---- middle: per-slot breakdown, every piece with its effect line ----
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(320, 100)
	scroll.size = Vector2(500, PANEL_H - 140)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var mid := VBoxContainer.new()
	mid.add_theme_constant_override("separation", 6)
	mid.custom_minimum_size = Vector2(480, 0)
	scroll.add_child(mid)
	var summed := ArmorSlots.summarize(_boons)
	for slot in ArmorSlots.ORDER:
		var e: Dictionary = summed[slot]
		var n := int(e["count"])
		var hd := Label.new()
		var count_note := "· %d piece%s" % [n, "" if n == 1 else "s"] if n > 0 else "· empty"
		hd.text = "%s   %s" % [ArmorSlots.pretty(slot), count_note]
		hd.add_theme_font_override("font", UiKit.display(700, 2))
		hd.add_theme_font_size_override("font_size", 15)
		hd.add_theme_color_override("font_color",
			Palette.rarity_color(String(e["best"])) if n > 0 else Palette.TEXT_DIM)
		mid.add_child(hd)
		if n == 0:
			var em := Label.new()
			em.text = "     — the draft forges pieces here"
			em.add_theme_font_size_override("font_size", 12)
			em.add_theme_color_override("font_color", Color(Palette.TEXT_DIM, 0.8))
			mid.add_child(em)
		for p in e["pieces"]:
			var pd: Dictionary = p
			var pt := Label.new()
			pt.text = "     ◆  " + String(pd["title"])
			pt.add_theme_font_size_override("font_size", 13)
			pt.add_theme_color_override("font_color", Palette.rarity_color(String(pd["rarity"])))
			mid.add_child(pt)
			if String(pd.get("desc", "")) != "":
				var pdsc := Label.new()
				pdsc.text = "          " + String(pd["desc"])
				pdsc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				pdsc.custom_minimum_size = Vector2(470, 0)
				pdsc.add_theme_font_size_override("font_size", 12)
				pdsc.add_theme_color_override("font_color", Palette.TEXT)
				mid.add_child(pdsc)
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(0, 8)
		mid.add_child(gap)

	# ---- right: equipped trinkets as full relic cards ----
	var rt := Label.new()
	rt.text = "TRINKETS"
	rt.add_theme_font_override("font", UiKit.display(650, 3))
	rt.add_theme_font_size_override("font_size", 12)
	rt.add_theme_color_override("font_color", Palette.GOLD_DIM.lightened(0.25))
	rt.position = Vector2(880, 96)
	panel.add_child(rt)
	var col := VBoxContainer.new()
	col.position = Vector2(866, 118)
	col.add_theme_constant_override("separation", 14)
	panel.add_child(col)
	for i in 2:
		if i < _gear.size():
			var id := String(_gear[i])
			var it := GearCatalog.item(id)
			var card := RelicCard.new(String(it.get("name", id)), String(it.get("desc", "")),
				"curio", String(it.get("rarity", "haiku")), false, "")
			card.ribbon_text = "◆ EQUIPPED · ×%d ◆" % int(_charges[id]) \
				if _charges.has(id) else "◆ EQUIPPED ◆"
			card.custom_minimum_size = Vector2(230, 250)
			card.mouse_filter = Control.MOUSE_FILTER_IGNORE
			col.add_child(card)
		else:
			var ph := GlassPanel.new("WELL", Palette.EDGE)
			ph.custom_minimum_size = Vector2(230, 250)
			var pl := Label.new()
			pl.text = "EMPTY SOCKET\n\nboss drops land here"
			pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			pl.add_theme_font_size_override("font_size", 12)
			pl.add_theme_color_override("font_color", Color(Palette.TEXT_DIM, 0.8))
			pl.set_anchors_preset(Control.PRESET_FULL_RECT)
			pl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			ph.add_child(pl)
			col.add_child(ph)

	# footer hint
	var hint := Label.new()
	hint.text = "Esc / click outside to close"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(Palette.TEXT_DIM, 0.7))
	hint.position = Vector2(36, PANEL_H - 34)
	panel.add_child(hint)
