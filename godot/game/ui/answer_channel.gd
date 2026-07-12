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
## px/s is CONSTANT — whole-flow tempo is baked into each bar's impact_tick at publish, so
## a faster tempo shows as comets with closer etas, never a render-side rescale — TANK-V3).
##
## THE CLAIM MOMENT (tank-v3 juice pass, Bill 2026-07-12): a claimed comet no longer just
## blinks out under a fixed tag. The band routes the graded engine verdict to `resolve()`,
## which fires a SHAPE-AWARE death at the comet's own last on-screen spot (`_last_x`, tracked
## verbatim in _draw): a PARRY shape SHATTERS, a DODGE shape GHOSTS left past the gate, a MISS
## bursts a crimson X + edge-flash, a feint puffs purple. A position-anchored VERDICT punches
## in (grade color + ±ms readout) and floats up, and the GATE pulses the grade color (BULLSEYE
## blooms the gold center band). All one-shots — they never touch what the committed comets draw.
##
## THE GATE is the game-wide grading target (GRADING COHERENCE LAW): steel GRAZE band →
## gold GOOD → mint PERFECT → bright-gold BULLSEYE center, identical in reading to the
## Twinfang rhythm bar; the thin steel notch is the PARRY land window (binary). A tiny mint
## dot above a heavy/buster marks "bullseye-dodge legal". Pure view — never touches state.
class_name AnswerChannel
extends Control

const PURPLE := Color("b072c9")            # the feint tell (Palette.RELIC)
const DEATH_LIFE := 0.45                    # comet death-anim life (sec)
const VERDICT_LIFE := 0.85                  # position-anchored verdict pop life (sec)
const GATE_LIFE := 0.28                     # gate-reaction pulse life (sec)
const BURST_LIFE := 0.55                    # the press burst (frozen line + expanding ring) — Twinfang's hold
const TICK_DT := 1.0 / 30.0                 # one engine tick (sub-tick comet interpolation)

# --- fed by the band every frame (view data straight off observe()) ---
var bars: Array = []                       ## committed stream bars: {id,kind,purple,eta,late,answered,flurry_i,flurry_n}
var tick_frac: float = 0.0                 ## the controller's accumulator fraction (0..1) — comets
                                           ## interpolate BETWEEN 30 Hz ticks (§0 pass 2; no stair-step)
var tempo: float = 1.0                     ## whole-flow multiplier (TANK-V3: baked into impact_tick at publish, kept as a no-op input field)
var flurry: bool = false                   ## FLURRY MODE (border + label + bg tint)
var aggro_lost: bool = false               ## stream paused because the boss hunts another
var horizon: float = 3.0                   ## the engine's publish lead (mouth = this many sec out)
var win_bullseye: float = 0.07             ## grading windows (sec) — drawn as the gate bands
var win_perfect: float = 0.14
var win_good: float = 0.30
var win_graze: float = 0.50
var parry_window: float = 0.10

var _seen: Dictionary = {}                 ## bar id -> true (late-flash bookkeeping)
var _last_x: Dictionary = {}               ## bar id -> {x, kind, purple, absent} (the claim anchor)
var _flashes: Array = []                   ## [{x, t}] LATE pop-in rings
var _stamps: Array = []                    ## [{txt, col, t}] secondary callouts (COUNTER / RIPOSTE …) floating over the gate
var _deaths: Array = []                    ## [{x, kind, purple, col, shape, t, seed}] claim death one-shots
var _verdicts: Array = []                  ## [{x, col, txt, ms, t, rays}] position-anchored graded pops
var _rail: Array = []                      ## last 8 verdict families (the grade history)
var _shards: Array = []                    ## SHATTER ghosts: [{x, kind, t}]
var _spin: float = 0.0                     ## buster/global octagon spin phase
var _gate_pulse: float = 0.0               ## gate-reaction timer (any verdict)
var _gate_col: Color = Palette.GOLD        ## gate-reaction color
var _gate_bloom: float = 0.0               ## BULLSEYE center-band bloom timer
var _edge_flash: float = 0.0               ## crimson border flash timer (a leak)
var _press_flash: float = 0.0              ## press-accepted echo: the gate line kicks the frame you press
var _press_kind: String = "dodge"          ## which button (tints the kick)
var _dud_t: float = 0.0                    ## dry-press (fumble) echo: a brief crimson tick at the gate

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
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
	for d in _deaths:
		d["t"] += delta
	_deaths = _deaths.filter(func(d): return d["t"] < DEATH_LIFE)
	for v in _verdicts:
		v["t"] += delta
	_verdicts = _verdicts.filter(func(v): return v["t"] < VERDICT_LIFE)
	_gate_pulse = maxf(0.0, _gate_pulse - delta)
	_gate_bloom = maxf(0.0, _gate_bloom - delta)
	_edge_flash = maxf(0.0, _edge_flash - delta)
	_press_flash = maxf(0.0, _press_flash - delta)
	_dud_t = maxf(0.0, _dud_t - delta)
	queue_redraw()

## THE PRESS ECHO (§0 pass 2): the frame you press, the gate kicks — always, even before any
## verdict. A claimed press's full moment (resolve) lands right on top of this; an unclaimed
## one still proves the input registered. Cheap, never wrong: pure acknowledgment.
func press_tick(kind: String) -> void:
	_press_flash = 0.15
	_press_kind = kind

## The dry press (WINDED / mid-recovery): a brief crimson tick — the input registered, the
## body couldn't answer.
func dud() -> void:
	_dud_t = 0.3

## A secondary callout landed (COUNTER / RIPOSTE / EN GARDE …): a light floating tag over the
## gate + a rail gem. The graded per-comet answers go through `resolve()` instead (below).
func stamp(txt: String, family: String) -> void:
	_stamps.append({"txt": txt, "col": _family_col(family), "t": 0.0})
	_rail.append(family)
	if _rail.size() > 8:
		_rail.pop_front()

## THE CLAIM MOMENT. The band routes a graded engine verdict here off the same events it feeds
## the slam. `id` = the bar the press claimed (the band's on-deck id); we anchor the death +
## verdict at that comet's last drawn x (`_last_x`), falling back to the nearest-to-gate tracked
## comet, then the gate itself. `ms_txt` = the pass-2 earliness readout ("" hides it).
func resolve(id: int, family: String, txt: String, ms_txt: String) -> void:
	var x := _gate_x()
	var kind := "auto"
	var purple := false
	var key := id
	var rec = _last_x.get(id)                 # untyped: .get() into := is a parse error
	if rec == null:
		key = _nearest_key()
		rec = _last_x.get(key)
	if rec != null:
		x = float(rec["x"])
		kind = String(rec["kind"])
		purple = bool(rec["purple"])
		_last_x.erase(key)                     # consume so a second claim can't re-anchor here
	var col := _family_col(family)
	var shape := "ghost"
	if family == "hit":
		shape = "burst"
		_edge_flash = 1.0
	elif family == "baited" or family == "read":
		shape = "puff"
	elif kind == "heavy" or kind == "buster":
		shape = "shatter"
	_deaths.append({"x": x, "kind": kind, "purple": purple, "col": col, "shape": shape,
		"t": 0.0, "seed": float(absi(id) % 211)})
	_verdicts.append({"x": x, "col": col, "txt": txt, "ms": ms_txt, "t": 0.0,
		"rays": family == "bullseye"})
	_gate_pulse = GATE_LIFE
	_gate_col = col
	if family == "bullseye":
		_gate_bloom = GATE_LIFE * 1.4
	_rail.append(family)
	if _rail.size() > 8:
		_rail.pop_front()

## The tracked comet nearest the gate (largest x that hasn't passed it) — the fallback anchor
## when the band's id is stale (frame skew) so a claim still lands on a real comet, not the gate.
func _nearest_key() -> int:
	var best := -9999
	var best_x := -1.0e9
	var gx := _gate_x() + 6.0
	for k in _last_x:
		var rx := float(_last_x[k]["x"])
		if rx <= gx and rx > best_x:
			best_x = rx
			best = int(k)
	return best

## The publisher's body died — its committed bars SHATTER (visible: killing the attacker
## cancels its swings). The band calls this off the stream_shatter event.
func shatter() -> void:
	for b_v in bars:
		var b: Dictionary = b_v
		_shards.append({"x": _bar_x(float(b.get("eta", 0.0))), "kind": String(b.get("kind", "auto")), "t": 0.0})
	_seen.clear()
	_last_x.clear()

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
	# CONSTANT px/s (TANK-V3, NG2): x is a pure function of eta — no global rescale can shift
	# comets relative to each other. Whole-flow tempo is already baked into impact_tick at
	# publish, so denser tempo shows as closer etas, never a render-side stretch.
	return (_gate_x() - 26.0) / maxf(0.5, horizon)

func _bar_x(eta: float) -> float:
	# eta is tick-quantized (30 Hz); tick_frac carries the render frame's position INSIDE the
	# current tick, so comets slide smoothly at 60+ fps instead of stair-stepping (§0 pass 2).
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
	# a leak bleeds crimson at the channel border (complements the slam's full-screen vignette)
	if _edge_flash > 0.0:
		var ec := Palette.CRIMSON
		ec.a = 0.75 * _edge_flash
		draw_rect(Rect2(1, 1, w - 2, h - 2), ec, false, 3.0)
	draw_line(Vector2(8, cy), Vector2(w - 8, cy), Palette.EDGE, 1.0)
	# --- THE GATE: the game-wide bullseye target (bands = the dodge ladder, drawn as
	#     approach-time; the steel notch = the binary parry land window) ---
	var gx := _gate_x()
	var pps := _pps()
	var bh := h - 26.0
	_gate_band(gx, cy, bh, win_graze * pps, Palette.STEEL.darkened(0.55))
	_gate_band(gx, cy, bh, win_good * pps, Palette.GOLD.darkened(0.25))
	_gate_band(gx, cy, bh, win_perfect * pps, Palette.PERFECT.darkened(0.1))
	# BULLSEYE center band — blooms bright on a landed bullseye
	var bull_col := Palette.GOLD_BRIGHT
	if _gate_bloom > 0.0:
		var bf := _gate_bloom / (GATE_LIFE * 1.4)
		bull_col = bull_col.lightened(0.4 * bf)
		var bloom := Palette.GOLD_BRIGHT
		bloom.a = 0.5 * bf
		draw_rect(Rect2(gx - win_perfect * pps, cy - bh * 0.5, win_perfect * pps, bh), bloom)
	_gate_band(gx, cy, bh, win_bullseye * pps, bull_col)
	draw_rect(Rect2(gx - parry_window * pps, cy - bh * 0.5 - 4, 2.0, 8.0), Palette.STEEL)
	# the gate line — pulses the grade color on any verdict
	var gate_line := Palette.TEXT
	var gate_wid := 2.0
	if _gate_pulse > 0.0:
		var gf := _gate_pulse / GATE_LIFE
		gate_line = Palette.TEXT.lerp(_gate_col, gf)
		gate_wid = 2.0 + 2.0 * gf
		var glow := _gate_col
		glow.a = 0.28 * gf
		draw_rect(Rect2(gx - 6.0, cy - bh * 0.5 - 6, 12.0, bh + 12.0), glow)
	# THE PRESS ECHO — the gate KICKS white the frame you press (before any verdict lands):
	# instant proof the input registered, tinted by the button.
	if _press_flash > 0.0:
		var pf := _press_flash / 0.15
		var pcol := (Palette.STEEL if _press_kind == "parry" else Palette.FLOW).lerp(Color.WHITE, 0.6)
		gate_line = gate_line.lerp(pcol, pf)
		gate_wid = maxf(gate_wid, 2.0 + 2.5 * pf)
	draw_line(Vector2(gx, cy - bh * 0.5 - 6), Vector2(gx, cy + bh * 0.5 + 6), gate_line, gate_wid)
	# the DRY press (fumble): a crimson cross-tick at the gate — registered, but no wind
	if _dud_t > 0.0:
		var df := _dud_t / 0.3
		var dc := Palette.CRIMSON
		dc.a = 0.9 * df
		var dg := 5.0 + 4.0 * (1.0 - df)
		draw_line(Vector2(gx - dg, cy - dg), Vector2(gx + dg, cy + dg), dc, 2.5, true)
		draw_line(Vector2(gx + dg, cy - dg), Vector2(gx - dg, cy + dg), dc, 2.5, true)
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
	var present: Dictionary = {}
	for b_v in bars:
		var b: Dictionary = b_v
		var eta := float(b.get("eta", 0.0))
		var x := minf(_bar_x(eta), gx)                 # a resolving bar HOLDS the gate (the slack)
		if x < 10.0 or x > w - 10.0:
			continue
		var id := int(b.get("id", -1))
		var kind := String(b.get("kind", "auto"))
		var purple := bool(b.get("purple", false))
		var answered := bool(b.get("answered", false))
		present[id] = true
		_last_x[id] = {"x": x, "kind": kind, "purple": purple, "absent": 0}   # claim anchor, verbatim
		if not _seen.has(id):
			_seen[id] = true
			if bool(b.get("late", false)):
				_flashes.append({"x": x, "t": 0.0})   # the LATE pop — flash where it appears
		_comet(x, cy, kind, purple, int(b.get("flurry_i", 0)), font, answered)
	# prune anchors for comets long gone (claims fire within a frame of disappearance, so keep
	# a short grace); consumed anchors are erased in resolve()
	var stale: Array = []
	for k in _last_x:
		if present.has(k):
			_last_x[k]["absent"] = 0
		else:
			_last_x[k]["absent"] = int(_last_x[k]["absent"]) + 1
			if int(_last_x[k]["absent"]) > 3:
				stale.append(k)
	for k in stale:
		_last_x.erase(k)
	# TANK-V3: the octagon projection is GONE. Raid-wide GLOBALS + targeted BUSTERS render on
	# the SHARED JUDGE (boss surface), answered by the fall-through press — the channel draws
	# ONLY the committed melee stream (one widget, one source of truth, NG1).
	# --- LATE flashes ---
	for f_v in _flashes:
		var f: Dictionary = f_v
		var t := float(f["t"])
		var col := Color(1, 1, 1, (1.0 - t * 2.0) * 0.9)
		draw_arc(Vector2(float(f["x"]), cy), 14.0 + t * 34.0, 0, TAU, 20, col, 2.5)
	# --- claim deaths (shatter / ghost / burst / puff) at the comet's own last spot ---
	for d_v in _deaths:
		_draw_death(d_v, cy)
	# --- secondary callouts (COUNTER / RIPOSTE …) float up LEFT of the gate, clear of the
	#     position-anchored verdict so the two never muddy each other ---
	for st_v in _stamps:
		var st: Dictionary = st_v
		var t := float(st["t"])
		var col: Color = st["col"]
		col.a = 1.0 - t / 0.9
		draw_string(font, Vector2(gx - 236, cy - 30 - t * 22.0), String(st["txt"]),
			HORIZONTAL_ALIGNMENT_CENTER, 150, 12, col)
	# --- position-anchored graded verdicts (the readability core) ---
	for v_v in _verdicts:
		_draw_verdict(v_v, cy, font)
	# --- the grade rail (last 8) ---
	for i in _rail.size():
		var col2 := _family_col(_rail[i])
		draw_rect(Rect2(w - 14, h - 12.0 - float(i) * 9.0, 7, 6), col2)
	# --- the quiet glass: no committed melee this instant. The channel no longer goes blank
	#     on aggro loss (peeled comets still ride it translucent), and boss GLOBALS/CASTS live
	#     on the judge — so an empty channel just means the melee runway is momentarily clear. ---
	if bars.is_empty() and _shards.is_empty():
		draw_string(font, Vector2(w * 0.5 - 32, cy + 4), "— HOLD —",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Palette.TEXT_DIM)

func _gate_band(gx: float, cy: float, bh: float, wpx: float, col: Color) -> void:
	col.a = 0.5
	draw_rect(Rect2(gx - wpx, cy - bh * 0.5, wpx, bh), col)

## The shape polygon for a kind (shared by comet / ghost / shatter so a death looks like the
## comet that died). Returns points around (x, cy).
func _shape_pts(kind: String, x: float, cy: float, r: float) -> PackedVector2Array:
	match kind:
		"heavy":
			var hp := PackedVector2Array()
			for i in 6:
				var a := TAU * float(i) / 6.0 - PI / 2.0
				hp.append(Vector2(x + cos(a) * r * 0.8, cy + sin(a) * r))
			return hp
		"buster":
			var op := PackedVector2Array()
			for i in 8:
				var a := TAU * float(i) / 8.0
				op.append(Vector2(x + cos(a) * r * 0.85, cy + sin(a) * r * 0.85))
			return op
		_:
			return PackedVector2Array([Vector2(x, cy - r), Vector2(x + r * 0.72, cy),
				Vector2(x, cy + r), Vector2(x - r * 0.72, cy)])

## One claim death, shape-aware, at the dead comet's spot.
func _draw_death(d: Dictionary, cy: float) -> void:
	var t := float(d["t"])
	var e := clampf(t / DEATH_LIFE, 0.0, 1.0)
	var ease := 1.0 - (1.0 - e) * (1.0 - e)     # ease-out
	var x := float(d["x"])
	var col: Color = d["col"]
	var seed := float(d["seed"])
	match String(d["shape"]):
		"shatter":
			var n := 8 if String(d["kind"]) == "buster" else 6
			for i in n:
				var ang := TAU * float(i) / float(n) - PI / 2.0 + sin(seed + float(i)) * 0.2
				var reach := (16.0 + 30.0 * ease) * (0.75 + 0.45 * absf(sin(seed * 1.7 + float(i))))
				var c := col
				c.a = (1.0 - e) * 0.95
				var p0 := Vector2(x + cos(ang) * (5.0 + 9.0 * ease), cy + sin(ang) * (5.0 + 9.0 * ease))
				var p1 := Vector2(x + cos(ang) * reach, cy + sin(ang) * reach)
				draw_line(p0, p1, c, 2.4 * (1.0 - e * 0.6), true)
			var rc := col.lightened(0.4)
			rc.a = (1.0 - e) * 0.85
			draw_arc(Vector2(x, cy), 8.0 + 42.0 * ease, 0, TAU, 30, rc, 2.6 * (1.0 - e), true)
			if e < 0.3:
				draw_circle(Vector2(x, cy), 5.0, Color(1, 1, 1, (1.0 - e / 0.3) * 0.7))
		"ghost":
			var sx := x - 30.0 * ease            # slips left, past the gate
			var a := (1.0 - e) * 0.85
			for k in 3:
				var gxk := sx + float(k) * 8.0
				var c := col
				c.a = a * (0.55 - 0.16 * float(k))
				var pts := _shape_pts(String(d["kind"]), gxk, cy, 12.0 + 2.0 * e)
				draw_polyline(pts + PackedVector2Array([pts[0]]), c, 1.6, true)
		"burst":
			var g := 7.0 + 15.0 * ease
			var c := Palette.CRIMSON
			c.a = (1.0 - e) * 0.95
			draw_line(Vector2(x - g, cy - g), Vector2(x + g, cy + g), c, 3.0 * (1.0 - e * 0.5), true)
			draw_line(Vector2(x + g, cy - g), Vector2(x - g, cy + g), c, 3.0 * (1.0 - e * 0.5), true)
			for i in 4:
				var ang := TAU * (float(i) + 0.5) / 4.0
				var rr := 10.0 + 22.0 * ease
				var c2 := Palette.CRIMSON
				c2.a = (1.0 - e) * 0.7
				draw_line(Vector2(x, cy), Vector2(x + cos(ang) * rr, cy + sin(ang) * rr), c2, 2.0 * (1.0 - e), true)
		"puff":
			var pc := PURPLE
			pc.a = (1.0 - e) * 0.8
			draw_arc(Vector2(x, cy), 6.0 + 24.0 * ease, 0, TAU, 22, pc, 2.2 * (1.0 - e), true)
			for i in 6:
				var ang := TAU * float(i) / 6.0 + seed
				var rr := 8.0 + 20.0 * ease
				var pc2 := PURPLE.lightened(0.2)
				pc2.a = (1.0 - e) * 0.7
				draw_circle(Vector2(x + cos(ang) * rr, cy + sin(ang) * rr), 2.0 * (1.0 - e * 0.5), pc2)

## The position-anchored graded verdict + THE PRESS BURST (rhythm_bar.gd's ghost, ported —
## the fading vertical line + the expanding circle that freeze WHERE you pressed). NO ease-in:
## the verdict punches at full size FRAME 1 and only decays (§0 pass 2 — the 0.12s scale-in
## read as lag); rays fire immediately. Float up + fade, grade color, ±ms sub-line.
func _draw_verdict(v: Dictionary, cy: float, font: Font) -> void:
	var t := float(v["t"])
	var punch := 1.0 + 0.35 * exp(-t * 14.0)             # full-size on frame 1, settles fast
	var y := cy - 26.0 - t * 30.0
	var fade := clampf((VERDICT_LIFE - t) / 0.3, 0.0, 1.0)
	var x := float(v["x"])
	var col: Color = v["col"]
	col.a = fade
	# --- THE PRESS BURST (Twinfang verbatim): its own ~0.55s per-frame decay ---
	var bf := clampf(1.0 - t / BURST_LIFE, 0.0, 1.0)
	if bf > 0.0:
		var bh := size.y - 26.0
		var lc: Color = v["col"]
		lc.a = 0.85 * bf
		# the frozen vertical line at the press pixel
		draw_line(Vector2(x, cy - bh * 0.5 - 2.0), Vector2(x, cy + bh * 0.5 + 2.0), lc, 3.0, true)
		# the expanding circle ABOVE the track (r 6 -> 28 as it fades)
		var br := 6.0 + 22.0 * (1.0 - bf)
		var rc0: Color = v["col"]
		rc0.a = 0.7 * bf
		draw_arc(Vector2(x, cy - bh * 0.5 - 10.0), br, 0.0, TAU, 24, rc0, 2.0, true)
		if bool(v["rays"]):
			# BULLSEYE: the second (mint) ring inside the burst
			var mc2 := Palette.PERFECT
			mc2.a = 0.8 * bf
			draw_arc(Vector2(x, cy - bh * 0.5 - 10.0), 14.0, 0.0, TAU, 20, mc2, 1.6, true)
	if bool(v["rays"]):
		var rf := clampf(t / 0.3, 0.0, 1.0)
		for k in 8:
			var a := TAU * float(k) / 8.0 + t * 1.2
			var rc := Palette.GOLD_BRIGHT
			rc.a = fade * 0.8 * (1.0 - rf)
			var c := Vector2(x, y - 5.0)
			draw_line(c + Vector2(cos(a), sin(a)) * (12.0 + 10.0 * rf),
				c + Vector2(cos(a), sin(a)) * (20.0 + 18.0 * rf), rc, 1.8, true)
	var fs := int(round(15.0 * punch))
	var sh := Color(0, 0, 0, 0.7 * fade)
	draw_string(font, Vector2(x - 70.0, y + 1.5), String(v["txt"]), HORIZONTAL_ALIGNMENT_CENTER, 140, fs, sh)
	draw_string(font, Vector2(x - 70.0, y), String(v["txt"]), HORIZONTAL_ALIGNMENT_CENTER, 140, fs, col)
	var ms := String(v["ms"])
	if ms != "":
		var mc := Palette.TEXT_DIM
		mc.a = fade * 0.95
		draw_string(font, Vector2(x - 50.0, y + 13.0), ms, HORIZONTAL_ALIGNMENT_CENTER, 100, 10, mc)

## One committed comet. Shape = the kind's costume; purple tints a FEINT's disguise. A subtle
## motion trail (pure function of x — comets slide in from the right) sells the constant speed.
## An ANSWERED comet (claimed at the press, still resolving through the slack) draws as a dim
## hollow husk — the death anim + verdict carry the punch; the husk just stays honest.
func _comet(x: float, cy: float, kind: String, purple: bool, flurry_i: int, font: Font,
		answered: bool = false) -> void:
	if answered:
		var hc := (PURPLE if purple else _comet_col(kind))
		hc.a = 0.3
		var hr := 18.0 if kind == "buster" else (15.0 if kind == "heavy" else 11.0)
		var hpts := _shape_pts(kind, x, cy, hr)
		draw_polyline(hpts + PackedVector2Array([hpts[0]]), hc, 1.6, true)
		return
	if kind != "eat":
		_trail(x, cy, kind, purple)
	match kind:
		"heavy":
			_glow(x, cy, 15.0, PURPLE if purple else Palette.HEAVY)
			_hexagon(x, cy, 15.0, PURPLE if purple else Palette.HEAVY)
			_bullseye_dot(x, cy, 15.0)
			_word(font, x, cy, "PARRY", PURPLE if purple else Palette.HEAVY)
		"buster":
			_glow(x, cy, 18.0, PURPLE if purple else Palette.CRUSH)
			_octagon(x, cy, 18.0, PURPLE if purple else Palette.CRUSH,
				PURPLE.lightened(0.3) if purple else Palette.CRIMSON)
			_bullseye_dot(x, cy, 18.0)
			_word(font, x, cy, "PARRY", PURPLE if purple else Palette.CRIMSON)
		"eat":
			var col := Palette.TEXT_DIM
			_diamond(x, cy, 13.0, col)
			draw_line(Vector2(x - 5, cy - 5), Vector2(x + 5, cy + 5), Palette.BG0, 2.0)
			draw_line(Vector2(x + 5, cy - 5), Vector2(x - 5, cy + 5), Palette.BG0, 2.0)
			_word(font, x, cy, "EAT", col)
		"flurry":
			var col2 := PURPLE if purple else Palette.FLOW
			draw_circle(Vector2(x, cy), 6.5, col2)
			draw_arc(Vector2(x, cy), 9.0, 0, TAU, 14, col2.darkened(0.3), 1.5)
			if flurry_i == 0:
				_word(font, x, cy, "WEAVE", col2)
		_:
			_diamond(x, cy, 11.0, PURPLE if purple else Palette.LIGHT)
			_word(font, x, cy, "DODGE", PURPLE if purple else Palette.LIGHT)
	# a feint's disguise breathes a faint purple ring — the only tell
	if purple:
		var pr := PURPLE
		pr.a = 0.18 + 0.14 * sin(_spin * 3.0)
		draw_arc(Vector2(x, cy), 18.0, 0, TAU, 18, pr, 1.4, true)

## Motion trail: 2 faint afterimages to the right (where the comet came from). Pure function of
## position — no stored history. Kept low-alpha so the track stays legible.
func _trail(x: float, cy: float, kind: String, purple: bool) -> void:
	var base := PURPLE if purple else _comet_col(kind)
	for k in range(1, 3):
		var tx := x + float(k) * 9.0
		if tx > _gate_x() + 4.0:
			continue
		var c := base
		c.a = 0.10 - 0.035 * float(k - 1)
		var pts := _shape_pts(kind, tx, cy, (11.0 if kind != "buster" else 16.0) - float(k) * 1.5)
		draw_colored_polygon(pts, c)

func _comet_col(kind: String) -> Color:
	match kind:
		"heavy": return Palette.HEAVY
		"buster": return Palette.CRUSH
		"flurry": return Palette.FLOW
		"eat": return Palette.TEXT_DIM
		_: return Palette.LIGHT

## A soft glow halo behind the big shapes (heavy / buster) — reads their weight at a glance.
func _glow(x: float, cy: float, r: float, col: Color) -> void:
	var c := col
	c.a = 0.12 + 0.05 * sin(_spin * 2.0)
	draw_circle(Vector2(x, cy), r + 6.0, c)

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
