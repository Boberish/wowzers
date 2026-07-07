## MapScreen — the Topology run map, drawn as a CIRCUIT BOARD (MASTER-PLAN §MAPS).
## Nodes are machine pads on copper traces; rows advance left → right toward the Seal.
## The one locked backdoor edge is stamped "401" (red) until the key is held — then
## "200 OK" (green). Selectable next nodes glow and carry an invisible button.
##
## Caller idiom (UI-OVERHAUL): set fields, THEN anchors, THEN add_child.
##   map / current (-1 = not entered yet) / inventory / hp_frac
## Emits node_entered(id); back/abandon is the caller's job (Esc handling lives in the HUD).
class_name MapScreen
extends Control

signal node_entered(id: int)

var map: RunMap
var current: int = -1
var inventory: Dictionary = {}
var hp_frac: float = 1.0
var subtitle: String = ""            ## optional ring/floor label (MAP-3c); "" = hide
var ring: int = -1                   ## MAP-2: current ring (drives realm title/sub); -1 = solo
var open_tickets: Array = []         ## MAP-2: titles of quests still open (header list)
var toast: String = ""               ## MAP-2: one-shot ticket pickup/close banner
var gear_line: String = ""           ## GEAR-1: equipped curios + ⏣ (raid map; "" = hidden)
var entropy: int = 0                  ## ⚡ within-run luck pool (Inference Check); 0 hides
var prior: int = 0                    ## 📁 across-run luck floor; 0 hides
var charge: int = -1                  ## ⏻ THE KILL SWITCH meter 0..100; <0 hides (solo map)

var _hover: int = -1
var _selectable: Array = []

const X0 := 250.0
const X1 := 1670.0
const Y_LANE := [360.0, 540.0, 720.0]     # lane 0/1/2 centers
const R_NODE := 26.0

# NOTE: const can't hold Palette statics (UI-OVERHAUL gotcha) — static var it is
static var KIND_COL := {
	RunMap.KIND_COMBAT: Palette.CRIMSON,
	RunMap.KIND_EVENT: Palette.VOID,
	RunMap.KIND_CACHE: Palette.GOLD,
	RunMap.KIND_COOLING: Palette.FLOW,
	RunMap.KIND_SEAL: Palette.CRUSH,
	RunMap.KIND_GATE: Palette.GOLD_BRIGHT,
}
const KIND_TAG := {
	RunMap.KIND_COMBAT: "FIGHT",
	RunMap.KIND_EVENT: "EVENT",
	RunMap.KIND_CACHE: "CACHE",
	RunMap.KIND_COOLING: "COOLING",
	RunMap.KIND_SEAL: "SEAL",
	RunMap.KIND_GATE: "GATE — one steps through alone",
}

## MAP-3b: online spectators (non-leaders) see the map read-only — the reachable
## nodes still glow, but there are no click buttons (only the leader routes).
var interactive: bool = true

func _ready() -> void:
	_selectable = map.reachable(current, inventory)
	_build_header()
	if interactive:
		_build_buttons()
	queue_redraw()

func _pos(n: Dictionary) -> Vector2:
	# span by THIS map's Seal row, not the class const — refit floors run 8 rows
	# (classic 6-row maps: seal row 5 = ROWS-1, so their layout is pixel-identical)
	var last_row: int = int(map.node(map.seal_id)["row"])
	var x: float = lerpf(X0, X1, float(n["row"]) / float(maxi(last_row, 1)))
	return Vector2(x, Y_LANE[int(n["lane"])])

# ============================================================ chrome
func _build_header() -> void:
	# ring-aware identity (MAP-2): the descent reads differently as privileges rise;
	# ring < 0 (the solo practice map) falls back to the classic constants.
	var rtitle := MapContent.realm_title(ring) if ring >= 0 else MapContent.REALM_TITLE
	var rsub := MapContent.realm_sub(ring) if ring >= 0 else MapContent.REALM_SUB
	_label(rtitle, 36, Palette.GOLD, Vector2(0, 96), UiKit.title(900))
	_label(rsub, 13, Palette.TEXT_DIM, Vector2(0, 148), UiKit.display(500, 3))
	if subtitle != "":
		_label(subtitle, 16, Palette.GOLD_BRIGHT, Vector2(0, 166), UiKit.title(700))
	# INTEGRITY only reads on the SOLO practice map (charge<0); the raid RETIRED it — a
	# healer tops HP off, so the sole HP stake there is a corrupted sector (see wounds).
	var status := ("INTEGRITY %d%%" % int(round(hp_frac * 100.0))) if charge < 0 else ""
	if map.seal_shard_req > 0:
		status += "      [CREDENTIAL SHARDS: %d / %d]" % [
			int(inventory.get("shards", 0)), map.seal_shard_req]
	if inventory.get("api_key", false):
		status += "      [KEY: %s]" % MapContent.KEY_NAME
	# The Inference Check meta rides the same status line: ⚡ Entropy (spend to bias a
	# roll) + 📁 Prior (your file, a floor on every check).
	if entropy > 0 or prior > 0:
		status += "      ⚡%d   📁%d(+%d%%)" % [entropy, prior, LuckProfile.prior_floor(prior)]
	if charge >= 0:
		status += "      ⏻ %d%% ARMED" % charge
	_label(status, 15, Palette.TEXT, Vector2(0, 186), UiKit.display(600, 2))
	# TICKETS (MAP-2): a one-shot toast for the last pickup/close, then the still-open list
	if toast != "":
		_label(toast, 15, Palette.GOLD_BRIGHT, Vector2(0, 210), UiKit.title(600))
	if not open_tickets.is_empty():
		_label("OPEN TICKETS:   " + "     ·     ".join(open_tickets), 12, Palette.FLOW,
			Vector2(0, 234), UiKit.display(600, 2))
	# GEAR-1: the raid's equipped curios (Realm-1: peripherals) + banked Tokens
	if gear_line != "":
		_label(gear_line, 13, Palette.GOLD, Vector2(0, 258), UiKit.display(600, 2))
	_label("choose a connected node  ·  %s routes need credentials  ·  Esc = abandon the run"
		% MapContent.LOCK_LABEL, 12, Palette.TEXT_DIM, Vector2(0, 880), UiKit.body())
	# legend
	var lg := "X FIGHT   ·   ? EVENT   ·   + CACHE   ·   ~ COOLING   ·   1 GATE   ·   ! SEAL"
	_label(lg, 11, Palette.GOLD_DIM, Vector2(0, 912), UiKit.display(500, 2))

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
	for n in map.nodes:
		var id := int(n["id"])
		if not _selectable.has(id):
			continue
		var b := Button.new()
		b.flat = true
		b.custom_minimum_size = Vector2(R_NODE * 2.6, R_NODE * 2.6)
		b.position = _pos(n) - Vector2(R_NODE * 1.3, R_NODE * 1.3)
		b.tooltip_text = "%s — %s" % [String(n["name"]), KIND_TAG[String(n["kind"])]]
		b.mouse_entered.connect(func():
			_hover = id
			queue_redraw())
		b.mouse_exited.connect(func():
			_hover = -1
			queue_redraw())
		b.pressed.connect(func(): node_entered.emit(id))
		add_child(b)

# ============================================================ the board
func _draw() -> void:
	# dark veil so the sanctum backdrop reads as depth, not noise
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.02, 0.045, 0.72))
	var fnt := UiKit.display(600, 1)
	var body := UiKit.body()
	# ---- copper traces (edges) — elbow polylines like PCB routing
	for n in map.nodes:
		var a := _pos(n)
		for nx in n["next"]:
			_trace(a, _pos(map.node(nx)), Palette.GOLD_DIM, 2.0)
		for nx in n["locked_next"]:
			var have_key: bool = inventory.get("api_key", false)
			var col := Palette.WIN if have_key else Palette.CRIMSON
			var b := _pos(map.node(nx))
			_trace(a, b, Color(col, 0.8), 2.0)
			var mid := (a + b) * 0.5 + Vector2(0, -10)
			var tag := MapContent.LOCK_OPEN_LABEL if have_key else MapContent.LOCK_LABEL
			draw_string(fnt, mid + Vector2(-40, 0), tag, HORIZONTAL_ALIGNMENT_CENTER, 80, 13, col)
	# ---- node pads
	for n in map.nodes:
		var id := int(n["id"])
		var p := _pos(n)
		var kind := String(n["kind"])
		var col: Color = KIND_COL[kind]
		var visited: bool = bool(n.get("visited", false))
		var is_cur := id == current
		var sel := _selectable.has(id)
		var fill := col
		if visited and not is_cur:
			fill = Color(col, 0.25)
		elif not sel and not is_cur:
			fill = Color(col, 0.45)
		# pad ring + fill (Seal is bigger — it's the boss)
		var r := R_NODE * (1.35 if kind == RunMap.KIND_SEAL else 1.0)
		draw_circle(p, r + 5.0, Color(Palette.EDGE, 0.9))
		draw_circle(p, r, Color(fill, 0.9 if sel or is_cur else 0.55))
		if is_cur:
			draw_arc(p, r + 9.0, 0, TAU, 40, Palette.GOLD_BRIGHT, 2.5)
		elif sel:
			var glow := Palette.GOLD if _hover != id else Palette.GOLD_BRIGHT
			draw_arc(p, r + 8.0, 0, TAU, 40, Color(glow, 0.9), 2.0)
		# kind glyph (plain ASCII — the bundled faces don't cover dingbats)
		var glyph: String = {"combat": "X", "event": "?", "cache": "+", "cooling": "~", "seal": "!", "gate": "1"}[kind]
		draw_string(fnt, p + Vector2(-20, 7), glyph, HORIZONTAL_ALIGNMENT_CENTER, 40, 20,
			Color(Palette.BG0, 0.95) if sel or is_cur else Color(Palette.BG0, 0.7))
		# key badge — visible until picked up
		if bool(n["key"]) and not visited:
			draw_string(fnt, p + Vector2(-30, -r - 12), "KEY", HORIZONTAL_ALIGNMENT_CENTER, 60, 13, Palette.GOLD_BRIGHT)
		# ticket badges (MAP-2): where to pick up a quest / where to turn it in
		if String(n.get("ticket_open", "")) != "" and not visited:
			draw_string(fnt, p + Vector2(-45, -r - 26), "TICKET", HORIZONTAL_ALIGNMENT_CENTER, 90, 12, Palette.FLOW)
		if String(n.get("ticket_close", "")) != "" and not visited:
			draw_string(fnt, p + Vector2(-45, -r - 26), "TURN-IN", HORIZONTAL_ALIGNMENT_CENTER, 90, 12, Palette.FLOW)
		# name + fight tag
		var name_col := Palette.TEXT if sel or is_cur else Palette.TEXT_DIM
		draw_string(body, p + Vector2(-90, r + 24), String(n["name"]),
			HORIZONTAL_ALIGNMENT_CENTER, 180, 12, name_col)
		if int(n["fight"]) >= 0:
			draw_string(body, p + Vector2(-90, r + 40), "· threat level %d ·" % (int(n["fight"]) + 1),
				HORIZONTAL_ALIGNMENT_CENTER, 180, 10, Color(name_col, 0.7))

## PCB elbow: out horizontally, one 45-ish bend, into the target pad.
func _trace(a: Vector2, b: Vector2, col: Color, w: float) -> void:
	var mx := (a.x + b.x) * 0.5
	var pts := PackedVector2Array([a, Vector2(mx, a.y), Vector2(mx, b.y), b])
	draw_polyline(pts, col, w, true)
	draw_circle(Vector2(mx, a.y), 2.5, col)
	draw_circle(Vector2(mx, b.y), 2.5, col)
