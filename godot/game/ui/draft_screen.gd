## DraftScreen — the shared Draft 2.0 between-fight screen (all five classes). Renders
## the fallen boss header + class flavor line, the Token plaque, the three offer cards
## (slot 0 marked RESONANT when the synergy slot matched the build), an UPSELL plaque
## under each card, and the REROLL plate under the row. All economy goes through the
## shared Draft engine; this screen only spends and re-renders. Emits `boon_taken`.
class_name DraftScreen
extends Control

signal boon_taken(boon: Dictionary)

var _run                       # RunState
var _offers: Array = []
var _headline: String          # rendered verbatim ("THE GATEKEEPER FALLS", "SALVAGE — TAKE ONE")
var _flavor: String
var _extra: Array = []
var _extra_col: Color
var _mid: VBoxContainer
var _tokens_lbl: Label
var _row: HBoxContainer
var _reroll: Button            ## REGENERATE — spends a banked charge to redraw the row

func _init(run, offers: Array, headline: String, flavor: String, extra_lines: Array = [],
		extra_color: Color = Palette.STEEL) -> void:
	_run = run
	_offers = offers
	_headline = headline
	_flavor = flavor
	_extra = extra_lines
	_extra_col = extra_color
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	var head := VBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.set_anchors_preset(Control.PRESET_CENTER_TOP)
	head.offset_left = -430.0
	head.offset_right = 430.0
	head.offset_top = 52.0
	head.offset_bottom = 200.0
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(head)
	var hl := _label(head, _headline, 30, Palette.GOLD)
	hl.add_theme_font_override("font", UiKit.display(750, 3))
	_label(head, _flavor, 15, Palette.TEXT_DIM)
	for line in _extra:
		_label(head, String(line), 13, _extra_col)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_mid = VBoxContainer.new()
	_mid.alignment = BoxContainer.ALIGNMENT_CENTER
	_mid.add_theme_constant_override("separation", 16)
	center.add_child(_mid)

	_tokens_lbl = _label(_mid, "", 15, Palette.GOLD)
	_tokens_lbl.add_theme_font_override("font", UiKit.display(650, 2))

	_row = HBoxContainer.new()
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", 24)
	_mid.add_child(_row)

	_reroll = Button.new()
	_reroll.custom_minimum_size = Vector2(240, 40)
	_reroll.add_theme_font_size_override("font_size", 15)
	_reroll.pressed.connect(_on_reroll)
	var rc := CenterContainer.new()
	rc.add_child(_reroll)
	_mid.add_child(rc)

	_rebuild()

## Re-render the cards + economy state (after a spend).
func _rebuild() -> void:
	for c in _row.get_children():
		c.queue_free()
	for i in _offers.size():
		var b: Dictionary = _offers[i]
		var col := VBoxContainer.new()
		col.alignment = BoxContainer.ALIGNMENT_CENTER
		col.add_theme_constant_override("separation", 8)
		# ARMORY: every boon is a PIECE — the chip names the armor slot it forges into
		var forge := _label(col, "⚒  %s" % ArmorSlots.pretty(ArmorSlots.slot_of(b)),
			11, Palette.GOLD_DIM)
		forge.add_theme_font_override("font", UiKit.display(600, 2))
		var card := RelicCard.new(String(b["title"]), String(b["desc"]), String(b["type"]),
			Draft.rarity(b), i == 0 and Draft.matches(b, _run), String(b.get("slot", "")))
		card.taken.connect(_on_taken.bind(i))
		col.add_child(card)
		var up := Button.new()
		up.text = "UPSELL · %d ⏣" % Draft.UPSELL_COST
		up.custom_minimum_size = Vector2(150, 34)
		up.add_theme_font_size_override("font_size", 13)
		if Draft.can_upsell(_run, _offers, i):
			up.pressed.connect(_on_upsell.bind(i))
		else:
			up.disabled = true
			up.modulate = Color(1, 1, 1, 0.35)
		col.add_child(up)
		_row.add_child(col)
		# the deal-in: each card arrives a beat after the last (rerolls re-deal too)
		col.modulate.a = 0.0
		var tw := col.create_tween()
		tw.tween_interval(0.10 + 0.09 * float(i))
		tw.tween_property(col, "modulate:a", 1.0, 0.22)
	var t: int = _run.tokens
	var rg: int = _run.regenerate
	_tokens_lbl.text = "TOKENS · %d   —   REGENERATE · %d   —   spend them responsibly" % [t, rg]
	_tokens_lbl.add_theme_color_override("font_color", Palette.GOLD if t > 0 else Palette.TEXT_DIM)
	# rerolls-out (§11 #3): the row is redrawn by a banked REGENERATE charge, not Tokens
	_reroll.text = "REGENERATE THE OFFER  (%d left)" % rg
	_reroll.disabled = rg <= 0

func _on_taken(i: int) -> void:
	boon_taken.emit(_offers[i])

## REGENERATE: spend a banked charge to redraw the whole row (rerolls-out; no LOCK).
func _on_reroll() -> void:
	var next := Draft.reroll(_run)
	if not next.is_empty():
		_offers = next
	_rebuild()

func _on_upsell(i: int) -> void:
	_offers = Draft.upsell(_run, _offers, i)
	_rebuild()

func _label(parent: Node, text: String, fs: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l
