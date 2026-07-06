## AtlasScreen — THE ATLAS, the world map (WORLD-PLAN W1): the game's geography as a
## menu. Region pins: the hometown, conquerable zones (with live conquest counts),
## instance doors, and fog silhouettes of what's not yet charted. Flight lines join
## unlocked waystations. This screen becomes the front door at W3; in W1 it hangs off
## THE WORLD entry on the home menu.
##
## Caller idiom: set fields, THEN anchors, THEN add_child.
##   save (WorldSave) / at_pin (where the warband token stands)
## Emits pin_entered(id); back_requested() = home menu.
class_name AtlasScreen
extends Control

signal pin_entered(id: String)
signal back_requested()

var save: WorldSave
var at_pin := "bastion"

var _hover := ""
var _pulse := 0.0

const R_PIN := 34.0

static var KIND_COL := {
	"hub": Palette.GOLD, "zone": Palette.VERDANCE, "raid": Palette.CRIMSON, "fog": Palette.EDGE,
}
const KIND_GLYPH := {"hub": "H", "zone": "Z", "raid": "R", "fog": "?"}

func _ready() -> void:
	_build_header()
	_build_buttons()
	queue_redraw()

func _process(delta: float) -> void:
	_pulse += delta * 2.0
	queue_redraw()

func _build_header() -> void:
	_label(WorldContent.REGION_TITLE, 42, Palette.GOLD, Vector2(0, 92), UiKit.title(900))
	_label(WorldContent.REGION_SUB, 13, Palette.TEXT_DIM, Vector2(0, 150), UiKit.display(500, 3))
	var ways: Array = save.data["waystations"]
	if not ways.is_empty():
		_label("SKY ROADS OPEN: %d waystation%s — flight is instant between lit beacons" \
			% [ways.size(), "" if ways.size() == 1 else "s"], 13, Palette.WIN,
			Vector2(0, 176), UiKit.display(500, 2))
	_label("walk your warband onto a pin · zones stay conquered FOREVER · doors open into the runs",
		12, Palette.TEXT_DIM, Vector2(0, 884), UiKit.body())
	var back := Button.new()
	back.text = "◂  HOME"
	back.flat = true
	back.add_theme_color_override("font_color", Palette.TEXT_DIM)
	back.pressed.connect(func(): back_requested.emit())
	back.set_anchors_preset(Control.PRESET_TOP_LEFT)
	back.position = Vector2(28, 24)
	back.custom_minimum_size = Vector2(120, 36)
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
	for pin in WorldContent.atlas_pins():
		if String(pin["kind"]) == "fog":
			continue           # the fog is not a destination
		var id := String(pin["id"])
		var b := Button.new()
		b.flat = true
		b.custom_minimum_size = Vector2(R_PIN * 3.0, R_PIN * 3.0)
		b.position = (pin["pos"] as Vector2) - Vector2(R_PIN * 1.5, R_PIN * 1.5)
		b.tooltip_text = "%s — %s" % [String(pin["name"]), String(pin["sub"])]
		b.mouse_entered.connect(func():
			_hover = id
			queue_redraw())
		b.mouse_exited.connect(func():
			_hover = ""
			queue_redraw())
		b.pressed.connect(func(): pin_entered.emit(id))
		add_child(b)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.025, 0.04, 0.80))
	var fnt := UiKit.display(600, 1)
	var body := UiKit.body()
	var pins := WorldContent.atlas_pins()
	# ---- flight lines: the Bastion is the first beacon; each unlocked waystation joins the web
	var lit: Array = [_pin_pos(pins, "bastion")]
	for zid in (save.data["waystations"] as Array):
		var p := _pin_pos(pins, String(zid))
		if p != Vector2.ZERO:
			lit.append(p)
	for i in lit.size():
		for j in range(i + 1, lit.size()):
			_skyroad(lit[i], lit[j], Color(Palette.WIN, 0.5))
	# ---- region roads (faint, fixed geography)
	_skyroad(_pin_pos(pins, "bastion"), _pin_pos(pins, WorldContent.ZONE1), Color(Palette.GOLD_DIM, 0.35))
	_skyroad(_pin_pos(pins, WorldContent.ZONE1), _pin_pos(pins, "rift_scar"), Color(Palette.GOLD_DIM, 0.25))
	# ---- the pins
	for pin in pins:
		var id := String(pin["id"])
		var kind := String(pin["kind"])
		var p: Vector2 = pin["pos"]
		var col: Color = KIND_COL.get(kind, Palette.GOLD)
		if kind == "fog":
			# a landmass in the fog: soft dark blot + a rumor of an edge
			for i in 3:
				draw_circle(p, R_PIN * (1.7 - 0.4 * float(i)), Color(0.05, 0.05, 0.07, 0.25))
			draw_arc(p, R_PIN, 0, TAU, 40, Color(Palette.EDGE, 0.35 + 0.1 * sin(_pulse)), 1.4)
			draw_string(body, p + Vector2(-90, R_PIN + 22), String(pin["sub"]),
				HORIZONTAL_ALIGNMENT_CENTER, 180, 11, Color(Palette.TEXT_DIM, 0.5))
			continue
		var hovered := _hover == id
		draw_circle(p, R_PIN + 6.0, Color(Palette.EDGE, 0.9))
		draw_circle(p, R_PIN, Color(col, 0.30))
		UiKit.gilded_ring(self, p, R_PIN, 2.2 if hovered else 1.6, 40)
		if hovered:
			draw_arc(p, R_PIN + 10.0, 0, TAU, 44, Color(Palette.GOLD_BRIGHT, 0.9), 2.0)
		draw_string(fnt, p + Vector2(-20, 8), String(KIND_GLYPH[kind]),
			HORIZONTAL_ALIGNMENT_CENTER, 40, 22, col.lightened(0.25))
		draw_string(fnt, p + Vector2(-140, R_PIN + 26), String(pin["name"]),
			HORIZONTAL_ALIGNMENT_CENTER, 280, 15, Palette.TEXT if hovered else Palette.GOLD)
		draw_string(body, p + Vector2(-150, R_PIN + 44), String(pin["sub"]),
			HORIZONTAL_ALIGNMENT_CENTER, 300, 10, Color(Palette.TEXT_DIM, 0.9))
		# live conquest line under a zone pin — the Atlas IS the World track's UI
		if kind == "zone":
			var z := WorldContent.zone(id)
			if not z.is_empty():
				var total: int = (z["nodes"] as Array).size()
				var done := save.cleared_count(id)
				var line := "CONQUEST  %d / %d" % [done, total]
				if WorldContent.zone_conquered(z, save):
					line = "CLEARED — the zone is yours"
				draw_string(fnt, p + Vector2(-140, R_PIN + 62), line, HORIZONTAL_ALIGNMENT_CENTER,
					280, 11, Palette.GOLD_BRIGHT if WorldContent.zone_conquered(z, save) else Palette.VERDANCE)
		if save.has_waystation(id) or id == "bastion":
			draw_string(fnt, p + Vector2(-60, -R_PIN - 12), "^ BEACON LIT", HORIZONTAL_ALIGNMENT_CENTER,
				120, 10, Palette.WIN)
	# ---- the warband token
	var hp := _pin_pos(pins, at_pin)
	if hp != Vector2.ZERO:
		hp += Vector2(0, -R_PIN - 26.0)
		var pts := PackedVector2Array([hp + Vector2(0, -13), hp + Vector2(10, 0), hp + Vector2(0, 13), hp + Vector2(-10, 0)])
		draw_colored_polygon(pts, Palette.GOLD_BRIGHT)
		draw_polyline(pts + PackedVector2Array([pts[0]]), Color(Palette.BG0, 0.8), 1.5, true)
		draw_string(fnt, hp + Vector2(-60, -22), "YOUR WARBAND", HORIZONTAL_ALIGNMENT_CENTER, 120, 10, Palette.GOLD_BRIGHT)

func _pin_pos(pins: Array, id: String) -> Vector2:
	for pin in pins:
		if String(pin["id"]) == id:
			return pin["pos"]
	return Vector2.ZERO

## A sky road: a high arc between beacons.
func _skyroad(a: Vector2, b: Vector2, col: Color) -> void:
	if a == Vector2.ZERO or b == Vector2.ZERO:
		return
	var c := (a + b) * 0.5 + Vector2(0, -60)
	var prev := a
	var segs := 18
	for i in range(1, segs + 1):
		var t := float(i) / float(segs)
		var q := a.lerp(c, t).lerp(c.lerp(b, t), t)
		if i % 2 == 1:
			draw_line(prev, q, col, 1.6, true)
		prev = q
