## AnswerChannel — THE CHANNEL (TANK-PLAN §0, tank-v2): the game's ONE answer instrument.
## Draws the engine's COMMITTED timeline verbatim — comets slide right-to-left at constant
## px/s into the IMPACT GATE; the widget has ZERO prediction logic, so nothing can pop,
## morph, or jump (LAW 1). Class-agnostic by construction: it renders whatever bars + the
## live telegraph the band feeds it (the Duelist is its first client; other classes migrate
## later and inherit it unchanged).
##
## THE VOCABULARY (SHAPE LAW 2026-07-13 — shape=answer · color=status · size=damage):
## ◇ diamond = DODGE or PARRY (auto / light personal beat) · ⬡ hexagon = DODGE-only (global /
## flurry) · ⯃ spiked octagon = PARRY-only (heavy / buster / HEAVY personal beat) · ☠ skull =
## BRACE (eat). COLOR is STATUS, never the answer: PURPLE = feint (a lie in a real shape + the
## breathing ring) · RED = peeled (the boss hunts another seat — still yours) · BLUE = flurry.
## SIZE scales the shape (light pokes small, big commits large). LATE bars pop in mid-track
## with a flash (THE SPEED LAW: difficulty is WHEN a bar appears, never how fast it moves;
## px/s is CONSTANT — whole-flow tempo is baked into each bar's impact_tick at publish, so
## a faster tempo shows as comets with closer etas, never a render-side rescale — TANK-V3).
##
## THE CLAIM MOMENT (§0 pass 2 + the AAA pass, 2026-07-12): a press is judged AT the press —
## the engine's duel_answer arrives the same tick you clicked, carrying the claimed bar's id +
## signed off_ms. `resolve()` anchors everything at that comet's frozen last-drawn pixel
## (`_last_x`): THE PRESS BURST (Twinfang's ghost — a fading vertical line + an expanding
## circle above, BULLSEYE adds the mint ring), a SHAPE-AWARE death (PARRY SHATTERS, DODGE
## GHOSTS, MISS bursts a crimson X, feint puffs purple), and a position-anchored VERDICT that
## punches at FULL SIZE frame 1 (no ease-in — ease-out only) with the ±ms readout. The GATE
## pulses the grade color (BULLSEYE blooms). Comets interpolate between 30 Hz ticks
## (tick_frac); every press echoes the frame it lands (press_tick / dud). All one-shots —
## they never touch what the committed comets draw.
##
## THE GATE is the game-wide grading target (GRADING COHERENCE LAW), SYMMETRIC around the
## gate line like the grading is (§0 pass 2): steel GRAZE → gold GOOD → mint PERFECT →
## bright-gold BULLSEYE centre band, gem-set mullions at the graze edges and the gilded
## aim-plumb on the gate line — identical in reading to the Twinfang rhythm bar; the steel
## notches are the PARRY land window (now the GOOD/BULLSEYE zone, not a binary). Pure view.
class_name AnswerChannel
extends Control

const PURPLE := Color("b072c9")            # the feint tell (Palette.RELIC)
const FLURRY_COL := Color("5bc8ff")        # BLUE = flurry / WEAVE mode (status color, SHAPE LAW)
const DEATH_LIFE := 0.45                    # comet death-anim life (sec)
const VERDICT_LIFE := 0.85                  # position-anchored verdict pop life (sec)
const GATE_LIFE := 0.28                     # gate-reaction pulse life (sec)
const BURST_LIFE := 0.55                    # the press burst (frozen line + expanding ring) — Twinfang's hold
const TICK_DT := 1.0 / 30.0                 # one engine tick (sub-tick comet interpolation)

# --- fed by the band every frame (view data straight off observe()) ---
var bars: Array = []                       ## committed stream bars: {id,kind,purple,eta,late,peeled,victim,answered,flurry_i,flurry_n}
var tbars: Array = []                      ## ONE BAR (2026-07-12): telegraph comets — GLOBALS (dodge) +
                                           ## targeted BUSTERS (parry) + my beats, synthetic negative ids
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

var late_grace: float = 0.04               ## the true post-line press window (sec) — the right-side
                                           ## bands draw ONLY this wide (everything visible is pressable)
# --- ART V2 / C6B (set ONLY by the dash host; both default off ⇒ legacy byte-identical) ---
var v2_skin: DashSkin = null               ## painted comet icons (◇⬡⯃⊘ + purple feints), resolved at
                                           ## construction by DashSkin (§3½ — never load in a draw).
                                           ## PURPLE ALONE is the feint tell in V2 — no breathing ring.
var v2_naked: bool = false                 ## the painted answer frame owns the housing — skip the
                                           ## channel's own seat/border/filigree, keep the glass + gate
var _seen: Dictionary = {}                 ## bar id -> true (late-flash bookkeeping)
var _last_x: Dictionary = {}               ## bar id -> {x, kind, purple, absent} (the claim anchor)
var _missed: Array = []                    ## THE MISS AFTERLIFE (Bill 2026-07-12): [{x0,kind,purple,t}] —
                                           ## an unpressed comet crosses the line, turns red + ✗ and keeps
                                           ## flowing to the end of the bar ("I missed it, it kept going")
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
	for k in _seen:
		_seen[k] = float(_seen[k]) + delta            # comet age — drives the spawn-in pop
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
	for m in _missed:
		m["t"] += delta
	_missed = _missed.filter(func(m): return m["t"] < 0.9)
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

## THE MISS AFTERLIFE: an unpressed comet crossed the line — flip it red + ✗ and let it keep
## flowing to the end of the bar. Seeded from the comet's own last-drawn spot (consumed so
## the death/verdict machinery can't double-anchor there).
func missed(id: int) -> void:
	var rec = _last_x.get(id)                 # untyped: .get() into := is a parse error
	if rec == null:
		return
	if bool(rec["purple"]):
		# belt-and-braces: a fake NEVER wears the red ✗ — it dissolves purple
		_deaths.append({"x": float(rec["x"]), "kind": String(rec["kind"]), "purple": true,
			"col": PURPLE, "shape": "puff", "t": 0.0, "seed": float(absi(id) % 211)})
	else:
		_missed.append({"x0": float(rec["x"]), "kind": String(rec["kind"]),
			"purple": false, "t": 0.0})
	_last_x.erase(id)

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
	var floor_x := _gate_x() - 70.0           # verdicts belong to the gate neighborhood —
	for k in _last_x:                          # never anchor on a comet still mid-track
		var rx := float(_last_x[k]["x"])
		if rx <= gx and rx >= floor_x and rx > best_x:
			best_x = rx
			best = int(k)
	return best

## THE GUARD: the boss rears up for its big move — the marked bars break off the track
## (selective shatter; the rest of the runway flows on). Shards at each comet's own pixel.
func shatter_ids(ids: Array) -> void:
	for id_v in ids:
		var rec = _last_x.get(int(id_v))          # untyped: .get() into := is a parse error
		if rec != null:
			_shards.append({"x": float(rec["x"]), "kind": String(rec["kind"]), "t": 0.0})
			_last_x.erase(int(id_v))

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
	# --- the gilded glass channel + the mode skin (AAA pass: grad glass, bevel, filigree) ---
	var bg0 := Palette.FILL_TOP
	var bg1 := Palette.FILL_BOT
	if flurry:
		bg0 = bg0.lerp(Palette.CRIMSON_DEEP, 0.45)
		bg1 = bg1.lerp(Palette.CRIMSON_DEEP, 0.3)
	UiKit.grad_rect(self, Rect2(0, 0, w, h), bg0, bg1)
	if not v2_naked:
		draw_rect(Rect2(0, h - 3.0, w, 3.0), Color(0, 0, 0, 0.35))   # seated base shadow
		draw_rect(Rect2(0, 0, w, 2.0), Color(1, 1, 1, 0.05))         # glass sheen lip
	var edge := Palette.EDGE
	if flurry:
		var pulse := 0.5 + 0.5 * sin(_spin * 4.0)
		edge = Palette.CRIMSON.lerp(Palette.GOLD_BRIGHT, pulse)
		UiKit.engraved_plaque(self, Vector2(w * 0.5, 10.0), "FLURRY — DON'T MISS ONE", true)
		# a travelling shimmer sells the quickened flow
		var sx2 := fmod(_spin * 90.0, w - 20.0) + 10.0
		var shim := Palette.CRIMSON.lightened(0.4)
		shim.a = 0.20
		draw_rect(Rect2(sx2, 4.0, 9.0, h - 8.0), shim)
	if not v2_naked:                       # C6B: the painted frame IS the housing
		draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0, 0.5), false, 3.0)    # dark outer seat
		draw_rect(Rect2(1, 1, w - 2, h - 2), edge if flurry else Palette.GOLD_DIM.darkened(0.2), false, 1.5)
		UiKit.filigree_corner(self, Vector2(0, 0), Vector2(1, 1))
		UiKit.filigree_corner(self, Vector2(w, 0), Vector2(-1, 1))
		UiKit.filigree_corner(self, Vector2(0, h), Vector2(1, -1))
		UiKit.filigree_corner(self, Vector2(w, h), Vector2(-1, -1))
	elif flurry:                           # the mode edge still reads on the naked glass
		draw_rect(Rect2(1, 1, w - 2, h - 2), edge, false, 1.5)
	# a leak bleeds crimson at the channel border (complements the slam's full-screen vignette)
	if _edge_flash > 0.0:
		var ec := Palette.CRIMSON
		ec.a = 0.75 * _edge_flash
		draw_rect(Rect2(1, 1, w - 2, h - 2), ec, false, 3.0)
	draw_line(Vector2(8, cy), Vector2(w - 8, cy), Palette.EDGE, 1.0)
	# --- THE GATE: the game-wide bullseye target, SYMMETRIC around the gate line (the
	#     grading is — §0 pass 2). Same read as the Twinfang rhythm bar's centre model:
	#     graze flanks → gold GOOD → mint PERFECT core → bright-gold BULLSEYE centre,
	#     gem-set mullions at the graze edges, the gilded aim-plumb on the line itself.
	#     The steel notches above/below = the binary PARRY land window. ---
	var gx := _gate_x()
	var pps := _pps()
	var bh := h - 26.0
	var ty := cy - bh * 0.5
	_gate_band(gx, cy, bh, win_graze * pps, Palette.STEEL.darkened(0.55), 0.14)
	_gate_band(gx, cy, bh, win_good * pps, Palette.GOLD.darkened(0.25), 0.16)
	var core := Palette.PERFECT.lightened(0.1)
	_gate_band(gx, cy, bh, win_perfect * pps, core, 0.20)
	# BULLSEYE centre band — blooms bright on a landed bullseye
	var bull_col := Palette.GOLD_BRIGHT
	var bull_a := 0.45
	if _gate_bloom > 0.0:
		var bf := _gate_bloom / (GATE_LIFE * 1.4)
		bull_col = bull_col.lightened(0.4 * bf)
		bull_a = 0.55 + 0.35 * bf
		var bloom := Palette.GOLD_BRIGHT
		bloom.a = 0.4 * bf
		draw_rect(Rect2(gx - win_perfect * pps, ty,
			win_perfect * pps + minf(win_perfect, late_grace) * pps, bh), bloom)
		UiKit.glow(self, Vector2(gx, cy), 46.0 + 30.0 * bf, Color(bull_col.r, bull_col.g, bull_col.b, 0.35 * bf))
	_gate_band(gx, cy, bh, win_bullseye * pps, bull_col, bull_a)
	# gem-set mullion at the band's CLOSE (the true late edge — the hard stop line). The
	# OPEN/approach edge is deliberately UNMARKED (Bill 2026-07-12): where you can start
	# clicking is implied by the grading bands lighting up, not a printed blue line.
	var cmx := gx + minf(win_graze, late_grace) * pps
	draw_line(Vector2(cmx, ty + 2), Vector2(cmx, ty + bh - 2), Palette.BG0, 3.0, true)
	draw_line(Vector2(cmx + 1.0, ty + 2), Vector2(cmx + 1.0, ty + bh - 2), Palette.STEEL, 1.2, true)
	draw_circle(Vector2(cmx, ty - 3.0), 2.2, Palette.STEEL.lightened(0.2))
	# the PARRY land window — steel notches above + below the track (late side = the grace)
	var pw := parry_window * pps
	var pwr := pw + minf(parry_window, late_grace) * pps
	draw_rect(Rect2(gx - pw, ty - 5.0, pwr, 3.0), Palette.STEEL)
	draw_rect(Rect2(gx - pw, ty + bh + 2.0, pwr, 3.0), Palette.STEEL)
	# THE HEARTBEAT: the gate leans in as the next comet closes — anticipation you can feel
	var next_eta := 9.9
	for b_v2 in bars:
		var b2: Dictionary = b_v2
		if not bool(b2.get("answered", false)):
			next_eta = minf(next_eta, float(b2.get("eta", 9.9)))
	for tb_v2 in tbars:
		var tb2: Dictionary = tb_v2
		if not bool(tb2.get("answered", false)):
			next_eta = minf(next_eta, float(tb2.get("eta", 9.9)))
	var beat := clampf(1.0 - next_eta / 0.5, 0.0, 1.0)
	if beat > 0.0:
		UiKit.glow(self, Vector2(gx, cy), 30.0 + 14.0 * beat,
			Color(Palette.GOLD_BRIGHT.r, Palette.GOLD_BRIGHT.g, Palette.GOLD_BRIGHT.b, 0.10 + 0.20 * beat))
	# the gate line — the gilded AIM PLUMB (RhythmBar's idiom: dark seat + gold stroke +
	# white hairline + a gem at heart). Pulses the grade color on any verdict.
	var gate_line := Palette.GOLD_BRIGHT
	gate_line.a = 0.85
	var gate_wid := 1.6 + 0.8 * beat
	if _gate_pulse > 0.0:
		var gf := _gate_pulse / GATE_LIFE
		gate_line = gate_line.lerp(_gate_col, gf)
		gate_wid = 1.6 + 2.0 * gf
		var glow := _gate_col
		glow.a = 0.28 * gf
		draw_rect(Rect2(gx - 6.0, ty - 6, 12.0, bh + 12.0), glow)
	# THE PRESS ECHO — the gate KICKS white the frame you press (before any verdict lands):
	# instant proof the input registered, tinted by the button.
	if _press_flash > 0.0:
		var pf := _press_flash / 0.15
		var pcol := (Palette.STEEL if _press_kind == "parry" else Palette.FLOW).lerp(Color.WHITE, 0.6)
		gate_line = gate_line.lerp(pcol, pf)
		gate_wid = maxf(gate_wid, 1.6 + 3.0 * pf)
		UiKit.glow(self, Vector2(gx, cy), 34.0, Color(pcol.r, pcol.g, pcol.b, 0.30 * pf))
	draw_line(Vector2(gx, ty - 6), Vector2(gx, ty + bh + 6), Palette.BG0, 3.4, true)
	draw_line(Vector2(gx, ty - 6), Vector2(gx, ty + bh + 6), gate_line, gate_wid, true)
	draw_line(Vector2(gx, ty - 4), Vector2(gx, ty + bh + 4), Color(1, 1, 1, 0.45 + 0.3 * beat), 0.7, true)
	draw_circle(Vector2(gx, cy), 3.2 + 1.6 * beat, Palette.GOLD_BRIGHT)
	draw_circle(Vector2(gx - 0.9, cy - 1.0), 1.0, Color(1, 1, 1, 0.75))
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
		_last_x[id] = {"x": x, "kind": kind, "purple": purple, "answered": answered, "absent": 0}   # claim anchor, verbatim
		if not _seen.has(id):
			_seen[id] = 0.0
			if bool(b.get("late", false)):
				_flashes.append({"x": x, "t": 0.0})   # the LATE pop — flash where it appears
		var age := float(_seen.get(id, 1.0))
		var sc := (1.0 + 0.45 * maxf(0.0, 1.0 - age / 0.22)) \
			* (1.0 + 0.10 * clampf(1.0 - eta / 0.55, 0.0, 1.0))
		if age < 0.2 and not bool(b.get("late", false)):
			var bc := Color(1, 1, 1, 0.5 * (1.0 - age / 0.2))
			draw_arc(Vector2(x, cy), 10.0 + age * 90.0, 0, TAU, 20, bc, 1.6, true)
		_comet(x, cy, kind, purple, int(b.get("flurry_i", 0)), font, answered,
			bool(b.get("peeled", false)), String(b.get("victim", "")), sc, int(b.get("size", -1)))
	# --- ONE BAR: telegraph comets (GLOBALS / targeted BUSTERS / my beats) on the same
	#     track — committed times off the live telegraph, same gate, same press ---
	for tb_v in tbars:
		var tb: Dictionary = tb_v
		var teta := float(tb.get("eta", 0.0))
		var tx2 := minf(_bar_x(teta), gx)
		if tx2 < 10.0 or tx2 > w - 10.0:
			continue
		var tid := int(tb.get("id", -1))
		var tkind := String(tb.get("kind", "global"))
		var tpurple := bool(tb.get("purple", false))
		present[tid] = true
		_last_x[tid] = {"x": tx2, "kind": tkind, "purple": tpurple,
			"answered": bool(tb.get("answered", false)), "absent": 0}
		if not _seen.has(tid):
			_seen[tid] = 0.0
			_flashes.append({"x": tx2, "t": 0.0})     # big moves announce themselves
		var tage := float(_seen.get(tid, 1.0))
		var tsc := (1.0 + 0.45 * maxf(0.0, 1.0 - tage / 0.22)) \
			* (1.0 + 0.10 * clampf(1.0 - teta / 0.55, 0.0, 1.0))
		_comet(tx2, cy, tkind, tpurple, 0, font, bool(tb.get("answered", false)), false, "", tsc, int(tb.get("size", -1)))
	# prune anchors for comets long gone (claims fire within a frame of disappearance, so keep
	# a short grace); consumed anchors are erased in resolve()/missed(). A TELEGRAPH comet
	# (negative id) that expires unconsumed at the gate = an unanswered big move — it gets
	# the same red miss-afterlife (stream bars get theirs via the duel_bar_missed event).
	var stale: Array = []
	for k in _last_x:
		if present.has(k):
			_last_x[k]["absent"] = 0
		else:
			_last_x[k]["absent"] = int(_last_x[k]["absent"]) + 1
			if int(_last_x[k]["absent"]) > 3:
				stale.append(k)
	for k in stale:
		var was_purple: bool = bool(_last_x[k]["purple"])
		var was_answered: bool = bool(_last_x[k].get("answered", false))
		if int(k) < 0 and float(_last_x[k]["x"]) >= gx - 10.0 and not was_answered:
			if was_purple:
				# a held FAKE dissolves purple — success feedback, never the red ✗
				_deaths.append({"x": float(_last_x[k]["x"]), "kind": String(_last_x[k]["kind"]),
					"purple": true, "col": PURPLE, "shape": "puff", "t": 0.0,
					"seed": float(absi(int(k)) % 211)})
			else:
				_missed.append({"x0": float(_last_x[k]["x"]), "kind": String(_last_x[k]["kind"]),
					"purple": false, "t": 0.0})
		_last_x.erase(k)
	# --- THE MISS AFTERLIFE: red ✗ husks keep flowing past the line to the bar's end ---
	for m_v in _missed:
		var m: Dictionary = m_v
		var mt := float(m["t"])
		var mx := float(m["x0"]) + mt * _pps()
		if mx > w - 10.0:
			continue
		var ma := clampf(1.0 - mt / 0.9, 0.0, 1.0)
		var mc := Palette.CRIMSON
		mc.a = 0.85 * ma
		var mr := 16.0 if String(m["kind"]) == "buster" or String(m["kind"]) == "global" else 12.0
		var mpts := _shape_pts(String(m["kind"]), mx, cy, mr)
		draw_polyline(mpts + PackedVector2Array([mpts[0]]), mc, 2.0, true)
		var xg := mr * 0.55
		draw_line(Vector2(mx - xg, cy - xg), Vector2(mx + xg, cy + xg), mc, 2.4, true)
		draw_line(Vector2(mx + xg, cy - xg), Vector2(mx - xg, cy + xg), mc, 2.4, true)
	# TANK-V3: the octagon projection is GONE. Raid-wide GLOBALS + targeted BUSTERS render on
	# the SHARED JUDGE (boss surface), answered by the fall-through press — the channel draws
	# ONLY the committed melee stream (one widget, one source of truth, NG1).
	# --- LATE flashes: a golden SHOCKWAVE where the reaction test pops in ---
	for f_v in _flashes:
		var f: Dictionary = f_v
		var t := float(f["t"])
		var fa := clampf(1.0 - t * 2.0, 0.0, 1.0)
		var fx := float(f["x"])
		UiKit.glow(self, Vector2(fx, cy), 30.0 * (1.0 - t), Color(Palette.GOLD_BRIGHT.r, Palette.GOLD_BRIGHT.g, Palette.GOLD_BRIGHT.b, 0.4 * fa))
		var col := Palette.GOLD_BRIGHT
		col.a = 0.9 * fa
		draw_arc(Vector2(fx, cy), 14.0 + t * 34.0, 0, TAU, 24, col, 2.5, true)
		var col2 := Color(1, 1, 1, 0.7 * fa)
		draw_arc(Vector2(fx, cy), 8.0 + t * 46.0, 0, TAU, 24, col2, 1.4, true)
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
		UiKit.text_shadowed(self, UiKit.display(600, 1), Vector2(gx - 236, cy - 30 - t * 22.0),
			String(st["txt"]), HORIZONTAL_ALIGNMENT_CENTER, 150, UiKit.SIZE["LABEL"], col)
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
	if bars.is_empty() and tbars.is_empty() and _shards.is_empty():
		UiKit.text_shadowed(self, UiKit.display(600, 3), Vector2(w * 0.5 - 60, cy + 4),
			"— HOLD —", HORIZONTAL_ALIGNMENT_CENTER, 120, UiKit.SIZE["LABEL"], Palette.TEXT_DIM)

## One grading band at the gate — full width on the approach side, but the far side draws
## ONLY as wide as the true post-line press window (late_grace): everything visible is
## pressable, nothing more (Bill 2026-07-12 — no dead target past the stop line).
func _gate_band(gx: float, cy: float, bh: float, wpx: float, col: Color, a: float = 0.5) -> void:
	col.a = a
	var right := minf(wpx, late_grace * _pps())
	draw_rect(Rect2(gx - wpx, cy - bh * 0.5, wpx + right, bh), col)

## The shape polygon for a kind (shared by comet / ghost / shatter so a death looks like the
## comet that died). Returns points around (x, cy).
func _shape_pts(kind: String, x: float, cy: float, r: float) -> PackedVector2Array:
	match kind:
		"heavy", "buster":
			var op := PackedVector2Array()
			for i in 8:
				var a := TAU * float(i) / 8.0
				op.append(Vector2(x + cos(a) * r * 0.85, cy + sin(a) * r * 0.85))
			return op
		"global":
			var hp := PackedVector2Array()
			for i in 6:
				var a := TAU * float(i) / 6.0 - PI / 2.0
				hp.append(Vector2(x + cos(a) * r * 0.8, cy + sin(a) * r))
			return hp
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
			# VERTICAL slip (Bill 2026-07-12): the fading outline rises off the track —
			# horizontal drift crowded the next incoming tone.
			var sy := cy - 26.0 * ease
			var a := (1.0 - e) * 0.85
			for k in 3:
				var gyk := sy - float(k) * 7.0
				var c := col
				c.a = a * (0.55 - 0.16 * float(k))
				var pts := _shape_pts(String(d["kind"]), x, gyk, 12.0 + 2.0 * e)
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
	var fs := int(round(float(UiKit.SIZE["SUBHEAD"]) * punch))
	var vf := UiKit.display(700, 1)
	var sh := Color(0, 0, 0, 0.7 * fade)
	draw_string(vf, Vector2(x - 70.0, y + 1.5), String(v["txt"]), HORIZONTAL_ALIGNMENT_CENTER, 140, fs, sh)
	draw_string(vf, Vector2(x - 70.0, y), String(v["txt"]), HORIZONTAL_ALIGNMENT_CENTER, 140, fs, col)
	var ms := String(v["ms"])
	if ms != "":
		var mc := Palette.TEXT_DIM
		mc.a = fade * 0.95
		draw_string(font, Vector2(x - 50.0, y + 13.0), ms, HORIZONTAL_ALIGNMENT_CENTER, 100, UiKit.SIZE["MICRO"], mc)

## One committed comet. Shape = the kind's costume; purple tints a FEINT's disguise. A subtle
## motion trail (pure function of x — comets slide in from the left) sells the constant speed.
## An ANSWERED comet (claimed at the press, still resolving through the slack) draws as a dim
## hollow husk — the death anim + verdict carry the punch; the husk just stays honest.
## A PEELED comet (§0 pass 2: the boss hunts someone else) draws with a crimson hunt-chevron +
## its victim's name — the tank still answers it (the comeback); the damage is the victim's.
func _comet(x: float, cy: float, kind: String, purple: bool, flurry_i: int, font: Font,
		answered: bool = false, peeled: bool = false, victim: String = "", sc: float = 1.0,
		size: int = -1) -> void:
	if answered:
		var hc := (PURPLE if purple else _comet_col(kind))
		hc.a = 0.3
		var hr := 18.0 if kind == "buster" else (15.0 if kind == "heavy" else 11.0)
		var hpts := _shape_pts(kind, x, cy, hr)
		draw_polyline(hpts + PackedVector2Array([hpts[0]]), hc, 1.6, true)
		return
	if peeled:
		# the hunt-tick: a crimson chevron over the comet + the hunted raider's name
		var pk := Palette.CRIMSON
		pk.a = 0.85 + 0.15 * sin(_spin * 3.0)
		var py := cy - 24.0
		draw_line(Vector2(x - 5, py - 4), Vector2(x, py + 2), pk, 2.2, true)
		draw_line(Vector2(x + 5, py - 4), Vector2(x, py + 2), pk, 2.2, true)
		if victim != "":
			var vc := Palette.CRIMSON.lightened(0.3)
			vc.a = 0.9
			UiKit.text_shadowed(self, UiKit.body(500), Vector2(x - 50, py - 8), "→ " + victim,
				HORIZONTAL_ALIGNMENT_CENTER, 100, UiKit.SIZE["MICRO"], vc)
	if kind != "eat":
		_trail(x, cy, kind, purple)
	# SHAPE = the button · COLOR = status (_stat_col) · SIZE = damage (the radius).
	var r := _size_r(kind, size) * sc
	# --- C6B: the painted icon set (◇⬡⯃ + purple feints + the ⊘ BRACE disc that
	# retires the skull/X). SAME live geometry — x/cy/r come from the committed
	# feed exactly as the polygons did; the texture only changes the costume.
	# Status law holds: a feint rides its own PAINTED purple variant (purple wins,
	# and PURPLE ALONE is the tell — the breathing ring is deliberately gone in
	# V2); peeled modulates crimson; flurry modulates blue; BRACE is never purple.
	if v2_skin != null:
		var itex := v2_skin.icon(kind, purple)
		if itex != null:
			var mod := Color.WHITE
			if not purple:
				if peeled:
					mod = Palette.CRIMSON.lightened(0.25)
				elif kind == "flurry":
					mod = FLURRY_COL.lightened(0.30)
			if kind == "heavy" or kind == "buster":
				_glow(x, cy, r + 3.0, PURPLE if purple else _comet_col(kind))
			var ih := r * 2.6
			var iw := ih * float(itex.get_width()) / float(itex.get_height())
			draw_texture_rect(itex, Rect2(x - iw * 0.5 + 1.5, cy - ih * 0.5 + 2.5, iw, ih),
				false, Color(0, 0, 0, 0.45))            # seated shadow (one virtual light)
			draw_texture_rect(itex, Rect2(x - iw * 0.5, cy - ih * 0.5, iw, ih), false, mod)
			if kind != "flurry" or flurry_i == 0:
				_word(font, x, cy, _v2_word(kind), _stat_col(_comet_col(kind), purple, peeled))
			return
	match kind:
		"heavy", "buster":
			# ⯃ PARRY-ONLY spiked octagon — bronze/amber, sized by damage
			var oc := _stat_col(Palette.HEAVY, purple, peeled)
			_glow(x, cy, r + 3.0, oc)
			_octagon(x, cy, r, oc, oc.lightened(0.4))
			_word(font, x, cy, "PARRY", oc)
		"global":
			# ⬡ DODGE-ONLY hexagon — the boss's room-wide move, cool steel; every seat dodges
			var gc := _stat_col(Palette.STEEL.lightened(0.2), purple, peeled)
			_glow(x, cy, r + 2.0, gc)
			_hexagon(x, cy, r, gc)
			_word(font, x, cy, "DODGE", gc)
		"flurry":
			# ⬡ DODGE-ONLY weave cluster — BLUE (status), a rapid WEAVE string
			var fc := PURPLE if purple else FLURRY_COL
			draw_circle(Vector2(x, cy), 6.5 * sc, fc)
			draw_arc(Vector2(x, cy), 9.0 * sc, 0, TAU, 14, fc.darkened(0.3), 1.5)
			if flurry_i == 0:
				_word(font, x, cy, "WEAVE", fc)
		"eat":
			# ☠ BRACE — a muted crossed marker; no press
			var col := Palette.TEXT_DIM
			_diamond(x, cy, 13.0 * sc, col)
			draw_line(Vector2(x - 5, cy - 5), Vector2(x + 5, cy + 5), Palette.BG0, 2.0)
			draw_line(Vector2(x + 5, cy - 5), Vector2(x - 5, cy + 5), Palette.BG0, 2.0)
			_word(font, x, cy, "EAT", col)
		_:
			# ◇ DODGE-or-PARRY diamond (auto / light personal beat) — warm gold, THE base read
			var dc := _stat_col(Palette.GOLD_BRIGHT, purple, peeled)
			_diamond(x, cy, r, dc)
			_word(font, x, cy, "DODGE", dc)
	# a feint's disguise breathes a faint purple ring — the only tell
	if purple:
		var pr := PURPLE
		pr.a = 0.18 + 0.14 * sin(_spin * 3.0)
		draw_arc(Vector2(x, cy), 18.0 * sc, 0, TAU, 18, pr, 1.4, true)

## The printed answer under a V2 comet — same word law as the polygons, plus the
## §2.3.1 A-table BRACE read for the eat token (the skull/X presentation retires
## with the painted ⊘; legacy keeps EAT untouched).
func _v2_word(kind: String) -> String:
	match kind:
		"heavy", "buster": return "PARRY"
		"global": return "DODGE"
		"flurry": return "WEAVE"
		"eat": return "BRACE"
		_: return "DODGE"

## Motion trail: layered afterimages BEHIND the comet (toward the mouth it came from — comets
## travel left→right into the gate) + a soft glow streak. Pure function of position — no
## stored history. Alphas ramped so the motion reads at a glance while the track stays legible.
func _trail(x: float, cy: float, kind: String, purple: bool) -> void:
	var base := PURPLE if purple else _comet_col(kind)
	UiKit.glow(self, Vector2(x - 8.0, cy), 16.0, Color(base.r, base.g, base.b, 0.10))
	if v2_skin != null:                    # C6B: the afterimages wear the painted icon too
		var itex := v2_skin.icon(kind, purple)
		if itex != null:
			for k in range(1, 4):
				var tx := x - float(k) * 8.0
				if tx < 12.0:
					continue
				var ih := ((26.0 if kind != "buster" else 38.0) - float(k) * 4.0)
				var iw := ih * float(itex.get_width()) / float(itex.get_height())
				draw_texture_rect(itex, Rect2(tx - iw * 0.5, cy - ih * 0.5, iw, ih),
					false, Color(1, 1, 1, 0.16 - 0.05 * float(k - 1)))
			return
	for k in range(1, 4):
		var tx := x - float(k) * 8.0
		if tx < 12.0:
			continue
		var c := base
		c.a = 0.16 - 0.05 * float(k - 1)
		var pts := _shape_pts(kind, tx, cy, (11.0 if kind != "buster" else 16.0) - float(k) * 1.8)
		draw_colored_polygon(pts, c)

## COLOR = STATUS (SHAPE LAW): a feint wears purple, a peeled comet wears red; else the shape
## keeps its quiet base tint — the shape already told the player the answer.
func _stat_col(base: Color, purple: bool, peeled: bool) -> Color:
	if purple:
		return PURPLE
	if peeled:
		return Palette.CRIMSON
	return base

## SIZE = damage: light pokes draw small, the big commits draw large. `size` is the strike's
## AbilityRes.Size (or -1 to derive from the kind for committed bars that carry no size field).
func _size_r(kind: String, size: int) -> float:
	var sz := size if size >= 0 else _kind_size(kind)
	match sz:
		AbilityRes.Size.CRUSH: return 18.0
		AbilityRes.Size.HEAVY: return 15.0
		_: return 11.0

func _kind_size(kind: String) -> int:
	match kind:
		"buster": return AbilityRes.Size.CRUSH
		"heavy", "global": return AbilityRes.Size.HEAVY
		_: return AbilityRes.Size.LIGHT

## The shape's quiet BASE tint (trails + husks) — matches _comet's shape colors. Status
## (purple/peel/blue) is applied at draw time in _stat_col, not here.
func _comet_col(kind: String) -> Color:
	match kind:
		"heavy", "buster": return Palette.HEAVY
		"global": return Palette.STEEL.lightened(0.2)
		"flurry": return FLURRY_COL
		"eat": return Palette.TEXT_DIM
		_: return Palette.GOLD_BRIGHT   # auto / beat — the base diamond

## A soft glow halo behind the big shapes (heavy / buster) — reads their weight at a glance.
## AAA pass: a real radial bloom (UiKit.glow), breathing.
func _glow(x: float, cy: float, r: float, col: Color) -> void:
	UiKit.glow(self, Vector2(x, cy), r * 2.1,
		Color(col.r, col.g, col.b, 0.30 + 0.08 * sin(_spin * 2.0)))

## The answer word under a comet — Cinzel smallcaps, shadowed (AAA pass: no more tiny
## default-font glyphs; the word is the read, it must land at a glance).
func _word(_font: Font, x: float, cy: float, txt: String, col: Color) -> void:
	col.a = 0.98
	UiKit.text_shadowed(self, UiKit.display(650, 1), Vector2(x - 40, cy + 31), txt,
		HORIZONTAL_ALIGNMENT_CENTER, 80, UiKit.SIZE["LABEL"], col)

## Shape drop shadow — every comet sits ON the glass, not IN it (one virtual light).
func _shape_shadow(pts: PackedVector2Array) -> void:
	var sp := PackedVector2Array()
	for p in pts:
		sp.append(p + Vector2(1.5, 2.5))
	draw_colored_polygon(sp, Color(0, 0, 0, 0.45))

## A tiny specular tick on the lit (top-left) rim — the shapes read as set gems.
func _specular(x: float, cy: float, r: float) -> void:
	draw_circle(Vector2(x - r * 0.32, cy - r * 0.42), maxf(1.2, r * 0.14), Color(1, 1, 1, 0.55))

func _diamond(x: float, cy: float, r: float, col: Color) -> void:
	var pts := PackedVector2Array([Vector2(x, cy - r), Vector2(x + r * 0.72, cy),
		Vector2(x, cy + r), Vector2(x - r * 0.72, cy)])
	_shape_shadow(pts)
	UiKit.glow(self, Vector2(x, cy), r * 1.7, Color(col.r, col.g, col.b, 0.22))
	draw_colored_polygon(pts, col)
	draw_polyline(pts + PackedVector2Array([pts[0]]), col.lightened(0.4), 1.8, true)
	_specular(x, cy, r)

func _hexagon(x: float, cy: float, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 6:
		var a := TAU * float(i) / 6.0 - PI / 2.0
		pts.append(Vector2(x + cos(a) * r * 0.8, cy + sin(a) * r))
	_shape_shadow(pts)
	draw_colored_polygon(pts, col)
	draw_polyline(pts + PackedVector2Array([pts[0]]), col.lightened(0.4), 1.8, true)
	_specular(x, cy, r)

## The spiked spinning octagon — the biggest-baddest shape (BUSTER in tank colors /
## GLOBAL in boss colors; the word carries the answer).
func _octagon(x: float, cy: float, r: float, col: Color, spike_col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 8:
		var a := TAU * float(i) / 8.0 + _spin
		pts.append(Vector2(x + cos(a) * r * 0.85, cy + sin(a) * r * 0.85))
	_shape_shadow(pts)
	draw_colored_polygon(pts, col)
	for i in 8:
		var a2 := TAU * (float(i) + 0.5) / 8.0 + _spin
		var p0 := Vector2(x + cos(a2) * r * 0.85, cy + sin(a2) * r * 0.85)
		var p1 := Vector2(x + cos(a2) * (r * 0.85 + 6.0), cy + sin(a2) * (r * 0.85 + 6.0))
		draw_line(p0, p1, spike_col, 2.0, true)
	draw_polyline(pts + PackedVector2Array([pts[0]]), spike_col, 1.8, true)
	_specular(x, cy, r * 0.9)
