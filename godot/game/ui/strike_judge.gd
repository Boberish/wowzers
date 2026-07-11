## The JUDGMENT CHANNEL — the game's precision-timing instrument, and the enemy
## cast bar fused into one reliquary device. Every telegraph pours toward a fixed
## gilded IMPACT GATE at the right end of a recessed glass channel: incoming
## swings/beats are comet-gems sliding right at a CONSTANT speed (fixed px/sec, so
## the approach reads the same on every attack and every HUD — muscle memory
## transfers), and the graded stained-glass bands before the gate (GRAZE steel /
## GOOD gold / PERFECT mint, all constant width) tell you exactly how tight your
## press was. The gate hairline is the "aim here" mark the dial's radial sweep
## never gave you.
##
## Feedback loop: a press freezes a VERDICT STAMP at the comet's exact position
## (ghost needle + burst; gold rays on PERFECT), a verdict line calls it, and a
## GRADE-HISTORY gem rail (bottom right) keeps the last several judgments visible
## — so in a fast string you can read at a glance whether what you're doing is
## working. Feints render as hollow purple comets over a hatched DON'T-PRESS
## veil; interruptible casts show the violet clean-kick band; boss self-heals
## fill the channel green (burn it down). Whiffing into the dodge lockout drops
## a crimson hatch veil so panic-mashing is visibly punished.
##
## Pure presentation: fed each frame from observe() (`feed`) and the combat event
## stream (`on_event`). It never touches CombatState.
class_name StrikeJudge
extends Control

## AAA feedback (Bill 2026-07-11): every verdict also fires here so the band can slam
## it center-screen. `family`: perfect | good | graze | hit | baited | read.
signal verdict(txt: String, family: String)

var pps := 250.0              ## approach speed, px per second — THE timing constant
                              ## (per-instance since ONE BAR: the tank's wide channel
                              ## runs faster so its short-lead rhythm enters at the mouth)
var size_verbs := false       ## §3½ height law words: small bars say DODGE, HEAVY+ say PARRY
var big := false              ## BIG display mode (the tank): taller track, larger comets/fonts
const STAMP_HOLD := 0.8       ## seconds a verdict stamp stays on the channel
const VERDICT_HOLD := 0.85
const HIST_MAX := 8

var verb := "PARRY"           ## the class defensive verb (classic swings)
var seat_ref: Object = null   ## raid: my seat — events are filtered against it
var compact := false          ## no header row; cast name lives inside the channel

# ---- per-frame model (rebuilt by feed) ----
var _active := false
var _name := ""
var _kind := ""               ## classic | feint | kick | heal | empower | brace | string
var _size := 0                ## classic swing size (LIGHT/HEAVY/CRUSH colour)
var _mine := true             ## classic swing aimed at me / next string beat mine
var _dur := 0.0
var _rem := 0.0               ## classic: time to impact · string: next mine beat
var _window := 0.0            ## classic parry window / kick clean window (seconds)
var _perfect_w := 0.14
var _good_w := 0.34
var _graze_w := 0.5
var _press_ok := true         ## the relevant press (defense / dodge) is available
var _beats: Array = []        ## string comets: {rem,size,feint,aoe,mine,answered,resolved,grade,victim}
var _combo_i := 0
var _combo_n := 0
var _next_feint := false      ## the next answerable thing is a feint — DON'T PRESS

# ---- verdict / juice state ----
var _stamps: Array = []       ## {x_frac, col, t, rays}
var _verdict := ""
var _verdict_col := Color.WHITE
var _verdict_t := 0.0
var _history: Array = []      ## {col, hollow, big}
var _hist_pop := 0.0          ## newest-gem pop-in scale timer
var _gate_hit := 0.0          ## impact flash at the gate (miss/landed)
var _pulse := 0.0
var _alpha := 0.0
var _linger := 0.0            ## keeps the instrument lit briefly after a swing ends

# ---- bookkeeping for miss detection / classic verdicts ----
var _seen := {}               ## "tick:idx" -> true once resolution was judged
var _tg_tick := -1
var _classic_closed := true   ## a negate/stagger already explained this classic swing
var _classic_defensible := false
var _classic_feint := false
var _last_rem := {}           ## beat idx -> last known remaining (stamp placement)
var _rhythm_armed := false    ## §3½ ONE BAR: a rhythm swing is in flight
var _rhythm_answered := false ## it got a duel_answer verdict (else its end = a MISS)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	_pulse += delta * 7.0
	_verdict_t = maxf(0.0, _verdict_t - delta)
	_hist_pop = maxf(0.0, _hist_pop - delta * 4.0)
	_gate_hit = maxf(0.0, _gate_hit - delta * 3.0)
	_linger = maxf(0.0, _linger - delta)
	for st in _stamps:
		st["t"] = float(st["t"]) - delta
	_stamps = _stamps.filter(func(st): return float(st["t"]) > 0.0)
	var want := 1.0 if (_active or _verdict_t > 0.0 or not _stamps.is_empty() or _linger > 0.0) else 0.16
	_alpha = lerpf(_alpha, want, minf(1.0, delta * 9.0))
	modulate.a = _alpha
	queue_redraw()

# ============================================================ FEED (per frame)
## `classic_window` = the seconds-wide answer window for a classic swing on THIS
## class (bulwark def_zone / twinfang dodge active / voidcaller clean zone).
func feed(s: CombatState, obs: Dictionary, classic_window: float) -> void:
	_perfect_w = s.config.strike_perfect
	_good_w = s.config.strike_good
	_graze_w = s.config.strike_graze
	var tg: Dictionary = obs.get("telegraph", {})
	if tg.is_empty():
		if _active:
			_close_classic_if_unexplained()
			_linger = maxf(_linger, 0.7)
		_active = false
		_beats = []
		_combo_n = 0
		return
	var tick := int(tg.get("tick", -1))
	if tick != _tg_tick:
		if _active:
			_close_classic_if_unexplained()   # chain verse landed and rolled straight on
		_tg_tick = tick
		_seen.clear()
		_last_rem.clear()
		_classic_closed = false
	_active = true
	_dur = float(s.telegraph.dur_ticks) * s.dt
	_name = s.telegraph.ability.name
	_rem = float(tg.get("remaining", 0.0))
	var beats_src: Array = tg.get("strikes", [])
	if beats_src.is_empty():
		_feed_classic(tg, obs, classic_window)
	else:
		_feed_string(beats_src, obs)

## §3½ THE ONE BAR: between real telegraphs the tank's auto-attack stream rides THIS
## channel — same gate, same bands, same comets, same verdicts. `lane` comes from
## observe()'s tank-only rhythm_lane telemetry: armed -> the real swing's comet;
## unarmed -> the projected NEXT swing glides in (eta = timer + windup, so the comet
## transitions seamlessly into the armed swing — nothing ever pops). A real telegraph
## simply takes the channel back (feed() overwrites) — globals and the rhythm share
## one instrument, which is the whole point. Empty lane = the old resting ghost.
func feed_rhythm(s: CombatState, lane: Dictionary, dodge_ok: bool, zone: float) -> void:
	_perfect_w = s.config.strike_perfect
	_good_w = s.config.strike_good
	_graze_w = s.config.strike_graze
	if lane.is_empty():
		if _active:
			_close_classic_if_unexplained()
			_linger = maxf(_linger, 0.7)
		_active = false
		_beats = []
		_combo_n = 0
		_rhythm_armed = false
		return
	if _active and _kind != "rhythm":      # leaving a real telegraph for the stream
		_close_classic_if_unexplained()
		_seen.clear()
		_last_rem.clear()
		_tg_tick = -1
	# armed == a bar is coming at ME (the stream only carries the tank's own bars now; a peeled
	# swing is an undodgeable hit that never reaches this channel — see observe()).
	var armed := bool(lane.get("armed", false))
	# an armed bar of MINE ended with no verdict -> it landed (the eaten-bar miss)
	if _kind == "rhythm" and _rhythm_armed and not armed and _mine and not _rhythm_answered:
		_judge_miss()
	if armed and not _rhythm_armed:
		_rhythm_answered = false
	_rhythm_armed = armed
	_active = true
	_kind = "rhythm"
	_classic_defensible = true             # the gold answer-window band (else-branch)
	_classic_closed = true                 # the classic closer never re-judges the stream
	_next_feint = false
	_combo_n = 0
	_beats = []
	_size = int(lane.get("size", AbilityRes.Size.LIGHT))
	_window = zone
	_press_ok = dodge_ok
	_dur = maxf(0.05, float(lane.get("windup", 0.6)))
	_mine = true                           # the stream only ever shows the tank's own bars
	if armed:
		_rem = float(lane.get("remaining", 0.0))
		_name = "THE RHYTHM"
	else:
		# projection: it's my NEXT swing (eta >= windup > window, so the live-window
		# flare can never light early)
		_mine = true
		_rem = float(lane.get("next_eta", 0.0))
		_name = "THE RHYTHM"

func _feed_classic(tg: Dictionary, obs: Dictionary, classic_window: float) -> void:
	_beats = []
	_combo_n = 0
	_press_ok = true
	_mine = bool(tg.get("targets_me", true))
	_size = int(tg.get("size", 0))
	_window = classic_window
	_classic_defensible = bool(tg.get("defensible", false))
	_classic_feint = bool(tg.get("feint", false))
	_next_feint = _classic_feint
	if _classic_feint:
		_kind = "feint"
		_press_ok = bool(obs.get("defense_ready", true))
	elif bool(tg.get("interruptible", false)):
		_kind = "kick"
		_press_ok = bool(obs.get("defense_ready", true))
	elif bool(tg.get("heal", false)):
		_kind = "heal"
	elif bool(tg.get("empower", false)):
		_kind = "empower"
	elif _classic_defensible:
		_kind = "classic"
		_press_ok = bool(obs.get("defense_ready", true))
	else:
		_kind = "brace"

func _feed_string(beats_src: Array, obs: Dictionary) -> void:
	_kind = "string"
	_classic_defensible = false
	_press_ok = bool(obs.get("dodge_ready", true))
	_combo_n = beats_src.size()
	_combo_i = _combo_n
	_next_feint = false
	_mine = false
	var arr: Array = []
	var next_found := false
	for i in beats_src.size():
		var b: Dictionary = beats_src[i]
		var resolved := bool(b.get("resolved", false))
		var answered := bool(b.get("answered", false))
		var mine := bool(b.get("mine", true)) \
			and int(b.get("guard", 0)) != StrikeRes.Guard.UNANSWERABLE
		var rem := float(b.get("remaining", 0.0))
		if not resolved:
			_last_rem[i] = rem
		var key := "%d:%d" % [_tg_tick, i]
		if resolved and not _seen.has(key):
			_seen[key] = true
			# a beat of MINE landed unanswered and un-faked -> a synthesized MISS
			# (the engine only emits grades for presses and held-feint READs)
			if mine and not answered and not bool(b.get("feint", false)):
				_judge_miss()
		if not resolved and not next_found:
			_combo_i = i + 1
			if mine and not answered:
				next_found = true
				_mine = true
				_rem = rem
				_next_feint = bool(b.get("feint", false))
		arr.append({"rem": rem, "size": int(b.get("size", 0)),
			"feint": bool(b.get("feint", false)), "aoe": bool(b.get("aoe", false)),
			"mine": mine, "answered": answered, "resolved": resolved,
			"grade": int(b.get("grade", -1)), "victim": String(b.get("victim", ""))})
	_beats = arr

## Classic swing ended with no negate/stagger to explain it: it LANDED (or a
## feint of mine got correctly HELD — the READ event handles the celebration).
func _close_classic_if_unexplained() -> void:
	if _classic_closed or _kind == "string":
		return
	_classic_closed = true
	if _kind == "classic" and _mine and _classic_defensible:
		_judge_miss()

func _judge_miss() -> void:
	_push_history(Palette.CRIMSON, false, false)
	_gate_hit = 1.0
	_set_verdict("HIT", Palette.CRIMSON)

# ============================================================ EVENTS
## Forward every combat event here; the judge picks out what belongs to it.
func on_event(ev: Dictionary) -> void:
	if not _ev_is_me(ev):
		return
	match String(ev.get("t", "")):
		"negate":
			# only a CLASSIC negate is a press verdict here — string dodges emit
			# their own negate at impact, already judged by strike_graded.
			if _kind == "string" or _classic_closed or not _active:
				return
			_classic_closed = true
			if bool(ev.get("feint", false)):
				_stamp(_rem, Palette.CRIMSON, false)
				_push_history(Palette.RELIC, true, false)
				_set_verdict("BAITED!", Palette.CRIMSON)
			else:
				_judge_classic_press()
		"strike_graded":
			var idx := int(ev.get("idx", -1))
			var rem := float(_last_rem.get(idx, 0.0))
			match int(ev.get("grade", 0)):
				StrikeRes.Grade.PERFECT:
					_stamp(rem, Palette.GOLD_BRIGHT, true)
					_push_history(Palette.GOLD_BRIGHT, false, true)
					_set_verdict("PERFECT", Palette.GOLD_BRIGHT)
				StrikeRes.Grade.GOOD:
					_stamp(rem, Palette.GOLD, false)
					_push_history(Palette.GOLD, false, false)
					_set_verdict("GOOD", Palette.GOLD)
				StrikeRes.Grade.GRAZE:
					_stamp(rem, Palette.STEEL, false)
					_push_history(Palette.STEEL, false, false)
					_set_verdict("GRAZE — half", Palette.STEEL)
				StrikeRes.Grade.BAITED:
					_stamp(rem, Palette.CRIMSON, false)
					_push_history(Palette.RELIC, true, false)
					_set_verdict("BAITED!", Palette.CRIMSON)
				StrikeRes.Grade.READ:
					_push_history(Palette.RELIC, false, false)
					_set_verdict("READ — held it", Palette.RELIC)
				StrikeRes.Grade.MISS:
					_judge_miss()
		"duel_answer":
			# the Duelist funnel's press verdict (rhythm bars + its classic swings —
			# string beats already arrive as strike_graded)
			if _kind == "string" or not _active:
				return
			_rhythm_answered = true
			_classic_closed = true
			var dv := "PARRY" if String(ev.get("kind", "dodge")) == "parry" else "DODGE"
			match int(ev.get("grade", 0)):
				StrikeRes.Grade.PERFECT:
					_stamp(_rem, Palette.GOLD_BRIGHT, true)
					_push_history(Palette.GOLD_BRIGHT, false, true)
					_set_verdict("PERFECT %s" % dv, Palette.GOLD_BRIGHT)
				StrikeRes.Grade.GOOD:
					_stamp(_rem, Palette.GOLD, false)
					_push_history(Palette.GOLD, false, false)
					_set_verdict("%s!" % dv, Palette.GOLD)
				_:
					_stamp(_rem, Palette.STEEL, false)
					_push_history(Palette.STEEL, false, false)
					_set_verdict("GRAZE — half", Palette.STEEL)
		"dodge_whiff":
			_stamp(minf(_rem, _view_secs()), Palette.CRIMSON.darkened(0.1), false)
			_push_history(Palette.CRIMSON.darkened(0.2), true, false)
			_set_verdict("TOO EARLY — locked", Palette.CRIMSON.darkened(0.1))
		"read":
			_push_history(Palette.RELIC, false, false)
			_set_verdict("READ — held it", Palette.RELIC)
		"staggered", "interrupt":
			if not _active:
				return
			_classic_closed = true
			var clean := bool(ev.get("clean", false))
			var col := Palette.WIN if bool(ev.get("was_heal", false)) else \
				(Palette.GOLD_BRIGHT if clean else Palette.KICK)
			_stamp(_rem, col, clean)
			_push_history(col, false, clean)
			if bool(ev.get("was_heal", false)):
				_set_verdict("DENIED!", col)
			else:
				_set_verdict("CLEAN KICK!" if clean else "KICKED!", col)
		"int_whiff":
			_push_history(Palette.KICK.darkened(0.25), true, false)
			_set_verdict("whiff — nothing to kick", Palette.TEXT_DIM)

func _ev_is_me(ev: Dictionary) -> bool:
	if not ev.has("seat"):
		return bool(ev.get("player", true))
	if seat_ref != null:
		return ev.get("seat") == seat_ref
	return bool(ev.get("player", false))

## Grade a successful classic press by how close to impact it was. The negate is
## FULL either way (engine truth) — the grade is pride, and it trains the gate.
func _judge_classic_press() -> void:
	if _rem <= _perfect_w:
		_stamp(_rem, Palette.GOLD_BRIGHT, true)
		_push_history(Palette.GOLD_BRIGHT, false, true)
		_set_verdict("PERFECT %s" % verb, Palette.GOLD_BRIGHT)
	elif _rem <= _good_w:
		_stamp(_rem, Palette.GOLD, false)
		_push_history(Palette.GOLD, false, false)
		_set_verdict("%s!" % verb, Palette.GOLD)
	else:
		_stamp(_rem, Palette.STEEL, false)
		_push_history(Palette.STEEL, false, false)
		_set_verdict("%s — early" % verb, Palette.STEEL)

func _stamp(rem: float, col: Color, rays: bool) -> void:
	_stamps.append({"x_frac": clampf(rem / maxf(_view_secs(), 0.001), 0.0, 1.0),
		"col": col, "t": STAMP_HOLD, "rays": rays})
	_linger = maxf(_linger, 1.1)

func _set_verdict(v: String, col: Color) -> void:
	_verdict = v
	_verdict_col = col
	_verdict_t = VERDICT_HOLD
	var fam := "read"
	if col == Palette.GOLD_BRIGHT:
		fam = "perfect"
	elif col == Palette.GOLD:
		fam = "good"
	elif col == Palette.STEEL:
		fam = "graze"
	elif col == Palette.CRIMSON or col == Palette.CRIMSON.darkened(0.1):
		fam = "baited" if v.begins_with("BAITED") else "hit"
	verdict.emit(v, fam)

func _push_history(col: Color, hollow: bool, big: bool) -> void:
	_history.append({"col": col, "hollow": hollow, "big": big})
	if _history.size() > HIST_MAX:
		_history.pop_front()
	_hist_pop = 1.0
	_linger = maxf(_linger, 1.4)

# ============================================================ DRAW
func _track(): # -> [tx, tw, gx, ty, th]
	var tx := 14.0
	var tw := size.x - 28.0
	if big:
		return [tx, tw, tx + tw - 24.0, 28.0, 46.0]
	return [tx, tw, tx + tw - 22.0, 8.0 if compact else 26.0, 36.0 if compact else 34.0]

func _view_secs() -> float:
	var t = _track()
	return maxf(0.4, (float(t[2]) - float(t[0]) - 10.0) / pps)

## remaining seconds -> channel x (comets fly left -> right into the gate)
func _x_of(rem: float) -> float:
	var t = _track()
	return float(t[2]) - clampf(rem / _view_secs(), 0.0, 1.0) * (float(t[2]) - float(t[0]) - 10.0)

func _draw() -> void:
	var t = _track()
	var tx: float = t[0]
	var tw: float = t[1]
	var gx: float = t[2]
	var ty: float = t[3]
	var th: float = t[4]
	var font := ThemeDB.fallback_font
	var accent := _accent()

	# ---- glass backing plate: the instrument holds its own against the stage ----
	var plate := StyleBoxFlat.new()
	plate.bg_color = Color(0.030, 0.026, 0.052, 0.62)
	plate.set_corner_radius_all(9)
	plate.border_color = Color(Palette.EDGE.r, Palette.EDGE.g, Palette.EDGE.b, 0.8)
	plate.set_border_width_all(1)
	draw_style_box(plate, Rect2(tx - 8.0, ty - (10.0 if compact else 22.0),
		tw + 16.0, th + (44.0 if compact else 56.0)))

	# ---- header: cast-name plaque · combo counter · impact countdown ----
	var plaque := _name.to_upper() if _active else "THE JUDGE WAITS"
	if _kind == "heal":
		plaque += " — BURN IT DOWN"
	elif _kind == "empower":
		plaque += " — IT GROWS"
	if not compact:
		UiKit.engraved_plaque(self, Vector2(tx + 78.0, 10.0), plaque, _active and _in_window())
		if _combo_n > 1:
			UiKit.text_shadowed(self, UiKit.display(650, 1), Vector2(tx + 176.0, 15.0),
				"STRIKE %d / %d" % [_combo_i, _combo_n], HORIZONTAL_ALIGNMENT_LEFT,
				tw - 200.0, UiKit.SIZE["CAPTION"], accent)
		if _active and _mine and _rem > 0.02:
			var cnt := ("%.1f" % _rem) if _rem >= 1.0 else ("%.2f" % _rem)
			UiKit.text_shadowed(self, UiKit.display(700, 1), Vector2(0.0, 16.0), cnt,
				HORIZONTAL_ALIGNMENT_RIGHT, size.x - 30.0, UiKit.SIZE["LABEL"],
				accent if _rem <= _good_w else Palette.TEXT_DIM)

	# ---- the recessed glass channel ----
	var well := StyleBoxFlat.new()
	well.bg_color = Color(0.026, 0.022, 0.045)
	well.set_corner_radius_all(7)
	draw_style_box(well, Rect2(tx, ty, tw, th))
	draw_rect(Rect2(tx + 2, ty + 2, tw - 4, th * 0.40), Color(0, 0, 0, 0.38))
	# approach chevrons, drifting toward the gate (subtle motion grain)
	var drift := fmod(_pulse * 9.0, 26.0)
	var cx := tx + 10.0 + drift
	while cx < gx - 34.0:
		var ca := Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.10)
		draw_line(Vector2(cx, ty + 8.0), Vector2(cx + 6.0, ty + th * 0.5), ca, 1.4, true)
		draw_line(Vector2(cx + 6.0, ty + th * 0.5), Vector2(cx, ty + th - 8.0), ca, 1.4, true)
		cx += 26.0
	if compact:
		# modern cast-bar style: the name lives INSIDE the channel, comets fly over it
		var nc := Palette.TEXT_DIM if not _active else Palette.TEXT
		nc.a = 0.75
		var label := plaque
		if _combo_n > 1:
			label += "   ·  %d / %d" % [_combo_i, _combo_n]
		UiKit.text_shadowed(self, UiKit.display(600, 1), Vector2(tx + 12.0, ty + th * 0.5 + 5.0),
			label, HORIZONTAL_ALIGNMENT_LEFT, tw - 24.0, UiKit.SIZE["CAPTION"], nc)
		if _active and _mine and _rem > 0.02:
			# countdown lives INSIDE the channel, tucked before the gate (the
			# compact judge sits under the healers' bind-hint line — no headroom)
			var cnt2 := ("%.1f" % _rem) if _rem >= 1.0 else ("%.2f" % _rem)
			UiKit.text_shadowed(self, UiKit.display(700, 1),
				Vector2(gx - 196.0, ty + th * 0.5 + 5.0), cnt2,
				HORIZONTAL_ALIGNMENT_RIGHT, 60.0, UiKit.SIZE["CAPTION"],
				accent if _rem <= _good_w else Palette.TEXT_DIM)

	if _active:
		_draw_bands(tx, gx, ty, th)
		if _kind == "heal" or _kind == "empower":
			_draw_channel_fill(tx, gx, ty, th)
	_draw_gate(gx, ty, th)
	if _active:
		_draw_comets(tx, gx, ty, th)
	if _active and _mine and not _press_ok and _kind != "heal" and _kind != "empower" \
			and _kind != "brace" and not _next_feint:
		_draw_lockout(tx, tw, ty, th)

	# ---- verdict stamps: ghost needle + burst at the pressed spot ----
	for stp in _stamps:
		var f := float(stp["t"]) / STAMP_HOLD
		var px := gx - float(stp["x_frac"]) * (gx - tx - 10.0)
		var col: Color = stp["col"]
		col.a = 0.9 * f
		draw_line(Vector2(px, ty - 4.0), Vector2(px, ty + th + 4.0), col, 3.0, true)
		var ring := 5.0 + 26.0 * (1.0 - f)
		col.a = 0.75 * f
		draw_arc(Vector2(px, ty + th * 0.5), ring, 0.0, TAU, 26, col, 2.2, true)
		if bool(stp["rays"]):
			for k in 8:
				var a := TAU * float(k) / 8.0 + (1.0 - f) * 0.6
				var d := Vector2(cos(a), sin(a))
				var rc := Palette.GOLD_BRIGHT
				rc.a = 0.85 * f
				draw_line(Vector2(px, ty + th * 0.5) + d * (ring + 2.0),
					Vector2(px, ty + th * 0.5) + d * (ring + 10.0 + 6.0 * (1.0 - f)), rc, 1.8, true)

	# ---- frame: bevel + filigree ----
	draw_line(Vector2(tx, ty), Vector2(tx + tw, ty), Palette.GOLD_BRIGHT, 1.5, true)
	draw_line(Vector2(tx, ty), Vector2(tx, ty + th), Palette.GOLD, 1.5, true)
	draw_line(Vector2(tx, ty + th), Vector2(tx + tw, ty + th), Palette.GOLD_DIM, 1.5, true)
	draw_line(Vector2(tx + tw, ty), Vector2(tx + tw, ty + th), Palette.GOLD_DIM, 1.5, true)
	UiKit.filigree_corner(self, Vector2(tx - 2, ty - 2), Vector2(1, 1), 8.0)
	UiKit.filigree_corner(self, Vector2(tx + tw + 2, ty - 2), Vector2(-1, 1), 8.0)

	_draw_verdict_line(tx, tw, ty, th, font)
	_draw_history(tx + tw, ty + th + 16.0)

## The cue word for the CURRENT thing: strings/rhythm are always the dodge-bread;
## a classic swing speaks by the height law when size_verbs is on (the Duelist).
func _cue_verb() -> String:
	if _kind == "string" or _kind == "rhythm":
		if size_verbs and (_next_size() if _kind == "string" else _size) >= AbilityRes.Size.HEAVY:
			return "PARRY"
		return "DODGE"
	if size_verbs and _kind == "classic":
		return "PARRY" if _size >= AbilityRes.Size.HEAVY else "DODGE"
	return verb

func _accent() -> Color:
	match _kind:
		"feint": return Palette.RELIC
		"kick": return Palette.KICK
		"heal": return Palette.WIN
		"empower": return Palette.CRIMSON
		"brace": return Palette.CRIMSON
		"string":
			return Palette.RELIC if _next_feint else Palette.size_color(_next_size())
		_: return Palette.size_color(_next_size())

func _next_size() -> int:
	if _kind == "string":
		for b in _beats:
			if not bool(b["resolved"]):
				return int(b["size"])
	return _size

func _in_window() -> bool:
	return _mine and not _next_feint and _rem <= (_window if _kind != "string" else _good_w) \
		and _rem > 0.0 and _press_ok

## The graded bands before the gate. Strings: mint PERFECT / gold GOOD / steel
## GRAZE at constant px width. Classic: the true answer window in gold + the
## cosmetic perfect sliver. Kick: the violet clean-kick band. Feint: hatched
## purple DON'T-PRESS veil instead of anything invitational.
func _draw_bands(tx: float, gx: float, ty: float, th: float) -> void:
	var dim := 1.0 if _mine else 0.32
	if _next_feint:
		return   # a feint gets NO bands and NO veil — the hollow purple gem is the read (Bill 2026-07-11)
	if _kind == "heal" or _kind == "empower" or _kind == "brace":
		return
	var live := _in_window()
	if _kind == "string":
		_band(gx, ty, th, _graze_w, Palette.STEEL, 0.10 * dim, false)
		_band(gx, ty, th, _good_w, Palette.GOLD, 0.15 * dim, false)
		_band(gx, ty, th, _perfect_w, Palette.PERFECT, (0.42 if live else 0.26) * dim, live)
	elif _kind == "kick":
		_band(gx, ty, th, _window, Palette.KICK, (0.30 if live else 0.18) * dim, live)
	else: # classic parry/dodge: the REAL window, plus the aim sliver
		_band(gx, ty, th, _window, Palette.GOLD, (0.20 if live else 0.13) * dim, false)
		_band(gx, ty, th, _perfect_w, Palette.PERFECT, (0.42 if live else 0.26) * dim, live)

func _band(gx: float, ty: float, th: float, secs: float, col: Color, alpha: float, shimmer: bool) -> void:
	var bx := _x_of(secs)
	var bw := gx - bx
	if bw < 1.0:
		return
	var c := col
	c.a = alpha
	draw_rect(Rect2(bx, ty + 2, bw, th - 4), c)
	c.a = alpha * 1.7
	draw_line(Vector2(bx, ty + 2), Vector2(bx, ty + th - 2), c, 1.4, true)
	draw_rect(Rect2(bx, ty + 2, bw, th * 0.26), Color(1, 1, 1, alpha * 0.35))
	if shimmer:
		var sx := bx + fmod(_pulse * 30.0, maxf(bw - 6.0, 1.0))
		var sh := col.lightened(0.5)
		sh.a = 0.35
		draw_rect(Rect2(sx, ty + 3, 5.0, th - 6), sh)

## Heal / Empower: the cast pours INTO the boss — fill the channel with its colour.
func _draw_channel_fill(tx: float, gx: float, ty: float, th: float) -> void:
	var frac := 1.0 - clampf(_rem / maxf(_dur, 0.001), 0.0, 1.0)
	var col := Palette.WIN if _kind == "heal" else Palette.CRIMSON
	col.a = 0.16 + 0.05 * sin(_pulse * 1.7)
	draw_rect(Rect2(tx + 2, ty + 2, (gx - tx) * frac, th - 4), col)

## The IMPACT GATE: engraved slot, gilded hairline, crown gem. Blazes when a
## press would land in the good bands; flashes crimson when something got through.
func _draw_gate(gx: float, ty: float, th: float) -> void:
	var live := _active and _in_window()
	draw_line(Vector2(gx - 2.0, ty - 5.0), Vector2(gx - 2.0, ty + th + 5.0), Color(0, 0, 0, 0.7), 4.0, true)
	var hl := Palette.GOLD_BRIGHT if live else Palette.GOLD
	if _gate_hit > 0.0:
		hl = hl.lerp(Palette.CRIMSON, _gate_hit)
	draw_line(Vector2(gx, ty - 5.0), Vector2(gx, ty + th + 5.0), hl, 2.0, true)
	draw_line(Vector2(gx + 1.2, ty - 5.0), Vector2(gx + 1.2, ty + th + 5.0), Color(1, 1, 1, 0.35), 1.0, true)
	if live:
		var halo := Palette.GOLD_BRIGHT
		halo.a = 0.22 + 0.16 * sin(_pulse * 1.6)
		draw_rect(Rect2(gx - 7.0, ty - 4.0, 14.0, th + 8.0), halo)
	if _gate_hit > 0.0:
		var burst := Palette.CRIMSON
		burst.a = 0.5 * _gate_hit
		draw_arc(Vector2(gx, ty + th * 0.5), 8.0 + 20.0 * (1.0 - _gate_hit), 0.0, TAU, 26, burst, 2.5, true)
	_gem(Vector2(gx, ty - 9.0), 6.0, Palette.GOLD if not live else Palette.GOLD_BRIGHT, live)

## Comet-gems riding the channel into the gate. Trails sell the speed; feints are
## hollow purple; aoe beats wear an outer ring; beats not mine fly dim.
func _draw_comets(tx: float, gx: float, ty: float, th: float) -> void:
	var cy := ty + th * 0.5
	var view := _view_secs()
	if _kind == "string":
		for b in _beats:
			if bool(b["resolved"]) or bool(b["answered"]):
				continue
			_comet(Vector2(_x_of(minf(float(b["rem"]), view)), cy),
				float(b["rem"]), view, int(b["size"]), bool(b["feint"]),
				bool(b["aoe"]), bool(b["mine"]), String(b["victim"]), ty, th)
	else:
		var col_mine := _mine or _kind == "kick" or _kind == "heal" or _kind == "empower"
		_comet(Vector2(_x_of(minf(_rem, view)), cy), _rem, view, _size,
			_kind == "feint", false, col_mine, "", ty, th)

func _comet(at: Vector2, rem: float, view: float, sz: int, feint: bool, aoe: bool,
		mine: bool, victim: String, ty: float, th: float) -> void:
	var parked := rem > view
	var col := Palette.RELIC if feint else _comet_color(sz)
	var dim := 1.0 if mine else 0.35
	if parked: # still out of view: waits at the mouth of the channel, dimmed
		col.a = 0.35 * dim + 0.1 * sin(_pulse * 2.0)
		_gem_shaped(at + Vector2(4.0, 0.0), sz, col, feint, false)
		var cd := Palette.TEXT_DIM
		cd.a = 0.8 * dim
		UiKit.text_shadowed(self, ThemeDB.fallback_font, Vector2(at.x - 2.0, ty - 8.0),
			"%.1f" % rem, HORIZONTAL_ALIGNMENT_LEFT, 80.0, UiKit.SIZE["CAPTION"], cd)
		return
	# motion trail (heavier hits drag a taller wake)
	var trail := minf(34.0, at.x - 16.0)
	var wake := 12.0 - 3.0 * float(mini(sz, 3))
	if trail > 3.0:
		for k in 5:
			var seg := trail / 5.0
			var tcol := col
			tcol.a = (0.04 + 0.05 * float(k)) * dim
			draw_rect(Rect2(at.x - trail + seg * float(k), ty + wake * 0.5, seg, th - wake), tcol)
	var near := rem <= _good_w and mine and not feint
	if near:
		var halo := col.lightened(0.3)
		halo.a = 0.30 + 0.22 * sin(_pulse * 2.2)
		draw_circle(at, 13.0 + 3.0 * float(mini(sz, 3)), halo)
	col.a = dim
	_gem_shaped(at, sz, col, feint, near)
	if aoe:
		var rc := col
		rc.a = 0.55 * dim
		draw_arc(at, 12.0, 0.0, TAU, 22, rc, 1.6, true)
	if not mine and not victim.is_empty():
		var vc := Palette.TEXT_DIM
		vc.a = 0.75
		UiKit.text_shadowed(self, ThemeDB.fallback_font, Vector2(at.x - 40.0, ty - 8.0),
			"→ " + victim, HORIZONTAL_ALIGNMENT_CENTER, 80.0, UiKit.SIZE["CAPTION"], vc)

## §3½ THE SHAPE ALPHABET (Bill 2026-07-11): read the answer off the SILHOUETTE —
## small diamond = the dodge-bread · wide HEXAGON = HEAVY, parry it · BIG spiked
## OCTAGON = CRUSH, the commit · hollow purple = feint, hold. Color stays the size
## law; the shape carries it at a glance.
func _gem_shaped(at: Vector2, sz: int, col: Color, feint: bool, near: bool) -> void:
	var k := 1.35 if big else 1.0          # BIG mode: the tank reads comets from the corner of an eye
	if feint:
		_gem_diamond(at, 7.5 * k, col, true)
		return
	match sz:
		AbilityRes.Size.CRUSH:
			_gem_poly(at, 8, (13.0 if near else 12.0) * k, col, _pulse * 0.30, true)
		AbilityRes.Size.HEAVY:
			_gem_poly(at, 6, (10.0 if near else 9.0) * k, col, 0.0, false)
		_:
			_gem_diamond(at, (6.0 if near else 5.0) * k, col, false)

## A filled n-gon gem: dark socket · body · gold rim · specular. CRUSH spikes get a
## slow menace-spin + a heavy outline so the biggest hit is unmistakable.
func _gem_poly(at: Vector2, n: int, r: float, col: Color, rot: float, spiked: bool) -> void:
	var pts := PackedVector2Array()
	for i in n:
		var a := rot + TAU * float(i) / float(n)
		pts.append(at + Vector2(cos(a), sin(a)) * r)
	var sock := PackedVector2Array()
	for i in n:
		var a := rot + TAU * float(i) / float(n)
		sock.append(at + Vector2(cos(a), sin(a)) * (r + 1.5))
	draw_colored_polygon(sock, Color(0, 0, 0, 0.6))
	draw_colored_polygon(pts, col)
	var rim := Palette.GOLD
	rim.a = col.a
	for i in n:
		draw_line(pts[i], pts[(i + 1) % n], rim, 1.4, true)
	if spiked:
		for i in n:
			var a := rot + TAU * (float(i) + 0.5) / float(n)
			var d := Vector2(cos(a), sin(a))
			draw_line(at + d * r, at + d * (r + 4.5), rim, 1.6, true)
	draw_circle(at + Vector2(-r * 0.3, -r * 0.3), r * 0.22, Color(1, 1, 1, 0.5 * col.a))

func _comet_color(sz: int) -> Color:
	match _kind:
		"kick": return Palette.KICK
		"heal": return Palette.WIN
		"empower", "brace": return Palette.CRIMSON
		_: return Palette.size_color(sz)

## dodge/guard on cooldown while a beat of yours approaches: hatch it crimson
func _draw_lockout(tx: float, tw: float, ty: float, th: float) -> void:
	var veil := Palette.CRIMSON_DEEP
	veil.a = 0.30
	draw_rect(Rect2(tx + 2, ty + 2, tw - 4, th - 4), veil)
	for hx in range(6, int(tw) - 6, 16):
		draw_line(Vector2(tx + float(hx), ty + th - 3.0), Vector2(tx + float(hx) + 9.0, ty + 3.0),
			Color(Palette.CRIMSON.r, Palette.CRIMSON.g, Palette.CRIMSON.b, 0.20), 1.6, true)
	var lc := Palette.CRIMSON
	lc.a = 0.75 + 0.25 * sin(_pulse * 3.0)
	UiKit.text_shadowed(self, UiKit.display(700, 2), Vector2(tx, ty + th * 0.5 + 5.0),
		"LOCKED", HORIZONTAL_ALIGNMENT_CENTER, tw, UiKit.SIZE["LABEL"], lc)

## The line under the channel: a held verdict, else the live coaching cue.
func _draw_verdict_line(tx: float, tw: float, ty: float, th: float, font: Font) -> void:
	var my := ty + th + 21.0
	if _verdict_t > 0.0:
		var fa := clampf(_verdict_t / VERDICT_HOLD, 0.0, 1.0)
		var vc := _verdict_col
		vc.a = 0.55 + 0.45 * fa
		UiKit.text_shadowed(self, UiKit.display(750, 1), Vector2(tx, my), _verdict,
			HORIZONTAL_ALIGNMENT_CENTER, tw, UiKit.SIZE["SUBHEAD"], vc)
		return
	if not _active:
		return
	var cue := ""
	var cc := Palette.TEXT_DIM
	if _kind == "heal":
		cue = "it is HEALING — burn it down"
		cc = Palette.WIN
	elif _kind == "empower":
		cue = "it is GROWING — brace"
		cc = Palette.CRIMSON
	elif _kind == "brace":
		cue = "UNAVOIDABLE — brace"
		cc = Palette.CRIMSON
	elif _next_feint:
		cue = "FEINT — DON'T PRESS"
		cc = Palette.RELIC
		cc.a = 0.7 + 0.3 * sin(_pulse * 2.4)
	elif not _mine:
		cue = "not yours — watch"
	elif _in_window():
		cue = ">>  %s  <<" % _cue_verb()
		cc = Palette.GOLD_BRIGHT
		cc.a = 0.6 + 0.4 * sin(_pulse * 2.0)
	elif not _press_ok:
		cue = "recharging…"
		cc = Palette.CRIMSON.darkened(0.2)
	else:
		cue = "wait for the gate…"
	UiKit.text_shadowed(self, font, Vector2(tx, my), cue,
		HORIZONTAL_ALIGNMENT_CENTER, tw, UiKit.SIZE["LABEL"], cc)

## The grade-history rail: your last few judgments as cut gems, newest at the
## right (popping in). One glance answers "am I doing this right?"
func _draw_history(right_x: float, y: float) -> void:
	if _history.is_empty():
		return
	var x := right_x - 4.0
	for i in range(_history.size() - 1, -1, -1):
		var h: Dictionary = _history[i]
		var newest := i == _history.size() - 1
		var r := (6.6 if bool(h["big"]) else 5.2) * (1.0 + (0.6 * _hist_pop if newest else 0.0))
		var col: Color = h["col"]
		col.a = clampf(0.35 + 0.65 * (float(i + 1) / float(_history.size())), 0.0, 1.0)
		if bool(h["hollow"]):
			var pts := _diamond_pts(Vector2(x, y), r)
			for k in 4:
				draw_line(pts[k], pts[(k + 1) % 4], col, 1.5, true)
		else:
			draw_colored_polygon(_diamond_pts(Vector2(x, y), r), col)
			if bool(h["big"]) and newest and _hist_pop > 0.0:
				var rays := Palette.GOLD_BRIGHT
				rays.a = _hist_pop
				for k in 4:
					var a := TAU * float(k) / 4.0 + PI / 4.0
					draw_line(Vector2(x, y) + Vector2(cos(a), sin(a)) * (r + 2.0),
						Vector2(x, y) + Vector2(cos(a), sin(a)) * (r + 6.0), rays, 1.4, true)
		x -= 16.0

func _diamond_pts(at: Vector2, r: float) -> PackedVector2Array:
	return PackedVector2Array([at + Vector2(0, -r), at + Vector2(r * 0.78, 0),
		at + Vector2(0, r), at + Vector2(-r * 0.78, 0)])

## a small cut gem (gold bezel, specular) — the gate's crown
func _gem(at: Vector2, r: float, body: Color, live: bool) -> void:
	if live:
		var halo := body.lightened(0.25)
		halo.a = 0.30 + 0.22 * sin(_pulse * 1.8)
		draw_circle(at, r * 1.9, halo)
	var pts := _diamond_pts(at, r)
	draw_colored_polygon(pts, body)
	draw_line(pts[0], pts[1], Palette.GOLD, 1.2, true)
	draw_line(pts[1], pts[2], Palette.GOLD_DIM, 1.2, true)
	draw_line(pts[2], pts[3], Palette.GOLD_DIM, 1.2, true)
	draw_line(pts[3], pts[0], Palette.GOLD_BRIGHT if live else Palette.GOLD, 1.2, true)
	draw_circle(at + Vector2(-r * 0.2, -r * 0.3), r * 0.2, Color(1, 1, 1, 0.7))

## a comet body: rotated gem, hollow for feints (there is nothing inside a lie)
func _gem_diamond(at: Vector2, r: float, col: Color, hollow: bool) -> void:
	var pts := _diamond_pts(at, r)
	if hollow:
		for k in 4:
			draw_line(pts[k], pts[(k + 1) % 4], col, 2.0, true)
		var qa := col
		qa.a *= 0.8
		UiKit.text_shadowed(self, ThemeDB.fallback_font, Vector2(at.x - 10.0, at.y + 4.0), "?",
			HORIZONTAL_ALIGNMENT_CENTER, 20.0, UiKit.SIZE["CAPTION"], qa)
		return
	draw_colored_polygon(pts, col)
	draw_line(pts[0], pts[1], Color(1, 1, 1, 0.45), 1.2, true)
	draw_line(pts[3], pts[0], Color(1, 1, 1, 0.3), 1.2, true)
	draw_line(pts[1], pts[2], Color(0, 0, 0, 0.35), 1.2, true)
	draw_line(pts[2], pts[3], Color(0, 0, 0, 0.35), 1.2, true)
	draw_circle(at + Vector2(-r * 0.22, -r * 0.28), r * 0.2, Color(1, 1, 1, 0.75))
