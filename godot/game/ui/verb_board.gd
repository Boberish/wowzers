## VerbBoard — the "YOUR RHYTHM" combo board (TEMPO rework / clarity). Draws your assembled
## verb as a plain machine: WHEN (your earned moments) → THEN (all effects fire) → ALWAYS
## (passive rules), plus your run's CREED and equipped MODULES. Renames Trigger/Payload/
## Property to WHEN/THEN/ALWAYS so the build reads as one sentence. Pure view — fed by the HUD.
class_name VerbBoard
extends Control

var creed_name: String = ""
var module_names: Array = []
var whens: Array = []       ## your drafted triggers (earned moments)
var thens: Array = []       ## your drafted payloads (effects)
var alwayses: Array = []    ## your drafted properties (passive rules)
var _pulse: float = 0.0

func _process(delta: float) -> void:
	_pulse += delta
	queue_redraw()

func set_verb(creed: String, mods: Array, w: Array, t: Array, a: Array) -> void:
	creed_name = creed; module_names = mods; whens = w; thens = t; alwayses = a
	queue_redraw()

func _draw() -> void:
	var w := size.x
	var h := size.y

	# ---- panel ----
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(Palette.PANEL.r, Palette.PANEL.g, Palette.PANEL.b, 0.94)
	panel.border_color = Palette.GOLD
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(10)
	panel.shadow_color = Color(0, 0, 0, 0.4); panel.shadow_size = 6
	draw_style_box(panel, Rect2(0, 0, w, h))
	UiKit.filigree_corner(self, Vector2(2, 2), Vector2(1, 1), 10.0)
	UiKit.filigree_corner(self, Vector2(w - 2, 2), Vector2(-1, 1), 10.0)
	UiKit.filigree_corner(self, Vector2(2, h - 2), Vector2(1, -1), 10.0)
	UiKit.filigree_corner(self, Vector2(w - 2, h - 2), Vector2(-1, -1), 10.0)

	var ui := UiKit.body(500)
	var disp := UiKit.display(600, 1)

	# ---- header: title + creed + modules ----
	UiKit.text_shadowed(self, UiKit.display(700, 2), Vector2(14, 24), "YOUR RHYTHM",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Palette.GOLD_BR)
	var hx := 150.0
	if creed_name != "":
		hx = _chip(disp, Vector2(hx, 12), "CREED · " + creed_name, Palette.CRIMSON)
	for m in module_names:
		hx = _chip(disp, Vector2(hx, 12), "MOD · " + String(m), Palette.FLOW)
	draw_line(Vector2(12, 40), Vector2(w - 12, 40), Palette.EDGE, 1.0)

	# ---- empty state ----
	if whens.is_empty() and thens.is_empty():
		UiKit.text_shadowed(self, ui, Vector2(14, h * 0.62),
			"Draft a WHEN (a moment) and a THEN (an effect) to build your combo.",
			HORIZONTAL_ALIGNMENT_LEFT, w - 28, 14, Palette.TEXT_DIM)
		_always_row(ui, w, h)
		return

	# ---- WHEN column | hub | THEN column ----
	var top := 54.0
	var colw := (w - 40.0) * 0.42
	var rx := w - 14.0 - colw
	_col_label(ui, Vector2(14, top), "WHEN — any of these…", Palette.CRIMSON)
	_col_label(ui, Vector2(rx, top), "THEN — fires ALL of these", Palette.GOLD, true, colw)
	var ry := top + 20.0
	var rows_h := h - ry - 34.0
	# WHEN rows
	var wn := maxi(whens.size(), 1)
	for i in whens.size():
		var y := ry + rows_h * (float(i) + 0.5) / float(wn)
		_node(disp, Vector2(14, y - 13), colw, String(whens[i]), Palette.CRIMSON, "")
	# THEN rows
	var tn := maxi(thens.size(), 1)
	for i in thens.size():
		var y2 := ry + rows_h * (float(i) + 0.5) / float(tn)
		_node(disp, Vector2(rx, y2 - 13), colw, String(thens[i]), Palette.GOLD, "▸")
	# converging arrows → hub
	var hub := Vector2(w * 0.5, ry + rows_h * 0.5)
	var glow := 0.5 + 0.5 * sin(_pulse * 2.2)
	for i in whens.size():
		var sy := ry + rows_h * (float(i) + 0.5) / float(wn)
		draw_line(Vector2(14 + colw, sy), hub, Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.5), 1.4, true)
	draw_line(hub, Vector2(rx, hub.y), Color(Palette.GOLD.r, Palette.GOLD.g, Palette.GOLD.b, 0.6), 1.4, true)
	draw_circle(hub, 15.0, Color(Palette.GOLD.r, Palette.GOLD.g, Palette.GOLD.b, 0.14 + 0.12 * glow))
	UiKit.text_shadowed(self, ui, Vector2(hub.x - 14, hub.y + 4), "fires", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Palette.GOLD_BR)

	_always_row(ui, w, h)

func _always_row(ui: Font, w: float, h: float) -> void:
	if alwayses.is_empty():
		return
	draw_line(Vector2(12, h - 28), Vector2(w - 12, h - 28), Palette.EDGE, 1.0)
	UiKit.text_shadowed(self, ui, Vector2(14, h - 9), "ALWAYS · " + " · ".join(alwayses),
		HORIZONTAL_ALIGNMENT_LEFT, w - 28, 13, Palette.FLOW)

func _col_label(f: Font, at: Vector2, s: String, col: Color, right := false, wide := 0.0) -> void:
	var al := HORIZONTAL_ALIGNMENT_RIGHT if right else HORIZONTAL_ALIGNMENT_LEFT
	UiKit.text_shadowed(self, f, at, s, al, wide if right else -1, 12, col)

func _node(f: Font, at: Vector2, ww: float, label: String, col: Color, arrow: String) -> void:
	var box := StyleBoxFlat.new()
	box.bg_color = Color(Palette.PANEL.r, Palette.PANEL.g, Palette.PANEL.b, 0.9)
	box.border_color = Color(col.r, col.g, col.b, 0.5)
	box.set_border_width_all(1); box.set_corner_radius_all(8)
	draw_style_box(box, Rect2(at.x, at.y, ww, 26))
	var tx := at.x + 10.0
	UiKit.text_shadowed(self, f, Vector2(tx, at.y + 17), (arrow + " " if arrow != "" else "") + label,
		HORIZONTAL_ALIGNMENT_LEFT, ww - 16, 14, Palette.TEXT)

func _chip(f: Font, at: Vector2, s: String, col: Color) -> float:
	var tw := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x + 16.0
	var box := StyleBoxFlat.new()
	box.bg_color = Color(col.r, col.g, col.b, 0.12)
	box.border_color = Color(col.r, col.g, col.b, 0.55)
	box.set_border_width_all(1); box.set_corner_radius_all(6)
	draw_style_box(box, Rect2(at.x, at.y, tw, 20))
	UiKit.text_shadowed(self, f, Vector2(at.x + 8, at.y + 14), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)
	return at.x + tw + 8.0
