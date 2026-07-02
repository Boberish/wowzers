## The shared class-entry "PICK A FIGHT" screen: an Aspect toggle up top and a boss
## list built from the class's run_encounters(), so every class gets the same level
## selector (and new bosses show up automatically). Picking a boss starts the run
## FROM that fight — the run continues onward from there, exactly like the Bulwark's
## original dev picker. Emits chosen(aspect, boss_id); boss_id "" = full run.
##
## Caller idiom (per the UI-OVERHAUL gotchas): set fields, THEN set anchors, THEN
## add_child — the screen renders itself on _ready and re-renders on aspect toggle.
class_name BossSelect
extends Control

signal chosen(aspect: String, boss_id: String)
signal back_pressed

var title := "THE CLASS"
var subtitle := "ROLE — VERB · PICK A FIGHT"
var aspects: Array = []      ## [{id, label, accent: Color, blurb}]
var encounters: Array = []   ## Array of EncounterRes (the class's run order)
var extras: Array = []       ## [{label, cb: Callable}] flat utility buttons (Mouse Bindings...)
var hint := ""               ## optional keybind hint line under the list
var current := ""            ## selected aspect id (defaults to the first)

func _ready() -> void:
	if current == "" and not aspects.is_empty():
		current = String(aspects[0]["id"])
	_render()

func _aspect(id: String) -> Dictionary:
	for a in aspects:
		if String(a["id"]) == id:
			return a
	return {}

func _render() -> void:
	for c in get_children():
		c.queue_free()
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 9)
	center.add_child(box)

	var hd := _label(box, title, 44, Palette.GOLD)
	hd.add_theme_font_override("font", UiKit.title(900))
	var sub := _label(box, subtitle, 14, Palette.TEXT_DIM)
	sub.add_theme_font_override("font", UiKit.display(500, 3))

	if aspects.size() > 1:
		var toggle := HBoxContainer.new()
		toggle.alignment = BoxContainer.ALIGNMENT_CENTER
		toggle.add_theme_constant_override("separation", 12)
		box.add_child(toggle)
		for a in aspects:
			_aspect_toggle(toggle, a)
	var cur := _aspect(current)
	if not cur.is_empty() and String(cur.get("blurb", "")) != "":
		_label(box, "%s  —  pick a boss to jump into (the run continues from there)"
			% String(cur["blurb"]), 13, Palette.TEXT_DIM)
	box.add_child(_gap(6))

	var accent: Color = cur.get("accent", Palette.GOLD)
	for i in encounters.size():
		var e: EncounterRes = encounters[i]
		_pick_button(box, "%d   ·   %s   ·   %d HP" % [i + 1, e.name, e.hp], accent,
			_pick.bind(String(e.id)))
	box.add_child(_gap(8))
	var first := String(encounters[0].name) if not encounters.is_empty() else "the start"
	_pick_button(box, "▶   FULL RUN  (start at %s)" % first, Palette.GOLD, _pick.bind(""))
	for x in extras:
		var b := Button.new()
		b.text = String(x["label"])
		b.flat = true
		b.add_theme_color_override("font_color", Palette.GOLD_DIM)
		b.pressed.connect(x["cb"] as Callable)
		box.add_child(b)
	_pick_button(box, "◂   back to Class menu", Palette.EDGE, func(): back_pressed.emit())
	if hint != "":
		_label(box, hint, 12, Palette.TEXT_DIM)

func _pick(boss_id: String) -> void:
	chosen.emit(current, boss_id)

func _set_aspect(id: String) -> void:
	current = id
	_render()

func _aspect_toggle(parent: Node, a: Dictionary) -> void:
	var on := current == String(a["id"])
	var accent: Color = a.get("accent", Palette.GOLD)
	var b := Button.new()
	b.custom_minimum_size = Vector2(304, 44)
	b.add_theme_font_size_override("font_size", 16)
	b.text = ("● " + String(a["label"])) if on else String(a["label"])
	b.add_theme_color_override("font_color", accent if on else Palette.TEXT_DIM)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.PANEL if on else Palette.BG1
	sb.border_color = accent if on else Palette.EDGE
	sb.set_border_width_all(3 if on else 1)
	sb.set_corner_radius_all(8)
	b.add_theme_stylebox_override("normal", sb)
	b.pressed.connect(_set_aspect.bind(String(a["id"])))
	parent.add_child(b)

func _pick_button(parent: Node, text: String, border: Color, cb: Callable) -> void:
	var b := Button.new()
	b.custom_minimum_size = Vector2(620, 50)
	b.add_theme_font_size_override("font_size", 15)
	b.text = text
	b.add_theme_color_override("font_color", Palette.TEXT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Palette.PANEL
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	b.add_theme_stylebox_override("normal", sb)
	b.pressed.connect(cb)
	parent.add_child(b)

func _label(parent: Node, text: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	parent.add_child(l)
	return l

func _gap(h: float) -> Control:
	var g := Control.new()
	g.custom_minimum_size = Vector2(0, h)
	return g
