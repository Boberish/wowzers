## MarketScreen — THE PROMPT MARKET (DESCENT §6), staffed by THE SCRAPER. A between-node
## shop: a printed-price stock you buy from YOUR wallet, a 4-seat wallet strip (per-seat
## wallets, V#11), an AUTO toggle (AI seats auto-spend their own ⏣ on LEAVE), and LEAVE.
## The HUD owns the money + the effects; this screen only renders and calls back:
##   stock      = [{title, desc, price, sold, disabled}]  (a slot per row)
##   buy        = func(i:int) -> bool   (spend + apply; true = bought, mark sold)
##   wallets_of = func() -> Array[{name, tokens, mine}]   (the strip, re-read each refresh)
##   set_auto   = func(on:bool)
##   done       = func()                (LEAVE)
## Mirrors draft_screen.gd's build-then-rebuild idiom.
class_name MarketScreen
extends Control

var _stock: Array = []
var _buy: Callable
var _wallets_of: Callable
var _set_auto: Callable
var _done: Callable
var _auto: bool = true
var _subtitle: String = ""

var _mid: VBoxContainer
var _strip: Label
var _row: VBoxContainer

func _init(stock: Array, buy: Callable, wallets_of: Callable, set_auto: Callable,
		done: Callable, auto_on: bool = true, subtitle: String = "") -> void:
	_stock = stock
	_buy = buy
	_wallets_of = wallets_of
	_set_auto = set_auto
	_done = done
	_auto = auto_on
	_subtitle = subtitle
	set_anchors_preset(Control.PRESET_FULL_RECT)

func _ready() -> void:
	var head := VBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.set_anchors_preset(Control.PRESET_CENTER_TOP)
	head.offset_left = -460.0
	head.offset_right = 460.0
	head.offset_top = 44.0
	head.offset_bottom = 210.0
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(head)
	var hl := _label(head, "THE PROMPT MARKET", 30, Palette.GOLD)
	hl.add_theme_font_override("font", UiKit.display(750, 3))
	_label(head, _subtitle if _subtitle != "" \
		else "THE SCRAPER: \"everything's scraped off the open web — 20% off and possibly stolen.\"",
		14, Palette.TEXT_DIM)
	_label(head, "TOKENS — spend them responsibly.", 12, Palette.GOLD_DIM)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_mid = VBoxContainer.new()
	_mid.alignment = BoxContainer.ALIGNMENT_CENTER
	_mid.add_theme_constant_override("separation", 10)
	center.add_child(_mid)

	_strip = _label(_mid, "", 14, Palette.GOLD)
	_strip.add_theme_font_override("font", UiKit.display(650, 2))

	_row = VBoxContainer.new()
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_row.add_theme_constant_override("separation", 8)
	_mid.add_child(_row)

	_rebuild()

func _rebuild() -> void:
	# the 4-seat wallet strip (per-seat wallets — you spend YOUR own ⏣; ★ marks yours)
	var bits: Array = []
	for w in _wallets_of.call():
		var star := " ★" if bool((w as Dictionary).get("mine", false)) else ""
		bits.append("%s %d⏣%s" % [String((w as Dictionary)["name"]), int((w as Dictionary)["tokens"]), star])
	_strip.text = "WALLETS:   " + "     ".join(PackedStringArray(bits))

	for c in _row.get_children():
		c.queue_free()
	var my_tokens := 0
	for w in _wallets_of.call():
		if bool((w as Dictionary).get("mine", false)):
			my_tokens = int((w as Dictionary)["tokens"])
	for i in _stock.size():
		var s: Dictionary = _stock[i]
		var line := HBoxContainer.new()
		line.alignment = BoxContainer.ALIGNMENT_CENTER
		line.add_theme_constant_override("separation", 14)
		var txt := Label.new()
		txt.custom_minimum_size = Vector2(560, 0)
		txt.add_theme_font_size_override("font_size", 14)
		txt.text = "%s — %s" % [String(s.get("title", "?")), String(s.get("desc", ""))]
		txt.add_theme_color_override("font_color", Palette.TEXT_DIM if _slot_dead(s) else Palette.TEXT)
		line.add_child(txt)
		var b := Button.new()
		b.custom_minimum_size = Vector2(150, 38)
		b.add_theme_font_size_override("font_size", 14)
		if bool(s.get("sold", false)):
			b.text = "SOLD"
			b.disabled = true
		elif bool(s.get("disabled", false)):
			b.text = String(s.get("disabled_text", "—"))
			b.disabled = true
		else:
			b.text = "BUY · %d⏣" % int(s.get("price", 0))
			b.disabled = my_tokens < int(s.get("price", 0))
			if not b.disabled:
				b.pressed.connect(_on_buy.bind(i))
		line.add_child(b)
		_row.add_child(line)

	# AUTO toggle + LEAVE
	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	foot.add_theme_constant_override("separation", 20)
	var auto := Button.new()
	auto.toggle_mode = true
	auto.button_pressed = _auto
	auto.custom_minimum_size = Vector2(300, 40)
	auto.add_theme_font_size_override("font_size", 14)
	auto.text = "AUTO: AI raiders spend their own ⏣  [%s]" % ("ON" if _auto else "OFF")
	auto.toggled.connect(func(on: bool):
		_auto = on
		if _set_auto.is_valid():
			_set_auto.call(on)
		_rebuild())
	foot.add_child(auto)
	var leave := Button.new()
	leave.custom_minimum_size = Vector2(220, 40)
	leave.add_theme_font_size_override("font_size", 15)
	leave.text = "LEAVE THE MARKET"
	leave.pressed.connect(func(): _done.call())
	foot.add_child(leave)
	_mid.add_child(foot)

func _slot_dead(s: Dictionary) -> bool:
	return bool(s.get("sold", false)) or bool(s.get("disabled", false))

func _on_buy(i: int) -> void:
	if _buy.is_valid() and bool(_buy.call(i)):
		(_stock[i] as Dictionary)["sold"] = true
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
