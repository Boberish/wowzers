## Bulwark HUD — Arcane Obsidian. Screens: Aspect select -> Combat -> (Draft ->
## Combat)* -> End. Combat draws with the custom radial dial / liquid orbs / runes and
## polls state each frame. Input: Space = Parry/Dodge, 1-5 = abilities, S = spellbook.
extends Control

const VERB := {"warden": "PARRY", "juggernaut": "DODGE"}
const ABILITY_NAMES := {
	"cleave": "Cleave", "rampage": "Rampage", "fortify": "Fortify",
	"vindicate": "Vindicate", "avalanche": "Avalanche",
	"bloodthirst": "Bloodthirst", "shockwave": "Shockwave",
}
const ABILITY_TIPS := {
	"cleave": {"stats": "Free  ·  42 dmg  ·  +6 rage", "tip": "Filler that builds rage. During a Riposte window it hits far harder — parry, then Cleave into the opening."},
	"rampage": {"stats": "40 rage  ·  130 dmg", "tip": "Your rage dump and main damage. Spend rage you banked from eating hits."},
	"fortify": {"stats": "30 rage  ·  heal 130  ·  -30% dmg 3.5s", "tip": "Turn rage into survival — heal and harden right before a dangerous stretch."},
	"vindicate": {"stats": "Spend Counter  ·  40 dmg each  ·  -25% dmg 3s", "tip": "The Warden payoff: bank Counter by parrying, then unload it all at once."},
	"avalanche": {"stats": "20 rage  ·  30 dmg/stack  ·  staggers", "tip": "The Juggernaut payoff: cash out all your Momentum, and it staggers the current swing."},
	"bloodthirst": {"stats": "25 rage  ·  80 dmg  ·  heals 60%", "tip": "Attack to sustain — heals for most of the damage it deals."},
	"shockwave": {"stats": "50 rage  ·  55 dmg  ·  interrupts", "tip": "Panic button — interrupts the boss's current swing outright."},
}
const SPEC_TIP := {
	"warden": {"name": "Counter & Riposte", "tip": "Parry swings to bank Counter (max 5) and open a brief Riposte window that empowers your next Cleave/Rampage. Spend Counter with Vindicate. Read the swing, punish it."},
	"juggernaut": {"name": "Momentum", "tip": "Dealing and eating hits builds Momentum: more damage AND more mitigation. But Dodging DUMPS it — so eat what you can, dodge only what you must, and cash out with Avalanche."},
}

var _ctrl: CombatController
var _run: RunState
var _screen: String = "select"

var _stage: StageBackdrop
var _stage3d: CombatStage3D = null
var _ui: Control
var _fx: Control
var _book: Control = null

# combat widgets
var _bar: BossBar
var _dial: BossCastDial
var _judge: StrikeJudge
var _hp_orb: LiquidOrb
var _rage_orb: LiquidOrb
var _spec: SpecGauge
var _runes: Array = []
var _guard: AbilityRune
var _progress: Label

# juice
var _shake_root: Control
var _post: ColorRect               # full-screen "feel" pass (screen_post.gdshader)
var _post_mat: ShaderMaterial
var _shake_amt: float = 0.0
var _flash_a: float = 0.0
var _flash_col: Color = Color(1, 1, 1)
var _ab: float = 0.0               # chromatic-aberration amount (decays)
var _shock_t: float = -1.0         # shockwave progress 0..1 (<0 = inactive)
var _shock_amt: float = 0.0
var _shock_c: Vector2 = Vector2(0.5, 0.5)

# loadout ids that read as "offensive" — they fire a bolt + impact burst at the boss
const OFFENSIVE := {
	"cleave": true, "rampage": true, "vindicate": true,
	"avalanche": true, "bloodthirst": true, "shockwave": true,
}

# topology map mode (MASTER-PLAN §MAPS MAP-1; active when _run.map != null)
var _draft_to_map := false         ## the next draft returns to the map, not the next fight
var _draft_header := ""            ## optional custom draft headline (cache salvage etc.)

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
	_ctrl.encounter_ended.connect(_on_end)
	_show_select()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--autostart="):
			# "--autostart=warden" or "--autostart=warden:devourer" to jump to a boss.
			var spec := a.substr("--autostart=".length()).split(":")
			_start_run(spec[0], spec[1] if spec.size() > 1 else "")

func _clear() -> void:
	_book = null
	_stage3d = null
	for c in _ui.get_children():
		c.queue_free()

# ============================================================ SELECT (dev boss picker)
## The Bulwark entry screen: you're here right after picking the class. Choose a boss
## from the list to jump into (the run then continues from there), with a Warden /
## Juggernaut Aspect toggle up top. Built from run_encounters() so new bosses show up
## automatically. "back" / Esc returns to the class-select menu.
func _show_select() -> void:
	_show_boss_select("warden")

func _show_boss_select(aspect: String) -> void:
	_screen = "bosssel"
	_clear()
	var sel := BossSelect.new()
	sel.title = "THE BULWARK"
	sel.subtitle = "TANK — MITIGATE · PICK A FIGHT"
	sel.aspects = [
		{"id": "warden", "label": "WARDEN", "accent": Palette.STEEL,
			"blurb": "Warden · parry & Counter"},
		{"id": "juggernaut", "label": "JUGGERNAUT", "accent": Palette.MOMENTUM,
			"blurb": "Juggernaut · Momentum snowball"},
	]
	sel.encounters = BulwarkContent.run_encounters()
	sel.current = aspect
	sel.hint = "SPACE = Parry/Dodge   ·   F = dodge combo beats   ·   1-5 abilities   ·   S = spellbook"
	sel.extras = [{"label": "THE TOPOLOGY — Ring 3 map run (Realm 1 PoC)",
		"cb": func(): _start_map_run(sel.current)}]
	sel.chosen.connect(_start_run)
	sel.back_pressed.connect(func(): get_tree().change_scene_to_file("res://game/main.tscn"))
	sel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(sel)

# ============================================================ RUN / COMBAT
func _start_run(aspect: String, jump_to: String = "") -> void:
	_run = RunState.start(aspect)
	if jump_to != "":                       # debug: jump straight to a boss by id
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
	_ctrl.begin(BulwarkContent.build_fight(_run, _run.fight_seed()))
	if _run.map != null:                       # map mode: fights start at run integrity
		var s0: Seat = _ctrl.state.seats[0]
		s0.hp = maxf(1.0, s0.hp_max * _run.hp_frac)

func _build_combat() -> void:
	# the physical fight: knight + boss on a 3D dais, behind every HUD widget,
	# in front of the painted backdrop (transparent viewport — the sanctum shows through)
	_stage3d = CombatStage3D.new(_run.aspect, String(_run.current_encounter().id))
	_ui.add_child(_stage3d)

	# combat widgets live under _shake_root so screen-shake moves them together
	_shake_root = Control.new()
	_shake_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shake_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_shake_root)

	_progress = Label.new()
	_progress.add_theme_font_size_override("font_size", 13)
	_progress.add_theme_color_override("font_color", Palette.TEXT_DIM)
	_place(_progress, 0, 0, 0, 0, 22, 16, 360, 40)
	_ui.add_child(_progress)

	var spellbtn := Button.new()
	spellbtn.text = "Spellbook (S)"
	spellbtn.flat = true
	spellbtn.add_theme_color_override("font_color", Palette.GOLD_DIM)
	_place(spellbtn, 1, 0, 1, 0, -150, 12, -18, 42)
	spellbtn.pressed.connect(_toggle_book)
	_ui.add_child(spellbtn)

	_bar = BossBar.new()
	_place(_bar, 0.5, 0, 0.5, 0, -340, 52, 340, 104)
	_shake_root.add_child(_bar)

	_dial = BossCastDial.new()
	_dial.verb = VERB.get(_run.aspect, "DEFEND")
	# center stage: with the 3D boss standing behind it, the dial drops its sigil
	# and becomes the telegraph RETICLE ringed around the boss's body
	_dial.show_sigil = false
	_place(_dial, 0.5, 0, 0.5, 0, -230, 128, 230, 660)
	_shake_root.add_child(_dial)

	# the Judgment Channel: the linear precision instrument under the reticle —
	# enemy cast bar + impact gate + graded bands + verdict stamps + history rail
	_judge = StrikeJudge.new()
	_judge.verb = VERB.get(_run.aspect, "DEFEND")
	_place(_judge, 0.5, 0, 0.5, 0, -330, 664, 330, 768)
	_shake_root.add_child(_judge)

	_hp_orb = LiquidOrb.new()
	_hp_orb.fill = Palette.BLOOD
	_hp_orb.caption = "HEALTH"
	_hp_orb.tooltip_text = "Your health. At 0, the run ends."
	_place(_hp_orb, 0, 1, 0, 1, 55, -170, 180, -45)
	_shake_root.add_child(_hp_orb)

	_rage_orb = LiquidOrb.new()
	_rage_orb.fill = Palette.RAGE
	_rage_orb.caption = "RAGE"
	_rage_orb.tooltip_text = "Rage — built by taking hits, spent on abilities."
	_place(_rage_orb, 1, 1, 1, 1, -180, -170, -55, -45)
	_shake_root.add_child(_rage_orb)

	_spec = SpecGauge.new()
	_spec.aspect = _run.aspect
	_spec.mouse_filter = Control.MOUSE_FILTER_STOP
	_spec.mouse_entered.connect(_show_spec_tip)
	_spec.mouse_exited.connect(_hide_tip)
	_place(_spec, 0.5, 1, 0.5, 1, -200, -245, 200, -180)
	_shake_root.add_child(_spec)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	_place(row, 0.5, 1, 0.5, 1, -330, -168, 330, -84)
	_shake_root.add_child(row)

	# Guard gauge — the defensive verb, with its own cooldown sweep (steel-tinted so
	# it reads apart from the gold ability runes). Clickable, or press Space.
	_guard = AbilityRune.new()
	_guard.label = VERB.get(_run.aspect, "GUARD")
	_guard.key_label = "SPC"
	_guard.icon_id = "guard"
	_guard.accent = Palette.STEEL
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
		rune.icon_id = id
		rune.pressed.connect(_use_ability.bind(i))
		rune.mouse_entered.connect(_show_ability_tip.bind(i))
		rune.mouse_exited.connect(_hide_tip)
		row.add_child(rune)
		_runes.append(rune)

	var hint := Label.new()
	hint.text = "SPACE — %s (own cooldown, off-GCD)    ·    F — DODGE combo beats" % VERB.get(_run.aspect, "DEFEND")
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Palette.GOLD_DIM)
	_place(hint, 0.5, 1, 0.5, 1, -260, -74, 260, -50)
	_shake_root.add_child(hint)

	# stable overlays (not shaken): floating numbers, screen flash, tooltip
	_fx = Control.new()
	_fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_fx)

	# full-screen post pass — the one screen-read in the HUD; hidden while idle
	_post = ColorRect.new()
	_post.set_anchors_preset(Control.PRESET_FULL_RECT)
	_post.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_post_mat = ShaderMaterial.new()
	_post_mat.shader = preload("res://game/ui/screen_post.gdshader")
	_post.material = _post_mat
	_post.visible = false
	_ui.add_child(_post)

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
	_tip_stats = _title(v, "", 12, Palette.STEEL)
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
		KEY_SPACE:
			_ctrl.human({"type": "defense"})
		KEY_F:
			_ctrl.human({"type": "dodge"})
		KEY_1: _use_ability(0)
		KEY_2: _use_ability(1)
		KEY_3: _use_ability(2)
		KEY_4: _use_ability(3)
		KEY_5: _use_ability(4)
		KEY_S:
			_toggle_book()

func _use_ability(i: int) -> void:
	if _screen == "combat" and i >= 0 and i < _run.loadout.size():
		_ctrl.human({"type": "ability", "id": _run.loadout[i]})

# ============================================================ COMBAT RENDER
func _process(delta: float) -> void:
	if _screen != "combat" or _dial == null or _ctrl.state == null:
		return

	# --- juice decay + full-screen post pass ---
	_shake_amt = maxf(0.0, _shake_amt - delta * 42.0)
	if _shake_root != null:
		_shake_root.position = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_amt
	_flash_a = maxf(0.0, _flash_a - delta * 2.4)
	_ab = maxf(0.0, _ab - delta * 4.0)
	if _shock_t >= 0.0:
		_shock_t += delta / 0.38
		if _shock_t > 1.0:
			_shock_t = -1.0
			_shock_amt = 0.0
	var pl := _ctrl.player()
	var hpf := pl.hp_frac() if pl != null else 1.0
	var vig := clampf((0.5 - hpf) / 0.5, 0.0, 1.0)
	vig *= vig
	if _post != null:
		var live := _flash_a > 0.001 or _ab > 0.001 or _shock_t >= 0.0 or vig > 0.01
		_post.visible = live
		if live:
			_post_mat.set_shader_parameter("flash_color", _flash_col)
			_post_mat.set_shader_parameter("flash_amt", _flash_a)
			_post_mat.set_shader_parameter("aberration", _ab)
			_post_mat.set_shader_parameter("shock_center", _shock_c)
			_post_mat.set_shader_parameter("shock_t", _shock_t)
			_post_mat.set_shader_parameter("shock_amt", _shock_amt)
			_post_mat.set_shader_parameter("vignette", vig)

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
		_dial.tg_strikes = []
	else:
		var dur := float(s.telegraph.dur_ticks) * s.dt
		_dial.tg_active = true
		_dial.tg_name = s.telegraph.ability.name
		_dial.tg_frac = (dur - float(tg.get("remaining", 0.0))) / maxf(dur, 0.001)
		_dial.tg_remaining = float(tg.get("remaining", 0.0))
		_dial.tg_size = int(tg.get("size", 0))
		_dial.tg_defensible = bool(tg.get("defensible", false))
		_dial.tg_heal = bool(tg.get("heal", false))
		_dial.tg_feint = bool(tg.get("feint", false))
		_dial.zone_frac = clampf(float(obs.get("def_zone", 0.3)) / maxf(dur, 0.001), 0.0, 1.0)
		_dial.in_zone = _dial.tg_defensible and _dial.tg_remaining <= float(obs.get("def_zone", 0.3)) \
			and bool(obs.get("defense_ready", false))
		_dial.feed_strikes(tg, dur, bool(obs.get("dodge_ready", true)), s.config.strike_good, s.config.strike_perfect)
	_dial.def_ready = bool(obs.get("defense_ready", true))
	_dial.dodge_ready = bool(obs.get("dodge_ready", true))
	if _judge != null:
		_judge.feed(s, obs, float(obs.get("def_zone", 0.3)))

	_hp_orb.set_values(p.hp, p.hp_max)
	_rage_orb.set_values(p.resource, p.resource_max)

	_spec.counter = int(obs.get("counter", 0))
	_spec.momentum = int(obs.get("momentum", 0))
	_spec.momentum_max = int(obs.get("momentum_max", 10))
	_spec.riposte = bool(obs.get("riposte_active", false))

	var gcd_ticks := float(CombatCore.to_ticks(1.0, s.config.fixed_hz))
	for i in _runes.size():
		var id: String = _run.loadout[i]
		_runes[i].affordable = _affordable(id, obs)
		_runes[i].usable = bool(obs.get("gcd_ready", false))
		_runes[i].cd_frac = clampf(float(p.gcd_until_tick - s.tick) / gcd_ticks, 0.0, 1.0)

	# guard gauge: fills back up over the defensive cooldown
	var dcd_ticks := maxf(1.0, float(CombatCore.to_ticks(float(obs.get("def_cd", 2.2)), s.config.fixed_hz)))
	_guard.usable = bool(obs.get("defense_ready", false))
	_guard.cd_frac = clampf(float(p.defense_ready_tick - s.tick) / dcd_ticks, 0.0, 1.0)

	if _stage3d != null:
		_stage3d.sync(s, obs, p)

	for ev in s.events:
		_handle_event(ev)
	s.events.clear()

# ============================================================ JUICE
func _handle_event(ev: Dictionary) -> void:
	if _stage3d != null:
		_stage3d.on_event(ev)      # the 3D actors act out the same event the HUD juices
	if _judge != null:
		_judge.on_event(ev)        # the Judgment Channel stamps its verdicts
	match String(ev.get("t", "")):
		"ability_fired":
			if bool(ev.get("player", false)):
				_on_ability_fired(String(ev.get("id", "")))
		"negate":
			# string dodges emit an echo negate at impact with no seat ref — the
			# strike_graded pop already judged that press, don't double-pop over it
			if bool(ev.get("player", false)) and ev.has("seat"):
				if bool(ev.get("feint", false)):
					# You guarded a Feint. Baited — read the punish, not a parry.
					_big_text("BAITED!", Palette.CRIMSON, 46)
					_do_flash(Palette.CRIMSON, 0.34)
					_add_shake(12.0)
					_ab = maxf(_ab, 0.9)
					_trigger_shock(Vector2(0.5, 0.5), 1.4)
				else:
					_big_text("PARRY!" if _run.aspect == "warden" else "DODGE!", Palette.GOLD_BRIGHT, 46)
					_do_flash(Palette.GOLD, 0.26)
					_add_shake(7.0)
					_ab = maxf(_ab, 0.6)
					_trigger_shock(Vector2(0.5, 0.4), 1.0)
					_dial.react("impact", 40.0)     # the riposte rocks the boss back
		"defend":
			if bool(ev.get("player", false)):
				_big_text("guard", Palette.STEEL, 22, 0.45)
		"hurt":
			if bool(ev.get("player", false)):
				var a := float(ev.get("amt", 0))
				_do_flash(Palette.CRIMSON, clampf(a / 220.0, 0.10, 0.5))
				_add_shake(clampf(a / 9.0, 3.0, 17.0))
				_float_num("-%d" % int(a), _fx.size * Vector2(0.14, 0.66), Palette.CRIMSON, 30.0)
				_ab = maxf(_ab, clampf(a / 140.0, 0.35, 1.5))
				_trigger_shock(Vector2(0.5, 0.5), clampf(a / 90.0, 0.6, 1.6))
		"boss_hit":
			var a := float(ev.get("amt", 0))
			_float_num("-%d" % int(a),
				_fx.size * Vector2(0.5, 0.30) + Vector2(randf_range(-34.0, 34.0), 0.0),
				Palette.GOLD_BRIGHT, -32.0)
			_dial.react("impact", a)
			if a >= 90.0:
				_add_shake(3.0)
		"boss_heal":
			# It's clawing HP back — sell it: green tick up near the boss + a soft green wash.
			var h := float(ev.get("amt", 0))
			_float_num("+%d" % int(h),
				_fx.size * Vector2(0.5, 0.24) + Vector2(randf_range(-30.0, 30.0), 0.0),
				Palette.WIN, -28.0)
			_do_flash(Palette.WIN, 0.12)
			_dial.react("heal")
		"read":
			# You correctly HELD a Feint — reward the discipline; the boss is Exposed.
			if bool(ev.get("player", false)):
				_big_text("READ!  —  exposed", Palette.RELIC, 30, 0.6)
		"strike_graded":
			# M7 string beat verdicts — the grade pop lands AT the press (or at a held
			# feint's impact for READ), so the feedback is glued to the input.
			if bool(ev.get("player", false)):
				match int(ev.get("grade", 0)):
					StrikeRes.Grade.PERFECT:
						_big_text("PERFECT!", Palette.GOLD_BRIGHT, 46)
						_do_flash(Palette.GOLD, 0.22)
						_trigger_shock(Vector2(0.5, 0.4), 1.0)
					StrikeRes.Grade.GOOD:
						_big_text("DODGED", Palette.GOLD, 34, 0.6)
					StrikeRes.Grade.GRAZE:
						_big_text("graze", Palette.STEEL, 26, 0.5)
					StrikeRes.Grade.BAITED:
						_big_text("BAITED!", Palette.CRIMSON, 46)
						_do_flash(Palette.CRIMSON, 0.30)
						_add_shake(10.0)
					StrikeRes.Grade.READ:
						_big_text("READ!", Palette.RELIC, 30, 0.6)
		"dodge_whiff":
			if bool(ev.get("player", false)):
				_big_text("TOO EARLY!", Palette.CRIMSON.darkened(0.1), 30, 0.6)
		"staggered":
			# You cut off a cast. Denying a heal is the sweet one.
			if bool(ev.get("was_heal", false)):
				_big_text("DENIED!", Palette.WIN, 44)
				_do_flash(Palette.WIN, 0.24)
			else:
				_big_text("STAGGERED!", Palette.STEEL, 38, 0.6)
				_do_flash(Palette.STEEL, 0.18)
			_dial.react("stagger")
			_add_shake(6.0)

func _add_shake(amt: float) -> void:
	_shake_amt = minf(20.0, maxf(_shake_amt, amt))

func _do_flash(col: Color, a: float) -> void:
	_flash_col = col
	_flash_a = maxf(_flash_a, a)

func _trigger_shock(center: Vector2, amt: float) -> void:
	_shock_c = center
	_shock_amt = maxf(_shock_amt, amt)
	_shock_t = 0.0

# centre of a widget in _fx's (stable, un-shaken) coordinate space
func _fx_local(node: Control) -> Vector2:
	return node.global_position + node.size * 0.5 - _fx.global_position

# An ability actually committed (past GCD/resource): give the press a visible hit.
func _on_ability_fired(id: String) -> void:
	var boss := _fx_local(_dial)
	if bool(OFFENSIVE.get(id, false)):
		var from := boss + Vector2(0.0, 120.0)
		var idx := int(_run.loadout.find(id))
		if idx >= 0 and idx < _runes.size():
			from = _fx_local(_runes[idx])
		var col := Palette.STEEL if id == "shockwave" else Palette.GOLD_BRIGHT
		_ability_bolt(from, boss, col)
		_impact_burst(boss, col)
		_add_shake(2.5)
	elif _hp_orb != null:
		# support cast (Fortify): a steel shield-burst on the health orb
		_impact_burst(_fx_local(_hp_orb), Palette.STEEL)

# a bright additive bolt from the pressed rune into the boss, snapping shut fast
func _ability_bolt(from: Vector2, to: Vector2, col: Color) -> void:
	var ln := Line2D.new()
	ln.add_point(from)
	ln.add_point(to)
	ln.width = 5.0
	ln.default_color = col
	ln.begin_cap_mode = Line2D.LINE_CAP_ROUND
	ln.end_cap_mode = Line2D.LINE_CAP_ROUND
	ln.z_index = 5
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	ln.material = m
	_fx.add_child(ln)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(ln, "modulate:a", 0.0, 0.22).from(1.0)
	tw.tween_property(ln, "width", 1.0, 0.22)
	tw.chain().tween_callback(ln.queue_free)

# a one-shot additive spark burst (CPU particles — web-reliable + headless-safe)
func _impact_burst(pos: Vector2, col: Color) -> void:
	var pz := CPUParticles2D.new()
	pz.position = pos
	pz.z_index = 6
	pz.emitting = false
	pz.one_shot = true
	pz.explosiveness = 1.0
	pz.amount = 20
	pz.lifetime = 0.5
	pz.direction = Vector2.UP
	pz.spread = 180.0
	pz.initial_velocity_min = 80.0
	pz.initial_velocity_max = 230.0
	pz.gravity = Vector2(0.0, 220.0)
	pz.scale_amount_min = 2.0
	pz.scale_amount_max = 3.5
	pz.color = col
	var g := Gradient.new()
	g.set_color(0, col)
	g.set_color(1, Color(col.r, col.g, col.b, 0.0))
	pz.color_ramp = g   # CPUParticles2D takes a Gradient directly (GPU particles want a texture)
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	pz.material = m
	_fx.add_child(pz)
	pz.emitting = true
	var t := get_tree().create_timer(0.9)
	t.timeout.connect(func(): if is_instance_valid(pz): pz.queue_free())

func _big_text(text: String, col: Color, fs: int = 40, life: float = 0.7) -> void:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.custom_minimum_size = Vector2(340, 0)
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	l.position = _fx.size * Vector2(0.5, 0.44) - Vector2(170.0, 0.0)
	_fx.add_child(l)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 34.0, life)
	tw.tween_property(l, "modulate:a", 0.0, life).set_trans(Tween.TRANS_QUAD)
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
	_position_tip_above(_spec)

func _do_guard() -> void:
	_ctrl.human({"type": "defense"})

func _show_guard_tip() -> void:
	_tip_title.text = VERB.get(_run.aspect, "GUARD")
	_tip_stats.text = "Space  ·  own cooldown, not your GCD"
	if _run.aspect == "warden":
		_tip_desc.text = "Parry a swing inside its window to negate it, reflect damage, and bank Counter."
	else:
		_tip_desc.text = "Dodge a swing inside its window to negate it — but it dumps your Momentum, so dodge only what you must."
	_position_tip_above(_guard)

func _hide_tip() -> void:
	if _tip != null:
		_tip.visible = false

func _position_tip_above(node: Control) -> void:
	var w := 250.0
	var h := 116.0
	var gp := node.global_position
	var x := clampf(gp.x + node.size.x * 0.5 - w * 0.5, 8.0, size.x - w - 8.0)
	var y := maxf(8.0, gp.y - h - 8.0)
	_tip.position = Vector2(x, y)
	_tip.size = Vector2(w, h)
	_tip.visible = true

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

func _phase_num(s: CombatState) -> int:
	var fr := s.boss.hp / s.boss.hp_max
	var n := 1
	for i in s.encounter.phases.size():
		if s.encounter.phases[i].at >= fr:
			n = i + 1
	return n

func _affordable(id: String, obs: Dictionary) -> bool:
	var rage := float(obs.get("rage", 0.0))
	match id:
		"rampage": return rage >= 40.0
		"fortify": return rage >= 30.0
		"vindicate": return int(obs.get("counter", 0)) >= 1
		"avalanche": return rage >= 20.0 and int(obs.get("momentum", 0)) >= 1
		"bloodthirst": return rage >= 25.0
		"shockwave": return rage >= 50.0
		_: return true

# ============================================================ SPELLBOOK
func _toggle_book() -> void:
	if _book != null:
		_book.queue_free()
		_book = null
		return
	_book = _panel(Palette.BG1.darkened(-0.0))
	_book.self_modulate = Color(1, 1, 1, 0.98)
	_place(_book, 0.5, 0.5, 0.5, 0.5, -280, -220, 280, 220)
	_ui.add_child(_book)
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 20)
	v.add_theme_constant_override("separation", 6)
	_book.add_child(v)
	_title(v, "SPELLBOOK", 22, Palette.GOLD)
	_title(v, "Abilities", 14, Palette.STEEL)
	for id in _run.loadout:
		_title(v, "  %s" % ABILITY_NAMES.get(id, id), 14, Palette.TEXT)
	_title(v, "Boons", 14, Palette.STEEL)
	if _run.boons.is_empty():
		_title(v, "  (none yet — win a fight to draft one)", 13, Palette.TEXT_DIM)
	for id in _run.boons:
		_title(v, "  * %s" % _boon_title(id), 13, Palette.TEXT)
	_title(v, "press S to close", 12, Palette.TEXT_DIM)

func _boon_title(id: String) -> String:
	for pool in [BulwarkBoons.SHARED, BulwarkBoons.WARDEN, BulwarkBoons.JUGG]:
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
		if _draft_to_map:                      # map mode: pool exhausted → back to the map
			_draft_to_map = false
			_draft_header = ""
			_show_map()
			return
		_run.enc_index += 1
		_begin_fight()
		return
	var extras: Array = []
	if _minted > 0:
		extras.append("+%d Tokens minted — spend them responsibly." % _minted)
	var hl_text := _draft_header if _draft_header != "" else "%s FALLS" % _run.current_encounter().name.to_upper()
	_draft_header = ""
	var ds := DraftScreen.new(_run, picks, hl_text,
		"Reforge — take one. The ✦ card resonates with your build.", extras, Palette.GOLD)
	ds.boon_taken.connect(_on_card_taken)
	_ui.add_child(ds)

func _on_card_taken(boon: Dictionary) -> void:
	Draft.take(_run, boon)
	if _draft_to_map:                          # map mode: drafts hand back to the map
		_draft_to_map = false
		_show_map()
		return
	_run.enc_index += 1
	_begin_fight()

# ============================================================ TOPOLOGY MAP (MAP-1)
## The Across-the-Obelisk-style run: a generated node map (RunMap) replaces the linear
## chain. Fights start at the run's persistent hp_frac (attrition is the tradeoff the
## map trades in); events/cooling/cache move hp_frac or grant drafts; the Seal ends it.
func _start_map_run(aspect: String) -> void:
	_run = RunState.start(aspect)
	_run.map = RunMap.generate(int(Time.get_ticks_usec()) & 0x7FFFFFFF,
		_run.encounters.size(), MapContent.event_ids())
	_show_map()

func _show_map() -> void:
	_screen = "map"
	_clear()
	var ms := MapScreen.new()
	ms.map = _run.map
	ms.current = _run.map_node
	ms.inventory = _run.inventory
	ms.hp_frac = _run.hp_frac
	ms.node_entered.connect(_enter_node)
	ms.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(ms)

func _enter_node(id: int) -> void:
	_run.map_node = id
	var n: Dictionary = _run.map.node(id)
	var first_visit: bool = not bool(n.get("visited", false))
	n["visited"] = true
	if first_visit and bool(n["key"]) and not _run.inventory.get("api_key", false):
		_run.inventory["api_key"] = true
		_map_stop(String(n["name"]), MapContent.KEY_PICKUP,
			[{"label": "TAKE IT", "fx": {"key": true,
				"result": "Authorization acquired. Try not to post it anywhere public."}}],
			Palette.GOLD_BRIGHT, _resolve_node.bind(n))
		return
	_resolve_node(n)

func _resolve_node(n: Dictionary) -> void:
	match String(n["kind"]):
		RunMap.KIND_COMBAT, RunMap.KIND_SEAL:
			_run.enc_index = int(n["fight"])
			_begin_fight()
		RunMap.KIND_EVENT:
			var ev := MapContent.event(String(n["event"]))
			_map_stop(String(ev["title"]), String(ev["body"]), ev["choices"], Palette.VOID, _show_map)
		RunMap.KIND_COOLING:
			_map_stop(MapContent.COOLING_TITLE, MapContent.COOLING_BODY,
				[{"label": "THROTTLE  (rest — +%d%% integrity)" % int(MapContent.COOLING_HEAL * 100),
					"fx": {"heal": MapContent.COOLING_HEAL, "result": MapContent.COOLING_RESULT}}],
				Palette.FLOW, _show_map)
		RunMap.KIND_CACHE:
			_map_stop(MapContent.CACHE_TITLE, MapContent.CACHE_BODY,
				[{"label": "SALVAGE A COMPONENT", "fx": {"draft": true, "result": MapContent.CACHE_RESULT}}],
				Palette.GOLD, _show_map)

## A stop = one MapEventPanel; applying the chosen fx, then continuing via `done`
## (or into a salvage draft that returns to the map).
func _map_stop(title: String, body: String, choices: Array, accent: Color, done: Callable) -> void:
	_screen = "mapstop"
	_clear()
	var p := MapEventPanel.new()
	p.title_text = title
	p.body_text = body
	p.choices = choices
	p.accent = accent
	p.finished.connect(func(fx: Dictionary):
		_apply_map_fx(fx)
		if bool(fx.get("draft", false)):
			_draft_to_map = true
			_draft_header = "SALVAGE — TAKE ONE"
			_show_draft()
		else:
			done.call())
	p.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(p)

## Events bruise or patch you, but only combat can kill: integrity floors at 5%.
func _apply_map_fx(fx: Dictionary) -> void:
	_run.hp_frac = clampf(_run.hp_frac + float(fx.get("heal", 0.0)) - float(fx.get("hurt", 0.0)),
		0.05, 1.0)

# ============================================================ END
var _minted := 0

func _on_end(won: bool) -> void:
	if _screen != "combat":
		return
	_minted = Draft.mint(_ctrl.state, _run.char_class) if won else 0
	_run.tokens += _minted
	if _run.map != null:                       # map mode: persist integrity, route by node
		var s0: Seat = _ctrl.state.seats[0]
		_run.hp_frac = clampf(s0.hp / maxf(1.0, s0.hp_max), 0.0, 1.0)
		if not won:
			_show_end(false)
		elif String(_run.map.node(_run.map_node)["kind"]) == RunMap.KIND_SEAL:
			_show_end(true)
		else:
			_draft_to_map = true
			_show_draft()
		return
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
	var banner := _title(box, "RUN CLEARED" if won else "DEFEATED", 52, Palette.WIN if won else Palette.LOSE)
	banner.add_theme_font_override("font", UiKit.title(900))
	if won:
		_title(box, "You held the line as the %s." % _run.aspect.capitalize(), 16, Palette.TEXT)
	else:
		_title(box, "%s ground you down. Reforge and try again." % _run.current_encounter().name, 16, Palette.TEXT)
	_title(box, "TOKENS · %d held%s" % [_run.tokens,
		(" · +%d minted this fight" % _minted) if _minted > 0 else ""], 13, Palette.TEXT_DIM)
	var again := Button.new()
	again.text = "PICK A FIGHT"
	again.custom_minimum_size = Vector2(220, 48)
	again.add_theme_font_size_override("font_size", 18)
	again.pressed.connect(_show_boss_select.bind(_run.aspect))   # back to the picker, same Aspect
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
