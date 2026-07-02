## Voidcaller HUD — Arcane Obsidian. Screens: Aspect select -> Combat -> (Draft ->
## Combat)* -> End. The boss's cast dial IS the fight: KICK (Space) the purple casts,
## Barrier the channels. Combat draws boss dial + your cast bar + Focus/HP orbs + the
## Backlash/Silence gauge, and polls state each frame.
## Input: Space = Kick, 1 Bolt, 2 Fracture, 3 Barrier, 4 signature, 5 draft spell, S book.
extends Control

const VERB := "KICK"
const ASPECT_ICONS := {"disruptor": "overload", "silencer": "silence"}
const ABILITY_NAMES := {
	"bolt": "Bolt", "fracture": "Fracture", "barrier": "Barrier", "overload": "Overload",
	"quietus": "Quietus", "silence": "Silence", "counterspell": "Counterspell",
}
const ABILITY_TIPS := {
	"bolt": {"stats": "instant  ·  34 dmg  ·  +14 Focus", "tip": "Instant filler that builds Focus. Your between-casts default while you watch the cast bar."},
	"fracture": {"stats": "26 Focus  ·  1.15s cast  ·  118 dmg", "tip": "Your nuke. Taking a hit mid-cast PUSHES IT BACK — protect it by kicking the boss's cast (and by Barriering channels)."},
	"barrier": {"stats": "instant  ·  45% DR 3s  ·  10s cd", "tip": "45% less damage for 3s. For the uninterruptible channels you just have to survive — pop it as the red bar winds up."},
	"overload": {"stats": "instant  ·  spend Backlash", "tip": "Spends all Backlash for 68 damage each AND makes your next Fracture instant. The payoff for clean interrupts."},
	"quietus": {"stats": "30 Focus  ·  9s cd", "tip": "Hard-Silences the boss 5s and leaves it Exposed +50% — cancels its current cast too. Open the door, then unload."},
	"silence": {"stats": "instant  ·  11s cd", "tip": "A 2nd interrupt that also Silences the boss 2.5s. Your answer for overlapping casts."},
	"counterspell": {"stats": "instant  ·  9s cd", "tip": "A 2nd interrupt that reflects 90 damage back on the cast it stops."},
}
const SPEC_TIP := {
	"disruptor": {"name": "Backlash & Overload", "tip": "Clean interrupts — kick in the last slice of the cast bar — bank Backlash (2 for a clean kick). Dump it all with Overload for a huge hit that also makes your next Fracture instant."},
	"silencer": {"name": "Silence & Exposed", "tip": "Your interrupts Silence the boss (longer if clean) so it can't cast — and leave it Exposed, so you deal more. Lock it down with Quietus, then burn it through the open window."},
}

var _ctrl: CombatController
var _run: RunState
var _screen: String = "select"

var _stage: StageBackdrop
var _ui: Control
var _fx: Control
var _book: Control = null

var _bar: BossBar
var _dial: BossCastDial
var _judge: StrikeJudge
var _recap_stats := {}          # view-side fight tallies for THE RECKONING
var _pcast: PlayerCastBar
var _hp_orb: LiquidOrb
var _focus_orb: LiquidOrb
var _gauge: VoidcallerGauge
var _runes: Array = []
var _guard: AbilityRune
var _progress: Label

var _shake_root: Control
var _flash: ColorRect
var _shake_amt: float = 0.0
var _flash_a: float = 0.0
var _flash_col: Color = Color(1, 1, 1)

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
	_ctrl.encounter_ended.connect(_on_end)
	_show_select()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--autostart="):
			var spec := a.substr("--autostart=".length()).split(":")
			if spec[0] == "disruptor" or spec[0] == "silencer":
				_start_run(spec[0], spec[1] if spec.size() > 1 else "")

func _clear() -> void:
	TransitionVeil.flash_on(self)   # screens settle in, never snap
	_book = null
	for c in _ui.get_children():
		c.queue_free()

# ============================================================ SELECT
func _show_select() -> void:
	_screen = "select"
	_clear()
	var sel := BossSelect.new()
	sel.title = "THE VOIDCALLER"
	sel.subtitle = "CASTER — INTERRUPT · PICK A FIGHT"
	sel.aspects = [
		{"id": "disruptor", "label": "DISRUPTOR", "accent": Palette.KICK,
			"blurb": "Disruptor · clean kicks bank Backlash — dump it with Overload"},
		{"id": "silencer", "label": "SILENCER", "accent": Palette.VOID,
			"blurb": "Silencer · kicks Silence + Expose — lock it down, burn the window"},
	]
	sel.encounters = VoidcallerContent.run_encounters()
	sel.hint = "Space = Kick   ·   1 Bolt  2 Fracture  3 Barrier  4 signature   ·   F = dodge   ·   S = spellbook"
	sel.chosen.connect(_start_run)
	sel.back_pressed.connect(func(): get_tree().change_scene_to_file("res://game/main.tscn"))
	sel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(sel)

# ============================================================ RUN / COMBAT
func _start_run(aspect: String, jump_to: String = "") -> void:
	_run = RunState.start_voidcaller(aspect)
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
	_ctrl.begin(VoidcallerContent.build_fight(_run, _run.fight_seed()))

func _build_combat() -> void:
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
	# center stage: the boss sigil + telegraph ring owns the middle of the screen
	_place(_dial, 0.5, 0, 0.5, 0, -210, 124, 210, 650)
	_shake_root.add_child(_dial)

	# YOUR cast bar moves to your own column on the left — the center line under
	# the boss belongs to ITS casts (the Judgment Channel, with the clean-kick band)
	_pcast = PlayerCastBar.new()
	_place(_pcast, 0.2, 0, 0.2, 0, -240, 664, 240, 714)
	_shake_root.add_child(_pcast)

	_judge = StrikeJudge.new()
	_judge.verb = VERB
	_place(_judge, 0.5, 0, 0.5, 0, -300, 658, 300, 762)
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

	_focus_orb = LiquidOrb.new()
	_focus_orb.fill = Palette.VOID
	_focus_orb.caption = "FOCUS"
	_focus_orb.tooltip_text = "Focus — built by Bolt, spent on Fracture / Quietus."
	_place(_focus_orb, 1, 1, 1, 1, -175, -172, -55, -52)
	_shake_root.add_child(_focus_orb)

	_gauge = VoidcallerGauge.new()
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
	_guard.accent = Palette.KICK
	_guard.icon_id = "kick"
	_guard.pressed.connect(_do_guard)
	_guard.mouse_entered.connect(_show_guard_tip)
	_guard.mouse_exited.connect(_hide_tip)
	row.add_child(_guard)
	var sep := Control.new()
	sep.custom_minimum_size = Vector2(14, 0)
	row.add_child(sep)

	_runes = []
	for i in _run.loadout.size():
		var id: String = _run.loadout[i]
		var rune := AbilityRune.new()
		rune.label = ABILITY_NAMES.get(id, id)
		rune.key_num = i + 1
		rune.accent = Palette.VOID
		rune.icon_id = id
		rune.pressed.connect(_use_ability.bind(i))
		rune.mouse_entered.connect(_show_ability_tip.bind(i))
		rune.mouse_exited.connect(_hide_tip)
		row.add_child(rune)
		_runes.append(rune)

	var hint := Label.new()
	hint.text = "SPACE — Kick the cast   (clean = in the last slice of the bar)"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Palette.GOLD_DIM)
	_place(hint, 0.5, 1, 0.5, 1, -280, -70, 280, -46)
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
	_tip_stats = _title(v, "", 12, Palette.VOID)
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
		_dial.tg_defensible = false
		_dial.tg_interruptible = bool(tg.get("interruptible", false))
		_dial.tg_heal = bool(tg.get("heal", false))
		_dial.tg_feint = false
		var clean_zone := float(obs.get("clean_zone", 0.62))
		_dial.zone_frac = clampf(clean_zone / maxf(dur, 0.001), 0.0, 1.0)
		_dial.in_zone = _dial.tg_interruptible and _dial.tg_remaining <= clean_zone \
			and bool(obs.get("defense_ready", false))
		_dial.feed_strikes(tg, dur, bool(obs.get("dodge_ready", true)), s.config.strike_good, s.config.strike_perfect)
	if tg.is_empty():
		_dial.tg_strikes = []
	_dial.def_ready = bool(obs.get("defense_ready", true))
	_dial.dodge_ready = bool(obs.get("dodge_ready", true))
	if _judge != null:
		_judge.feed(s, obs, float(obs.get("clean_zone", 0.62)))

	# your cast bar
	var casting: Dictionary = obs.get("casting", {})
	if casting.is_empty():
		_pcast.active = false
		_pcast.next_instant = bool(obs.get("next_instant", false))
	else:
		_pcast.active = true
		var cdur := float(casting["dur_ticks"])
		_pcast.frac = clampf(float(s.tick - int(casting["start_tick"])) / maxf(cdur, 1.0), 0.0, 1.0)
		_pcast.label = ABILITY_NAMES.get(String(casting["id"]), String(casting["id"]))
		_pcast.pushed = bool(casting.get("pushed", false))

	_hp_orb.set_values(p.hp, p.hp_max)
	_focus_orb.set_values(obs.get("focus", 0.0), obs.get("focus_max", 100.0))

	_gauge.backlash = int(obs.get("backlash", 0))
	_gauge.backlash_max = int(obs.get("backlash_max", 5))
	_gauge.next_instant = bool(obs.get("next_instant", false))
	_gauge.silence_left = float(obs.get("silence_left", 0.0))
	_gauge.boss_exposed = bool(obs.get("boss_exposed", false))
	_gauge.expose_amt = float(obs.get("expose_amt", 0.0))

	for i in _runes.size():
		var id: String = _run.loadout[i]
		var st := _rune_state(id, obs, p, s)
		_runes[i].affordable = st["afford"]
		_runes[i].usable = st["usable"]
		_runes[i].cd_frac = st["cd"]

	# interrupt (Kick) gauge — its own cooldown; glows KICK when a cast is up + ready
	var icd_ticks := maxf(1.0, float(CombatCore.to_ticks(defense_cd_sec(obs), s.config.fixed_hz)))
	_guard.usable = bool(obs.get("defense_ready", false))
	_guard.cd_frac = clampf(float(p.defense_ready_tick - s.tick) / icd_ticks, 0.0, 1.0)

	for ev in s.events:
		_handle_event(ev)
	s.events.clear()

func defense_cd_sec(_obs: Dictionary) -> float:
	return 3.0 if _run.boons.get("quickint", false) else 5.0

func _rune_state(id: String, obs: Dictionary, p: Seat, s: CombatState) -> Dictionary:
	var focus := float(obs.get("focus", 0.0))
	var can_cast := (obs.get("casting", {}) as Dictionary).is_empty() and bool(obs.get("gcd_ready", true))
	var afford := true
	var usable := can_cast
	var cd := 0.0
	match id:
		"fracture": afford = focus >= 26.0
		"overload": afford = int(obs.get("backlash", 0)) >= 1
		"quietus":
			afford = focus >= 30.0
			cd = _cd_frac(p, s, "quietus", 9.0); usable = can_cast and cd <= 0.0
		"barrier":
			cd = _cd_frac(p, s, "barrier", 10.0); usable = can_cast and cd <= 0.0
		"silence":
			cd = _cd_frac(p, s, "silence", 11.0); usable = can_cast and cd <= 0.0
		"counterspell":
			cd = _cd_frac(p, s, "counterspell", 9.0); usable = can_cast and cd <= 0.0
	if cd <= 0.0 and not can_cast:
		cd = clampf(float(p.gcd_until_tick - s.tick) / float(CombatCore.to_ticks(1.0, s.config.fixed_hz)), 0.0, 1.0)
	return {"afford": afford, "usable": usable, "cd": cd}

func _cd_frac(p: Seat, s: CombatState, id: String, cd_sec: float) -> float:
	var left := int(p.cooldowns.get(id, 0)) - s.tick
	if left <= 0:
		return 0.0
	return clampf(float(left) / float(CombatCore.to_ticks(cd_sec, s.config.fixed_hz)), 0.0, 1.0)

# ============================================================ JUICE
func _handle_event(ev: Dictionary) -> void:
	if _judge != null:
		_judge.on_event(ev)        # the Judgment Channel stamps its verdicts
	RecapPanel.track(_recap_stats, ev)
	match String(ev.get("t", "")):
		"strike_graded":
			# M7 combo-beat verdicts (a PERFECT dodge feeds Focus).
			if bool(ev.get("player", false)):
				match int(ev.get("grade", 0)):
					StrikeRes.Grade.PERFECT:
						_big_text("PERFECT DODGE!  +FOCUS", Palette.GOLD_BRIGHT, 34)
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
		"interrupt":
			if bool(ev.get("was_heal", false)):
				_big_text("DENIED!", Palette.KICK, 42)
				_dial.react("stagger")
				_do_flash(Palette.KICK, 0.24)
				_add_shake(7.0)
			elif bool(ev.get("clean", false)):
				_big_text("CLEAN KICK!", Palette.GOLD_BRIGHT, 36)
				_dial.react("stagger")
				_do_flash(Palette.KICK, 0.20)
				_add_shake(6.0)
			else:
				_big_text("KICK!", Palette.KICK, 34, 0.55)
				_dial.react("stagger")
				_do_flash(Palette.KICK, 0.14)
				_add_shake(4.0)
		"int_whiff":
			if bool(ev.get("player", false)):
				_big_text("whiff", Palette.TEXT_DIM, 20, 0.4)
		"silence":
			_big_text("SILENCED", Palette.VOID, 28, 0.6)
		"overload":
			_big_text("OVERLOAD!", Palette.KICK, 38)
			_do_flash(Palette.KICK, 0.24)
			_add_shake(8.0)
		"quietus":
			_big_text("QUIETUS — LOCKED", Palette.VOID, 30, 0.7)
			_do_flash(Palette.VOID, 0.2)
			_add_shake(6.0)
		"empower":
			_big_text("EMPOWERED", Palette.EXPOSE, 26, 0.7)   # bad — you let it buff
			_do_flash(Palette.EXPOSE, 0.16)
		"pushback":
			if bool(ev.get("player", false)):
				_big_text("pushed!", Palette.CRIMSON, 20, 0.45)
		"boss_hit":
			var a := float(ev.get("amt", 0))
			_float_num("-%d" % int(a),
				_fx.size * Vector2(0.5, 0.26) + Vector2(randf_range(-40.0, 40.0), 0.0),
				Palette.GOLD_BRIGHT, -32.0)
			_dial.react("impact", a)
			if a >= 120.0:
				_add_shake(4.0)
		"boss_heal":
			var h := float(ev.get("amt", 0))
			_float_num("+%d" % int(h),
				_fx.size * Vector2(0.5, 0.20) + Vector2(randf_range(-30.0, 30.0), 0.0),
				Palette.WIN, -28.0)
			_do_flash(Palette.WIN, 0.12)
			_dial.react("heal")
		"hurt":
			if bool(ev.get("player", false)):
				var d := float(ev.get("amt", 0))
				_do_flash(Palette.CRIMSON, clampf(d / 160.0, 0.10, 0.5))
				_add_shake(clampf(d / 8.0, 3.0, 17.0))
				_float_num("-%d" % int(d), _fx.size * Vector2(0.14, 0.66), Palette.CRIMSON, 30.0)

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
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 20)
	l.add_theme_color_override("font_color", color)
	l.position = pos
	_fx.add_child(l)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", pos.y + dy, 0.7)
	tw.tween_property(l, "modulate:a", 0.0, 0.7).set_trans(Tween.TRANS_QUAD)
	tw.chain().tween_callback(l.queue_free)

# ============================================================ TOOLTIPS
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
	_tip_title.text = "Kick"
	_tip_stats.text = "Space  ·  own cooldown"
	_tip_desc.text = "Kick the boss's current cast. A CLEAN kick — in the last slice of the bar — pays more (Backlash / longer Silence). Every kick also heals you. On cooldown, so choose which cast to shut down."
	_position_tip_above(_guard)

func _hide_tip() -> void:
	if _tip != null:
		_tip.visible = false

func _position_tip_above(node: Control) -> void:
	var w := 250.0
	var h := 124.0
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
	var abilities: Array = [{"icon": "kick", "name": "KICK", "key": "SPC",
		"stats": "5.0s cd  ·  clean = last slice of the cast",
		"tip": "Cut the boss's cast short. A CLEAN kick (inside the bright window) pays your Aspect; a whiffed press still burns the cooldown."}]
	for i in _run.loadout.size():
		var id: String = _run.loadout[i]
		var info: Dictionary = ABILITY_TIPS.get(id, {"stats": "", "tip": ""})
		abilities.append({"icon": id, "name": ABILITY_NAMES.get(id, id), "key": str(i + 1),
			"stats": String(info["stats"]), "tip": String(info["tip"])})
	_book = Grimoire.new("THE VOIDCALLER — %s" % _run.aspect.to_upper(), abilities, _boon_dicts(),
		Palette.VOID)
	_book.closed.connect(_toggle_book)
	_ui.add_child(_book)

func _boon_dicts() -> Array:
	var out: Array = []
	for id in _run.boons:
		for pool in [VoidcallerBoons.SHARED, VoidcallerBoons.DISRUPTOR, VoidcallerBoons.SILENCER]:
			for b in pool:
				if b["id"] == id:
					out.append(b)
	return out

func _boon_title(id: String) -> String:
	for pool in [VoidcallerBoons.SHARED, VoidcallerBoons.DISRUPTOR, VoidcallerBoons.SILENCER]:
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
		"Attune — take one. The ✦ card resonates with your build.", extras, Palette.GOLD)
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
		_title(box, "Every broken cast fed the next — you read the choir and shut it down as the %s." % _run.aspect.capitalize(), 15, Palette.TEXT)
	else:
		_title(box, "%s out-cast you. Attune the void and run it back." % _run.current_encounter().name, 15, Palette.TEXT)
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
