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
	# THE CHANNEL — bottom-center, where the tank's eyes live. Everything answerable rides
	# it, one bar at a time; the boss's SPELLS stay on the cast bar (footwork ≠ spellwork).
	# The shared judge hides for this seat entirely — the channel IS the tank's instrument
	# (the judge's resting ghost was photobombing behind it, WSLg pass 2026-07-11).
	if hud._judge != null:
		hud._judge.visible = false
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
	channel.bars = stream.get("bars", [])
	channel.tempo = float(stream.get("tempo", 1.0)) * (1.25 if bool(obs.get("engarde_live", false)) else 1.0)
	channel.flurry = bool(obs.get("flurry", false))
	channel.aggro_lost = not bool(obs.get("aggro_me", true))
	channel.horizon = s.config.stream_horizon
	channel.win_bullseye = float(obs.get("win_bullseye", 0.07))
	channel.win_perfect = float(obs.get("win_perfect", 0.14))
	channel.win_good = float(obs.get("win_good", 0.30))
	channel.win_graze = float(obs.get("win_graze", 0.50))
	channel.parry_window = float(obs.get("parry_window", 0.10))
	# the live telegraph riding the channel: a targeted BUSTER (parry) or a GLOBAL beat (dodge)
	channel.buster_bar = {}
	channel.global_bar = {}
	var tg: Dictionary = obs.get("telegraph", {})
	if not tg.is_empty():
		var beats: Array = tg.get("strikes", [])
		if beats.is_empty():
			if bool(tg.get("defensible", false)) and bool(tg.get("targets_me", false)):
				channel.buster_bar = {"eta": float(tg.get("remaining", 0.0)),
					"purple": bool(tg.get("feint", false))}
		else:
			for bt_v in beats:
				var bt: Dictionary = bt_v
				if not bool(bt.get("resolved", false)) and (bool(bt.get("aoe", false)) or bool(bt.get("mine", false))):
					channel.global_bar = {"eta": float(bt.get("remaining", 0.0))}
					break
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

## One graded answer → the stamp (always) + the slam (the moments that deserve the room).
func _verdict(kind: String, grade: int, size: int) -> void:
	match grade:
		StrikeRes.Grade.BULLSEYE:
			if kind == "parry":
				channel.stamp("PARRY!", "bullseye")
				slam.slam("PARRY!", "perfect")
			else:
				channel.stamp("BULLSEYE!", "bullseye")
				slam.slam("BULLSEYE!", "perfect")
			hud._shake_amt = maxf(hud._shake_amt, 2.0)
		StrikeRes.Grade.PERFECT:
			channel.stamp("PERFECT", "perfect")
		StrikeRes.Grade.GOOD:
			channel.stamp("GOOD", "good")
		StrikeRes.Grade.GRAZE:
			channel.stamp("GRAZE", "graze")
		StrikeRes.Grade.BAITED:
			channel.stamp("BAITED!", "baited")
			slam.slam("BAITED", "baited")
		StrikeRes.Grade.READ:
			channel.stamp("READ", "read")
		_:
			if kind == "parry":
				channel.stamp("MISSED", "hit")
				slam.slam("MISSED PARRY", "hit")
			elif size >= AbilityRes.Size.HEAVY:
				channel.stamp("WRONG — PARRY IT", "hit")
				slam.slam("PARRY IT", "hit")
			else:
				channel.stamp("MISS", "hit")
			hud._shake_amt = maxf(hud._shake_amt, 7.0)

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
