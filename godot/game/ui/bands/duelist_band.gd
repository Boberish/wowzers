## DuelistBand — THE DUELIST's HUD band, rebuilt for tank-v2 (TANK-PLAN §0). Raises THE
## CHANNEL (AnswerChannel — its OWN widget, never a mode-fork of the shared judge), the
## FLOW/AGGRO orb (tank only), the WIND bubble + ◆ pips (DuelistGauge, carried), THE VERDICT
## SLAM (carried, re-wired to engine events), and the answer runes. Binds (kept):
## 1/SPACE/LMB = DODGE · 2/RMB = PARRY · 3 = ⚡DUMP · 4 = ⏱EN GARDE. Pure view.
class_name DuelistBand
extends ClassBand

var channel: AnswerChannel
var gauge: DuelistGauge
var slam: VerdictSlam
var tuner: StreamTuner

# --- claim-moment routing (view-only): the on-deck comet id + the press earliness in ms ---
var _front_id: int = -1                  ## nearest committed bar THIS frame
var _front_id_prev: int = -1             ## nearest LAST frame — the bar a same-frame verdict claimed
var _pending_ms: int = -1                ## the last press's earliness (ms), captured off obs
var _prev_ans_tick: int = -100000        ## detects a fresh press (seat.vars.ans_tick flips)
var parry_rune: AbilityRune
var dodge_rune: AbilityRune
var dump_rune: AbilityRune
var engarde_rune: AbilityRune

func build() -> void:
	hp_orb = hud._orb(Palette.BLOOD, "HEALTH", false)
	res_orb = hud._orb(Palette.STEEL, "FLOW / AGGRO", true)   # the aggro driver, shown as %
	gauge = DuelistGauge.new()
	UiKit.place(gauge, 0.5, 1, 0.5, 1, -200, -245, 200, -180)
	hud._shake_root.add_child(gauge)
	# THE CHANNEL — bottom-center, where the tank's eyes live. It draws ONLY the committed
	# melee stream (footwork). TANK-V3: the SHARED JUDGE stays visible for this seat and now
	# carries the raid-wide GLOBALS + CASTS (the octagon projection is deleted); the judge's
	# gap-frame ghost is fixed at the source (raid_hud _seat_judge_window feed-or-deactivate).
	channel = AnswerChannel.new()
	UiKit.place(channel, 0.5, 1, 0.5, 1, -370, -412, 370, -288)
	hud._shake_root.add_child(channel)
	# THE VERDICT SLAM — center-screen verdicts (carried from the juice pass; place THEN add)
	slam = VerdictSlam.new()
	slam.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud._shake_root.add_child(slam)
	var row: HBoxContainer = hud._rune_row(-380.0, 380.0)
	dodge_rune = AbilityRune.new()
	dodge_rune.label = "Dodge"
	dodge_rune.key_num = 1
	dodge_rune.icon_id = "dodge"
	dodge_rune.accent = Palette.FLOW
	dodge_rune.tooltip_text = "DODGE — 1 / SPACE / LEFT CLICK. Graded GRAZE<GOOD<PERFECT<BULLSEYE. Answers autos at any grade, globals at any grade; a BULLSEYE answers even a heavy. Cheap WIND. Never hits back."
	dodge_rune.pressed.connect(func(): hud._ctrl.human({"type": "dodge"}))
	row.add_child(dodge_rune)
	parry_rune = AbilityRune.new()
	parry_rune.label = "Parry"
	parry_rune.key_num = 2
	parry_rune.icon_id = "guard"
	parry_rune.accent = Palette.STEEL
	parry_rune.tooltip_text = "PARRY — 2 / RIGHT CLICK. Binary: land it (tight window) = best mit + COUNTER + ◆ + flow spike; miss = wind gone. Answers anything aimed at YOU — never a global."
	parry_rune.pressed.connect(func(): hud._ctrl.human({"type": "defense"}))
	row.add_child(parry_rune)
	var sep := Control.new()
	sep.custom_minimum_size = Vector2(14, 0)
	row.add_child(sep)
	dump_rune = AbilityRune.new()
	dump_rune.label = "Dump"
	dump_rune.key_num = 3
	dump_rune.icon_id = "avalanche"
	dump_rune.accent = Palette.GOLD_BRIGHT
	dump_rune.tooltip_text = "⚡ DUMP — spend the ◆ bank for a burst of pure damage."
	dump_rune.pressed.connect(func(): hud._ctrl.human({"type": "ability", "id": "dump"}))
	row.add_child(dump_rune)
	engarde_rune = AbilityRune.new()
	engarde_rune.label = "En Garde"
	engarde_rune.key_num = 4
	engarde_rune.icon_id = "shockwave"
	engarde_rune.accent = Palette.CRIMSON
	engarde_rune.tooltip_text = "⏱ EN GARDE (~1-min CD) — CALL IT OUT: the stream quickens +25%, leaks HALVED, clean answers pay DOUBLE flow. Two slips break it. An amplifier — pays nothing if you don't answer."
	engarde_rune.pressed.connect(func(): hud._ctrl.human({"type": "ability", "id": "engarde"}))
	row.add_child(engarde_rune)
	hud._hint_line("1 / SPACE / LMB — DODGE    ·    2 / RMB — PARRY (land = counter + ◆)    ·    3 — ⚡ DUMP    ·    4 — ⏱ EN GARDE")

func render(s: CombatState, p: Seat, obs: Dictionary) -> void:
	hp_orb.set_values(p.hp, p.hp_max)
	res_orb.set_values(float(obs.get("flow", 0.0)) * 100.0, 100.0)   # FLOW as an aggro %
	gauge.wind = float(obs.get("wind", 10.0))
	gauge.wind_max = float(obs.get("wind_max", 10.0))
	gauge.combo = int(obs.get("combo", 0))
	gauge.combo_max = int(obs.get("combo_max", 5))
	gauge.fumbling = bool(obs.get("fumbling", false))
	gauge.queue_redraw()
	# THE CHANNEL: hand it the committed view data verbatim (LAW 1 — no view math here)
	var stream: Dictionary = obs.get("stream", {})
	var bars: Array = stream.get("bars", [])
	channel.bars = bars
	# CLAIM ROUTING (view-only): track the on-deck (nearest) comet + how early the press was, so
	# a graded verdict can anchor at that comet's spot with a ±ms readout. The engine's duel_answer
	# carries no id/timing, so we read the nearest bar's eta and the seat's ans_tick — never
	# predicting, never mutating: pure presentation off observe() + seat.vars.
	var fid := -1
	var feta := 9.0e9
	for b_v in bars:
		var bb: Dictionary = b_v
		var e2 := float(bb.get("eta", 9.0e9))
		if e2 < feta:
			feta = e2
			fid = int(bb.get("id", -1))
	_front_id_prev = _front_id
	_front_id = fid
	var at := int(p.vars.get("ans_tick", -100000))
	if at != _prev_ans_tick and at > -50000:
		_prev_ans_tick = at
		if feta < 2.0:
			var age := maxi(0, s.tick - at)
			_pending_ms = int(round(maxf(0.0, feta - float(age) * s.dt) * 1000.0))
		else:
			_pending_ms = -1
	channel.tempo = float(stream.get("tempo", 1.0)) * (1.25 if bool(obs.get("engarde_live", false)) else 1.0)
	channel.flurry = bool(obs.get("flurry", false))
	channel.aggro_lost = not bool(obs.get("aggro_me", true))
	channel.horizon = s.config.stream_horizon
	channel.win_bullseye = float(obs.get("win_bullseye", 0.07))
	channel.win_perfect = float(obs.get("win_perfect", 0.14))
	channel.win_good = float(obs.get("win_good", 0.30))
	channel.win_graze = float(obs.get("win_graze", 0.50))
	channel.parry_window = float(obs.get("parry_window", 0.10))
	# TANK-V3: GLOBALS + BUSTERS no longer project onto the channel — they render on the
	# shared JUDGE (raid_hud._render_dial tank branch feeds it), answered by the fall-through
	# press. The channel is fed ONLY the committed melee stream above (NG1: one source).
	dump_rune.affordable = int(obs.get("combo", 0)) > 0
	dump_rune.usable = bool(obs.get("gcd_ready", true))
	engarde_rune.usable = bool(obs.get("engarde_ready", false))
	engarde_rune.affordable = not bool(obs.get("engarde_live", false))
	var eg := int(p.cooldowns.get("engarde", 0))
	engarde_rune.cd_frac = clampf(float(eg - s.tick) / float(CombatCore.to_ticks(60.0, s.config.fixed_hz)), 0.0, 1.0)

func key_pressed(code: int) -> void:
	match code:
		KEY_1, KEY_SPACE:
			hud._ctrl.human({"type": "dodge"})
		KEY_2, KEY_F:
			hud._ctrl.human({"type": "defense"})   # F = legacy alias
		KEY_3:
			hud._ctrl.human({"type": "ability", "id": "dump"})
		KEY_4:
			hud._ctrl.human({"type": "ability", "id": "engarde"})
		KEY_F9:
			_toggle_tuner()                        # THE STREAM TUNER (dev-only overlay)

## Mouse grammar: LEFT CLICK = DODGE · RIGHT CLICK = PARRY. Clicks on real buttons keep
## their click (the hovered-control check stops the double-fire).
func mouse(event: InputEventMouseButton) -> void:
	if not event.pressed or event.button_index > MOUSE_BUTTON_RIGHT:
		return
	var hov: Control = hud.get_viewport().gui_get_hovered_control()
	if hov is BaseButton:
		return
	if event.button_index == MOUSE_BUTTON_LEFT:
		hud._ctrl.human({"type": "dodge"})
	else:
		hud._ctrl.human({"type": "defense"})

## Engine events → the feedback layer (channel stamps + rail; the SLAM for the big ones).
func on_event(ev: Dictionary, mine: bool) -> void:
	if not mine:
		if String(ev.get("t", "")) == "stream_shatter" and channel != null:
			channel.shatter()
		return
	match String(ev.get("t", "")):
		"duel_answer":
			_verdict(String(ev.get("kind", "")), int(ev.get("grade", 0)), int(ev.get("size", 1)))
		"duel_counter":
			channel.stamp("COUNTER +◆", "bullseye")
		"duel_riposte":
			channel.stamp("RIPOSTE!", "perfect")
			slam.slam("RIPOSTE!", "perfect")
		"duel_weave_blown":
			channel.stamp("BLOWN", "hit")
			slam.slam("WEAVE BLOWN", "hit")
			hud._shake_amt = maxf(hud._shake_amt, 6.0)
		"duel_parry_sealed":
			channel.stamp("PARRY SEALED — WEAVE!", "baited")
		"duel_fumble":
			channel.stamp("WINDED", "hit")
		"duel_eat":
			channel.stamp("BRACE", "graze")
		"duel_engarde":
			channel.stamp("EN GARDE!", "bullseye")
		"duel_engarde_break":
			channel.stamp("BROKEN", "hit")
		"stream_shatter":
			channel.shatter()

## One graded answer → the CLAIM MOMENT on the channel (positional death + verdict + ±ms, at
## the claimed comet's own spot) plus the slam (the moments that deserve the whole room). The
## claimed comet id is last frame's on-deck bar (this frame's obs already dropped it), and the
## ms is the earliness captured in render(); the channel falls back gracefully if either is stale.
func _verdict(kind: String, grade: int, size: int) -> void:
	var id := _front_id_prev
	match grade:
		StrikeRes.Grade.BULLSEYE:
			if kind == "parry":
				channel.resolve(id, "bullseye", "PARRY!", _ms_txt())
				slam.slam("PARRY!", "perfect")
			else:
				channel.resolve(id, "bullseye", "BULLSEYE!", _ms_txt())
				slam.slam("BULLSEYE!", "perfect")
			hud._shake_amt = maxf(hud._shake_amt, 2.0)
		StrikeRes.Grade.PERFECT:
			channel.resolve(id, "perfect", "PERFECT", _ms_txt())
		StrikeRes.Grade.GOOD:
			channel.resolve(id, "good", "GOOD", _ms_txt())
		StrikeRes.Grade.GRAZE:
			channel.resolve(id, "graze", "GRAZE", _ms_txt())
		StrikeRes.Grade.BAITED:
			channel.resolve(id, "baited", "BAITED!", _ms_txt())
			slam.slam("BAITED", "baited")
		StrikeRes.Grade.READ:
			channel.resolve(id, "read", "READ", "")     # held it — no press to time
		_:
			if kind == "parry":
				channel.resolve(id, "hit", "MISSED", "")
				slam.slam("MISSED PARRY", "hit")
			elif size >= AbilityRes.Size.HEAVY:
				channel.resolve(id, "hit", "WRONG — PARRY IT", "")
				slam.slam("PARRY IT", "hit")
			else:
				channel.resolve(id, "hit", "MISS", "")
			hud._shake_amt = maxf(hud._shake_amt, 7.0)
	_pending_ms = -1

## The pass-2 earliness readout for the just-claimed press ("" when unavailable — never faked).
func _ms_txt() -> String:
	return "" if _pending_ms < 0 else "%d ms early" % _pending_ms

## THE STREAM TUNER (dev-only): live-tune the ACTIVE body's texture profile mid-fight.
func _toggle_tuner() -> void:
	if not OS.is_debug_build():
		return
	if tuner != null:
		tuner.queue_free()
		tuner = null
		return
	tuner = StreamTuner.new()
	tuner.ctrl = hud._ctrl
	UiKit.place(tuner, 1, 0, 1, 0, -340, 60, -20, 60)
	hud.add_child(tuner)
