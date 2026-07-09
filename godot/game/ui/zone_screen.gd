## ZoneScreen — a persistent-conquest ZONE rendered as an overworld map (WORLD-PLAN W1).
## Deliberately NOT the Topology's circuit board: this is the earnest world — worn roads,
## wax-seal waypoints, fog that lifts FOREVER as the warband conquers. Conquered ground
## is free travel; the frontier glows; silhouettes loom one step past it.
##
## Caller idiom (UI-OVERHAUL): set fields, THEN anchors, THEN add_child.
##   zone (WorldContent.zone dict) / save (WorldSave) / toast
## Emits node_entered(id) for BOTH frontier pushes and free travel onto cleared ground
## (the HUD decides which it was); back_requested() = return to the Atlas.
class_name ZoneScreen
extends Control

signal node_entered(id: int)
signal back_requested()

var zone: Dictionary
var save: WorldSave
var toast := ""

var _vis: Dictionary = {}
var _front: Array = []
var _hover := -1
var _pulse := 0.0

const R_NODE := 24.0

# NOTE: const can't hold Palette statics (UI-OVERHAUL gotcha) — static var it is
static var KIND_COL := {
	"fight": Palette.CRIMSON, "elite": Palette.RAGE, "boss": Palette.CRUSH,
	"event": Palette.VOID, "choice": Palette.REACT,
	"camp": Palette.FLOW, "cache": Palette.GOLD, "waystation": Palette.WIN,
	"door": Palette.RELIC,
}
const KIND_GLYPH := {
	"fight": "X", "elite": "*", "boss": "!", "event": "?",
	"choice": "%", "camp": "~", "cache": "+", "waystation": "^", "door": "#",
}
const KIND_TAG := {
	"fight": "FIGHT", "elite": "ELITE", "boss": "THE CAPSTONE",
	"event": "EVENT", "choice": "A CHOICE — the zone remembers", "camp": "CAMP", "cache": "CACHE",
	"waystation": "WAYSTATION", "door": "INSTANCE DOOR",
}

func _ready() -> void:
	_vis = WorldContent.visibility(zone, save)
	_front = WorldContent.frontier(zone, save)
	_build_header()
	_build_buttons()
	queue_redraw()

func _process(delta: float) -> void:
	_pulse += delta * 2.2
	queue_redraw()

func _node(id: int) -> Dictionary:
	return WorldContent.resolved_node(zone, id, save.flags(String(zone["id"])))

# ============================================================ chrome
func _build_header() -> void:
	var zid := String(zone["id"])
	_label(String(zone["name"]), 38, Palette.GOLD, Vector2(0, 88), UiKit.title(900))
	_label(String(zone["sub"]), 13, Palette.TEXT_DIM, Vector2(0, 142), UiKit.display(500, 3))
	var total: int = (zone["nodes"] as Array).size()
	var status := "CONQUEST  %d / %d  —  cleared ground is yours FOREVER" \
		% [save.cleared_count(zid), total]
	if WorldContent.zone_conquered(zone, save):
		status = "ZONE CLEARED  —  " + status
	_label(status, 15, Palette.GOLD_BRIGHT if WorldContent.zone_conquered(zone, save) else Palette.TEXT,
		Vector2(0, 164), UiKit.display(600, 2))
	if save.has_waystation(zid):
		_label("FLIGHT PATH: GILDWATCH BEACON — the sky roads know this zone", 12, Palette.WIN,
			Vector2(0, 188), UiKit.display(500, 2))
	if toast != "":
		_label(toast, 15, Palette.GOLD_BRIGHT, Vector2(0, 214), UiKit.title(600))
	_label("push the FRONTIER (lit rings) · travel conquered ground freely · the fog never returns",
		12, Palette.TEXT_DIM, Vector2(0, 884), UiKit.body())
	_label("X FIGHT   ·   * ELITE   ·   ! CAPSTONE   ·   ? EVENT   ·   % CHOICE   ·   ~ CAMP   ·   + CACHE   ·   ^ WAYSTATION   ·   # DOOR   ·   1 GATE",
		11, Palette.GOLD_DIM, Vector2(0, 914), UiKit.display(500, 2))
	var back := Button.new()
	back.text = "◂  THE ATLAS"
	back.flat = true
	back.add_theme_color_override("font_color", Palette.TEXT_DIM)
	back.pressed.connect(func(): back_requested.emit())
	back.set_anchors_preset(Control.PRESET_TOP_LEFT)
	back.position = Vector2(28, 24)
	back.custom_minimum_size = Vector2(150, 36)
	add_child(back)

func _label(text: String, fs: int, col: Color, at: Vector2, font: Font) -> void:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	l.add_theme_font_override("font", font)
	l.set_anchors_preset(Control.PRESET_TOP_WIDE)
	l.position = at
	add_child(l)

func _build_buttons() -> void:
	var zid := String(zone["id"])
	var at := save.at_node(zid)
	for n in (zone["nodes"] as Array):
		var id := int(n["id"])
		if int(_vis.get(id, 0)) != 2 or id == at:
			continue    # clickable = known ground (frontier push or free travel), not where we stand
		var rn := _node(id)
		var b := Button.new()
		b.flat = true
		b.custom_minimum_size = Vector2(R_NODE * 2.8, R_NODE * 2.8)
		b.position = (rn["pos"] as Vector2) - Vector2(R_NODE * 1.4, R_NODE * 1.4)
		var tag := String(KIND_TAG.get(String(rn["kind"]), "")) if _front.has(id) else "conquered — free travel"
		b.tooltip_text = "%s — %s" % [String(rn["name"]), tag]
		b.mouse_entered.connect(func():
			_hover = id
			queue_redraw())
		b.mouse_exited.connect(func():
			_hover = -1
			queue_redraw())
		b.pressed.connect(func(): node_entered.emit(id))
		add_child(b)

# ============================================================ the land
func _draw() -> void:
	# the land under the fog: a deep field-dark, warmer than the Topology's void
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.035, 0.03, 0.02, 0.78))
	var zid := String(zone["id"])
	var fnt := UiKit.display(600, 1)
	var body := UiKit.body()
	# ---- fog lifts around known ground: layered soft halos (permanence made visible)
	for n in (zone["nodes"] as Array):
		var id := int(n["id"])
		if int(_vis.get(id, 0)) == 2:
			var p: Vector2 = n["pos"]
			for i in 4:
				var rr := 130.0 - 26.0 * float(i)
				draw_circle(p, rr, Color(0.10, 0.085, 0.05, 0.05 + 0.012 * float(i)))
	# ---- worn roads between known nodes; silhouette edges fade into the fog
	for n in (zone["nodes"] as Array):
		var a_id := int(n["id"])
		var va := int(_vis.get(a_id, 0))
		if va == 0:
			continue
		for e in (n["edges"] as Array):
			var b_id := int(e)
			if b_id < a_id:
				continue    # each undirected edge once
			var vb := int(_vis.get(b_id, 0))
			if vb == 0:
				continue
			var a: Vector2 = n["pos"]
			var b: Vector2 = ((zone["nodes"] as Array)[b_id] as Dictionary)["pos"]
			var known := va == 2 and vb == 2
			var col := Color(Palette.GOLD_DIM, 0.55 if known else 0.16)
			_road(a, b, col, 2.2 if known else 1.4)
	# ---- the waypoints
	var at := save.at_node(zid)
	for n in (zone["nodes"] as Array):
		var id := int(n["id"])
		var v := int(_vis.get(id, 0))
		if v == 0:
			continue
		var rn := _node(id)
		var p: Vector2 = rn["pos"]
		var kind := String(rn["kind"])
		if v == 1:
			# a shape in the fog: dark seal, nameless
			draw_circle(p, R_NODE * 0.85, Color(0.05, 0.045, 0.035, 0.9))
			draw_arc(p, R_NODE * 0.85, 0, TAU, 32, Color(Palette.EDGE, 0.5), 1.5)
			draw_string(fnt, p + Vector2(-20, 7), "?", HORIZONTAL_ALIGNMENT_CENTER, 40, 18,
				Color(Palette.TEXT_DIM, 0.5))
			draw_string(body, p + Vector2(-90, R_NODE + 22), "· · ·",
				HORIZONTAL_ALIGNMENT_CENTER, 180, 12, Color(Palette.TEXT_DIM, 0.45))
			continue
		var cleared := save.is_cleared(zid, id)
		var col: Color = KIND_COL.get(kind, Palette.GOLD)
		var is_front := _front.has(id)
		var r := R_NODE * (1.4 if kind == "boss" else (1.15 if kind == "door" or kind == "waystation" else 1.0))
		# conquered ground settles: dim seal + gold etching. The frontier BREATHES.
		draw_circle(p, r + 5.0, Color(Palette.EDGE, 0.9))
		draw_circle(p, r, Color(col, 0.30 if cleared else 0.85))
		if id == at:
			draw_arc(p, r + 10.0, 0, TAU, 44, Palette.GOLD_BRIGHT, 2.6)
		if cleared:
			draw_arc(p, r + 3.0, 0, TAU, 40, Color(Palette.GOLD_DIM, 0.65), 1.4)
		elif is_front:
			var breathe := 0.55 + 0.35 * (0.5 + 0.5 * sin(_pulse + float(id)))
			var glow := Palette.GOLD_BRIGHT if _hover == id else Palette.GOLD
			draw_arc(p, r + 8.0 + 1.5 * sin(_pulse + float(id)), 0, TAU, 44, Color(glow, breathe), 2.2)
		var glyph := String(KIND_GLYPH.get(kind, "·"))
		draw_string(fnt, p + Vector2(-20, 7), glyph, HORIZONTAL_ALIGNMENT_CENTER, 40, 19,
			Color(Palette.BG0, 0.95) if not cleared else Color(Palette.BG0, 0.7))
		var name_col := Palette.TEXT if (is_front or id == at) else Palette.TEXT_DIM
		draw_string(body, p + Vector2(-110, r + 22), String(rn["name"]),
			HORIZONTAL_ALIGNMENT_CENTER, 220, 12, name_col)
		if is_front and _hover == id:
			draw_string(body, p + Vector2(-150, r + 38), String(rn["sub"]),
				HORIZONTAL_ALIGNMENT_CENTER, 300, 10, Color(Palette.TEXT_DIM, 0.9))
	# ---- the warband token: a gold standard where you stand
	if at >= 0:
		var hp: Vector2 = (_node(at)["pos"] as Vector2) + Vector2(0, -R_NODE - 22.0)
		var pts := PackedVector2Array([hp + Vector2(0, -12), hp + Vector2(9, 0), hp + Vector2(0, 12), hp + Vector2(-9, 0)])
		draw_colored_polygon(pts, Palette.GOLD_BRIGHT)
		draw_polyline(pts + PackedVector2Array([pts[0]]), Color(Palette.BG0, 0.8), 1.5, true)
		draw_string(fnt, hp + Vector2(-60, -20), "YOUR WARBAND", HORIZONTAL_ALIGNMENT_CENTER, 120, 10, Palette.GOLD_BRIGHT)

## A worn road: gentle curve (perpendicular sag), drawn as short strokes — cart-track,
## not copper trace.
func _road(a: Vector2, b: Vector2, col: Color, w: float) -> void:
	var mid := (a + b) * 0.5
	var d := (b - a)
	var perp := Vector2(-d.y, d.x).normalized() * minf(26.0, d.length() * 0.10)
	var c := mid + perp * (1.0 if int(a.x + b.y) % 2 == 0 else -1.0)
	var prev := a
	var segs := 14
	for i in range(1, segs + 1):
		var t := float(i) / float(segs)
		var q := a.lerp(c, t).lerp(c.lerp(b, t), t)
		if i % 2 == 1:      # dashed strokes read as a worn track
			draw_line(prev, q, col, w, true)
		prev = q
