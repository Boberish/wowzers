## Bloomweaver HUD — Arcane Obsidian. Aspect select -> Combat -> draft -> End.
## Raid frames with click-cast (hover + keys / mouse chords). The class reads on the
## frames: Growth pips tick, hovering a Growth'd frame ghosts its BLOOM value (the
## double-tap payoff), wards cap the bar in gold, PERFECT WARD pops when one is
## fully eaten, wilts fade grey. Sap orb + Verdance petal ring. Esc -> class menu.
extends Control

const SPELL_KEYS := {"1": "growth", "2": "bark", "3": "overgrowth", "4": "lash",
	"q": "saprot", "e": "lifesurge", "7": "signature"}
const SPELL_TIPS := {
	"growth": "Plant a heal-over-time. RECAST on a Growth'd ally to BLOOM it — cash the remaining ticks instantly. Plant early, bloom the spike.",
	"bark": "Instant ward. If damage FULLY consumes it: PERFECT WARD — Sap refund + bonus Verdance. If it expires unused, it wilts (wasted).",
	"overgrowth": "2s cast: plant Growth on the whole party. The blanket that starts the garden.",
	"lash": "Flick a thorn at the boss (18). The greed button for calm windows.",
	"saprot": "Cleanse a debuff and leave a Growth where it was — rot becomes flowers. Off-GCD.",
	"lifesurge": "BLOOM every Growth at 125%, at once. The panic button is the garden you already planted. Off-GCD, 30s.",
	"wildbloom": "WILDGROVE: spend all Verdance — heal every Growth'd ally for that much and restart their Growths.",
	"briarheart": "THORNVEIL: spend all Verdance — thorned wards on the whole party. They reflect, and full absorbs refund.",
}

var _ctrl: CombatController
var _run: RunState
var _bcfg: BloomweaverConfig
var _binds: Dictionary = {}
var _screen: String = "select"

var _stage: StageBackdrop
var _ui: Control
var _fx: Control

var _bar: BossBar
var _dial: BossCastDial
var _judge: StrikeJudge
var _recap_stats := {}          # view-side fight tallies for THE RECKONING
var _sap: LiquidOrb
var _verd: VerdanceGauge
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
var _enrage_col := Color(0, 0, 0, 0)   # cached enrage-label colour (apply override only on change)
var _gcd_cursor: GcdCursor
var _stat_eff: float = 0.0
var _stat_over: float = 0.0
var _stat_dmg: float = 0.0
var _stat_saves: int = 0
var _stat_biggest: int = 0
var _prev_frac: Dictionary = {}

var _tip: Control
var _tip_title: Label
var _tip_desc: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	seed(Time.get_ticks_usec())
	set_theme(UiKit.build_theme())
	_bcfg = BloomweaverContent.make_bloom_config()
	_binds = BloomweaverBinds.load_binds()
	_stage = StageBackdrop.new()
	add_child(_stage)
	_add_vignette()
	_ui = Control.new()
	_ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_ui)
	_ctrl = CombatController.new()
	add_child(_ctrl)
	_ctrl.encounter_ended.connect(_on_end_moment)
	_show_select()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--autostart="):
			var parts := a.substr("--autostart=".length()).split(":")
			if parts[0] == "wildgrove" or parts[0] == "thornveil":
				_start_run(parts[0], parts[1] if parts.size() > 1 else "")

func _clear() -> void:
	TransitionVeil.flash_on(self)   # screens settle in, never snap
	for c in _ui.get_children():
		c.queue_free()

func _signature() -> String:
	return "wildbloom" if _run.aspect == "wildgrove" else "briarheart"

func _aspect_color() -> Color:
	return Palette.VERDANCE if _run.aspect == "wildgrove" else Palette.THORN

# ============================================================ SELECT
func _show_select() -> void:
	_screen = "select"
	_clear()
	var sel := BossSelect.new()
	sel.title = "THE BLOOMWEAVER"
	sel.subtitle = "HEALER — ANTICIPATE · PICK A FIGHT"
	sel.aspects = [
		{"id": "wildgrove", "label": "WILDGROVE", "accent": Palette.VERDANCE,
			"blurb": "Wildgrove · 3+ Growths light Flourish — sprawl and ramp the garden"},
		{"id": "thornveil", "label": "THORNVEIL", "accent": Palette.THORN,
			"blurb": "Thornveil · wards reflect; a PERFECT ward refunds — answer the swing"},
	]
	sel.encounters = BloomweaverContent.run_encounters()
	sel.extras = [{"label": "Mouse Bindings", "cb": _show_binds}]
	sel.hint = "Hover an ally + 1-4 / Q / E / 7 to cast   ·   double-tap Growth = BLOOM   ·   SPACE/F = Dodge   ·   Esc = class menu"
	sel.chosen.connect(_start_run)
	sel.back_pressed.connect(func(): get_tree().change_scene_to_file("res://game/main.tscn"))
	sel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ui.add_child(sel)

# ============================================================ RUN / COMBAT
func _start_run(aspect: String, jump_to: String = "") -> void:
	_run = RunState.start_bloomweaver(aspect)
	if jump_to != "":                       # debug: jump straight to a boss by id
		for i in _run.encounters.size():
			if String(_run.encounters[i].id) == jump_to:
				_run.enc_index = i
				break
	_begin_fight()

func _begin_fight() -> void:
	_screen = "combat"
	_clear()
	_ctrl.begin(BloomweaverContent.build_fight(_run, _run.fight_seed()))
	_hover_seat = null
	_focus_seat = null
	_stat_eff = 0.0; _stat_over = 0.0; _stat_dmg = 0.0
	_stat_saves = 0; _stat_biggest = 0
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

	# every fight opens with a ceremony: the boss's name-card burns in and off
	BossIntro.play(_ui, _run.current_encounter().name)
	_recap_stats = {}              # a fresh reckoning per fight

	# raid frames — the whole raid, YOU included: aoe strike beats (M7) hit the
	# healer too, so your own HP is a frame like everyone else's (and self-castable).
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

	# Sap orb (bottom-left)
	_sap = LiquidOrb.new()
	_sap.fill = Palette.SAP.darkened(0.25)
	_sap.caption = "SAP"
	_place(_sap, 0, 1, 0, 1, 55, -170, 180, -45)
	_ui.add_child(_sap)

	# the Blooming Medallion — the winged Verdance centrepiece
	_verd = VerdanceGauge.new()
	_verd.aspect = _run.aspect
	_verd.verdance_max = _bcfg.verdance_max
	_verd.min_spend = _bcfg.verd_min_spend
	_place(_verd, 0.5, 1, 0.5, 1, -300, -298, 300, -168)
	_ui.add_child(_verd)

	# the benediction channel — under the raid frames, invisible unless casting
	_castbar = CastChannel.new()
	_castbar.accent = Palette.VERDANCE
	_place(_castbar, 0.5, 1, 0.5, 1, -240, -358, 240, -298)
	_ui.add_child(_castbar)

	# ability runes (bottom-center)
	var rrow := HBoxContainer.new()
	rrow.alignment = BoxContainer.ALIGNMENT_CENTER
	rrow.add_theme_constant_override("separation", 8)
	_place(rrow, 0.5, 1, 0.5, 1, -300, -158, 300, -86)
	_ui.add_child(rrow)
	_runes = []
	for id in _run.loadout:
		var sp: Dictionary = _bcfg.spells.get(id, {})
		var rune := AbilityRune.new()
		rune.label = String(sp.get("name", id)).split(" ")[0]
		rune.key_label = String(sp.get("key", "")).to_upper()
		rune.icon_id = id
		if sp.has("spec"):
			rune.accent = _aspect_color()
		rune.pressed.connect(_cast.bind(id))
		rune.mouse_entered.connect(_show_tip.bind(id, rune))
		rune.mouse_exited.connect(_hide_tip)
		rrow.add_child(rune)
		rune.custom_minimum_size = Vector2(62, 62)
		_runes.append({"rune": rune, "id": id})

	_meter = _label(_ui, "", 12, Palette.VERDANCE, HORIZONTAL_ALIGNMENT_LEFT)
	_place(_meter, 0, 1, 0, 1, 48, -202, 380, -180)
	_enrage_lbl = _label(_ui, "", 14, Palette.TEXT_DIM, HORIZONTAL_ALIGNMENT_RIGHT)
	_enrage_col = Color(0, 0, 0, 0)   # fresh label each fight — re-apply the colour once
	_place(_enrage_lbl, 1, 0, 1, 0, -250, 44, -18, 66)

	_ui.add_child(_fx)
	_build_tooltip()

	_gcd_cursor = GcdCursor.new()
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
	match event.keycode:
		KEY_SPACE, KEY_F:
			_ctrl.human({"type": "dodge"})     # universal dodge (M7)
		KEY_1: _cast("growth")
		KEY_2: _cast("bark")
		KEY_3: _cast("overgrowth")
		KEY_4: _cast("lash")
		KEY_Q: _cast("saprot")
		KEY_E: _cast("lifesurge")
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
	var sp: Dictionary = _bcfg.spells.get(id, {})
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
	var sp: Dictionary = _bcfg.spells.get(id, {})
	if sp.is_empty():
		return
	var s := _ctrl.state
	var p := _ctrl.player()
	if s == null or p == null:
		return
	# Mirror the engine's gates for instant feedback (gold = cast, grey = blocked).
	var offgcd := bool(sp.get("offgcd", false))
	var kit := p.kit as BloomweaverKit
	var ready := true
	if not offgcd and s.tick < p.gcd_until_tick:
		ready = false
	elif s.tick < int(p.cooldowns.get(id, 0)):
		ready = false
	elif not offgcd and not p.casting.is_empty():
		ready = false
	elif p.resource < float(sp.get("sap", 0.0)):
		ready = false
	elif id == "saprot" and seat.debuff.is_empty():
		ready = false
	elif sp.has("spec") and float(p.vars.get("verdance", 0.0)) < _bcfg.verd_min_spend:
		ready = false
	elif id == "lifesurge" and kit != null and kit._garden_count(s) == 0:
		ready = false
	if not ready:
		if _frame_by_seat.has(seat):
			_frame_by_seat[seat].flash(Palette.TEXT_DIM)   # muted flash = "not ready"
		return
	var target: Seat = seat if bool(sp.get("target", false)) else null
	if _frame_by_seat.has(seat):
		_frame_by_seat[seat].flash(Palette.GOLD)           # gold flash = cast accepted
	_ctrl.human({"type": "ability", "id": id, "target": target})

## Predicted BLOOM restore for a hovered Growth'd frame (the double-tap ghost).
func _bloom_frac(seat: Seat) -> float:
	var p := _ctrl.player()
	if p == null or seat == null or seat.hp_max <= 0.0:
		return 0.0
	var kit := p.kit as BloomweaverKit
	if kit == null:
		return 0.0
	var gi := kit._find_growth(seat)
	if gi < 0:
		return 0.0
	var amt: float = kit._remaining(seat.hots[gi]) * kit._bloom_eff() * kit.heal_mult(seat)
	return amt / seat.hp_max

# ============================================================ MOUSE BINDINGS
func _hint_text() -> String:
	var parts: Array = []
	for c in BloomweaverBinds.CHORDS:
		var id := String(_binds.get(c, "none"))
		if id != "none":
			var real := _signature() if id == "signature" else id
			var nm := String(_bcfg.spells.get(real, {}).get("name", real)).split(" ")[0]
			parts.append("%s %s" % [BloomweaverBinds.CHORD_SHORT.get(c, c), nm])
	parts.append("SPACE/F Dodge")
	return "   ".join(parts)

func _spell_display(sid: String) -> String:
	if sid == "none":
		return "— none —"
	if sid == "signature":
		return "Signature (7)"
	return String(_bcfg.spells.get(sid, {}).get("name", sid))

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
	_label(box, "Click-cast: pick which spell each mouse chord casts on a raid frame.", 14, Palette.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(_gap(6))
	for c in BloomweaverBinds.CHORDS:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		var lbl := _label(row, BloomweaverBinds.CHORD_NAMES.get(c, c), 15, Palette.TEXT, HORIZONTAL_ALIGNMENT_RIGHT)
		lbl.custom_minimum_size = Vector2(150, 0)
		var opt := OptionButton.new()
		opt.custom_minimum_size = Vector2(210, 34)
		for sid in BloomweaverBinds.SPELL_OPTIONS:
			opt.add_item(_spell_display(sid))
		opt.selected = BloomweaverBinds.SPELL_OPTIONS.find(String(_binds.get(c, "none")))
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
	_binds[chord] = BloomweaverBinds.SPELL_OPTIONS[idx]

func _save_binds() -> void:
	BloomweaverBinds.save_binds(_binds)
	_show_select()

func _reset_binds() -> void:
	_binds = BloomweaverBinds.DEFAULTS.duplicate(true)
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
	_bar.phase_num = BossBar.phase_index(s)
	if _bar.phase_ats.is_empty():	# immutable per fight; set once (bar is fresh each fight)
		_bar.phase_ats = s.encounter.phases.map(func(ph): return ph.at)
	_bar.enrage_in = (s.encounter.enrage_at - float(s.tick) * s.dt) if s.encounter.enrage_at > 0.0 else INF
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
		fr.bloodied = seat.alive() and seat.hp_frac() <= 0.35
		fr.is_target = (seat == _hover_seat) or (_hover_seat == null and seat == _focus_seat)
		# hovering a Growth'd frame ghosts what a BLOOM (double-tap) would restore
		fr.incoming_frac = _bloom_frac(seat) if seat == _hover_seat else 0.0
		fr.incoming_dmg_frac = 0.0
		fr.incoming_lethal = false

	# incoming boss damage: red "about to lose" on the frames the telegraph will hit
	if s.telegraph != null:
		var ab := s.telegraph.ability
		var amt := ab.amount * CombatCore.current_phase(s).mult
		var victims: Array = []
		match ab.effect:
			AbilityRes.Effect.DMG_TARGET, AbilityRes.Effect.MARK_NUKE:
				if s.telegraph.target != null:
					victims = [s.telegraph.target]
			AbilityRes.Effect.DMG_ALL, AbilityRes.Effect.NOVA:
				for e3 in _frames:
					if e3["seat"].alive():
						victims.append(e3["seat"])
		for v in victims:
			if _frame_by_seat.has(v) and v.hp_max > 0.0:
				var fr2: RaidFrame = _frame_by_seat[v]
				fr2.incoming_dmg_frac = amt / v.hp_max
				fr2.incoming_lethal = amt >= (v.hp + v.absorb)

	_sap.set_values(p.resource, _bcfg.sap_max)

	# Verdance petal ring
	_verd.verdance = float(obs.get("verdance", 0.0))
	_verd.flourish = bool(obs.get("flourish", false))
	_verd.garden = int(obs.get("garden", 0))
	_verd.thorns = int(float(p.vars.get("stat_thorns", 0.0)))

	# cast bar (Overgrowth)
	var casting: Dictionary = p.casting
	if casting.is_empty():
		_castbar.active = false
	else:
		_castbar.active = true
		var prog := float(s.tick - int(casting["start_tick"])) / maxf(1.0, float(casting["dur_ticks"]))
		_castbar.frac = clampf(prog, 0.0, 1.0)
		var cast_t: Seat = casting.get("target")
		_castbar.target = cast_t.unit_name if cast_t != null else ""
		_castbar.spell_id = String(casting["id"])
		_castbar.label = String(_bcfg.spells[casting["id"]]["name"])

	# runes: affordability + cooldown sweep
	var gcd_ticks := float(CombatCore.to_ticks(_bcfg.gcd, s.config.fixed_hz))
	var kit := p.kit as BloomweaverKit
	for e in _runes:
		var rid: String = e["id"]
		var rune: AbilityRune = e["rune"]
		var sp: Dictionary = _bcfg.spells[rid]
		var offgcd := bool(sp.get("offgcd", false))
		var afford := p.resource >= float(sp.get("sap", 0.0))
		if sp.has("spec"):
			afford = afford and float(obs.get("verdance", 0.0)) >= _bcfg.verd_min_spend
		elif rid == "lifesurge":
			afford = afford and int(obs.get("garden", 0)) > 0
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

	# global-cooldown cursor ring
	var cur_frac := 1.0
	if not p.casting.is_empty():
		var cst: Dictionary = p.casting
		cur_frac = clampf(float(s.tick - int(cst["start_tick"])) / maxf(1.0, float(cst["dur_ticks"])), 0.0, 1.0)
	elif s.tick < p.gcd_until_tick:
		var gt := maxf(1.0, float(CombatCore.to_ticks(_bcfg.gcd, s.config.fixed_hz)))
		cur_frac = 1.0 - clampf(float(p.gcd_until_tick - s.tick) / gt, 0.0, 1.0)
	_gcd_cursor.frac = cur_frac

	# performance meters + enrage clock
	for fe in _frames:
		var st: Seat = fe["seat"]
		var cf := st.hp_frac()
		if float(_prev_frac.get(st, 1.0)) < 0.2 and cf >= 0.2 and st.alive():
			_stat_saves += 1
		_prev_frac[st] = cf
	_meter.text = "HPS %d   ·   Overheal %d%%   ·   Perfect Wards %d" % [
		int(_stat_eff / maxf(1.0, s.time())), int(_overheal_pct()),
		int(p.vars.get("stat_perfect", 0))]
	var en := s.encounter.enrage_at
	if en > 0.0:
		var left := en - s.time()
		var col: Color
		if left > 0.0:
			_enrage_lbl.text = "ENRAGE in %ds" % int(ceil(left))
			col = Palette.CRIMSON if left < 15.0 else Palette.TEXT_DIM
		else:
			_enrage_lbl.text = "!! ENRAGED !!"
			col = Palette.CRIMSON
		if col != _enrage_col:               # theme override only on change (was every frame)
			_enrage_lbl.add_theme_color_override("font_color", col)
			_enrage_col = col
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
	var v: Dictionary = _ctrl.player().vars
	return "Effective healing %d   ·   HPS %d   ·   Overheal %d%%   ·   Biggest %d\nBlooms %d   ·   Perfect Wards %d   ·   Wilted %d   ·   Thorn damage %d   ·   Saves %d" % [
		int(_stat_eff), int(_stat_eff / t), int(_overheal_pct()), _stat_biggest,
		int(v.get("stat_blooms", 0)), int(v.get("stat_perfect", 0)),
		int(float(v.get("stat_wilted", 0.0))), int(float(v.get("stat_thorns", 0.0))), _stat_saves]

func _handle_event(ev: Dictionary) -> void:
	var t := String(ev.get("t", ""))
	if _judge != null:
		_judge.on_event(ev)        # the Judgment Channel stamps its verdicts
	RecapPanel.track(_recap_stats, ev)
	# M7 strike beats: the healer's own verdicts pop centre-screen.
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
	var fr: RaidFrame = _frame_by_seat.get(seat) if seat != null else null
	match t:
		"hurt":
			if fr != null:
				fr.flash(Palette.CRIMSON)
				_float_over(fr, "-%d" % int(ev.get("amt", 0)), Palette.CRIMSON, 26.0)
		"heal":
			if fr != null and int(ev.get("amt", 0)) > 0:
				fr.flash(Palette.WIN)
				_float_over(fr, "+%d" % int(ev.get("amt", 0)), Palette.WIN, -26.0)
		"debuff":
			if fr != null:
				fr.flash(Palette.CRIMSON)
		"bloom":
			if fr != null:
				fr.flash(Palette.VERDANCE)
				_float_over(fr, "BLOOM +%d" % int(ev.get("amt", 0)), Palette.VERDANCE, -34.0, 17)
		"perfect_ward":
			if fr != null:
				fr.flash(Palette.GOLD_BRIGHT)
				_float_over(fr, "PERFECT WARD!", Palette.GOLD_BRIGHT, -34.0, 17)
		"wilt":
			if fr != null:
				_float_over(fr, "wilted −%d" % int(ev.get("amt", 0)), Palette.TEXT_DIM, 20.0)
		"warded":
			if fr != null:
				fr.flash(Palette.GOLD)
		"saprot":
			if fr != null:
				fr.flash(Palette.VERDANCE)
				_float_over(fr, "rot → flowers", Palette.VERDANCE, -26.0)
		"lifesurge":
			_banner("LIFESURGE — the garden blooms!", Palette.VERDANCE)
		"wildbloom":
			_banner("WILDBLOOM", Palette.VERDANCE)
		"briarheart":
			_banner("BRIARHEART", Palette.THORN)
		"boss_hit":
			if _dial != null:
				_dial.react("impact", float(ev.get("amt", 0)))   # the sigil flinches — thorns bite
			if _run.aspect == "thornveil" and _bar != null and int(ev.get("amt", 0)) > 0:
				_float_at(_bar.global_position + Vector2(_bar.size.x - 60.0, 30.0),
					"-%d" % int(ev.get("amt", 0)), Palette.THORN)

## Big centre-screen verdict pop (M7 dodge feedback; plain position — no anchors
## preset, per the UI-OVERHAUL gotcha).
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

func _float_over(fr: RaidFrame, text: String, col: Color, dy: float, fs: int = 15) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	l.position = fr.global_position + Vector2(fr.size.x * 0.5 - 14.0, 6.0)
	_fx.add_child(l)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y + dy, 0.7)
	tw.tween_property(l, "modulate:a", 0.0, 0.7)
	tw.chain().tween_callback(l.queue_free)

func _float_at(pos: Vector2, text: String, col: Color) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 13)
	l.add_theme_color_override("font_color", col)
	l.position = pos + Vector2(randf() * 30.0 - 15.0, 0.0)
	_fx.add_child(l)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 22.0, 0.6)
	tw.tween_property(l, "modulate:a", 0.0, 0.6)
	tw.chain().tween_callback(l.queue_free)

func _banner(text: String, col: Color) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 26)
	l.add_theme_color_override("font_color", col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_CENTER_TOP)
	l.position = Vector2(size.x * 0.5 - 220.0, size.y * 0.36)
	l.custom_minimum_size = Vector2(440, 40)
	_fx.add_child(l)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 30.0, 1.0)
	tw.tween_property(l, "modulate:a", 0.0, 1.0).set_delay(0.3)
	tw.chain().tween_callback(l.queue_free)


# ============================================================ DRAFT / END
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
		"The garden holds. Take a boon — the ✦ card resonates with your build.",
		extras, Palette.VERDANCE)
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
		_label(box, "The garden outlived them all — %s." % _run.aspect.capitalize(), 16, Palette.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	else:
		_label(box, "%s overwhelmed the garden." % _run.current_encounter().name, 16, Palette.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_label(box, _stats_summary(), 14, Palette.VERDANCE, HORIZONTAL_ALIGNMENT_CENTER)
	_label(box, "TOKENS · %d held%s" % [_run.tokens,
		(" · +%d minted this fight" % _minted) if _minted > 0 else ""], 13, Palette.TEXT_DIM, HORIZONTAL_ALIGNMENT_CENTER)
	# THE RECKONING — the fight's recap plaque (state survives into this screen)
	if _ctrl != null and _ctrl.state != null and _ctrl.player() != null:
		box.add_child(RecapPanel.new(_ctrl.state, _ctrl.player(), _recap_stats))
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
	var real := _signature() if (id == "wildbloom" or id == "briarheart") else id
	_tip_title.text = String(_bcfg.spells.get(real, {}).get("name", real))
	var desc := String(SPELL_TIPS.get(real, ""))
	var h := 110.0
	if real == "growth":                      # Phase B: YOUR GARDEN rides the Growth/Bloom verb
		var gl := BloomweaverBoons.verb_summary(_run.boons, _run.aspect)
		if not gl.is_empty():
			desc += "\n" + "\n".join(gl)
			h += 24.0 + 44.0 * gl.size()
	_tip_desc.text = desc
	var w := 260.0
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

func _place(node: Control, al: float, at: float, ar: float, ab: float,
		ol: float, ot: float, orr: float, ob: float) -> void:
	node.anchor_left = al; node.anchor_top = at; node.anchor_right = ar; node.anchor_bottom = ab
	node.offset_left = ol; node.offset_top = ot; node.offset_right = orr; node.offset_bottom = ob


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
