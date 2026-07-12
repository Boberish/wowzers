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

# ONE-BAR telegraph tracking (2026-07-12 feint/red-beat fix): a telegraph comet's own
# `answered` flag reads s.telegraph.answers, which the TANK never writes (bespoke dodge skips
# _answer_strike) — so every dodged global/beat/buster was falsely painted MISSED. The band
# owns the truth instead: when the tank's telegraph answer fires (a duel_answer with no bar
# id), we mark the nearest telegraph comet answered here + resolve THAT comet by id. Only a
# genuinely unanswered comet reaches the gate with answered=false → the honest red miss.
var _tg_answered: Dictionary = {}     ## telegraph comet id -> true (answered this appearance)
var _last_tbars: Array = []           ## the telegraph comets fed this frame (for the nearest-lookup)

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
	hud._hint_line("1 / SPACE / LMB — DODGE    ·    2 / RMB — PARRY (land = counter + ◆)    ·    3 — ⚡ DUMP    ·    4 — ⏱ EN GARDE    ·    PURPLE = A FAKE, DON'T PRESS    ·    SKULL = BRACE")

func render(s: CombatState, p: Seat, obs: Dictionary) -> void:
	hp_orb.set_values(p.hp, p.hp_max)
	res_orb.set_values(float(obs.get("flow", 0.0)) * 100.0, 100.0)   # FLOW as an aggro %
	gauge.wind = float(obs.get("wind", 10.0))
	gauge.wind_max = float(obs.get("wind_max", 10.0))
	gauge.combo = int(obs.get("combo", 0))
	gauge.combo_max = int(obs.get("combo_max", 5))
	gauge.fumbling = bool(obs.get("fumbling", false))
	gauge.queue_redraw()
	# THE CHANNEL: hand it the committed view data verbatim (LAW 1 — no view math here).
	# The claim moment needs NO reconstruction anymore: the engine's duel_answer carries the
	# claimed bar's id + the signed off_ms (§0 pass 2) — on_event routes them straight in.
	var stream: Dictionary = obs.get("stream", {})
	channel.bars = stream.get("bars", [])
	channel.tick_frac = clampf(hud._ctrl._accum / s.dt, 0.0, 1.0)   # smooth 60 fps comets
	# ONE BAR (Bill 2026-07-12): GLOBALS + targeted BUSTERS ride the channel as comets too —
	# a live telegraph is COMMITTED (fixed end tick, beats at fixed offsets; timers freeze,
	# they never jump), so this is verbatim view data, zero prediction. Casts (heal/empower/
	# kickable/brace) stay on the BossCastBar under the boss HP. Synthetic NEGATIVE ids keep
	# them apart from stream bars (and clear of the -1 sentinel).
	var tbars: Array = []
	var tg: Dictionary = obs.get("telegraph", {})
	if not tg.is_empty():
		var tgid := int(tg.get("tick", 0))
		var is_cast: bool = bool(tg.get("heal", false)) or bool(tg.get("empower", false)) \
			or bool(tg.get("interruptible", false))
		if not is_cast:
			var beats: Array = tg.get("strikes", [])
			if beats.is_empty():
				if bool(tg.get("targets_me", false)) and bool(tg.get("defensible", false)):
					tbars.append({"id": -(1000 + tgid * 8), "kind": "buster",
						"eta": float(tg.get("remaining", 0.0)),
						"purple": bool(tg.get("feint", false)), "answered": false})
			else:
				for i in beats.size():
					var bt: Dictionary = beats[i]
					if bool(bt.get("resolved", false)) or not bool(bt.get("mine", false)):
						continue
					tbars.append({"id": -(1000 + tgid * 8 + 1 + i),
						"kind": ("global" if bool(bt.get("aoe", false)) else "beat"),
						"eta": float(bt.get("remaining", 0.0)),
						"purple": bool(bt.get("feint", false)),
						"answered": bool(bt.get("answered", false))})
	# the band OWNS `answered` for telegraph comets (the engine flag is tank-blind): a comet
	# the tank has answered stays answered; drop tracking for comets no longer on screen.
	var live_ids := {}
	for tb_v in tbars:
		var tb: Dictionary = tb_v
		if _tg_answered.has(int(tb["id"])):
			tb["answered"] = true
		live_ids[int(tb["id"])] = true
	for aid in _tg_answered.keys():
		if not live_ids.has(aid):
			_tg_answered.erase(aid)
	_last_tbars = tbars
	channel.tbars = tbars
	channel.late_grace = s.config.stream_resolve_slack   # the gate draws ONLY the true late window
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
			_verdict(String(ev.get("kind", "")), int(ev.get("grade", 0)), int(ev.get("size", 1)),
				ev.has("id"), int(ev.get("id", -1)), ev.has("off_ms"), int(ev.get("off_ms", 0)))
		"duel_dodge":
			channel.press_tick("dodge")            # the frame-you-press echo (§0 pass 2)
			dodge_rune.kick()                      # the bind rail animates too (key/mouse bypass _gui_input)
		"duel_parry":
			channel.press_tick("parry")
			parry_rune.kick()
		"duel_dump":
			dump_rune.kick()
		"duel_engarde":
			engarde_rune.kick()
			channel.stamp("EN GARDE!", "bullseye")
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
			channel.dud()                          # the dry-press echo at the gate
			channel.stamp("WINDED", "hit")
		"duel_bar_missed":
			channel.missed(int(ev.get("id", -1)))  # red ✗, keeps flowing past the line
		"duel_eat":
			channel.stamp("BRACE", "graze")
		"duel_engarde_break":
			channel.stamp("BROKEN", "hit")
		"stream_shatter":
			channel.shatter()

## One graded answer → the CLAIM MOMENT on the channel (positional death + press burst +
## verdict + ±ms, at the claimed comet's own frozen pixel) plus the slam (the moments that
## deserve the whole room). STREAM claims carry the bar's id + signed off_ms on the event
## (§0 pass 2 — judged AT the press, so this fires the same tick you clicked). TELEGRAPH
## answers (globals/busters on the judge) carry neither — they get the slam + a gate stamp,
## never a mis-anchored comet death.
func _verdict(kind: String, grade: int, size: int, has_id: bool, id: int,
		has_ms: bool, off_ms: int) -> void:
	var ms := ("%+d ms" % off_ms) if has_ms else ""
	match grade:
		StrikeRes.Grade.BULLSEYE:
			var txt := "PARRY!" if kind == "parry" else "BULLSEYE!"
			if has_id:
				channel.resolve(id, "bullseye", txt, ms)
			else:
				_tg_claim("bullseye", txt)   # telegraph answer → its own comet
			slam.slam(txt, "perfect")
			hud._shake_amt = maxf(hud._shake_amt, 2.0)
		StrikeRes.Grade.PERFECT:
			if has_id:
				channel.resolve(id, "perfect", "PERFECT", ms)
			else:
				_tg_claim("perfect", "PERFECT")
		StrikeRes.Grade.GOOD:
			if has_id:
				channel.resolve(id, "good", "GOOD", ms)
			else:
				_tg_claim("good", "GOOD")
		StrikeRes.Grade.GRAZE:
			if has_id:
				channel.resolve(id, "graze", "GRAZE", ms)
			else:
				_tg_claim("graze", "GRAZE")
		StrikeRes.Grade.BAITED:
			if has_id:
				channel.resolve(id, "baited", "BAITED!", ms)
			else:
				_tg_claim("baited", "BAITED!")
			slam.slam("BAITED", "baited")
		StrikeRes.Grade.READ:
			# the event carries the fake's own id now — the purple dissolve lands ON it
			channel.resolve(id, "read", "READ", "held the fake")
		_:
			var mtxt := "MISS"
			if kind == "parry":
				mtxt = "MISSED"
				slam.slam("MISSED PARRY", "hit")
			elif size >= AbilityRes.Size.HEAVY:
				mtxt = "WRONG — PARRY IT"
				slam.slam("PARRY IT", "hit")
			if has_id:
				channel.resolve(id, "hit", mtxt, ms)
			else:
				_tg_claim("hit", mtxt)
			hud._shake_amt = maxf(hud._shake_amt, 7.0)

## Resolve a TELEGRAPH answer (globals/busters/beats — the engine event carries no bar id) on
## the nearest telegraph comet by its OWN id, and mark it answered so the miss-afterlife prune
## can never also paint it red. A clean dodge/parry now kills the comet with its proper verdict
## + burst; only a comet the tank NEVER answers reaches the gate unclaimed → the honest red miss.
func _tg_claim(family: String, txt: String) -> void:
	var best_id := 1
	var best_eta := 1.0e9
	for tb_v in _last_tbars:
		var tb: Dictionary = tb_v
		var tid := int(tb["id"])
		if _tg_answered.has(tid):
			continue
		var e := float(tb.get("eta", 1.0e9))
		if e < best_eta:
			best_eta = e
			best_id = tid
	if best_id < 0:
		_tg_answered[best_id] = true
		channel.resolve(best_id, family, txt, "")
	else:
		channel.stamp(txt, family)   # no telegraph comet tracked — a bare gate stamp

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
