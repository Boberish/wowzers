## AnswerChannel — THE CHANNEL (TANK-PLAN §0, tank-v2): the game's ONE answer instrument.
## Draws the engine's COMMITTED timeline verbatim — comets slide right-to-left at constant
## px/s into the IMPACT GATE; the widget has ZERO prediction logic, so nothing can pop,
## morph, or jump (LAW 1). Class-agnostic by construction: it renders whatever bars + the
## live telegraph the band feeds it (the Duelist is its first client; other classes migrate
## later and inherit it unchanged).
##
## THE VOCABULARY (v3): AUTO diamond (word DODGE) · HEAVY hexagon (PARRY) · BUSTER spiked
## octagon, tank colors (PARRY) · GLOBAL spiked octagon, boss colors (DODGE — every seat) ·
## FEINT = a disguise wearing a real shape + word, PURPLE is the only tell · FLURRY beat
## cluster (WEAVE — the channel mode-swaps) · EAT skull (brace). LATE bars pop in mid-track
## with a flash (THE SPEED LAW: difficulty is WHEN a bar appears, never how fast it moves;
## whole-flow tempo shifts ride the eased `tempo` multiplier — everything compresses
## together).
##
## THE GATE is the game-wide grading target (GRADING COHERENCE LAW): steel GRAZE band →
## gold GOOD → mint PERFECT → bright-gold BULLSEYE center, identical in reading to the
## Twinfang rhythm bar; the thin steel notch is the PARRY land window (binary). A tiny mint
## dot above a heavy/buster marks "bullseye-dodge legal". Pure view — never touches state.
class_name AnswerChannel
extends Control

const PURPLE := Color("b072c9")            # the feint tell (Palette.RELIC)
const GLOBAL_COL := Color("e0b23a")        # the boss's move (Palette.EXPOSE amber-gold)

# --- fed by the band every frame (view data straight off observe()) ---
var bars: Array = []                       ## committed stream bars: {id,kind,purple,eta,late,flurry_i,flurry_n}
var global_bar: Dictionary = {}            ## the live GLOBAL beat: {eta} ({} = none)
var buster_bar: Dictionary = {}            ## a telegraph buster aimed at me: {eta, purple} ({} = none)
var tempo: float = 1.0                     ## whole-flow multiplier (eased below — no jumps)
var flurry: bool = false                   ## FLURRY MODE (border + label + bg tint)
var aggro_lost: bool = false               ## stream paused because the boss hunts another
var horizon: float = 3.0                   ## the engine's publish lead (mouth = this many sec out)
var win_bullseye: float = 0.07             ## grading windows (sec) — drawn as the gate bands
var win_perfect: float = 0.14
var win_good: float = 0.30
var win_graze: float = 0.50
var parry_window: float = 0.10

var tick_frac: float = 0.0                 ## the controller's accumulator fraction (0..1) — comets
                                           ## interpolate BETWEEN 30 Hz ticks (pass 2: stepped motion
                                           ## read as input lag against tight windows)
var late_slack: float = 0.15               ## bars hold the gate this long after touch (late presses)

const TICK_DT := 1.0 / 30.0                ## the fixed timestep IS the law (CLAUDE.md)

var _tempo_vis: float = 1.0                ## eased toward tempo (a snap would jump every comet)
var _seen: Dictionary = {}                 ## bar id -> true (late-flash bookkeeping)
var _flashes: Array = []                   ## [{x, t}] LATE pop-in rings
var _stamps: Array = []                    ## [{txt, col, t}] verdict pops at the gate
var _rail: Array = []                      ## last 8 verdict families (the grade history)
var _shards: Array = []                    ## SHATTER ghosts: [{x, kind, t}]
var _spin: float = 0.0                     ## buster/global octagon spin phase

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	_tempo_vis = lerpf(_tempo_vis, maxf(0.25, tempo), minf(1.0, delta * 3.0))
	_spin += delta * 2.2
	for f in _flashes:
		f["t"] += delta
	_flashes = _flashes.filter(func(f): return f["t"] < 0.5)
	for st in _stamps:
		st["t"] += delta
	_stamps = _stamps.filter(func(st): return st["t"] < 0.9)
	for sh in _shards:
		sh["t"] += delta
	_shards = _shards.filter(func(sh): return sh["t"] < 0.6)
	queue_redraw()

## A verdict landed (the band routes engine events here + to the slam): stamp + rail gem.
func stamp(txt: String, family: String) -> void:
	_stamps.append({"txt": txt, "col": _family_col(family), "t": 0.0})
	_rail.append(family)
	if _rail.size() > 8:
		_rail.pop_front()

## The publisher's body died — its committed bars SHATTER (visible: killing the attacker
## cancels its swings). The band calls this off the stream_shatter event.
func shatter() -> void:
	for b_v in bars:
		var b: Dictionary = b_v
		_shards.append({"x": _bar_x(float(b.get("eta", 0.0))), "kind": String(b.get("kind", "auto")), "t": 0.0})
	_seen.clear()

func _family_col(family: String) -> Color:
	match family:
		"bullseye": return Palette.GOLD_BRIGHT
		"perfect": return Palette.PERFECT
		"good": return Palette.GOLD
		"graze": return Palette.STEEL
		"baited": return PURPLE
		"read": return PURPLE.lightened(0.3)
		_: return Palette.CRIMSON

func _gate_x() -> float:
	return size.x - 78.0

func _pps() -> float:
	return (_gate_x() - 26.0) / maxf(0.5, horizon) * _tempo_vis

func _bar_x(eta: float) -> float:
	# interpolate between engine ticks (eta only changes at 30 Hz; the screen runs faster)
	return _gate_x() - (eta - tick_frac * TICK_DT) * _pps()

func _draw() -> void:
	var w := size.x
	var h := size.y
	var cy := h * 0.46
	# --- the glass channel + the mode skin ---
	var bg0 := Palette.FILL_TOP
	var bg1 := Palette.FILL_BOT
	if flurry:
		bg0 = bg0.lerp(Palette.CRIMSON_DEEP, 0.45)
		bg1 = bg1.lerp(Palette.CRIMSON_DEEP, 0.3)
	draw_rect(Rect2(0, 0, w, h), bg1)
	draw_rect(Rect2(0, 0, w, h * 0.5), bg0)
	var edge := Palette.EDGE
	if flurry:
		var pulse := 0.5 + 0.5 * sin(_spin * 4.0)
		edge = Palette.CRIMSON.lerp(Palette.GOLD_BRIGHT, pulse)
		draw_string(get_theme_default_font(), Vector2(w * 0.5 - 92, 14),
			"FLURRY — DON'T MISS ONE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, edge)
	draw_rect(Rect2(0, 0, w, h), edge, false, 2.0)
	draw_line(Vector2(8, cy), Vector2(w - 8, cy), Palette.EDGE, 1.0)
	# --- THE GATE: the game-wide bullseye target (bands = the dodge ladder, drawn as
	#     approach-time; the steel notch = the binary parry land window) ---
	var gx := _gate_x()
	var pps := _pps()
	var bh := h - 26.0
	# SYMMETRIC bands (THE TWINFANG MODEL): the same grade a hair early or a hair late —
	# the late side is bounded by the resolve slack, so it draws shorter past the line.
	_gate_band(gx, cy, bh, win_graze * pps, Palette.STEEL.darkened(0.55))
	_gate_band(gx, cy, bh, win_good * pps, Palette.GOLD.darkened(0.25))
	_gate_band(gx, cy, bh, win_perfect * pps, Palette.PERFECT.darkened(0.1))
	_gate_band(gx, cy, bh, win_bullseye * pps, Palette.GOLD_BRIGHT)
	draw_rect(Rect2(gx - parry_window * pps, cy - bh * 0.5 - 4,
		minf(parry_window, late_slack) * pps + parry_window * pps, 3.0), Palette.STEEL)
	draw_line(Vector2(gx, cy - bh * 0.5 - 6), Vector2(gx, cy + bh * 0.5 + 6), Palette.TEXT, 2.0)
	# --- SHATTER shards (dead publisher's bars breaking) ---
	for sh_v in _shards:
		var sh: Dictionary = sh_v
		var t := float(sh["t"])
		var a := 1.0 - t / 0.6
		var col := Palette.STEEL
		col.a = a * 0.8
		var sx := float(sh["x"])
		draw_line(Vector2(sx - 6, cy - 8 + t * 40.0), Vector2(sx + 2, cy + 2 + t * 46.0), col, 2.0)
		draw_line(Vector2(sx + 5, cy - 6 + t * 44.0), Vector2(sx - 3, cy + 5 + t * 50.0), col, 2.0)
	# --- the committed comets (right-to-left; the engine already filtered/ordered them) ---
	var font := get_theme_default_font()
	for b_v in bars:
		var b: Dictionary = b_v
		var eta := float(b.get("eta", 0.0))
		var x := minf(_bar_x(eta), gx)                 # a resolving bar HOLDS the gate (the slack)
		if x < 10.0 or x > w - 10.0:
			continue
		var id := int(b.get("id", -1))
		if not _seen.has(id):
			_seen[id] = true
			if bool(b.get("late", false)):
				_flashes.append({"x": x, "t": 0.0})   # the LATE pop — flash where it appears
		_comet(x, cy, String(b.get("kind", "auto")), bool(b.get("purple", false)),
			int(b.get("flurry_i", 0)), font,
			bool(b.get("peeled", false)), bool(b.get("answered", false)))
	# --- the live telegraph riding the channel: a GLOBAL (boss colors, DODGE) or a
	#     targeted BUSTER (tank colors, PARRY) — both fully committed at start ---
	if not global_bar.is_empty():
		var gx2 := _bar_x(float(global_bar.get("eta", 0.0)))
		if gx2 > 10.0 and gx2 < w - 10.0:
			_octagon(gx2, cy, 19.0, GLOBAL_COL, Palette.GOLD_BRIGHT)
			_word(font, gx2, cy, "DODGE", Palette.GOLD_BRIGHT)
	if not buster_bar.is_empty():
		var bx := _bar_x(float(buster_bar.get("eta", 0.0)))
		if bx > 10.0 and bx < w - 10.0:
			var purple := bool(buster_bar.get("purple", false))
			_octagon(bx, cy, 18.0, PURPLE if purple else Palette.CRUSH,
				PURPLE.lightened(0.3) if purple else Palette.CRIMSON)
			_word(font, bx, cy, "PARRY", PURPLE if purple else Palette.CRIMSON)
	# --- LATE flashes ---
	for f_v in _flashes:
		var f: Dictionary = f_v
		var t := float(f["t"])
		var col := Color(1, 1, 1, (1.0 - t * 2.0) * 0.9)
		draw_arc(Vector2(float(f["x"]), cy), 14.0 + t * 34.0, 0, TAU, 20, col, 2.5)
	# --- verdict stamps (float up over the gate) ---
	for st_v in _stamps:
		var st: Dictionary = st_v
		var t := float(st["t"])
		var col: Color = st["col"]
		col.a = 1.0 - t / 0.9
		draw_string(font, Vector2(gx - 60, cy - 26 - t * 22.0), String(st["txt"]),
			HORIZONTAL_ALIGNMENT_CENTER, 120, 13, col)
	# --- the grade rail (last 8) ---
	for i in _rail.size():
		var col2 := _family_col(_rail[i])
		draw_rect(Rect2(w - 14, h - 12.0 - float(i) * 9.0, 7, 6), col2)
	# --- the quiet states ---
	if bars.is_empty() and global_bar.is_empty() and buster_bar.is_empty() and _shards.is_empty():
		var msg := "AGGRO LOST — IT HUNTS ANOTHER" if aggro_lost else ""
		if msg != "":
			draw_string(font, Vector2(w * 0.5 - 120, cy + 4), msg,
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.CRIMSON.lerp(Palette.TEXT_DIM, 0.3))

func _gate_band(gx: float, cy: float, bh: float, wpx: float, col: Color) -> void:
	col.a = 0.5
	var right := minf(wpx, late_slack * _pps())            # the late half, slack-bounded
	draw_rect(Rect2(gx - wpx, cy - bh * 0.5, wpx + right, bh), col)

## One committed comet. Shape = the kind's costume; purple tints a FEINT's disguise.
## PEELED (pass 2): drawn translucent with a crimson hunt-tick — it hunts a raider, the
## tank still answers it for flow. ANSWERED: dimmed hollow, its word gone (it's done).
func _comet(x: float, cy: float, kind: String, purple: bool, flurry_i: int, font: Font,
		peeled := false, answered := false) -> void:
	var fade := 1.0
	if answered:
		fade = 0.30
	elif peeled:
		fade = 0.55
	match kind:
		"heavy":
			_hexagon(x, cy, 15.0, _f(PURPLE if purple else Palette.HEAVY, fade))
			if not answered:
				_bullseye_dot(x, cy, 15.0)
				_word(font, x, cy, "PARRY", _f(PURPLE if purple else Palette.HEAVY, fade))
		"buster":
			_octagon(x, cy, 18.0, _f(PURPLE if purple else Palette.CRUSH, fade),
				_f(PURPLE.lightened(0.3) if purple else Palette.CRIMSON, fade))
			if not answered:
				_bullseye_dot(x, cy, 18.0)
				_word(font, x, cy, "PARRY", _f(PURPLE if purple else Palette.CRIMSON, fade))
		"eat":
			var col := _f(Palette.TEXT_DIM, fade)
			_diamond(x, cy, 13.0, col)
			draw_line(Vector2(x - 5, cy - 5), Vector2(x + 5, cy + 5), Palette.BG0, 2.0)
			draw_line(Vector2(x + 5, cy - 5), Vector2(x - 5, cy + 5), Palette.BG0, 2.0)
			if not answered:
				_word(font, x, cy, "EAT", col)
		"flurry":
			var col2 := _f(PURPLE if purple else Palette.FLOW, fade)
			draw_circle(Vector2(x, cy), 6.5, col2)
			draw_arc(Vector2(x, cy), 9.0, 0, TAU, 14, col2.darkened(0.3), 1.5)
			if flurry_i == 0 and not answered:
				_word(font, x, cy, "WEAVE", col2)
		_:
			_diamond(x, cy, 11.0, _f(PURPLE if purple else Palette.LIGHT, fade))
			if not answered:
				_word(font, x, cy, "DODGE", _f(PURPLE if purple else Palette.LIGHT, fade))
	if peeled and not answered:
		draw_line(Vector2(x - 4, cy + 18), Vector2(x + 4, cy + 18), Palette.CRIMSON, 2.0)

func _f(col: Color, fade: float) -> Color:
	col.a *= fade
	return col

## The mint center-dot: "a BULLSEYE dodge answers this" (heavy/buster only).
func _bullseye_dot(x: float, cy: float, r: float) -> void:
	draw_circle(Vector2(x, cy - r - 5.0), 2.5, Palette.PERFECT)

func _word(font: Font, x: float, cy: float, txt: String, col: Color) -> void:
	col.a = 0.95
	draw_string(font, Vector2(x - 30, cy + 30), txt, HORIZONTAL_ALIGNMENT_CENTER, 60, 11, col)

func _diamond(x: float, cy: float, r: float, col: Color) -> void:
	var pts := PackedVector2Array([Vector2(x, cy - r), Vector2(x + r * 0.72, cy),
		Vector2(x, cy + r), Vector2(x - r * 0.72, cy)])
	draw_colored_polygon(pts, col)
	draw_polyline(pts + PackedVector2Array([pts[0]]), col.lightened(0.35), 1.5)

func _hexagon(x: float, cy: float, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 6:
		var a := TAU * float(i) / 6.0 - PI / 2.0
		pts.append(Vector2(x + cos(a) * r * 0.8, cy + sin(a) * r))
	draw_colored_polygon(pts, col)
	draw_polyline(pts + PackedVector2Array([pts[0]]), col.lightened(0.35), 1.5)

## The spiked spinning octagon — the biggest-baddest shape (BUSTER in tank colors /
## GLOBAL in boss colors; the word carries the answer).
func _octagon(x: float, cy: float, r: float, col: Color, spike_col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 8:
		var a := TAU * float(i) / 8.0 + _spin
		pts.append(Vector2(x + cos(a) * r * 0.85, cy + sin(a) * r * 0.85))
	draw_colored_polygon(pts, col)
	for i in 8:
		var a2 := TAU * (float(i) + 0.5) / 8.0 + _spin
		var p0 := Vector2(x + cos(a2) * r * 0.85, cy + sin(a2) * r * 0.85)
		var p1 := Vector2(x + cos(a2) * (r * 0.85 + 6.0), cy + sin(a2) * (r * 0.85 + 6.0))
		draw_line(p0, p1, spike_col, 2.0)
	draw_polyline(pts + PackedVector2Array([pts[0]]), spike_col, 1.5)
