## MobileSpike — a THROWAWAY landscape touch UI to feel Twinfang·Tempo on a phone browser.
##
## Purpose: answer ONE question — does timing-based Tempo combat feel good under your thumbs on
## a phone? It drives the real 1v1 Tempo fight (TwinfangContent.make_state — the same solo state
## the sim uses) and reuses the real rhythm/flow/opening widgets, so the test is authentic. The
## only new things are the LAYOUT (landscape, big thumb targets) and a raw multi-touch input
## adapter that fires on PRESS-DOWN (not release) for minimal latency + two-thumb play.
##
## ONE dodge button (Bill, 2026-07-08: there is one dodge). It previews the coming unified dodge —
## on tap it negates a single swing (defense) OR answers a live barrage beat (dodge). Under the
## hood that's still the two engine verbs until DODGE-PLAN.md lands; the player sees one button.
##
## Boots via ?spike (web) or --autostart=mobilespike (native/editor). Not wired into the real HUD.
class_name MobileSpike
extends Control

var _state: CombatState
var _blade: Seat
var _accum: float = 0.0
var _slow: bool = false                 # dev toggle: 0.5× real-time to isolate lag from speed
var _fps_t: float = 0.0
var _fps: float = 0.0

# reused game widgets (authentic rendering)
var _rhythm: RhythmBar
var _tf_gauge: TwinfangGauge
var _opening: OpeningBar

# drawn touch buttons: {id, rect:Rect2, label, sub, accent}
var _btns: Array = []
var _glow: Dictionary = {}              # id -> 0..1 attention glow (dodge cue etc.)
var _active_touches: Dictionary = {}    # touch index -> true (to ignore emulated mouse on phones)

# center feedback pop
var _big: String = ""
var _big_t: float = 0.0
var _big_col: Color = Color.WHITE

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# reused widgets — placed in _layout()
	_rhythm = RhythmBar.new()
	_tf_gauge = TwinfangGauge.new(); _tf_gauge.aspect = "tempo"
	_opening = OpeningBar.new()
	for w in [_opening, _tf_gauge, _rhythm]:
		w.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(w)
	resized.connect(_layout)
	_build_fight()
	_layout()

func _build_fight() -> void:
	var cfg := TwinfangContent.make_config()
	var tcfg := TwinfangContent.make_twinfang_config()
	var enc := TwinfangContent.make_warden()          # the true 1v1: a dodgeable swing, a heal-to-kick, a string
	var seed := int(Time.get_ticks_usec()) & 0x7FFFFFFF
	_state = TwinfangContent.make_state(seed, "tempo", cfg, tcfg, enc)
	_blade = _state.seats[0]
	_blade.policy = null                              # the human (touch) drives the blade
	_accum = 0.0
	_big = ""; _big_t = 0.0

# --- layout (landscape; laid out in this Control's coords = the viewport) ----------------
func _layout() -> void:
	var W := size.x
	var H := size.y
	# rhythm bar = the star: wide, upper-centre
	_rhythm.position = Vector2(W * 0.16, H * 0.16)
	_rhythm.size = Vector2(W * 0.68, H * 0.20)
	# opening bar: just under the rhythm
	_opening.position = Vector2(W * 0.16, H * 0.40)
	_opening.size = Vector2(W * 0.68, H * 0.03)
	# flow gauge: centre-left, clear of the right thumb cluster
	_tf_gauge.position = Vector2(W * 0.20, H * 0.48)
	_tf_gauge.size = Vector2(W * 0.34, H * 0.18)
	# --- thumb zones ---
	var pad := W * 0.012
	# DODGE: big, left thumb
	_btns = [
		{"id": "dodge", "rect": Rect2(W * 0.03, H * 0.60, W * 0.20, H * 0.34), "label": "DODGE", "sub": "SPC", "accent": Palette.FLOW},
	]
	# ability cluster, bottom-right: STRIKE big (top), EVIS/KICK/COUP small (bottom row)
	var cw := W * 0.40
	var cx := W - cw - pad
	var cyt := H * 0.56
	var ch := H * 0.40
	_btns.append({"id": "strike", "rect": Rect2(cx, cyt, cw, ch * 0.52), "label": "STRIKE", "sub": "1", "accent": Palette.STEEL})
	var by := cyt + ch * 0.52 + pad
	var bh2 := ch * 0.48 - pad
	var third := (cw - pad * 2) / 3.0
	_btns.append({"id": "eviscerate",  "rect": Rect2(cx, by, third, bh2), "label": "EVIS", "sub": "2", "accent": Palette.CRIMSON})
	_btns.append({"id": "kick",        "rect": Rect2(cx + third + pad, by, third, bh2), "label": "KICK", "sub": "3", "accent": Palette.KICK})
	_btns.append({"id": "coupdegrace", "rect": Rect2(cx + (third + pad) * 2.0, by, third, bh2), "label": "COUP", "sub": "4", "accent": Palette.PERFECT})
	# dev toggles top-right
	_btns.append({"id": "slow",    "rect": Rect2(W - 130, 12, 118, 40), "label": ("SLOW ✓" if _slow else "SLOW"), "sub": "", "accent": Palette.RELIC})
	_btns.append({"id": "restart", "rect": Rect2(W - 130, 58, 118, 40), "label": "RESTART", "sub": "", "accent": Palette.STEEL})

# --- the fight loop (own the step → drain events → render order) --------------------------
func _process(delta: float) -> void:
	_fps_t += delta
	if _fps_t >= 0.25:
		_fps = 1.0 / maxf(0.0001, delta); _fps_t = 0.0
	if _state == null:
		return
	if not _state.over:
		_accum += minf(0.25, delta) * (0.5 if _slow else 1.0)
		var dt := _state.dt
		while _accum >= dt and not _state.over:
			_accum -= dt
			CombatCore.update(_state)                 # party of one; the boss scheduler runs inside
			_drain_events()
	_feed_widgets()
	if _big_t > 0.0:
		_big_t -= delta
	for k in _glow.keys():
		_glow[k] = maxf(0.0, float(_glow[k]) - delta * 2.2)
	queue_redraw()
	_rhythm.queue_redraw(); _tf_gauge.queue_redraw(); _opening.queue_redraw()

func _drain_events() -> void:
	for ev in _state.events:
		var t := String(ev.get("t", ""))
		if not bool(ev.get("player", true)) and ev.get("seat") != _blade and t != "add_spawn":
			continue
		match t:
			"strike":
				var res := String(ev.get("result", ""))
				_rhythm.show_result("perfect" if (res == "perfect" or res == "bullseye") else res)
				if res == "bullseye": _pop("BULLSEYE!", Palette.GOLD_BRIGHT)
				elif res == "perfect": _pop("PERFECT!", Palette.PERFECT)
			"strike_graded":
				match int(ev.get("grade", 0)):
					StrikeRes.Grade.PERFECT: _pop("PERFECT DODGE!", Palette.GOLD_BRIGHT)
					StrikeRes.Grade.GOOD: _pop("DODGED", Palette.GOLD_BRIGHT)
					StrikeRes.Grade.BAITED: _pop("BAITED!", Palette.CRIMSON)
					StrikeRes.Grade.GRAZE: _pop("graze", Palette.STEEL)
			"negate": _pop("DODGE!", Palette.FLOW)
			"dodge_whiff": _pop("TOO EARLY!", Palette.CRIMSON)
			"opening":
				_opening.show_result(String(ev.get("grade", "")))
				if String(ev.get("grade", "")) == "peak": _pop("PUNISH!", Palette.GOLD_BRIGHT)
			"coup": _pop("COUP DE GRÂCE!", Palette.PERFECT)
			"flow_lost": _pop("FLOW LOST!", Palette.CRIMSON)
	_state.events.clear()

func _feed_widgets() -> void:
	var obs := CombatCore.observe(_state, _blade)
	_rhythm.since = int(obs.get("since_strike", 0))
	_rhythm.swing_min = int(obs.get("swing_min_ticks", 13))
	_rhythm.perfect_lo = int(obs.get("perfect_lo", 18))
	_rhythm.perfect_hi = int(obs.get("perfect_hi", 29))
	_rhythm.bull_frac = float(obs.get("grade_bull_frac", 0.18))
	_rhythm.perfect_frac = float(obs.get("grade_perfect_frac", 0.55))
	_rhythm.scale_ticks = int(obs.get("rhythm_scale", 33))
	_rhythm.flow = int(obs.get("flow", 0))
	_rhythm.flow_max = int(obs.get("flow_max", 6))
	_tf_gauge.combo = int(obs.get("cp", 0))
	_tf_gauge.combo_max = int(obs.get("cp_max", 5))
	_tf_gauge.flow = int(obs.get("flow", 0))
	_tf_gauge.flow_max = int(obs.get("flow_max", 6))
	_tf_gauge.flow_mult = float(obs.get("flow_mult", 1.0))
	_tf_gauge.tier = int(obs.get("tier", 0))
	_opening.now_tick = int(obs.get("tick", 0))
	_opening.from_tick = int(obs.get("open_from", -1))
	_opening.peak_tick = int(obs.get("open_peak", -1))
	_opening.to_tick = int(obs.get("open_to", -1))
	_opening.core_ticks = int(obs.get("open_core_ticks", 3))
	_opening.bonus_now = float(obs.get("open_bonus_now", 0.0))
	_opening.active = int(obs.get("open_to", -1)) >= _opening.now_tick
	_opening.armed = int(obs.get("cp", 0)) >= 1 or bool(obs.get("coup_ready", false)) or float(obs.get("energy", 0.0)) >= 28.0
	# DODGE cue: light the dodge button when a swing or a barrage beat is imminent
	var tg: Dictionary = obs.get("telegraph", {})
	var def_zone := float(obs.get("def_zone", 0.42))
	var cue := false
	if not tg.is_empty():
		if bool(tg.get("defensible", false)) and bool(tg.get("targets_me", false)) and float(tg.get("remaining", 9.0)) <= def_zone:
			cue = true
		for b in tg.get("strikes", []):
			if bool(b.get("mine", false)) and not bool(b.get("resolved", false)) and not bool(b.get("answered", false)) \
					and float(b.get("remaining", 9.0)) <= def_zone + 0.12:
				cue = true
	if cue:
		_glow["dodge"] = 1.0

func _pop(msg: String, col: Color) -> void:
	_big = msg; _big_col = col; _big_t = 0.9

# --- raw touch adapter: fire on PRESS-DOWN, multi-touch, ignore emulated mouse on phones ----
func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var tp := event as InputEventScreenTouch
		if tp.pressed:
			_active_touches[tp.index] = true
			_press(tp.position)
		else:
			_active_touches.erase(tp.index)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if not _active_touches.is_empty():
			return                                    # a real touch is driving — ignore synthesized mouse
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			_press(mb.position)

func _press(pos: Vector2) -> void:
	for b in _btns:
		if (b["rect"] as Rect2).has_point(pos):
			_fire(String(b["id"]))
			return

func _fire(id: String) -> void:
	match id:
		"strike", "eviscerate", "kick", "coupdegrace":
			_enqueue({"type": "ability", "id": id})
			_glow[id] = 0.6
		"dodge":
			_enqueue(_dodge_action())
			_glow["dodge"] = 0.6
		"slow":
			_slow = not _slow; _layout()
		"restart":
			_build_fight(); _layout()

## The one dodge, routed (previews the unified dodge): a live barrage → answer the beat; else the
## single-swing negate. One button, right verb — no wasted whiff on a single swing.
func _dodge_action() -> Dictionary:
	if _state != null and _state.telegraph != null and not _state.telegraph.ability.strikes.is_empty():
		return {"type": "dodge"}
	return {"type": "defense"}

func _enqueue(a: Dictionary) -> void:
	if _state != null and not _state.over:
		_state.enqueue(_state.tick + 1, _blade, a)

# --- draw: bg, boss bar, telegraph, buttons, feedback -------------------------------------
func _draw() -> void:
	var W := size.x
	var H := size.y
	draw_rect(Rect2(0, 0, W, H), Palette.BG0)
	var f := ThemeDB.fallback_font
	# boss plate + HP bar
	var bhp := _state.boss.hp / maxf(1.0, _state.boss.hp_max)
	var bar := Rect2(W * 0.20, H * 0.045, W * 0.60, H * 0.028)
	draw_rect(bar, Palette.BG0.lightened(0.06))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * bhp, bar.size.y)), Palette.CRIMSON)
	draw_rect(bar, Palette.STEEL, false, 2.0)
	draw_string(f, Vector2(bar.position.x, bar.position.y - 6), String(_state.encounter.name),
		HORIZONTAL_ALIGNMENT_CENTER, bar.size.x, 20, Palette.TEXT)
	# telegraph readout
	var obs := CombatCore.observe(_state, _blade)
	var tg: Dictionary = obs.get("telegraph", {})
	if not tg.is_empty() and bool(tg.get("danger", false)):
		var rem := float(tg.get("remaining", 0.0))
		var warn: bool = bool(tg.get("targets_me", false)) or not (tg.get("strikes", []) as Array).is_empty()
		var msg := "◆ INCOMING  %.1fs" % rem
		draw_string(f, Vector2(W * 0.20, H * 0.115), msg, HORIZONTAL_ALIGNMENT_CENTER, W * 0.60, 22,
			Palette.CRIMSON if warn else Palette.TEXT_DIM)
	# buttons
	for b in _btns:
		_draw_btn(f, b)
	# center feedback pop
	if _big_t > 0.0:
		var a := clampf(_big_t / 0.9, 0.0, 1.0)
		var col := _big_col; col.a = a
		draw_string(f, Vector2(0, H * 0.30), _big, HORIZONTAL_ALIGNMENT_CENTER, W, 46, col)
	# fps / mode readout
	draw_string(f, Vector2(12, 26), "%d fps%s" % [int(round(_fps)), ("  ·  0.5×" if _slow else "")],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Palette.TEXT_DIM)
	# win / lose
	if _state.over:
		var res := "VICTORY" if _state.boss.hp <= 0.0 else "DOWNED"
		draw_string(f, Vector2(0, H * 0.5), res + "  —  tap RESTART", HORIZONTAL_ALIGNMENT_CENTER, W, 52,
			Palette.GOLD_BRIGHT if _state.boss.hp <= 0.0 else Palette.CRIMSON)

func _draw_btn(f: Font, b: Dictionary) -> void:
	var r: Rect2 = b["rect"]
	var g := float(_glow.get(b["id"], 0.0))
	var accent: Color = b["accent"]
	var base: Color = Palette.BG0.lightened(0.10).lerp(accent, 0.18 + 0.5 * g)
	draw_rect(r, base)
	draw_rect(r, accent.lerp(Color.WHITE, g), false, 2.0 + 2.0 * g)
	var f2 := ThemeDB.fallback_font
	draw_string(f2, Vector2(r.position.x, r.position.y + r.size.y * 0.5 + 8), String(b["label"]),
		HORIZONTAL_ALIGNMENT_CENTER, r.size.x, int(clampf(r.size.y * 0.28, 16, 34)), Palette.TEXT)
	if String(b["sub"]) != "":
		draw_string(f2, Vector2(r.position.x + 6, r.position.y + 18), String(b["sub"]),
			HORIZONTAL_ALIGNMENT_LEFT, r.size.x, 14, Palette.TEXT_DIM)
