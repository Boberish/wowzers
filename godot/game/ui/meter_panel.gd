## MeterPanel — the DPS/HPS meter window (Recount, reliquary-styled). A right-rail
## glass plaque that reads `state.meter` (engine-truth accounting, never checksummed)
## live each frame:
##   COMPACT — one bar per combatant, ranked: name · total · DPS/HPS (bar ∝ leader).
##   DETAIL  — one combatant's per-SPELL breakdown: total · share · hits · avg · max
##             · crits (damage) / overheal (healing).
## Header click cycles the column (DAMAGE → HEALING → TAKEN); a compact row click
## drills into that combatant; M cycles compact → detail → hidden (session-sticky).
## `frozen` builds the end-screen recap variant (no live NOW readout, no key hints).
## Pure view layer — reads state, never writes it.
class_name MeterPanel
extends Control

const W := 300.0
const HDR := 34.0
const ROW_C := 24.0            # compact row
const ROW_D := 31.0            # detail row (name line + dim stat line)
const FOOT := 18.0

const MODES: Array = ["dmg", "heal", "taken"]
const MODE_NAMES := {"dmg": "DAMAGE DONE", "heal": "HEALING DONE", "taken": "DAMAGE TAKEN"}
const MODE_RATE := {"dmg": "DPS", "heal": "HPS", "taken": "DTPS"}

## source label -> display name, where String.capitalize() isn't enough
static var PRETTY := {
	"attack": "Attack", "hot": "HoT", "ward": "Wards", "debuff": "DoT (Riftrot)",
	"enrage": "Enrage", "perfect": "Perfect Strike", "strike": "Strike",
	"finisher": "Eviscerate", "coup": "Coup de Grâce", "flurry": "Flurry",
	"poison": "Poison", "kick": "Kick", "medit": "Meditation", "flash": "Flash Heal",
	"mend": "Mend", "well": "Welling Tide", "laststand": "Last Stand",
	"perfect_burst": "Perfect Ward", "void_dot": "Void Rot", "lash": "Thornlash",
}

var mode: String = "dmg"
var frozen := false                 # end-screen recap: static, no NOW/hints
var focus_i := -1                   # detail view: seats[] index (-1 = the player)

## session-sticky visibility the M key cycles: 0 compact · 1 detail · 2 hidden
static var view_state := 0

var _ctrl                           # CombatController (duck-typed .state / .player())
var _frozen_detail := false         # end-screen recap drill-down (frozen panels only)
var _hits: Array = []               # click regions rebuilt each draw: {rect, kind, i}
var _now_buf: Array = []            # rolling (time, total) samples for the NOW readout
var _now_rate := 0.0

func _init(ctrl, default_mode := "dmg", frozen_recap := false) -> void:
	_ctrl = ctrl
	mode = default_mode
	frozen = frozen_recap
	mouse_filter = Control.MOUSE_FILTER_STOP

func _state() -> CombatState:
	return _ctrl.state if _ctrl != null else null

## M key: compact -> detail -> hidden -> compact (shared across fights/HUDs)
func cycle() -> void:
	view_state = (view_state + 1) % 3

# ------------------------------------------------------------------ data reads
static func _row(s: CombatState, i: int) -> Dictionary:
	return s.meter.get(i, {})

static func _total(s: CombatState, i: int, m: String) -> float:
	return float(_row(s, i).get(m + "_total", 0.0))

## ranked [ [seat_i, total], ... ] for the mode, zeros dropped
static func _ranking(s: CombatState, m: String) -> Array:
	var out: Array = []
	for i in s.seats.size():
		var t := _total(s, i, m)
		if t > 0.0:
			out.append([i, t])
	out.sort_custom(func(a, b): return float(a[1]) > float(b[1]))
	return out

## ranked [ [src, entry], ... ] inside one seat's mode dict
static func _sources(s: CombatState, i: int, m: String) -> Array:
	var by: Dictionary = _row(s, i).get(m, {})
	var out: Array = []
	for src in by:
		out.append([src, by[src]])
	out.sort_custom(func(a, b): return float(a[1]["total"]) > float(b[1]["total"]))
	return out

static func pretty_src(src) -> String:
	var k := String(src)
	return String(PRETTY.get(k, k.capitalize()))

static func _fmt(x: float) -> String:
	if x >= 100000.0:
		return "%.0fk" % (x / 1000.0)
	if x >= 10000.0:
		return "%.1fk" % (x / 1000.0)
	return str(int(round(x)))

static func _fmt_rate(x: float) -> String:
	return ("%.0f" % x) if x >= 99.5 else ("%.1f" % x)

func _accent(seat: Seat) -> Color:
	if seat == null or seat.kit == null:
		return Palette.TEXT_DIM
	var scr: Script = seat.kit.get_script()
	match (String(scr.get_global_name()) if scr != null else ""):
		"BulwarkKit": return Palette.GOLD
		"TwinfangKit": return Palette.FLOW
		"VoidcallerKit": return Palette.VOID
		"MenderKit": return Palette.SPELL
		"BloomweaverKit": return Palette.VERDANCE
		_: return Palette.STEEL.darkened(0.15)

func _seat_name(seat: Seat) -> String:
	if seat.unit_name != "":
		return seat.unit_name
	return "You" if seat.is_player else "Ally"

func _focus_seat_i(s: CombatState) -> int:
	if focus_i >= 0 and focus_i < s.seats.size():
		return focus_i
	var p = _ctrl.player() if _ctrl != null else null
	var i: int = s.seats.find(p) if p != null else -1
	return maxi(i, 0)

# ------------------------------------------------------------------ live loop
func _process(delta: float) -> void:
	var s := _state()
	if s == null:
		return
	if not frozen:
		# rolling NOW rate over the last ~5s of the focused seat's column
		var t := s.time()
		_now_buf.append(Vector2(t, _total(s, _focus_seat_i(s), mode)))
		while _now_buf.size() > 2 and _now_buf[0].x < t - 5.0:
			_now_buf.pop_front()
		var span: float = _now_buf[-1].x - _now_buf[0].x
		_now_rate = ((_now_buf[-1].y - _now_buf[0].y) / span) if span > 0.5 else 0.0
	queue_redraw()

# ------------------------------------------------------------------ input
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		for h in _hits:
			if (h["rect"] as Rect2).has_point(event.position):
				match String(h["kind"]):
					"mode":
						mode = MODES[(MODES.find(mode) + 1) % MODES.size()]
						_now_buf.clear()
					"seat":
						focus_i = int(h["i"])
						if frozen:
							_frozen_detail = true
						else:
							view_state = 1
					"back":
						focus_i = -1
						if frozen:
							_frozen_detail = false
						else:
							view_state = 0
				accept_event()
				queue_redraw()
				return

# ------------------------------------------------------------------ draw
func _draw() -> void:
	_hits = []
	var s := _state()
	if s == null:
		return
	if view_state == 2 and not frozen:
		# collapsed chip — discoverable without stealing space
		var chip := Rect2(size.x - 92, 0, 92, 20)
		draw_rect(chip, Color(0.03, 0.026, 0.052, 0.55))
		draw_rect(chip, Palette.EDGE, false, 1.0)
		UiKit.text_shadowed(self, UiKit.display(600, 1), Vector2(chip.position.x, 14),
			"METER · M", HORIZONTAL_ALIGNMENT_CENTER, chip.size.x, UiKit.SIZE["MICRO"], Palette.TEXT_DIM)
		return

	var rk := _ranking(s, mode)
	var detail := (_frozen_detail if frozen else view_state == 1)
	if rk.size() <= 1:
		detail = true                          # solo duel: the ranking IS you — skip to spells
	var fi := _focus_seat_i(s)

	# ---- content height first (bg fits what's shown) ----
	var rows := (_sources(s, fi, mode).size() if detail else rk.size())
	var h := HDR + 6.0 + float(rows) * (ROW_D if detail else ROW_C) + FOOT + 4.0
	h = maxf(h, HDR + FOOT + 26.0)

	# ---- plaque ----
	var plate := StyleBoxFlat.new()
	plate.bg_color = Color(0.030, 0.026, 0.052, 0.66)
	plate.set_corner_radius_all(8)
	plate.border_color = Palette.EDGE
	plate.set_border_width_all(1)
	draw_style_box(plate, Rect2(0, 0, size.x, h))
	draw_line(Vector2(10, 1), Vector2(size.x - 10, 1), Palette.GOLD_DIM, 1.2, true)

	# ---- header: mode (click to cycle) · clock · NOW ----
	var hdr := Rect2(0, 0, size.x, HDR)
	_hits.append({"rect": hdr, "kind": "mode", "i": 0})
	var secs := s.time()
	var clock := "%d:%04.1f" % [int(secs) / 60, fmod(secs, 60.0)] if secs >= 60.0 else "%.0fs" % secs
	var mname := String(MODE_NAMES[mode])
	UiKit.text_shadowed(self, UiKit.display(700, 2), Vector2(12, 21),
		"◆ " + mname, HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, UiKit.SIZE["MICRO"], Palette.GOLD)
	var right := clock
	if not frozen and not s.over and _now_rate > 0.0:
		right = "NOW %s/s · %s" % [_fmt_rate(_now_rate), clock]
	UiKit.text_shadowed(self, UiKit.body(500), Vector2(0, 21), right,
		HORIZONTAL_ALIGNMENT_RIGHT, size.x - 12, UiKit.SIZE["MICRO"], Palette.TEXT_DIM)

	var y := HDR + 2.0
	if detail:
		y = _draw_detail(s, fi, rk, y)
	else:
		y = _draw_compact(s, rk, y)

	# ---- footer hint ----
	if not frozen:
		var hint := "M · view      click title · column"
		if detail and rk.size() > 1:
			hint = "M · view      ‹ back to ranking"
		UiKit.text_shadowed(self, UiKit.body(500), Vector2(0, h - 6.0), hint,
			HORIZONTAL_ALIGNMENT_CENTER, size.x, UiKit.SIZE["MICRO"],
			Palette.TEXT_DIM.darkened(0.2))

## COMPACT: ranked combatant bars (bar length ∝ the leader), total + rate.
func _draw_compact(s: CombatState, rk: Array, y: float) -> float:
	var elapsed := maxf(s.time(), 1.0)
	var top := (float(rk[0][1]) if not rk.is_empty() else 1.0)
	var party := 0.0
	for r in rk:
		party += float(r[1])
	for r in rk:
		var i := int(r[0])
		var t := float(r[1])
		var seat: Seat = s.seats[i]
		var acc := _accent(seat)
		var rr := Rect2(8, y + 2, size.x - 16, ROW_C - 5)
		_hits.append({"rect": Rect2(0, y, size.x, ROW_C), "kind": "seat", "i": i})
		# ranked bar
		draw_rect(Rect2(rr.position, Vector2(rr.size.x * (t / maxf(top, 1.0)), rr.size.y)),
			Color(acc.r, acc.g, acc.b, 0.28))
		draw_rect(Rect2(rr.position, Vector2(2.5, rr.size.y)), acc)
		if not seat.alive():
			draw_rect(rr, Color(0, 0, 0, 0.35))
		# name · total · rate
		var name_col := Palette.GOLD_BRIGHT if seat.is_player else Palette.TEXT
		if not seat.alive():
			name_col = Palette.TEXT_DIM
		UiKit.text_shadowed(self, UiKit.body(600), Vector2(16, y + ROW_C - 8.0),
			_seat_name(seat) + (" ◆" if seat.is_player else ""),
			HORIZONTAL_ALIGNMENT_LEFT, size.x * 0.45, UiKit.SIZE["CAPTION"], name_col)
		UiKit.text_shadowed(self, UiKit.display(650), Vector2(0, y + ROW_C - 8.0),
			"%s   %s" % [_fmt(t), _fmt_rate(t / elapsed)],
			HORIZONTAL_ALIGNMENT_RIGHT, size.x - 14, UiKit.SIZE["CAPTION"],
			Palette.GOLD_BRIGHT if seat.is_player else Palette.TEXT_DIM)
		y += ROW_C
	if rk.is_empty():
		UiKit.text_shadowed(self, UiKit.body(500), Vector2(0, y + 14), "· nothing yet ·",
			HORIZONTAL_ALIGNMENT_CENTER, size.x, UiKit.SIZE["CAPTION"], Palette.TEXT_DIM)
		y += ROW_C
	return y

## DETAIL: one combatant's spells — total · share% · hits/avg/max · crit/overheal.
func _draw_detail(s: CombatState, fi: int, rk: Array, y: float) -> float:
	var seat: Seat = s.seats[fi]
	var acc := _accent(seat)
	var col_total := _total(s, fi, mode)
	# whose spells + back affordance
	var crumb := _seat_name(seat) + " — " + String(MODE_RATE[mode])
	if rk.size() > 1:
		crumb = "‹ " + crumb
		_hits.append({"rect": Rect2(0, y, size.x, 18), "kind": "back", "i": 0})
	var elapsed := maxf(s.time(), 1.0)
	UiKit.text_shadowed(self, UiKit.display(600, 1), Vector2(12, y + 12),
		crumb + " %s" % _fmt_rate(_total(s, fi, mode) / elapsed),
		HORIZONTAL_ALIGNMENT_LEFT, size.x - 24, UiKit.SIZE["MICRO"], acc.lightened(0.2))
	y += 18.0
	var srcs := _sources(s, fi, mode)
	var top := (float(srcs[0][1]["total"]) if not srcs.is_empty() else 1.0)
	for e in srcs:
		var entry: Dictionary = e[1]
		var t := float(entry["total"])
		var rr := Rect2(8, y + 2, size.x - 16, ROW_D - 6)
		draw_rect(Rect2(rr.position, Vector2(rr.size.x * (t / maxf(top, 1.0)), 12.0)),
			Color(acc.r, acc.g, acc.b, 0.22))
		draw_rect(Rect2(rr.position, Vector2(2.5, 12.0)), acc)
		UiKit.text_shadowed(self, UiKit.body(600), Vector2(16, y + 13),
			pretty_src(e[0]), HORIZONTAL_ALIGNMENT_LEFT, size.x * 0.55,
			UiKit.SIZE["CAPTION"], Palette.TEXT)
		UiKit.text_shadowed(self, UiKit.display(650), Vector2(0, y + 13),
			"%s  %d%%" % [_fmt(t), int(round(100.0 * t / maxf(col_total, 1.0)))],
			HORIZONTAL_ALIGNMENT_RIGHT, size.x - 14, UiKit.SIZE["CAPTION"], Palette.GOLD_BRIGHT)
		# dim stat line: hits · avg · max, then crits (gold) / overheal (dim)
		var n := int(entry["n"])
		var stat := ""
		if n > 0:
			stat = "%d× · avg %s · max %s" % [n, _fmt(t / float(n)), _fmt(float(entry["max"]))]
		else:
			stat = "continuous"
		var extra := ""
		var extra_col := Palette.TEXT_DIM
		if mode == "heal" and float(entry.get("over", 0.0)) > 0.5:
			var ov := float(entry["over"])
			extra = " · %d%% over" % int(round(100.0 * ov / maxf(t + ov, 1.0)))
		elif int(entry.get("crit_n", 0)) > 0:
			extra = " · %d crit" % int(entry["crit_n"])
			extra_col = Palette.GOLD
		UiKit.text_shadowed(self, UiKit.body(500), Vector2(16, y + ROW_D - 4.0),
			stat, HORIZONTAL_ALIGNMENT_LEFT, size.x - 60, UiKit.SIZE["MICRO"],
			Palette.TEXT_DIM.darkened(0.1))
		if extra != "":
			UiKit.text_shadowed(self, UiKit.body(600), Vector2(0, y + ROW_D - 4.0),
				extra.trim_prefix(" · "), HORIZONTAL_ALIGNMENT_RIGHT, size.x - 14,
				UiKit.SIZE["MICRO"], extra_col)
		y += ROW_D
	if srcs.is_empty():
		UiKit.text_shadowed(self, UiKit.body(500), Vector2(0, y + 14), "· nothing yet ·",
			HORIZONTAL_ALIGNMENT_CENTER, size.x, UiKit.SIZE["CAPTION"], Palette.TEXT_DIM)
		y += ROW_D
	return y
