## Twinfang HUD — Arcane Obsidian. Screens: Aspect select -> Combat -> (Draft ->
## Combat)* -> End. Combat draws the boss dial + the rhythm bar (the strike-timing
## centerpiece) + combo/Flow/spec gauge + HP/Energy orbs, and polls state each frame.
## Input: 1 = Strike (in the green!), 2/3/4/5 = abilities, Space = Dodge, S = spellbook.
extends Control

const VERB := "DODGE"
const ASPECT_ICONS := {"tempo": "flurry", "venomancer": "envenom"}
const ABILITY_NAMES := {
	"strike": "Strike", "eviscerate": "Eviscerate", "kick": "Kick", "envenom": "Envenom",
	"coupdegrace": "Coup", "rupture": "Rupture", "flurry": "Flurry",
}
const ABILITY_TIPS := {
	"strike": {"stats": "12 energy  ·  19 dmg  ·  +1 combo", "tip": "Your builder AND your metronome. Tap it in the GREEN window (wait ~0.6s after your last) for a Perfect: 1.6x damage, +2 combo, +1 Flow. Too early and the press is ignored — patience, not mashing."},
	"eviscerate": {"stats": "25 energy  ·  23 dmg / combo", "tip": "Finisher. Spends ALL combo for 23 damage each (115 at 5), scaled by Flow. Your burst payoff."},
	"kick": {"stats": "10 energy  ·  7s cd  ·  interrupt", "tip": "Kick the boss mid-cast to cancel its self-heal — read the violet bar. Whiffs (still costs) if there's nothing to interrupt."},
	"envenom": {"stats": "25 energy  ·  combo -> Festering", "tip": "Poison finisher. Spends all combo to lay that many Festering stacks — completing the trio is what powers Toxic Synergy."},
	"coupdegrace": {"stats": "30 energy  ·  5s cd  ·  max Flow", "tip": "Unlocked at MAX Flow. A massive strike that refunds 3 combo — Coup, Eviscerate the refund, and keep the solo going. The capstone."},
	"rupture": {"stats": "22 energy  ·  3.5s cd  ·  detonate", "tip": "Detonates ALL poison for a burst scaled by total stacks x Synergy x Flow. Layer the three types, ramp Synergy, blow it at the peak."},
	"flurry": {"stats": "28 energy  ·  3 hits  ·  +2 combo", "tip": "A fast 3-hit (39 dmg), +2 combo burst. Quick points under pressure."},
}
const SPEC_TIP := {
	"tempo": {"name": "Flow & Tiers", "tip": "Chain Perfect Strikes to build Flow — a damage multiplier. As it climbs your kit transforms: Perfects double-hit, then refund energy + combo, and at MAX Flow you unlock Coup de Grace. Hold the solo and the whole kit sings."},
	"venomancer": {"name": "Poison Cocktail", "tip": "Normal strikes apply Crippling, Perfects apply Virulent, Envenom lays Festering. Keep all THREE alive and Toxic Synergy ramps your ticks. Then Rupture detonates the whole cocktail. Setup and payoff — mix normal and perfect hits."},
}

var _ctrl: CombatController
var _run: RunState
var _screen: String = "select"

var _stage: StageBackdrop
var _stage2d: CombatStage2D = null
var _ui: Control
var _fx: Control
var _book: Control = null

# combat widgets
var _bar: BossBar
var _dial: BossCastDial
var _rhythm: RhythmBar
var _judge: StrikeJudge
var _recap_stats := {}          # view-side fight tallies for THE RECKONING
var _hp_orb: LiquidOrb
var _en_orb: LiquidOrb
var _gauge: TwinfangGauge
var _runes: Array = []
var _guard: AbilityRune
var _progress: Label
var _strike_idx: int = -1

# juice
var _shake_root: Control
var _flash: ColorRect
var _shake_amt: float = 0.0
var _flash_a: float = 0.0
var _flash_col: Color = Color(1, 1, 1)

# tooltip
var _tip: Control
var _tip_title: Label
var _tip_stats: Label
var _tip_desc: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	seed(Time.get_ticks_usec())
	set_theme(UiKit.build_theme())
	_stage = StageBackdrop.new()
	add_child(_stage)
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_ui)
	_ctrl = CombatController.new()
	add_child(_ctrl)
	_ctrl.encounter_ended.connect(_on_end_moment)
	_show_select()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--autostart="):
			# "--autostart=tempo" or "--autostart=venomancer:executioner"
			var spec := a.substr("--autostart=".length()).split(":")
			if spec[0] == "tempo" or spec[0] == "venomancer":
				_start_run(spec[0], spec[1] if spec.size() > 1 else "")

func _clear() -> void:
	TransitionVeil.flash_on(self)   # screens settle in, never snap
	_book = null
	_stage2d = null
	for c in _ui.get_children():
		c.queue_free()

# ============================================================ SELECT
func _show_select() -> void:
	_screen = "select"
	_clear()
	var sel := BossSelect.new()
	sel.title = "THE TWINFANG"
	sel.subtitle = "MELEE — DRIVE THE RHYTHM · PICK A FIGHT"
	sel.aspects = [
		{"id": "tempo", "label": "TEMPO", "accent": Palette.PERFECT,
			"blurb": "Tempo · chain Perfect Strikes, climb Flow tiers to Coup de Grace"},
		{"id": "venomancer", "label": "VENOMANCER", "accent": Palette.POISON,
			"blurb": "Venomancer · layer three poisons, ramp Synergy, Rupture the cocktail"},
	]
	sel.encounters = TwinfangContent.run_encounters()
	sel.hint = "1 = Strike (in the green!)   ·   2-5 = abilities   ·   Space = Dodge   ·   F = combo dodge   ·   S = spellbook"
	sel.chosen.connect(_start_run)
	sel.back_pressed.connect(func(): get_tree().change_scene_to_file("res://game/main.tscn"))
	sel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(sel)

# ============================================================ RUN / COMBAT
func _start_run(aspect: String, jump_to: String = "") -> void:
	_run = RunState.start_twinfang(aspect)
	if jump_to != "":
		for i in _run.encounters.size():
			if String(_run.encounters[i].id) == jump_to:
				_run.enc_index = i
				break
	_begin_fight()

func _begin_fight() -> void:
	_screen = "combat"
	_clear()
	_build_combat()
	_shake_amt = 0.0
	_flash_a = 0.0
	_ctrl.begin(TwinfangContent.build_fight(_run, _run.fight_seed()))

func _build_combat() -> void:
	# the physical fight in side-view 2D: rogue (left) vs headsman (right), cutout
	# puppets between the painted backdrop and every HUD widget
	_stage2d = CombatStage2D.new(_run.aspect, String(_run.current_encounter().id))
	_ui.add_child(_stage2d)

	_shake_root = Control.new()
	_shake_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shake_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_shake_root)

	_progress = Label.new()
	_progress.add_theme_font_size_override("font_size", 13)
	_progress.add_theme_color_override("font_color", Palette.TEXT_DIM)
	_place(_progress, 0, 0, 0, 0, 22, 16, 380, 40)
	_ui.add_child(_progress)

	var spellbtn := Button.new()
	spellbtn.text = "Spellbook (S)"
	spellbtn.flat = true
	spellbtn.add_theme_color_override("font_color", Palette.GOLD_DIM)
	_place(spellbtn, 1, 0, 1, 0, -150, 12, -18, 42)
	spellbtn.pressed.connect(_toggle_book)
	_ui.add_child(spellbtn)

	_bar = BossBar.new()
	_place(_bar, 0.5, 0, 0.5, 0, -340, 50, 340, 100)
	_shake_root.add_child(_bar)

	_dial = BossCastDial.new()
	_dial.verb = VERB
	# with the 2D boss standing at the right of the stage, the dial drops its sigil
	# and rings the puppet as the telegraph RETICLE (x-anchor matches the boss slot)
	_dial.show_sigil = false
	_place(_dial, 0.655, 0, 0.655, 0, -210, 164, 210, 690)
	_shake_root.add_child(_dial)

	_rhythm = RhythmBar.new()
	# the metronome channel — YOUR instrument, under YOUR side of the stage;
	# the boss's Judgment Channel answers it under the reticle on the right
	_place(_rhythm, 0.29, 0, 0.29, 0, -360, 656, 360, 756)
	_shake_root.add_child(_rhythm)

	_judge = StrikeJudge.new()
	_judge.verb = VERB
	_place(_judge, 0.655, 0, 0.655, 0, -290, 656, 290, 760)
	_shake_root.add_child(_judge)

	# every fight opens with a ceremony: the boss's name-card burns in and off
	BossIntro.play(_ui, _run.current_encounter().name)
	_recap_stats = {}              # a fresh reckoning per fight

	_hp_orb = LiquidOrb.new()
	_hp_orb.fill = Palette.BLOOD
	_hp_orb.caption = "HEALTH"
	_hp_orb.tooltip_text = "Your health. At 0, the run ends."
	_place(_hp_orb, 0, 1, 0, 1, 55, -172, 175, -52)
	_shake_root.add_child(_hp_orb)

	_en_orb = LiquidOrb.new()
	_en_orb.fill = Palette.ENERGY
	_en_orb.caption = "ENERGY"
	_en_orb.tooltip_text = "Energy — regenerates over time, spent on abilities."
	_place(_en_orb, 1, 1, 1, 1, -175, -172, -55, -52)
	_shake_root.add_child(_en_orb)

	_gauge = TwinfangGauge.new()
	_gauge.aspect = _run.aspect
	_gauge.mouse_filter = Control.MOUSE_FILTER_STOP
	_gauge.mouse_entered.connect(_show_spec_tip)
	_gauge.mouse_exited.connect(_hide_tip)
	# the winged spec medallion owns the band between the stage and the rune rail
	_place(_gauge, 0.5, 1, 0.5, 1, -300, -302, 300, -172)
	_shake_root.add_child(_gauge)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	_place(row, 0.5, 1, 0.5, 1, -360, -160, 360, -76)
	_shake_root.add_child(row)

	_guard = AbilityRune.new()
	_guard.label = VERB
	_guard.key_label = "SPC"
	_guard.accent = Palette.FLOW
	_guard.icon_id = "dodge"
	_guard.pressed.connect(_do_guard)
	_guard.mouse_entered.connect(_show_guard_tip)
	_guard.mouse_exited.connect(_hide_tip)
	row.add_child(_guard)
	var sep := Control.new()
	sep.custom_minimum_size = Vector2(14, 0)
	row.add_child(sep)

	_runes = []
	_strike_idx = -1
	for i in _run.loadout.size():
		var id: String = _run.loadout[i]
		if id == "strike":
			_strike_idx = i
		var rune := AbilityRune.new()
		rune.label = ABILITY_NAMES.get(id, id)
		rune.key_num = i + 1
		rune.icon_id = id
		rune.pressed.connect(_use_ability.bind(i))
		rune.mouse_entered.connect(_show_ability_tip.bind(i))
		rune.mouse_exited.connect(_hide_tip)
		row.add_child(rune)
		_runes.append(rune)

	var hint := Label.new()
	hint.text = "SPACE — Dodge   (eating a swing wipes your Flow)"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Palette.GOLD_DIM)
	_place(hint, 0.5, 1, 0.5, 1, -260, -70, 260, -46)
	_shake_root.add_child(hint)

	_fx = Control.new()
	_fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_fx)

	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.color = Color(0, 0, 0, 0)
	_ui.add_child(_flash)

	_build_tooltip()

func _build_tooltip() -> void:
	_tip = _panel(Palette.BG1)
	_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip.visible = false
	_tip.custom_minimum_size = Vector2(250, 96)
	_ui.add_child(_tip)
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
	v.add_theme_constant_override("separation", 4)
	_tip.add_child(v)
	_tip_title = _title(v, "", 15, Palette.GOLD)
	_tip_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_tip_stats = _title(v, "", 12, Palette.FLOW)
	_tip_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_tip_desc = Label.new()
	_tip_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip_desc.custom_minimum_size = Vector2(226, 0)
	_tip_desc.add_theme_font_size_override("font_size", 13)
	_tip_desc.add_theme_color_override("font_color", Palette.TEXT)
	v.add_child(_tip_desc)

# ============================================================ INPUT
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://game/main.tscn")
		return
	if _screen != "combat":
		return
	match event.keycode:
		KEY_SPACE: _ctrl.human({"type": "defense"})
		KEY_F: _ctrl.human({"type": "dodge"})      # universal dodge (M7 strings)
		KEY_1: _use_ability(0)
		KEY_2: _use_ability(1)
		KEY_3: _use_ability(2)
		KEY_4: _use_ability(3)
		KEY_5: _use_ability(4)
		KEY_S: _toggle_book()

func _use_ability(i: int) -> void:
	if _screen == "combat" and i >= 0 and i < _run.loadout.size():
		_ctrl.human({"type": "ability", "id": _run.loadout[i]})

func _do_guard() -> void:
	_ctrl.human({"type": "defense"})

# ============================================================ COMBAT RENDER
func _process(delta: float) -> void:
	if _screen != "combat" or _dial == null or _ctrl.state == null:
		return

	_shake_amt = maxf(0.0, _shake_amt - delta * 42.0)
	if _shake_root != null:
		_shake_root.position = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_amt
	_flash_a = maxf(0.0, _flash_a - delta * 2.4)
	if _flash != null:
		_flash.color = Color(_flash_col.r, _flash_col.g, _flash_col.b, _flash_a)

	var s := _ctrl.state
	var p := _ctrl.player()
	var obs := CombatCore.observe(s, p)

	_progress.text = "Fight %d / %d   ·   %s" % [_run.enc_index + 1, _run.total(), _run.aspect.capitalize()]

	_bar.boss_name = s.encounter.name
	_bar.hp = s.boss.hp
	_bar.hp_max = s.boss.hp_max
	_bar.phase_num = _phase_num(s)
	_bar.phase_ats = s.encounter.phases.map(func(ph): return ph.at)
	_bar.enrage_in = (s.encounter.enrage_at - float(s.tick) * s.dt) if s.encounter.enrage_at > 0.0 else INF
	_dial.boss_name = s.encounter.name
	_dial.boss_hp_frac = s.boss.hp / maxf(s.boss.hp_max, 1.0)
	_dial.enraged = s.encounter.enrage_at > 0.0 and float(s.tick) * s.dt >= s.encounter.enrage_at

	var tg: Dictionary = obs.get("telegraph", {})
	if tg.is_empty():
		_dial.tg_active = false
	else:
		var dur := float(s.telegraph.dur_ticks) * s.dt
		_dial.tg_active = true
		_dial.tg_name = s.telegraph.ability.name
		_dial.tg_frac = (dur - float(tg.get("remaining", 0.0))) / maxf(dur, 0.001)
		_dial.tg_remaining = float(tg.get("remaining", 0.0))
		_dial.tg_size = int(tg.get("size", 0))
		_dial.tg_defensible = bool(tg.get("defensible", false))
		_dial.tg_interruptible = bool(tg.get("interruptible", false))
		_dial.tg_heal = bool(tg.get("heal", false))
		_dial.tg_feint = false
		_dial.zone_frac = clampf(float(obs.get("def_zone", 0.42)) / maxf(dur, 0.001), 0.0, 1.0)
		_dial.in_zone = _dial.tg_defensible and _dial.tg_remaining <= float(obs.get("def_zone", 0.42)) \
			and bool(obs.get("defense_ready", false))
		_dial.feed_strikes(tg, dur, bool(obs.get("dodge_ready", true)), s.config.strike_good, s.config.strike_perfect)
	if tg.is_empty():
		_dial.tg_strikes = []
	_dial.def_ready = bool(obs.get("defense_ready", true))
	_dial.dodge_ready = bool(obs.get("dodge_ready", true))
	if _judge != null:
		_judge.feed(s, obs, float(obs.get("def_zone", 0.42)))

	# rhythm bar
	_rhythm.since = int(obs.get("since_strike", 0))
	_rhythm.swing_min = int(obs.get("swing_min_ticks", 13))
	_rhythm.perfect_lo = int(obs.get("perfect_lo", 18))
	_rhythm.perfect_hi = int(obs.get("perfect_hi", 29))
	var in_green := _rhythm.since >= _rhythm.perfect_lo and _rhythm.since <= _rhythm.perfect_hi

	_hp_orb.set_values(p.hp, p.hp_max)
	_en_orb.set_values(obs.get("energy", 0.0), obs.get("energy_max", 100.0))

	_gauge.combo = int(obs.get("cp", 0))
	_gauge.combo_max = int(obs.get("cp_max", 5))
	_gauge.flow = int(obs.get("flow", 0))
	_gauge.flow_max = int(obs.get("flow_max", 6))
	_gauge.flow_mult = float(obs.get("flow_mult", 1.0))
	_gauge.tier = int(obs.get("tier", 0))
	_gauge.venom = obs.get("venom", {})

	# ability runes
	for i in _runes.size():
		var id: String = _run.loadout[i]
		var st := _rune_state(id, obs, p, s)
		_runes[i].affordable = st["afford"]
		_runes[i].usable = st["usable"]
		_runes[i].cd_frac = st["cd"]
		if i == _strike_idx:
			_runes[i].accent = Palette.PERFECT if in_green else Palette.GOLD

	# guard (Dodge) gauge
	var dcd_ticks := maxf(1.0, float(CombatCore.to_ticks(float(obs.get("def_cd", 2.4)), s.config.fixed_hz)))
	_guard.usable = bool(obs.get("defense_ready", false))
	_guard.cd_frac = clampf(float(p.defense_ready_tick - s.tick) / dcd_ticks, 0.0, 1.0)

	if _stage2d != null:
		_stage2d.sync(s, obs, p)

	for ev in s.events:
		_handle_event(ev)
	s.events.clear()

func _rune_state(id: String, obs: Dictionary, p: Seat, s: CombatState) -> Dictionary:
	var energy := float(obs.get("energy", 0.0))
	var cp := int(obs.get("cp", 0))
	var cd := 0.0
	var afford := true
	var usable := true
	match id:
		"strike":
			afford = energy >= 12.0
			usable = int(obs.get("since_strike", 0)) >= int(obs.get("swing_min_ticks", 13))
		"eviscerate":
			afford = energy >= 25.0
			usable = cp >= 1
		"envenom":
			afford = energy >= 25.0
			usable = cp >= 1
		"flurry":
			afford = energy >= 28.0
		"kick":
			afford = energy >= 10.0
			cd = _cd_frac(p, s, "kick", 7.0)
			usable = cd <= 0.0
		"coupdegrace":
			afford = energy >= 30.0
			cd = _cd_frac(p, s, "coupdegrace", 5.0)
			usable = cd <= 0.0 and int(obs.get("flow", 0)) >= int(obs.get("flow_max", 6))
		"rupture":
			afford = energy >= 22.0
			cd = _cd_frac(p, s, "rupture", 3.5)
			usable = cd <= 0.0 and int(obs.get("venom_total", 0)) >= 1
	return {"afford": afford, "usable": usable, "cd": cd}

func _cd_frac(p: Seat, s: CombatState, id: String, cd_sec: float) -> float:
	var ready := int(p.cooldowns.get(id, 0))
	var left := ready - s.tick
	if left <= 0:
		return 0.0
	return clampf(float(left) / float(CombatCore.to_ticks(cd_sec, s.config.fixed_hz)), 0.0, 1.0)

# ============================================================ JUICE
func _handle_event(ev: Dictionary) -> void:
	if _stage2d != null:
		_stage2d.on_event(ev)      # the puppets act out the same event the HUD juices
	if _judge != null:
		_judge.on_event(ev)        # the Judgment Channel stamps its verdicts
	RecapPanel.track(_recap_stats, ev)
	match String(ev.get("t", "")):
		"strike":
			# Flash the held verdict on the rhythm bar so every press reads clearly.
			if _rhythm != null:
				_rhythm.show_result(String(ev.get("result", "")))
		"strike_graded":
			# M7 combo-beat verdicts (a PERFECT dodge also banks +1 Flow).
			if bool(ev.get("player", false)):
				match int(ev.get("grade", 0)):
					StrikeRes.Grade.PERFECT:
						_big_text("PERFECT DODGE!  +FLOW", Palette.GOLD_BRIGHT, 34)
						_do_flash(Palette.GOLD, 0.16)
					StrikeRes.Grade.GOOD:
						_big_text("DODGED", Palette.GOLD, 28, 0.55)
					StrikeRes.Grade.GRAZE:
						_big_text("graze", Palette.STEEL, 22, 0.5)
					StrikeRes.Grade.BAITED:
						_big_text("BAITED!", Palette.CRIMSON, 38)
						_do_flash(Palette.CRIMSON, 0.24)
					StrikeRes.Grade.READ:
						_big_text("READ!", Palette.RELIC, 26, 0.55)
		"dodge_whiff":
			if bool(ev.get("player", false)):
				_big_text("TOO EARLY!", Palette.CRIMSON.darkened(0.1), 26, 0.55)
		"perfect":
			if bool(ev.get("player", false)):
				_big_text("PERFECT!", Palette.PERFECT, 34, 0.55)
				_do_flash(Palette.PERFECT, 0.10)
		"boss_hit":
			var a := float(ev.get("amt", 0))
			var crit := bool(ev.get("crit", false))
			_float_num(("✦ -%d" % int(a)) if crit else "-%d" % int(a),
				_fx.size * Vector2(0.5, 0.26) + Vector2(randf_range(-40.0, 40.0), 0.0),
				Palette.GOLD_BRIGHT if crit else Palette.GOLD, -32.0)
			_dial.react("impact", a)
			if crit or a >= 110.0:
				_add_shake(4.0)
		"poison":
			_float_num("-%d" % int(ev.get("amt", 0)),
				_fx.size * Vector2(0.5, 0.20) + Vector2(randf_range(-38.0, 38.0), 0.0),
				Palette.POISON, -26.0)
		"rupture":
			_big_text("RUPTURE!", Palette.POISON, 36)
			_do_flash(Palette.POISON, 0.22)
			_add_shake(7.0)
		"coup":
			_big_text("COUP DE GRÂCE!", Palette.PERFECT, 34)
			_do_flash(Palette.PERFECT, 0.20)
			_add_shake(7.0)
		"negate":
			if bool(ev.get("player", false)):
				_big_text("DODGE!", Palette.FLOW, 40, 0.55)
				_do_flash(Palette.FLOW, 0.18)
				_add_shake(5.0)
		"flow_lost":
			if bool(ev.get("player", false)):
				_big_text("FLOW LOST!", Palette.CRIMSON, 30, 0.6)
				_do_flash(Palette.CRIMSON, 0.14)
		"kick_whiff":
			if bool(ev.get("player", false)):
				_big_text("whiff", Palette.TEXT_DIM, 20, 0.4)
		"staggered":
			if bool(ev.get("was_heal", false)):
				_big_text("DENIED!", Palette.KICK, 42)
				_do_flash(Palette.KICK, 0.24)
			else:
				_big_text("INTERRUPT!", Palette.KICK, 34, 0.6)
				_do_flash(Palette.KICK, 0.18)
			_dial.react("stagger")
			_add_shake(6.0)
		"hurt":
			if bool(ev.get("player", false)):
				var d := float(ev.get("amt", 0))
				_do_flash(Palette.CRIMSON, clampf(d / 160.0, 0.10, 0.5))
				_add_shake(clampf(d / 8.0, 3.0, 17.0))
				_float_num("-%d" % int(d), _fx.size * Vector2(0.14, 0.66), Palette.CRIMSON, 30.0)
		"boss_heal":
			var h := float(ev.get("amt", 0))
			_float_num("+%d" % int(h),
				_fx.size * Vector2(0.5, 0.20) + Vector2(randf_range(-30.0, 30.0), 0.0),
				Palette.WIN, -28.0)
			_do_flash(Palette.WIN, 0.12)
			_dial.react("heal")

func _add_shake(amt: float) -> void:
	_shake_amt = minf(20.0, maxf(_shake_amt, amt))

func _do_flash(col: Color, a: float) -> void:
	_flash_col = col
	_flash_a = maxf(_flash_a, a)

func _big_text(text: String, col: Color, fs: int = 40, life: float = 0.7) -> void:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(360, 0)
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	l.position = _fx.size * Vector2(0.5, 0.42) - Vector2(180.0, 0.0)
	_fx.add_child(l)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 34.0, life)
	tw.tween_property(l, "modulate:a", 0.0, life).set_trans(Tween.TRANS_QUAD)
	tw.chain().tween_callback(l.queue_free)

func _float_num(text: String, pos: Vector2, color: Color, dy: float) -> void:
	# damage text with WEIGHT: numerals scale with magnitude, drift as they rise,
	# hold bright for a beat and fade late (Cinzel display numerals)
	var mag := absf(text.to_float())
	var fs := 17
	if mag >= 200.0:
		fs = 30
	elif mag >= 90.0:
		fs = 25
	elif mag >= 40.0:
		fs = 21
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", UiKit.display(750))
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.position = pos + Vector2(randf_range(-8.0, 8.0), 0.0)
	_fx.add_child(l)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y + dy, 0.8) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "position:x", l.position.x + randf_range(-14.0, 14.0), 0.8)
	tw.tween_property(l, "modulate:a", 0.0, 0.45).set_delay(0.35)
	tw.chain().tween_callback(l.queue_free)

func _show_ability_tip(i: int) -> void:
	if i < 0 or i >= _run.loadout.size():
		return
	var id: String = _run.loadout[i]
	var info: Dictionary = ABILITY_TIPS.get(id, {"stats": "", "tip": ""})
	_tip_title.text = ABILITY_NAMES.get(id, id)
	_tip_stats.text = String(info["stats"])
	_tip_desc.text = String(info["tip"])
	_position_tip_above(_runes[i])

func _show_spec_tip() -> void:
	var info: Dictionary = SPEC_TIP.get(_run.aspect, {"name": "", "tip": ""})
	_tip_title.text = String(info["name"])
	_tip_stats.text = ""
	_tip_desc.text = String(info["tip"])
	_position_tip_above(_gauge)

func _show_guard_tip() -> void:
	_tip_title.text = "Dodge"
	_tip_stats.text = "Space  ·  2.4s cooldown"
	_tip_desc.text = "Evade a telegraphed swing in its window. Getting HIT by a swing wipes your Flow — so dodging protects your damage as much as your health."
	_position_tip_above(_guard)

func _hide_tip() -> void:
	if _tip != null:
		_tip.visible = false

func _position_tip_above(node: Control) -> void:
	var w := 250.0
	var h := 120.0
	var gp := node.global_position
	var x := clampf(gp.x + node.size.x * 0.5 - w * 0.5, 8.0, size.x - w - 8.0)
	var y := maxf(8.0, gp.y - h - 8.0)
	_tip.position = Vector2(x, y)
	_tip.size = Vector2(w, h)
	_tip.visible = true

func _phase_num(s: CombatState) -> int:
	var fr := s.boss.hp / s.boss.hp_max
	var n := 1
	for i in s.encounter.phases.size():
		if s.encounter.phases[i].at >= fr:
			n = i + 1
	return n

# ============================================================ SPELLBOOK
func _toggle_book() -> void:
	if _book != null:
		_book.queue_free()
		_book = null
		return
	var abilities: Array = [{"icon": "dodge", "name": "DODGE", "key": "SPC",
		"stats": "0.55s window  ·  2.4s cd",
		"tip": "Dodge a swing in its window — it protects your FLOW, not just your health. A landed swing wipes the rhythm."}]
	for i in _run.loadout.size():
		var id: String = _run.loadout[i]
		var info: Dictionary = ABILITY_TIPS.get(id, {"stats": "", "tip": ""})
		abilities.append({"icon": id, "name": ABILITY_NAMES.get(id, id), "key": str(i + 1),
			"stats": String(info["stats"]), "tip": String(info["tip"])})
	_book = Grimoire.new("THE TWINFANG — %s" % _run.aspect.to_upper(), abilities, _boon_dicts(),
		Palette.FLOW)
	_book.closed.connect(_toggle_book)
	_ui.add_child(_book)

func _boon_dicts() -> Array:
	var out: Array = []
	for id in _run.boons:
		for pool in [TwinfangBoons.SHARED, TwinfangBoons.TEMPO, TwinfangBoons.VENOM]:
			for b in pool:
				if b["id"] == id:
					out.append(b)
	return out

func _boon_title(id: String) -> String:
	for pool in [TwinfangBoons.SHARED, TwinfangBoons.TEMPO, TwinfangBoons.VENOM]:
		for b in pool:
			if b["id"] == id:
				return b["title"]
	return id

# ============================================================ DRAFT
func _show_draft() -> void:
	_screen = "draft"
	_clear()
	var picks := Draft.roll_offers(_run)
	if picks.is_empty():
		_run.enc_index += 1
		_begin_fight()
		return
	var extras: Array = []
	if _minted > 0:
		extras.append("+%d Tokens minted — spend them responsibly." % _minted)
	var ds := DraftScreen.new(_run, picks, "%s FALLS" % _run.current_encounter().name.to_upper(),
		"Sharpen — take one. The ✦ card resonates with your build.", extras, Palette.GOLD)
	ds.boon_taken.connect(_on_card_taken)
	_ui.add_child(ds)

func _on_card_taken(boon: Dictionary) -> void:
	Draft.take(_run, boon)
	_run.enc_index += 1
	_begin_fight()

# ============================================================ END
var _minted := 0

func _on_end(won: bool) -> void:
	if _screen != "combat":
		return
	_minted = Draft.mint(_ctrl.state, _run.char_class) if won else 0
	_run.tokens += _minted
	if won and not _run.is_last():
		_show_draft()
	else:
		_show_end(won)

func _show_end(won: bool) -> void:
	_screen = "end"
	_clear()
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(center)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)
	var banner := Label.new()
	banner.text = "RUN CLEARED" if won else "DEFEATED"
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_font_override("font", UiKit.title(900))
	banner.add_theme_font_size_override("font_size", 52)
	banner.add_theme_color_override("font_color", Palette.WIN if won else Palette.LOSE)
	box.add_child(banner)
	if won:
		_title(box, "Clean Flow, kicked heals, dodged the heavy swings — you out-paced them as the %s." % _run.aspect.capitalize(), 15, Palette.TEXT)
	else:
		_title(box, "%s ground you out. Sharpen the blade and run it back." % _run.current_encounter().name, 15, Palette.TEXT)
	_title(box, "TOKENS · %d held%s" % [_run.tokens,
		(" · +%d minted this fight" % _minted) if _minted > 0 else ""], 13, Palette.TEXT_DIM)
	# THE RECKONING — the fight's recap plaque (state survives into this screen)
	if _ctrl != null and _ctrl.state != null and _ctrl.player() != null:
		box.add_child(RecapPanel.new(_ctrl.state, _ctrl.player(), _recap_stats))
	var again := Button.new()
	again.text = "NEW RUN"
	again.custom_minimum_size = Vector2(200, 48)
	again.add_theme_font_size_override("font_size", 18)
	again.pressed.connect(_show_select)
	box.add_child(again)

# ============================================================ ui helpers
func _title(parent: Node, text: String, fs: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	parent.add_child(l)
	return l

func _panel(_bg: Color) -> Control:
	return GlassPanel.new("PANEL")

func _gap(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c

func _place(node: Control, al: float, at: float, ar: float, ab: float,
		ol: float, ot: float, orr: float, ob: float) -> void:
	node.anchor_left = al
	node.anchor_top = at
	node.anchor_right = ar
	node.anchor_bottom = ab
	node.offset_left = ol
	node.offset_top = ot
	node.offset_right = orr
	node.offset_bottom = ob


## The fight-end BEAT: SLAIN / YOU FALL slams over the arena for a breath,
## THEN the normal end flow (draft / end screen / map) runs. Headless runs
## (smokes, sims) skip the beat entirely.
func _on_end_moment(won: bool) -> void:
	if _screen != "combat" or DisplayServer.get_name() == "headless":
		_on_end(won)
		return
	var bname := _ctrl.state.encounter.name if _ctrl != null and _ctrl.state != null else ""
	KillMoment.play(_ui, won, bname)
	get_tree().create_timer(1.25).timeout.connect(func():
		if _screen == "combat":
			_on_end(won))
