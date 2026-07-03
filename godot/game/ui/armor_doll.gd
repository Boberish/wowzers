## ARMORY — "YOUR SET": the run-armor paper doll. A PRESENTATION layer only —
## boons stay boons (Draft 2.0 stacking untouched); each drafted boon renders as a
## PIECE forged into one of five armor slots (ArmorSlots.slot_of), and the two curio
## equip slots render as TRINKET sockets. A slot's frame glows with its family's
## best rarity and shows its piece count. ARMORY-UI: hovering a socket raises a
## gilded stat card (every piece's effect line); clicking any socket emits
## `inspect_requested` — the HUD opens the full ArmorModal. Feed it with
## set_build() whenever the run's boons/curios change.
class_name ArmorDoll
extends Control

signal inspect_requested

## the "click to inspect" caption — the modal's own doll hides it
var show_hint := true

const W := 236.0
const H := 332.0

## socket centers on the doll (helm crown / weapon hand / cuirass heart /
## gauntlet hand / greaves feet / trinkets on the belt row)
const SPOTS := {
	"helm": Vector2(118, 46),
	"weapon": Vector2(40, 138),
	"cuirass": Vector2(118, 140),
	"gauntlets": Vector2(196, 138),
	"greaves": Vector2(118, 226),
}
const TRINKET_SPOTS := [Vector2(72, 296), Vector2(164, 296)]
const R_ARMOR := 27.0
const R_TRINKET := 21.0

var _sockets := {}          ## slot -> _Socket
var _trinkets: Array = []   ## [_Socket, _Socket]

func _ready() -> void:
	custom_minimum_size = Vector2(W, H)
	mouse_filter = Control.MOUSE_FILTER_IGNORE   # only the sockets catch hover (tooltips)
	for slot in ArmorSlots.ORDER:
		var sk := _Socket.new()
		sk.kind = slot
		sk.radius = R_ARMOR
		_place_socket(sk, SPOTS[slot], R_ARMOR)
		_sockets[slot] = sk
	for i in 2:
		var tk := _Socket.new()
		tk.kind = "trinket"
		tk.radius = R_TRINKET
		_place_socket(tk, TRINKET_SPOTS[i], R_TRINKET)
		_trinkets.append(tk)

func _place_socket(sk: _Socket, at: Vector2, r: float) -> void:
	sk.position = at - Vector2(r + 6, r + 6)
	sk.custom_minimum_size = Vector2((r + 6) * 2, (r + 6) * 2)
	sk.size = sk.custom_minimum_size
	sk.mouse_filter = Control.MOUSE_FILTER_STOP     # hover cards + click-to-inspect
	sk.clicked.connect(func(): inspect_requested.emit())
	add_child(sk)

## The one feed: the run's drafted boons + equipped curio ids (+ active charges).
func set_build(taken_boons: Array, gear_ids: Array, gear_charges: Dictionary = {}) -> void:
	var sum := ArmorSlots.summarize(taken_boons)
	for slot in ArmorSlots.ORDER:
		var e: Dictionary = sum[slot]
		var sk: _Socket = _sockets[slot]
		sk.count = int(e["count"])
		sk.best = String(e["best"])
		sk.data = {"kind": "slot", "name": ArmorSlots.pretty(slot), "count": sk.count,
			"best": sk.best, "pieces": e["pieces"]}
		sk.tooltip_text = " "   # non-empty → _make_custom_tooltip fires
		sk.queue_redraw()
	for i in 2:
		var tk: _Socket = _trinkets[i]
		if i < gear_ids.size():
			var id := String(gear_ids[i])
			var it := GearCatalog.item(id)
			tk.count = 1
			tk.best = String(it.get("rarity", "haiku"))
			tk.data = {"kind": "trinket", "name": String(it.get("name", id)),
				"rarity": tk.best, "desc": String(it.get("desc", "")),
				"flavor": String(it.get("flavor", "")),
				"charges": int(gear_charges.get(id, -1)),
				"scrap": GearCatalog.scrap_value(id)}
		else:
			tk.count = 0
			tk.best = ""
			tk.data = {"kind": "trinket", "name": "", "rarity": "", "desc": "",
				"flavor": "", "charges": -1, "scrap": 0}
		tk.tooltip_text = " "
		tk.queue_redraw()
	queue_redraw()

## Faint body silhouette behind the sockets, so the sockets read as a FIGURE.
func _draw() -> void:
	UiKit.engraved_plaque(self, Vector2(W * 0.5, 10), "YOUR SET", true)
	if show_hint:
		UiKit.text_shadowed(self, UiKit.display(500, 2), Vector2(0, 27), "· CLICK TO INSPECT ·",
			HORIZONTAL_ALIGNMENT_CENTER, W, 8, Color(Palette.TEXT_DIM, 0.8))
	var sil := Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.20)
	var cx := W * 0.5
	draw_arc(Vector2(cx, 46), 16.0, 0.0, TAU, 24, sil, 1.5, true)               # head
	draw_line(Vector2(cx, 66), Vector2(cx, 196), sil, 1.5, true)                # spine
	draw_line(Vector2(cx - 52, 106), Vector2(cx + 52, 106), sil, 1.5, true)     # shoulders
	draw_line(Vector2(cx - 52, 106), Vector2(SPOTS["weapon"].x, 128), sil, 1.5, true)
	draw_line(Vector2(cx + 52, 106), Vector2(SPOTS["gauntlets"].x, 128), sil, 1.5, true)
	draw_line(Vector2(cx, 196), Vector2(cx - 26, 250), sil, 1.5, true)          # legs
	draw_line(Vector2(cx, 196), Vector2(cx + 26, 250), sil, 1.5, true)
	draw_line(Vector2(46, 296), Vector2(W - 46, 296), Color(sil, 0.6), 1.0, true)   # belt row

## One armor/trinket socket: dark well + rarity ring + engraved glyph + count.
## ARMORY-UI: hover raises a gilded stat card (custom tooltip); click = inspect.
class _Socket:
	extends Control
	signal clicked
	var kind := "helm"
	var radius := 27.0
	var count := 0
	var best := ""
	var data := {}          ## structured hover payload (set_build fills it)
	var _hovered := false

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed \
				and event.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit()
			accept_event()

	func _notification(what: int) -> void:
		if what == NOTIFICATION_MOUSE_ENTER:
			_hovered = true
			queue_redraw()
		elif what == NOTIFICATION_MOUSE_EXIT:
			_hovered = false
			queue_redraw()

	## The rich hover card: slot name + count header, then every piece's title
	## (rarity-colored) with its effect line; trinkets show effect/flavor/charges.
	## Rides the theme's gilded TooltipPanel chip (UiKit.build_theme).
	func _make_custom_tooltip(_for_text: String) -> Object:
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 4)
		box.custom_minimum_size = Vector2(280, 0)
		if String(data.get("kind", "")) == "trinket":
			_tip_trinket(box)
		else:
			_tip_slot(box)
		return box

	func _tip_slot(box: VBoxContainer) -> void:
		var n := int(data.get("count", 0))
		_tip_header(box, String(data.get("name", "")),
			"%d PIECE%s" % [n, "" if n == 1 else "S"] if n > 0 else "EMPTY",
			Palette.rarity_color(String(data.get("best", ""))) if n > 0 else Palette.TEXT_DIM)
		if n == 0:
			_tip_line(box, "The draft forges pieces into this slot.", Palette.TEXT_DIM, true)
			return
		for p in data.get("pieces", []):
			var pd: Dictionary = p
			_tip_line(box, String(pd["title"]), Palette.rarity_color(String(pd["rarity"])), false)
			if String(pd.get("desc", "")) != "":
				_tip_line(box, String(pd["desc"]), Palette.TEXT, true)

	func _tip_trinket(box: VBoxContainer) -> void:
		if String(data.get("name", "")) == "":
			_tip_header(box, "TRINKET", "EMPTY SOCKET", Palette.TEXT_DIM)
			_tip_line(box, "Boss drops socket here — Seals, gates, first kills.",
				Palette.TEXT_DIM, true)
			return
		var rar := String(data.get("rarity", "haiku"))
		_tip_header(box, String(data["name"]), rar.to_upper() + " · CURIO",
			Palette.rarity_color(rar))
		_tip_line(box, String(data.get("desc", "")), Palette.TEXT, true)
		if String(data.get("flavor", "")) != "":
			_tip_line(box, "\"%s\"" % String(data["flavor"]), Palette.TEXT_DIM, true)
		if int(data.get("charges", -1)) >= 0:
			_tip_line(box, "CHARGES LEFT · %d" % int(data["charges"]), Palette.GOLD, false)
		_tip_line(box, "scrap value · %d⏣" % int(data.get("scrap", 0)), Palette.GOLD_DIM, false)

	func _tip_header(box: VBoxContainer, title: String, sub: String, col: Color) -> void:
		var t := Label.new()
		t.text = title
		t.add_theme_font_override("font", UiKit.display(700, 1))
		t.add_theme_font_size_override("font_size", 15)
		t.add_theme_color_override("font_color", Palette.GOLD.lerp(Palette.GOLD_BRIGHT, 0.4))
		box.add_child(t)
		var s := Label.new()
		s.text = sub
		s.add_theme_font_override("font", UiKit.display(600, 3))
		s.add_theme_font_size_override("font_size", 10)
		s.add_theme_color_override("font_color", col)
		box.add_child(s)
		var rule := ColorRect.new()
		rule.color = Color(Palette.GOLD_DIM, 0.55)
		rule.custom_minimum_size = Vector2(0, 1)
		box.add_child(rule)

	func _tip_line(box: VBoxContainer, s: String, col: Color, wrap: bool) -> void:
		var l := Label.new()
		l.text = s
		l.add_theme_color_override("font_color", col)
		l.add_theme_font_size_override("font_size", 12)
		if wrap:
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.custom_minimum_size = Vector2(280, 0)
		box.add_child(l)

	func _draw() -> void:
		var c := size * 0.5
		var lit := count > 0
		var rar := Palette.rarity_color(best) if lit else Palette.EDGE
		# recessed well + rarity glow (+ hover lift)
		draw_circle(c, radius, Color(Palette.BG1.r, Palette.BG1.g, Palette.BG1.b, 0.92))
		if lit:
			draw_circle(c, radius + 4.0, Color(rar.r, rar.g, rar.b, 0.10))
		if _hovered:
			draw_circle(c, radius + 6.0, Color(Palette.GOLD_BRIGHT, 0.07))
			draw_arc(c, radius + 5.0, 0.0, TAU, 40, Color(Palette.GOLD_BRIGHT, 0.65), 1.4, true)
		draw_arc(c, radius, 0.0, TAU, 40, rar if lit else Color(rar, 0.8),
			2.2 if lit else 1.2, true)
		if lit:
			UiKit.gilded_ring(self, c, radius + 2.5, 1.6, 36)
		# glyph: engraved dark metal, warmed by the rarity when lit
		var metal := Color(0.34, 0.33, 0.38) if lit else Color(0.20, 0.20, 0.24)
		var edge := metal.lerp(rar, 0.45) if lit else metal.lightened(0.15)
		_glyph(c, radius * 0.62, metal.lerp(rar, 0.25) if lit else metal, edge)
		# piece count badge, bottom-right of the well
		if count > 0 and kind != "trinket":
			var bc := c + Vector2(radius * 0.78, radius * 0.78)
			draw_circle(bc, 8.5, Palette.BG0)
			draw_arc(bc, 8.5, 0.0, TAU, 20, rar, 1.2, true)
			UiKit.text_shadowed(self, UiKit.body(700), bc + Vector2(-8, 4), "+%d" % count,
				HORIZONTAL_ALIGNMENT_CENTER, 16, 10, Palette.TEXT)
		# slot name under the well
		var nm := ArmorSlots.pretty(kind) if kind != "trinket" else "TRINKET"
		UiKit.text_shadowed(self, UiKit.display(600, 1), Vector2(c.x - 40, c.y + radius + 13),
			nm, HORIZONTAL_ALIGNMENT_CENTER, 80, 8,
			Palette.GOLD if lit else Palette.TEXT_DIM)

	func _glyph(c: Vector2, s: float, fill: Color, edge: Color) -> void:
		match kind:
			"helm":
				# dome + visor slit + crest
				var pts := PackedVector2Array()
				for i in 13:
					var a := PI + PI * float(i) / 12.0
					pts.append(c + Vector2(cos(a), sin(a)) * s + Vector2(0, s * 0.1))
				pts.append(c + Vector2(s, s * 0.55))
				pts.append(c + Vector2(-s, s * 0.55))
				draw_colored_polygon(pts, fill)
				draw_polyline(pts, edge, 1.2, true)
				draw_line(c + Vector2(-s * 0.7, s * 0.18), c + Vector2(s * 0.7, s * 0.18),
					Palette.BG0, 2.5, true)
				draw_line(c + Vector2(0, -s * 1.05), c + Vector2(0, -s * 0.55), edge, 2.0, true)
			"weapon":
				# sword: blade up, crossguard, grip
				var tip := c + Vector2(0, -s * 1.05)
				draw_colored_polygon(PackedVector2Array([
					tip, c + Vector2(s * 0.18, -s * 0.1), c + Vector2(s * 0.18, s * 0.35),
					c + Vector2(-s * 0.18, s * 0.35), c + Vector2(-s * 0.18, -s * 0.1)]), fill)
				draw_line(tip, c + Vector2(0, s * 0.35), Palette.BG0, 1.2, true)   # fuller
				draw_line(c + Vector2(-s * 0.55, s * 0.35), c + Vector2(s * 0.55, s * 0.35),
					edge, 3.0, true)
				draw_line(c + Vector2(0, s * 0.35), c + Vector2(0, s * 0.95), edge, 2.6, true)
				draw_circle(c + Vector2(0, s * 1.0), 2.6, edge)
			"cuirass":
				# breastplate: shouldered torso + center ridge
				var p := PackedVector2Array([
					c + Vector2(-s * 0.95, -s * 0.75), c + Vector2(-s * 0.35, -s * 0.95),
					c + Vector2(s * 0.35, -s * 0.95), c + Vector2(s * 0.95, -s * 0.75),
					c + Vector2(s * 0.7, s * 0.35), c + Vector2(0, s * 0.95),
					c + Vector2(-s * 0.7, s * 0.35)])
				draw_colored_polygon(p, fill)
				draw_polyline(p, edge, 1.2, true)
				draw_line(c + Vector2(0, -s * 0.9), c + Vector2(0, s * 0.9), Palette.BG0, 2.0, true)
				draw_arc(c + Vector2(0, -s * 0.15), s * 0.5, PI * 0.15, PI * 0.85, 12,
					Palette.BG0, 1.4, true)
			"gauntlets":
				# gauntlet: cuff + fist with knuckle grooves
				draw_colored_polygon(PackedVector2Array([
					c + Vector2(-s * 0.85, -s * 0.9), c + Vector2(s * 0.45, -s * 0.9),
					c + Vector2(s * 0.45, -s * 0.4), c + Vector2(-s * 0.85, -s * 0.4)]), fill)
				draw_circle(c + Vector2(-s * 0.1, s * 0.25), s * 0.62, fill)
				draw_arc(c + Vector2(-s * 0.1, s * 0.25), s * 0.62, 0.0, TAU, 26, edge, 1.2, true)
				for k in 3:
					var kx := -s * 0.45 + float(k) * s * 0.36
					draw_line(c + Vector2(kx, -s * 0.05), c + Vector2(kx, s * 0.5),
						Palette.BG0, 1.6, true)
				draw_line(c + Vector2(-s * 0.85, -s * 0.4), c + Vector2(s * 0.45, -s * 0.4),
					edge, 1.4, true)
			"greaves":
				# boot: shin + foot
				var b := PackedVector2Array([
					c + Vector2(-s * 0.4, -s * 0.95), c + Vector2(s * 0.25, -s * 0.95),
					c + Vector2(s * 0.25, s * 0.35), c + Vector2(s * 0.95, s * 0.7),
					c + Vector2(s * 0.95, s * 0.95), c + Vector2(-s * 0.4, s * 0.95)])
				draw_colored_polygon(b, fill)
				draw_polyline(b, edge, 1.2, true)
				draw_line(c + Vector2(-s * 0.4, s * 0.0), c + Vector2(s * 0.25, s * 0.0),
					Palette.BG0, 1.6, true)
				draw_line(c + Vector2(-s * 0.4, -s * 0.5), c + Vector2(s * 0.25, -s * 0.5),
					Palette.BG0, 1.6, true)
			_:
				# trinket: amulet gem on a loop
				draw_arc(c + Vector2(0, -s * 0.55), s * 0.35, 0.0, TAU, 20, edge, 1.6, true)
				var gem := PackedVector2Array([
					c + Vector2(0, -s * 0.25), c + Vector2(s * 0.55, s * 0.15),
					c + Vector2(0, s * 0.75), c + Vector2(-s * 0.55, s * 0.15)])
				draw_colored_polygon(gem, fill)
				draw_polyline(gem, edge, 1.2, true)
				draw_line(c + Vector2(-s * 0.2, 0), c + Vector2(s * 0.1, s * 0.3),
					Color(1, 1, 1, 0.25), 1.2, true)
