## PauseOverlay — the in-combat PAUSE menu + DEV CLASS CODEX (see ClassCodex).
## A dim veil over the frozen fight with a gilded card: RESUME / QUIT plus a scannable
## "how does this class work" guide for the seat you're driving — core loop, what each
## BAR does, what each MOVE encourages, the GOAL ROTATION for your Aspect, and THE
## BRANCHES (both Aspects + boon/gear sub-builds). Built so a playtester can read the
## build "at a glance" without leaving the fight.
##
## Usage:
##     var p := PauseOverlay.new("bulwark", "warden", owned_boon_dicts, frozen)
##     p.resumed.connect(_resume); p.quit_to_menu.connect(_quit)
##     _ui.add_child(p)
## `boon_dicts`: resolved [{title, rarity, type}] the human has drafted (may be []).
class_name PauseOverlay
extends Control

signal resumed
signal quit_to_menu

var _class_id := ""
var _aspect := ""
var _codex: Dictionary = {}
var _accent: Color = Palette.GOLD
var _boons: Array = []
var _frozen := true
var _t := 0.0
var _card: Control

func _init(class_id: String, aspect: String, boon_dicts: Array = [], frozen: bool = true) -> void:
	_class_id = class_id
	_aspect = aspect
	_boons = boon_dicts
	_frozen = frozen
	_codex = ClassCodex.entry(class_id)
	_accent = _color(String(_codex.get("accent", "gold")))
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP     # eat clicks so the fight underneath ignores them

## tint key (from ClassCodex) -> a Palette color. (const can't hold Palette statics.)
func _color(key: String) -> Color:
	match key:
		"blood": return Palette.BLOOD
		"rage": return Palette.RAGE
		"steel": return Palette.STEEL
		"momentum": return Palette.MOMENTUM
		"void": return Palette.VOID
		"kick": return Palette.KICK
		"flow": return Palette.FLOW
		"win": return Palette.WIN
		"verdance": return Palette.VERDANCE
		"sap": return Palette.SAP
		"thorn": return Palette.THORN
		"crimson": return Palette.CRIMSON
		"relic": return Palette.RELIC
		"venombrew": return Palette.VENOM_BREW
		"rotbrew": return Palette.ROT_BREW
		"react": return Palette.REACT
		_: return Palette.GOLD

# ---- veil + entrance ----
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.62 * clampf(_t / 0.16, 0.0, 1.0)))

func _process(delta: float) -> void:
	if _t < 0.3:
		_t += delta
		var e := clampf(_t / 0.16, 0.0, 1.0)
		e = 1.0 - (1.0 - e) * (1.0 - e)
		if _card != null:
			_card.modulate.a = e
			_card.scale = Vector2.ONE * (0.985 + 0.015 * e)
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	# a click on the dark veil (not the card) resumes — same idiom as the Grimoire
	if event is InputEventMouseButton and event.pressed:
		resumed.emit()

# ============================================================ BUILD
func _ready() -> void:
	# the card: inset from every edge (scales with the 1920x1080 stretch)
	_card = Control.new()
	_card.set_anchors_preset(Control.PRESET_FULL_RECT)
	_card.offset_left = 84
	_card.offset_top = 60
	_card.offset_right = -84
	_card.offset_bottom = -56
	_card.pivot_offset = Vector2(918, 480)
	_card.mouse_filter = Control.MOUSE_FILTER_STOP     # clicks on the card don't resume
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.043, 0.037, 0.066, 0.985)
	panel.set_corner_radius_all(14)
	panel.border_color = _accent.lerp(Palette.GOLD, 0.4)
	panel.set_border_width_all(2)
	panel.shadow_color = Color(0, 0, 0, 0.6)
	panel.shadow_size = 24
	var bg := Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_theme_stylebox_override("panel", panel)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(bg)
	add_child(_card)

	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.offset_left = 26
	root.offset_top = 20
	root.offset_right = -26
	root.offset_bottom = -18
	root.add_theme_constant_override("separation", 10)
	_card.add_child(root)

	_build_header(root)
	if _codex.is_empty():
		var none := Label.new()
		none.text = "No class guide authored for '%s' yet." % _class_id
		none.add_theme_color_override("font_color", Palette.TEXT_DIM)
		root.add_child(none)
		return
	_build_body(root)

# ---- header: PAUSED · class · build · Resume / Quit ----
func _build_header(root: VBoxContainer) -> void:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 16)
	root.add_child(bar)

	var titlecol := VBoxContainer.new()
	titlecol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titlecol.add_theme_constant_override("separation", 0)
	bar.add_child(titlecol)
	var paused := Label.new()
	paused.text = "PAUSED"
	paused.add_theme_font_override("font", UiKit.title(900))
	paused.add_theme_font_size_override("font_size", 34)
	paused.add_theme_color_override("font_color", Palette.GOLD_BRIGHT)
	titlecol.add_child(paused)
	var sub := Label.new()
	sub.text = ("The fight is frozen — read up, then resume." if _frozen
		else "Online: the fight keeps running while you read.")
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", Palette.TEXT_DIM)
	titlecol.add_child(sub)

	# CLASS · role · current build
	var idcol := VBoxContainer.new()
	idcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	idcol.alignment = BoxContainer.ALIGNMENT_CENTER
	idcol.add_theme_constant_override("separation", 1)
	bar.add_child(idcol)
	var cname := Label.new()
	cname.text = String(_codex.get("name", "")) + "   ·   " + _aspect.to_upper()
	cname.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cname.add_theme_font_override("font", UiKit.display(750, 2))
	cname.add_theme_font_size_override("font_size", 22)
	cname.add_theme_color_override("font_color", _accent)
	idcol.add_child(cname)
	var role := Label.new()
	var bl := "%d boon%s drafted" % [_boons.size(), "" if _boons.size() == 1 else "s"]
	role.text = "%s   ·   %s" % [String(_codex.get("role", "")), bl]
	role.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role.add_theme_font_size_override("font_size", 12)
	role.add_theme_color_override("font_color", Palette.TEXT_DIM)
	idcol.add_child(role)

	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 10)
	btns.alignment = BoxContainer.ALIGNMENT_END
	bar.add_child(btns)
	var resume := Button.new()
	resume.text = "▶ RESUME  (Esc)"
	resume.custom_minimum_size = Vector2(180, 46)
	resume.pressed.connect(func(): resumed.emit())
	btns.add_child(resume)
	var quit := Button.new()
	quit.text = "QUIT TO MENU"
	quit.custom_minimum_size = Vector2(150, 46)
	quit.add_theme_color_override("font_color", Palette.LOSE)
	quit.pressed.connect(func(): quit_to_menu.emit())
	btns.add_child(quit)

	root.add_child(_rule())

# ---- body: two columns + full-width branches, all in one scroll ----
func _build_body(root: VBoxContainer) -> void:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	scroll.add_child(content)

	var cols := HBoxContainer.new()
	cols.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_theme_constant_override("separation", 30)
	content.add_child(cols)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.0
	left.add_theme_constant_override("separation", 14)
	cols.add_child(left)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_stretch_ratio = 1.05
	right.add_theme_constant_override("separation", 14)
	cols.add_child(right)

	# LEFT — what am I
	var loop := _section(left, "CORE LOOP")
	_para(loop, String(_codex.get("verb", "")), _accent, 14, true)
	_para(loop, String(_codex.get("fantasy", "")))
	var bars := _section(left, "YOUR BARS")
	for r in _codex.get("resources", []):
		_bar_row(bars, r)
	if String(_codex.get("gear", "")) != "":
		var gear := _section(left, "GEAR · CURIOS")
		_para(gear, String(_codex["gear"]))

	# RIGHT — what do I press
	var d: Dictionary = _codex.get("defense", {})
	var moves := _section(right, "YOUR MOVES")
	if not d.is_empty():
		_move_row(moves, {"name": String(d.get("name", "")), "key": String(d.get("key", "")),
			"cost": "the defensive verb", "body": String(d.get("body", ""))}, Palette.STEEL)
	for m in _codex.get("moves", []):
		var tag := String(m.get("tag", ""))
		if tag == "" or tag == _aspect:
			_move_row(moves, m, _accent)
	var asp := ClassCodex.aspect_of(_class_id, _aspect)
	if not asp.is_empty():
		var rot := _section(right, "GOAL ROTATION — %s" % String(asp.get("name", "")))
		_para(rot, String(asp.get("tagline", "")), _color(String(asp.get("tint", "gold"))), 14, true)
		var steps: Array = asp.get("rotation", [])
		for i in steps.size():
			_step(rot, i + 1, String(steps[i]))

	# FULL WIDTH — the branches
	var br := _section(content, "THE BRANCHES — the two sub-classes + their build lanes")
	var lane := HBoxContainer.new()
	lane.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lane.add_theme_constant_override("separation", 26)
	br.add_child(lane)
	for a in _codex.get("aspects", []):
		_aspect_card(lane, a)

# ============================================================ builders
func _section(parent: Node, title: String) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 5)
	var h := Label.new()
	h.text = title
	h.add_theme_font_override("font", UiKit.display(650, 2))
	h.add_theme_font_size_override("font_size", 15)
	h.add_theme_color_override("font_color", Palette.GOLD)
	box.add_child(h)
	box.add_child(_rule(Palette.GOLD_DIM))
	parent.add_child(box)
	return box

func _rule(col: Color = Palette.GOLD) -> Control:
	var r := ColorRect.new()
	r.color = Color(col.r, col.g, col.b, 0.4)
	r.custom_minimum_size = Vector2(0, 1)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r

func _para(parent: Node, text: String, col: Color = Palette.TEXT, sz: int = 13, emph: bool = false) -> void:
	if text == "":
		return
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	if emph:
		l.add_theme_font_override("font", UiKit.body(600))
	parent.add_child(l)

func _step(parent: Node, n: int, text: String) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 8)
	var num := Label.new()
	num.text = str(n)
	num.custom_minimum_size = Vector2(20, 0)
	num.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	num.add_theme_font_override("font", UiKit.display(700))
	num.add_theme_font_size_override("font_size", 14)
	num.add_theme_color_override("font_color", _accent)
	row.add_child(num)
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", Palette.TEXT)
	row.add_child(l)
	parent.add_child(row)

func _bar_row(parent: Node, r: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 9)
	var tint := _color(String(r.get("tint", "gold")))
	var dot := _dot(tint)
	row.add_child(dot)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 0)
	row.add_child(col)
	var nm := Label.new()
	nm.text = String(r.get("name", ""))
	nm.add_theme_font_override("font", UiKit.display(650, 1))
	nm.add_theme_font_size_override("font_size", 14)
	nm.add_theme_color_override("font_color", tint.lightened(0.15))
	col.add_child(nm)
	_para(col, String(r.get("body", "")), Palette.TEXT_DIM)
	parent.add_child(row)

func _move_row(parent: Node, m: Dictionary, accent: Color) -> void:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 0)
	var head := HBoxContainer.new()
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_theme_constant_override("separation", 8)
	var key := Label.new()
	key.text = "[ %s ]" % String(m.get("key", ""))
	key.add_theme_font_override("font", UiKit.display(650))
	key.add_theme_font_size_override("font_size", 12)
	key.add_theme_color_override("font_color", Palette.GOLD_BRIGHT)
	head.add_child(key)
	var nm := Label.new()
	nm.text = String(m.get("name", ""))
	nm.add_theme_font_override("font", UiKit.display(650, 1))
	nm.add_theme_font_size_override("font_size", 14)
	nm.add_theme_color_override("font_color", accent.lightened(0.2))
	head.add_child(nm)
	var cost := Label.new()
	cost.text = String(m.get("cost", ""))
	cost.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cost.add_theme_font_size_override("font_size", 11)
	cost.add_theme_color_override("font_color", Palette.GOLD_DIM.lightened(0.3))
	head.add_child(cost)
	col.add_child(head)
	_para(col, String(m.get("body", "")), Palette.TEXT_DIM)
	parent.add_child(col)

func _aspect_card(parent: Node, a: Dictionary) -> void:
	var mine := String(a.get("id", "")) == _aspect
	var tint := _color(String(a.get("tint", "gold")))
	var card := VBoxContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_stretch_ratio = 1.0
	card.add_theme_constant_override("separation", 6)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(tint.r, tint.g, tint.b, 0.05 if mine else 0.02)
	sb.set_corner_radius_all(10)
	sb.border_color = tint if mine else Palette.EDGE
	sb.set_border_width_all(2 if mine else 1)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	var pc := PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pc.add_theme_stylebox_override("panel", sb)
	pc.add_child(card)
	parent.add_child(pc)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	var nm := Label.new()
	nm.text = String(a.get("name", ""))
	nm.add_theme_font_override("font", UiKit.display(750, 2))
	nm.add_theme_font_size_override("font_size", 18)
	nm.add_theme_color_override("font_color", tint.lightened(0.2))
	head.add_child(nm)
	if mine:
		var you := Label.new()
		you.text = "◂ YOU"
		you.add_theme_font_override("font", UiKit.display(700, 1))
		you.add_theme_font_size_override("font_size", 12)
		you.add_theme_color_override("font_color", Palette.GOLD_BRIGHT)
		head.add_child(you)
	card.add_child(head)
	_para(card, String(a.get("tagline", "")), tint.lightened(0.1), 13, true)
	_para(card, String(a.get("identity", "")), Palette.TEXT)
	_para(card, String(a.get("bar", "")), Palette.TEXT_DIM)

	var sub := Label.new()
	sub.text = "BUILD LANES"
	sub.add_theme_font_override("font", UiKit.display(650, 2))
	sub.add_theme_font_size_override("font_size", 12)
	sub.add_theme_color_override("font_color", Palette.GOLD_DIM.lightened(0.3))
	card.add_child(sub)
	for b in a.get("branches", []):
		_branch(card, b, tint)

func _branch(parent: Node, b: Dictionary, tint: Color) -> void:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 0)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	var nm := Label.new()
	nm.text = "› " + String(b.get("name", ""))
	nm.add_theme_font_override("font", UiKit.display(650, 1))
	nm.add_theme_font_size_override("font_size", 13)
	nm.add_theme_color_override("font_color", tint.lightened(0.25))
	head.add_child(nm)
	col.add_child(head)
	var via := Label.new()
	via.text = String(b.get("via", ""))
	via.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	via.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	via.add_theme_font_size_override("font_size", 11)
	via.add_theme_color_override("font_color", Palette.RELIC.lightened(0.1))
	col.add_child(via)
	_para(col, String(b.get("body", "")), Palette.TEXT_DIM, 12)
	parent.add_child(col)

func _dot(col: Color) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(14, 22)
	c.draw.connect(func():
		c.draw_circle(Vector2(7, 8), 5.0, col)
		c.draw_circle(Vector2(5.5, 6.5), 1.6, Color(1, 1, 1, 0.7)))
	return c
