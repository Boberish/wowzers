## Mender HUD — Arcane Obsidian. Aspect select -> Combat -> (continue)* -> End.
## Raid frames (health bars + absorb + debuff + HoT pips) with click-cast: hover a
## frame, press a spell key (1-6, Q, E, 7). Reuses the boss bar/dial, a mana orb, and
## the combat event stream for per-frame hit/heal juice. Esc -> class menu.
extends Control

const SPELL_KEYS := {"1": "flash", "2": "mend", "3": "renew", "4": "ward",
	"5": "cascade", "6": "well", "q": "dispel", "e": "medit", "7": "signature"}
# Click-cast mouse binds are rebindable (loaded from MenderBinds into `_binds`).
const SPELL_TIPS := {
	"flash": "Fast, pricey emergency heal. Brinkwarden: huge on a low target.",
	"mend": "Efficient filler heal. Your bread-and-butter.",
	"renew": "Instant heal-over-time. Pre-cast it before damage.",
	"ward": "Instant damage shield (absorb). Blunt a spike before it lands.",
	"cascade": "Smart AoE — heals your 3 lowest allies.",
	"well": "Instant raid heal to everyone (30s cooldown).",
	"dispel": "Cleanse a debuff (the pulsing crimson marks). Off-GCD.",
	"medit": "Restore 280 mana (45s cooldown). Off-GCD.",
	"surge": "TIDECALLER: spend your Reservoir as raid shields — a beat AHEAD of a spike.",
	"laststand": "BRINKWARDEN: spend Nerve for a huge raid heal + 45% DR. Catch the raid a beat BEHIND.",
}

var _ctrl: CombatController
var _run: RunState
var _mcfg: MenderConfig
var _binds: Dictionary = {}          ## click-cast mouse binds (rebindable)
var _screen: String = "select"

var _stage: StageBackdrop
var _ui: Control
var _fx: Control

var _bar: BossBar
var _dial: BossCastDial
var _judge: StrikeJudge
var _mana: LiquidOrb
var _spec: SpecStrip
var _castbar: CastChannel
var _runes: Array = []
var _frames: Array = []            ## [{frame, seat}]
var _frame_by_seat: Dictionary = {}
var _hover_seat: Seat = null
var _focus_seat: Seat = null
var _progress: Label

# performance meters
var _meter: Label
var _enrage_lbl: Label
var _gcd_cursor: GcdCursor
var _stat_eff: float = 0.0
var _stat_over: float = 0.0
var _stat_dmg: float = 0.0
var _stat_saves: int = 0
var _stat_mana: float = 0.0
var _stat_biggest: int = 0
var _prev_mana: float = 0.0
var _prev_frac: Dictionary = {}

var _tip: Control
var _tip_title: Label
var _tip_desc: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	seed(Time.get_ticks_usec())
	set_theme(UiKit.build_theme())
	_mcfg = MenderContent.make_mender_config()
	_binds = MenderBinds.load_binds()
	_stage = StageBackdrop.new()
	add_child(_stage)
	_add_vignette()
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_ui)
	_ctrl = CombatController.new()
	add_child(_ctrl)
	_ctrl.encounter_ended.connect(_on_end)
	_show_select()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--autostart="):
			var parts := a.substr("--autostart=".length()).split(":")
			if parts[0] == "tidecaller" or parts[0] == "brinkwarden":
				_start_run(parts[0], parts[1] if parts.size() > 1 else "")

func _clear() -> void:
	for c in _ui.get_children():
		c.queue_free()

func _signature() -> String:
	return "surge" if _run.aspect == "tidecaller" else "laststand"

# ============================================================ SELECT
func _show_select() -> void:
	_screen = "select"
	_clear()
	var sel := BossSelect.new()
	sel.title = "THE MENDER"
	sel.subtitle = "HEALER — KEEP-ALIVE · PICK A FIGHT"
	sel.aspects = [
		{"id": "tidecaller", "label": "TIDECALLER", "accent": Palette.STEEL,
			"blurb": "Tidecaller · bank overheal, Surge it into shields — play AHEAD"},
		{"id": "brinkwarden", "label": "BRINKWARDEN", "accent": Palette.MOMENTUM,
			"blurb": "Brinkwarden · heals swell as allies drop — play BEHIND"},
	]
	sel.encounters = MenderContent.run_encounters()
	sel.extras = [{"label": "Mouse Bindings", "cb": _show_binds}]
	sel.hint = "Hover an ally + 1-6 / Q / E / 7 to cast   ·   SPACE/F = Dodge   ·   Esc = class menu"
	sel.chosen.connect(_start_run)
	sel.back_pressed.connect(func(): get_tree().change_scene_to_file("res://game/main.tscn"))
	sel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(sel)

# ============================================================ RUN / COMBAT
func _start_run(aspect: String, jump_to: String = "") -> void:
	_run = RunState.start_mender(aspect)
	if jump_to != "":                       # debug: jump straight to a boss by id
		for i in _run.encounters.size():
			if String(_run.encounters[i].id) == jump_to:
				_run.enc_index = i
				break
	_begin_fight()

func _begin_fight() -> void:
	_screen = "combat"
	_clear()
	_ctrl.begin(MenderContent.build_fight(_run, _run.fight_seed()))
	_hover_seat = null
	_focus_seat = null
	_stat_eff = 0.0; _stat_over = 0.0; _stat_dmg = 0.0
	_stat_saves = 0; _stat_mana = 0.0; _stat_biggest = 0
	_prev_mana = _mcfg.mana_max
	_prev_frac = {}
	_build_combat()

func _build_combat() -> void:
	_fx = Control.new()
	_fx.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_progress = _label(_ui, "", 13, Palette.TEXT_DIM, HORIZONTAL_ALIGNMENT_LEFT)
	_place(_progress, 0, 0, 0, 0, 22, 16, 380, 40)
	var menuhint := _label(_ui, "Esc: menu", 12, Palette.GOLD_DIM, HORIZONTAL_ALIGNMENT_RIGHT)
	_place(menuhint, 1, 0, 1, 0, -140, 16, -18, 40)

	_bar = BossBar.new()
	_place(_bar, 0.5, 0, 0.5, 0, -340, 46, 340, 96)
	_ui.add_child(_bar)

	_dial = BossCastDial.new()
	_dial.tg_defensible = false
	# center stage: the boss sigil owns the space above the raid frames
	_place(_dial, 0.5, 0, 0.5, 0, -140, 112, 140, 480)
	_ui.add_child(_dial)

	# the Judgment Channel (compact): the barrage-dodge timing instrument, right
	# under the raid frames where the healer's eyes already live
	_judge = StrikeJudge.new()
	_judge.verb = "DODGE"
	_judge.compact = true
	_place(_judge, 0.5, 0, 0.5, 0, -280, 634, 280, 714)
	_ui.add_child(_judge)

	# raid frames — the whole raid, YOU included: aoe strike beats (M7) can hit the
	# healer now, so your own HP is a frame like everyone else's (and self-castable).
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	_place(row, 0.5, 0.5, 0.5, 0.5, -376, -36, 376, 78)
	_ui.add_child(row)
	_frames = []
	_frame_by_seat = {}
	for seat in _ctrl.state.seats:
		var fr := RaidFrame.new()
		fr.unit_name = seat.unit_name
		fr.role = seat.role
		fr.hovered.connect(_on_frame_hover)
		fr.unhovered.connect(_on_frame_unhover)
		row.add_child(fr)
		_frames.append({"frame": fr, "seat": seat})
		_frame_by_seat[seat] = fr

	var binds := _label(_ui, _hint_text(), 11, Palette.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	_place(binds, 0.5, 0.5, 0.5, 0.5, -370, 76, 370, 96)

	# mana orb (bottom-left)
	_mana = LiquidOrb.new()
	_mana.fill = Color("2f5e93")
	_mana.caption = "MANA"
	_place(_mana, 0, 1, 0, 1, 55, -170, 180, -45)
	_ui.add_child(_mana)

	# spec readout (Reservoir / Nerve) — a reliquary meter that ignites when castable
	_spec = SpecStrip.new()
	_spec.title = "RESERVOIR" if _run.aspect == "tidecaller" else "NERVE"
	_spec.accent = Palette.STEEL if _run.aspect == "tidecaller" else Palette.MOMENTUM
	_place(_spec, 0.5, 1, 0.5, 1, -220, -254, 220, -206)
	_ui.add_child(_spec)

	# the benediction channel — sits just under the raid frames, invisible unless casting
	_castbar = CastChannel.new()
	_place(_castbar, 0.5, 1, 0.5, 1, -240, -322, 240, -262)
	_ui.add_child(_castbar)

	# ability runes (bottom-center)
	var rrow := HBoxContainer.new()
	rrow.alignment = BoxContainer.ALIGNMENT_CENTER
	rrow.add_theme_constant_override("separation", 8)
	_place(rrow, 0.5, 1, 0.5, 1, -340, -158, 340, -86)
	_ui.add_child(rrow)
	_runes = []
	for id in _run.loadout:
		var sp: Dictionary = _mcfg.spells.get(id, {})
		var rune := AbilityRune.new()
		rune.label = String(sp.get("name", id)).split(" ")[0]
		rune.key_label = String(sp.get("key", "")).to_upper()
		rune.icon_id = id
		if sp.has("spec"):
			rune.accent = Palette.STEEL if _run.aspect == "tidecaller" else Palette.MOMENTUM
		rune.pressed.connect(_cast.bind(id))
		rune.mouse_entered.connect(_show_tip.bind(id, rune))
		rune.mouse_exited.connect(_hide_tip)
		rrow.add_child(rune)
		rune.custom_minimum_size = Vector2(62, 62)
		_runes.append({"rune": rune, "id": id})

	_meter = _label(_ui, "", 12, Palette.STEEL, HORIZONTAL_ALIGNMENT_LEFT)
	_place(_meter, 0, 1, 0, 1, 48, -202, 340, -180)
	_enrage_lbl = _label(_ui, "", 14, Palette.TEXT_DIM, HORIZONTAL_ALIGNMENT_RIGHT)
	_place(_enrage_lbl, 1, 0, 1, 0, -250, 44, -18, 66)

	_ui.add_child(_fx)
	_build_tooltip()

	_gcd_cursor = GcdCursor.new()      # cursor-attached global-cooldown ring, on top
	_gcd_cursor.z_index = 100
	_ui.add_child(_gcd_cursor)

# ============================================================ INPUT / CASTING
func _input(event: InputEvent) -> void:
	# Mouseover click-cast: a bound mouse chord casts on the HOVERED frame (VuhDo-style).
	if event is InputEventMouseButton and event.pressed:
		if _screen == "combat" and _hover_seat != null:
			var chord := _mouse_chord(event)
			if chord != "":
				var id := String(_binds.get(chord, "none"))
				if id == "signature":
					id = _signature()
				if id != "none" and id != "":
					_focus_seat = _hover_seat
					_cast_on(_hover_seat, id)
		return
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://game/main.tscn")
		return
	if _screen != "combat":
		return
	# keyboard keys cast on the hovered frame too
	match event.keycode:
		KEY_SPACE, KEY_F:
			_ctrl.human({"type": "dodge"})     # universal dodge (M7) — cancels your cast
		KEY_1: _cast("flash")
		KEY_2: _cast("mend")
		KEY_3: _cast("renew")
		KEY_4: _cast("ward")
		KEY_5: _cast("cascade")
		KEY_6: _cast("well")
		KEY_Q: _cast("dispel")
		KEY_E: _cast("medit")
		KEY_7: _cast(_signature())

func _mouse_chord(e: InputEventMouseButton) -> String:
	var mods := ""
	if e.shift_pressed:
		mods += "shift+"
	if e.ctrl_pressed:
		mods += "ctrl+"
	if e.alt_pressed:
		mods += "alt+"
	match e.button_index:
		MOUSE_BUTTON_LEFT:
			return mods + "left"
		MOUSE_BUTTON_RIGHT:
			return mods + "right"
		MOUSE_BUTTON_MIDDLE:
			return mods + "middle"
	return ""

func _cast(id: String) -> void:
	if id == "signature":
		id = _signature()
	var sp: Dictionary = _mcfg.spells.get(id, {})
	if sp.is_empty():
		return
	var target: Seat = null
	if bool(sp.get("target", false)):
		target = _hover_seat if _hover_seat != null else _focus_seat
		if target == null or not target.alive():
			return
	_ctrl.human({"type": "ability", "id": id, "target": target})

func _on_frame_hover(fr: RaidFrame) -> void:
	for e in _frames:
		if e["frame"] == fr:
			_hover_seat = e["seat"]

func _on_frame_unhover(fr: RaidFrame) -> void:
	for e in _frames:
		if e["frame"] == fr and _hover_seat == e["seat"]:
			_hover_seat = null

func _cast_on(seat: Seat, id: String) -> void:
	var sp: Dictionary = _mcfg.spells.get(id, {})
	if sp.is_empty():
		return
	var s := _ctrl.state
	var p := _ctrl.player()
	if s == null or p == null:
		return
	# Mirror the engine's gates so we can give instant feedback (gold = cast, grey = blocked).
	var offgcd := bool(sp.get("offgcd", false))
	var ready := true
	if not offgcd and s.tick < p.gcd_until_tick:
		ready = false
	elif s.tick < int(p.cooldowns.get(id, 0)):
		ready = false
	elif not offgcd and not p.casting.is_empty():
		ready = false
	elif p.resource < float(sp.get("mana", 0.0)):
		ready = false
	elif id == "dispel" and seat.debuff.is_empty():
		ready = false
	elif id == "surge" and float(p.vars.get("reservoir", 0.0)) <= 1.0:
		ready = false
	elif id == "laststand" and float(p.vars.get("nerve", 0.0)) <= 1.0:
		ready = false
	if not ready:
		if _frame_by_seat.has(seat):
			_frame_by_seat[seat].flash(Palette.TEXT_DIM)   # muted flash = "not ready"
		return
	var target: Seat = seat if bool(sp.get("target", false)) else null
	if _frame_by_seat.has(seat):
		_frame_by_seat[seat].flash(Palette.GOLD)           # gold flash = cast accepted
	_ctrl.human({"type": "ability", "id": id, "target": target})

func _heal_mult(seat: Seat) -> float:
	if _run.aspect == "brinkwarden":
		return 1.0 + (1.0 - seat.hp_frac()) * _mcfg.brink_heal_scale
	return 1.0

func _predict(sp: Dictionary, seat: Seat) -> float:
	if seat.hp_max <= 0.0:
		return 0.0
	return (float(sp["heal"]) * _heal_mult(seat)) / seat.hp_max

# ============================================================ MOUSE BINDINGS
func _hint_text() -> String:
	var parts: Array = []
	for c in MenderBinds.CHORDS:
		var id := String(_binds.get(c, "none"))
		if id != "none":
			var real := _signature() if id == "signature" else id
			var nm := String(_mcfg.spells.get(real, {}).get("name", real)).split(" ")[0]
			parts.append("%s %s" % [MenderBinds.CHORD_SHORT.get(c, c), nm])
	parts.append("SPACE/F Dodge")
	return "   ".join(parts)

func _spell_display(sid: String) -> String:
	if sid == "none":
		return "— none —"
	if sid == "signature":
		return "Signature (7)"
	return String(_mcfg.spells.get(sid, {}).get("name", sid))

func _show_binds() -> void:
	_screen = "binds"
	_clear()
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(center)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 10)
	center.add_child(box)
	_label(box, "MOUSE BINDINGS", 30, Palette.GOLD, HORIZONTAL_ALIGNMENT_CENTER)
	_label(box, "Click-cast: pick which heal each mouse chord casts on a raid frame.", 14, Palette.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(_gap(6))
	for c in MenderBinds.CHORDS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		var lbl := _label(row, MenderBinds.CHORD_NAMES.get(c, c), 15, Palette.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
		lbl.custom_minimum_size = Vector2(150, 0)
		var opt := OptionButton.new()
		opt.custom_minimum_size = Vector2(210, 34)
		for sid in MenderBinds.SPELL_OPTIONS:
			opt.add_item(_spell_display(sid))
		opt.selected = MenderBinds.SPELL_OPTIONS.find(String(_binds.get(c, "none")))
		opt.item_selected.connect(_on_bind_changed.bind(c))
		row.add_child(opt)
		box.add_child(row)
	box.add_child(_gap(8))
	var btnrow := HBoxContainer.new()
	btnrow.add_theme_constant_override("separation", 14)
	btnrow.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(btnrow)
	var save := Button.new()
	save.text = "SAVE"
	save.custom_minimum_size = Vector2(160, 42)
	save.add_theme_font_size_override("font_size", 16)
	save.pressed.connect(_save_binds)
	btnrow.add_child(save)
	var reset := Button.new()
	reset.text = "Reset to defaults"
	reset.flat = true
	reset.add_theme_color_override("font_color", Palette.TEXT_DIM)
	reset.pressed.connect(_reset_binds)
	btnrow.add_child(reset)

func _on_bind_changed(idx: int, chord: String) -> void:
	_binds[chord] = MenderBinds.SPELL_OPTIONS[idx]

func _save_binds() -> void:
	MenderBinds.save_binds(_binds)
	_show_select()

func _reset_binds() -> void:
	_binds = MenderBinds.DEFAULTS.duplicate(true)
	_show_binds()

# ============================================================ RENDER
func _process(_delta: float) -> void:
	if _screen != "combat" or _dial == null or _ctrl.state == null:
		return
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
		_dial.tg_size = int(tg.get("size", 0))
		_dial.tg_defensible = false
		_dial.feed_strikes(tg, dur, bool(obs.get("dodge_ready", true)), s.config.strike_good, s.config.strike_perfect)
	_dial.dodge_ready = bool(obs.get("dodge_ready", true))
	_dial.verb = "DODGE"
	if _judge != null:
		_judge.feed(s, obs, 0.0)

	# raid frames
	for e in _frames:
		var seat: Seat = e["seat"]
		var fr: RaidFrame = e["frame"]
		fr.frac = seat.hp_frac()
		fr.hp = int(round(seat.hp))
		fr.maxhp = int(round(seat.hp_max))
		fr.absorb_frac = (seat.absorb / seat.hp_max) if seat.hp_max > 0.0 else 0.0
		fr.has_debuff = not seat.debuff.is_empty()
		fr.hot_count = seat.hots.size()
		fr.dead = not seat.alive()
		fr.bloodied = seat.alive() and seat.hp_frac() <= _mcfg.blood_thresh
		fr.is_target = (seat == _hover_seat) or (_hover_seat == null and seat == _focus_seat)
		fr.incoming_frac = 0.0
		fr.incoming_dmg_frac = 0.0
		fr.incoming_lethal = false

	# incoming boss damage: red "about to lose" on the frames the current telegraph will hit
	if s.telegraph != null:
		var ab := s.telegraph.ability
		var amt := ab.amount * CombatCore.current_phase(s).mult
		var victims: Array = []
		if not ab.strikes.is_empty():
			# string (M7): worst case = the summed remaining aoe payload (beats can
			# still be dodged); aoe beats threaten EVERY frame — the healer's too
			var frac_sum := 0.0
			for i in range(s.telegraph.next_strike, ab.strikes.size()):
				var st: StrikeRes = ab.strikes[i]
				if st.aoe and not st.feint:
					frac_sum += st.amount_frac
			if frac_sum > 0.0:
				amt *= frac_sum
				for e3 in _frames:
					if e3["seat"].alive():
						victims.append(e3["seat"])
		else:
			match ab.effect:
				AbilityRes.Effect.DMG_TARGET, AbilityRes.Effect.MARK_NUKE:
					if s.telegraph.target != null:
						victims = [s.telegraph.target]
				AbilityRes.Effect.DMG_ALL, AbilityRes.Effect.NOVA:
					for e3 in _frames:
						if e3["seat"].alive() and e3["seat"].role != "healer":
							victims.append(e3["seat"])   # classic novas never touch the healer
		for v in victims:
			if _frame_by_seat.has(v) and v.hp_max > 0.0:
				var fr2: RaidFrame = _frame_by_seat[v]
				fr2.incoming_dmg_frac = amt / v.hp_max
				fr2.incoming_lethal = amt >= (v.hp + v.absorb)

	# cast prediction: a faded incoming-heal ghost on the target(s) of an in-flight cast
	var cast_now: Dictionary = p.casting
	if not cast_now.is_empty():
		var cid := String(cast_now["id"])
		var csp: Dictionary = _mcfg.spells.get(cid, {})
		if csp.has("heal"):
			if bool(csp.get("target", false)):
				var ct = cast_now.get("target")
				if ct != null and _frame_by_seat.has(ct):
					_frame_by_seat[ct].incoming_frac = _predict(csp, ct)
			elif cid == "cascade":
				var pool: Array = []
				for e2 in _frames:
					if e2["seat"].alive():
						pool.append(e2["seat"])
				pool.sort_custom(func(a, b): return a.hp_frac() < b.hp_frac())
				for i in mini(3, pool.size()):
					if _frame_by_seat.has(pool[i]):
						_frame_by_seat[pool[i]].incoming_frac = _predict(csp, pool[i])

	_mana.set_values(p.resource, _mcfg.mana_max)

	# spec readout
	if _run.aspect == "tidecaller":
		var res := float(obs.get("reservoir", 0.0))
		_spec.value = res
		_spec.max_value = _mcfg.reservoir_max
		_spec.charged = res > 1.0
	else:
		var nv := float(obs.get("nerve", 0.0))
		var blood := 0
		for e in _frames:
			var st: Seat = e["seat"]
			if st.alive() and st.hp_frac() <= _mcfg.blood_thresh:
				blood += 1
		_spec.value = nv
		_spec.max_value = _mcfg.nerve_max
		_spec.charged = nv > 1.0
		_spec.hint = "%d bloodied" % blood if blood > 0 else ""

	# cast bar
	var casting: Dictionary = p.casting
	if casting.is_empty():
		_castbar.active = false
	else:
		_castbar.active = true
		var prog := float(s.tick - int(casting["start_tick"])) / maxf(1.0, float(casting["dur_ticks"]))
		_castbar.frac = clampf(prog, 0.0, 1.0)
		var ct: Seat = casting.get("target")
		_castbar.target = ct.unit_name if ct != null else ""
		_castbar.spell_id = String(casting["id"])
		_castbar.label = String(_mcfg.spells[casting["id"]]["name"])

	# runes: affordability + cooldown sweep (read the seat directly)
	var gcd_ticks := float(CombatCore.to_ticks(_mcfg.gcd, s.config.fixed_hz))
	for e in _runes:
		var rid: String = e["id"]
		var rune: AbilityRune = e["rune"]
		var sp: Dictionary = _mcfg.spells[rid]
		var offgcd := bool(sp.get("offgcd", false))
		var afford := p.resource >= float(sp.get("mana", 0.0))
		if rid == "surge":
			afford = afford and float(obs.get("reservoir", 0.0)) > 1.0
		elif rid == "laststand":
			afford = afford and float(obs.get("nerve", 0.0)) > 1.0
		rune.affordable = afford
		var cd_until := int(p.cooldowns.get(rid, 0))
		var gcd_block := (not offgcd) and s.tick < p.gcd_until_tick
		var cd_block := s.tick < cd_until
		rune.usable = not gcd_block and not cd_block
		if cd_block:
			rune.cd_frac = clampf(float(cd_until - s.tick) / maxf(1.0, float(CombatCore.to_ticks(float(sp.get("cd", 1.0)), s.config.fixed_hz))), 0.0, 1.0)
		elif gcd_block:
			rune.cd_frac = clampf(float(p.gcd_until_tick - s.tick) / gcd_ticks, 0.0, 1.0)
		else:
			rune.cd_frac = 0.0

	# global-cooldown cursor ring: fills during a cast or the GCD, "ready" pulse when free
	var cur_frac := 1.0
	if not p.casting.is_empty():
		var cst: Dictionary = p.casting
		cur_frac = clampf(float(s.tick - int(cst["start_tick"])) / maxf(1.0, float(cst["dur_ticks"])), 0.0, 1.0)
	elif s.tick < p.gcd_until_tick:
		var gt := maxf(1.0, float(CombatCore.to_ticks(_mcfg.gcd, s.config.fixed_hz)))
		cur_frac = 1.0 - clampf(float(p.gcd_until_tick - s.tick) / gt, 0.0, 1.0)
	_gcd_cursor.frac = cur_frac

	# performance meters + enrage clock
	_stat_mana += maxf(0.0, _prev_mana - p.resource)
	_prev_mana = p.resource
	for fe in _frames:
		var st: Seat = fe["seat"]
		var cf := st.hp_frac()
		if float(_prev_frac.get(st, 1.0)) < 0.2 and cf >= 0.2 and st.alive():
			_stat_saves += 1
		_prev_frac[st] = cf
	_meter.text = "HPS %d   ·   Overheal %d%%   ·   Saves %d" % [
		int(_stat_eff / maxf(1.0, s.time())), int(_overheal_pct()), _stat_saves]
	var en := s.encounter.enrage_at
	if en > 0.0:
		var left := en - s.time()
		if left > 0.0:
			_enrage_lbl.text = "ENRAGE in %ds" % int(ceil(left))
			_enrage_lbl.add_theme_color_override("font_color", Palette.CRIMSON if left < 15.0 else Palette.TEXT_DIM)
		else:
			_enrage_lbl.text = "!! ENRAGED !!"
			_enrage_lbl.add_theme_color_override("font_color", Palette.CRIMSON)
	else:
		_enrage_lbl.text = ""

	for ev in s.events:
		_handle_event(ev)
	s.events.clear()

func _overheal_pct() -> float:
	var total := _stat_eff + _stat_over
	return (100.0 * _stat_over / total) if total > 0.0 else 0.0

func _stats_summary() -> String:
	var t := maxf(1.0, _ctrl.state.time())
	return "Effective healing %d   ·   HPS %d   ·   Overheal %d%%\nDamage taken %d   ·   Mana spent %d   ·   Saves %d   ·   Biggest heal %d" % [
		int(_stat_eff), int(_stat_eff / t), int(_overheal_pct()),
		int(_stat_dmg), int(_stat_mana), _stat_saves, _stat_biggest]

func _handle_event(ev: Dictionary) -> void:
	var t := String(ev.get("t", ""))
	if _judge != null:
		_judge.on_event(ev)        # the Judgment Channel stamps its verdicts
	# M7 strike beats: the healer's own verdicts pop centre-screen — the dodge is
	# YOUR button now, so its feedback lives where your eyes are, not on a frame.
	if t == "strike_graded":
		if bool(ev.get("player", false)):
			match int(ev.get("grade", 0)):
				StrikeRes.Grade.PERFECT:
					_center_pop("PERFECT DODGE!", Palette.GOLD_BRIGHT, 34)
				StrikeRes.Grade.GOOD:
					_center_pop("DODGED", Palette.GOLD, 26)
				StrikeRes.Grade.GRAZE:
					_center_pop("graze", Palette.STEEL, 20)
				StrikeRes.Grade.BAITED:
					_center_pop("BAITED!", Palette.CRIMSON, 34)
				StrikeRes.Grade.READ:
					_center_pop("READ!", Palette.RELIC, 24)
		return
	if t == "dodge_whiff":
		if bool(ev.get("player", false)):
			_center_pop("TOO EARLY!", Palette.CRIMSON, 24)
		return
	if t == "cast_cancelled":
		_center_pop("cast cancelled", Palette.TEXT_DIM, 16)
		return
	if t == "heal":
		_stat_eff += float(ev.get("amt", 0))
		_stat_over += float(ev.get("over", 0))
		_stat_biggest = maxi(_stat_biggest, int(ev.get("amt", 0)))
	elif t == "hurt":
		_stat_dmg += float(ev.get("amt", 0))
	var seat = ev.get("seat")
	if (t == "hurt" or t == "heal" or t == "debuff") and seat != null and _frame_by_seat.has(seat):
		var fr: RaidFrame = _frame_by_seat[seat]
		if t == "hurt":
			fr.flash(Palette.CRIMSON)
			_float_over(fr, "-%d" % int(ev.get("amt", 0)), Palette.CRIMSON, 26.0)
		elif t == "heal":
			if int(ev.get("amt", 0)) > 0:
				fr.flash(Palette.WIN)
				_float_over(fr, "+%d" % int(ev.get("amt", 0)), Palette.WIN, -26.0)
		elif t == "debuff":
			fr.flash(Palette.CRIMSON)

## Big centre-screen verdict pop (the martial HUDs' _big_text equivalent).
func _center_pop(text: String, col: Color, fsize: int) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", UiKit.display(750, 2))
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(_fx.size.x * 0.5 - 220.0, _fx.size.y * 0.34)
	l.size = Vector2(440.0, 44.0)
	_fx.add_child(l)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 26.0, 0.8)
	tw.tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.25)
	tw.chain().tween_callback(l.queue_free)

func _float_over(fr: RaidFrame, text: String, col: Color, dy: float) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", col)
	l.position = fr.global_position + Vector2(fr.size.x * 0.5 - 14.0, 6.0)
	_fx.add_child(l)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y + dy, 0.7)
	tw.tween_property(l, "modulate:a", 0.0, 0.7)
	tw.chain().tween_callback(l.queue_free)

func _phase_num(s: CombatState) -> int:
	var fr := s.boss.hp / s.boss.hp_max
	var n := 1
	for i in s.encounter.phases.size():
		if s.encounter.phases[i].at >= fr:
			n = i + 1
	return n

# ============================================================ CONTINUE / END
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

func _show_draft() -> void:
	_screen = "draft"
	_clear()
	var picks := Draft.roll_offers(_run)
	if picks.is_empty():
		_run.enc_index += 1
		_begin_fight()
		return
	var extras: Array = [_stats_summary()]
	if _minted > 0:
		extras.append("+%d Tokens minted — spend them responsibly." % _minted)
	var ds := DraftScreen.new(_run, picks, "%s FALLS" % _run.current_encounter().name.to_upper(),
		"The party holds. Take a boon — the ✦ card resonates with your build.",
		extras, Palette.STEEL)
	ds.boon_taken.connect(_on_card_taken)
	_ui.add_child(ds)

func _on_card_taken(boon: Dictionary) -> void:
	Draft.take(_run, boon)
	_run.enc_index += 1
	_begin_fight()

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
	banner.text = "RUN CLEARED" if won else "WIPED"
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_font_override("font", UiKit.title(900))
	banner.add_theme_font_size_override("font_size", 52)
	banner.add_theme_color_override("font_color", Palette.WIN if won else Palette.LOSE)
	box.add_child(banner)
	if won:
		_label(box, "You kept them all standing as the %s." % _run.aspect.capitalize(), 16, Palette.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	else:
		_label(box, "%s overwhelmed the party." % _run.current_encounter().name, 16, Palette.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_label(box, _stats_summary(), 14, Palette.STEEL, HORIZONTAL_ALIGNMENT_CENTER)
	_label(box, "TOKENS · %d held%s" % [_run.tokens,
		(" · +%d minted this fight" % _minted) if _minted > 0 else ""], 13, Palette.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	var again := Button.new()
	again.text = "NEW RUN"
	again.custom_minimum_size = Vector2(200, 48)
	again.add_theme_font_size_override("font_size", 18)
	again.pressed.connect(_show_select)
	box.add_child(again)
	var menu := Button.new()
	menu.text = "Class menu"
	menu.flat = true
	menu.add_theme_color_override("font_color", Palette.TEXT_DIM)
	menu.pressed.connect(func(): get_tree().change_scene_to_file("res://game/main.tscn"))
	box.add_child(menu)

# ============================================================ TOOLTIP
func _build_tooltip() -> void:
	_tip = GlassPanel.new("TOOLTIP")
	_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip.visible = false
	_tip.custom_minimum_size = Vector2(260, 78)
	_ui.add_child(_tip)
	var v := VBoxContainer.new()
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 12)
	v.add_theme_constant_override("separation", 4)
	_tip.add_child(v)
	_tip_title = _label(v, "", 15, Palette.GOLD, HORIZONTAL_ALIGNMENT_LEFT)
	_tip_desc = Label.new()
	_tip_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_tip_desc.custom_minimum_size = Vector2(236, 0)
	_tip_desc.add_theme_font_size_override("font_size", 13)
	_tip_desc.add_theme_color_override("font_color", Palette.TEXT)
	v.add_child(_tip_desc)

func _show_tip(id: String, rune: AbilityRune) -> void:
	var real := _signature() if (id == "surge" or id == "laststand") else id
	_tip_title.text = String(_mcfg.spells.get(real, {}).get("name", real))
	_tip_desc.text = String(SPELL_TIPS.get(real, ""))
	var w := 260.0
	var h := 96.0
	var gp := rune.global_position
	_tip.position = Vector2(clampf(gp.x + rune.size.x * 0.5 - w * 0.5, 8.0, size.x - w - 8.0), maxf(8.0, gp.y - h - 8.0))
	_tip.size = Vector2(w, h)
	_tip.visible = true

func _hide_tip() -> void:
	if _tip != null:
		_tip.visible = false

# ============================================================ helpers
func _label(parent: Node, text: String, fs: int, col: Color, align: int) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	parent.add_child(l)
	return l

func _gap(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c

func _add_vignette() -> void:
	var grad := Gradient.new()
	grad.set_color(0, Color(0, 0, 0, 0.0))
	grad.set_color(1, Color(0, 0, 0, 0.5))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 1.0)
	gt.width = 512
	gt.height = 512
	var v := TextureRect.new()
	v.texture = gt
	v.stretch_mode = TextureRect.STRETCH_SCALE
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(v)

func _round_bar(bar: ProgressBar, fill_color: Color) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.03, 0.025, 0.05)
	bg.set_corner_radius_all(6)
	bg.set_border_width_all(1)
	bg.border_color = Palette.GOLD_DIM
	bar.add_theme_stylebox_override("background", bg)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(6)
	fill.border_width_top = 2                 # a lit top sheen edge
	fill.border_color = fill_color.lightened(0.45)
	bar.add_theme_stylebox_override("fill", fill)

func _place(node: Control, al: float, at: float, ar: float, ab: float,
		ol: float, ot: float, orr: float, ob: float) -> void:
	node.anchor_left = al; node.anchor_top = at; node.anchor_right = ar; node.anchor_bottom = ab
	node.offset_left = ol; node.offset_top = ot; node.offset_right = orr; node.offset_bottom = ob
