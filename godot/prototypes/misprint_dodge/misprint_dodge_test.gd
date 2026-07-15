## Interactive isolated proof: real Mistral fight, real Duelist HUD/input, real
## CombatState.tick. The panel only switches the test cadence and AI replay.
extends Control

var _hud: Control
var _panel: PanelContainer
var _mode_label: Label
var _auto_button: Button
var _view_button: Button
var _motion_button: Button
var _auto := true
var _clean_view := true
var _pushed_motion := true
var _policy: DuelistPolicy
var _last_policy_tick := -1
var _mode := "normal"

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	MisprintDodgeProof.enabled = true
	MisprintDodgeProof.pushed_motion = _pushed_motion
	# Use the real approved dashboard/theater layout, but isolate this animation
	# from the older Duelist actor and full-screen flipbook stack.
	ArtV2.actors = false
	ArtV2.scene = "stack_atrium"
	ArtV2.dash = false
	ArtV2.vfx = false
	_hud = (load("res://game/raid_main.tscn") as PackedScene).instantiate()
	add_child(_hud)
	_build_controls()
	call_deferred("_restart", "normal")

func _exit_tree() -> void:
	MisprintDodgeProof.enabled = false
	MisprintDodgeProof.pushed_motion = false

func _build_controls() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_panel.position = Vector2(-386, 28)
	_panel.size = Vector2(370, 500)
	_panel.z_index = 100
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.07, 0.08, 0.94)
	style.border_color = Color(0.95, 0.72, 0.28, 0.85)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	_panel.add_child(box)
	var title := Label.new()
	title.text = "MISPRINT · DODGE PROOF"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color("f1c46b"))
	box.add_child(title)
	_mode_label = Label.new()
	_mode_label.text = "NORMAL · live Mistral songbook"
	box.add_child(_mode_label)
	var row := HBoxContainer.new()
	box.add_child(row)
	var normal := Button.new()
	normal.text = "NORMAL"
	normal.pressed.connect(func(): _restart("normal"))
	row.add_child(normal)
	var stress := Button.new()
	stress.text = "HIGH-FLOW"
	stress.pressed.connect(func(): _restart("high_flow"))
	row.add_child(stress)
	_auto_button = Button.new()
	_auto_button.text = "AUTO: ON"
	_auto_button.pressed.connect(_toggle_auto)
	row.add_child(_auto_button)
	_view_button = Button.new()
	_view_button.text = "VIEW: CLEAN"
	_view_button.pressed.connect(_toggle_view)
	box.add_child(_view_button)
	_motion_button = Button.new()
	_motion_button.text = "MOTION: PUSHED"
	_motion_button.pressed.connect(_toggle_motion)
	box.add_child(_motion_button)
	var tuning_title := Label.new()
	tuning_title.text = "PUSHED PARAMETERS · live"
	tuning_title.add_theme_font_size_override("font_size", 13)
	tuning_title.add_theme_color_override("font_color", Color(0.68, 0.84, 0.92))
	box.add_child(tuning_title)
	_add_motion_slider(box, "EASE", 20.0, 200.0, 5.0, 120.0, " ms",
		func(value: float): MisprintDodgeProof.motion_ease_s = value / 1000.0)
	_add_motion_slider(box, "TRAILS", 0.0, 4.0, 1.0, 4.0, "",
		func(value: float): MisprintDodgeProof.trail_count = int(round(value)))
	_add_motion_slider(box, "SPREAD", 0.0, 1.5, 0.05, 1.0, "×",
		func(value: float): MisprintDodgeProof.trail_spread = value)
	_add_motion_slider(box, "OPACITY", 0.0, 1.5, 0.05, 1.0, "×",
		func(value: float): MisprintDodgeProof.trail_opacity = value)
	_add_motion_slider(box, "BLUR", 0.0, 12.0, 0.5, 6.0, " px",
		func(value: float): MisprintDodgeProof.blur_px = value)
	var help := Label.new()
	help.text = "Sliders update live; pose timing stays 333 ms.\nAUTO OFF: answer with 1/Space + 2."
	help.add_theme_font_size_override("font_size", 12)
	help.add_theme_color_override("font_color", Color(0.78, 0.82, 0.82))
	box.add_child(help)

func _add_motion_slider(parent: VBoxContainer, title: String, minimum: float, maximum: float,
		step: float, initial: float, suffix: String, apply_value: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	var name_label := Label.new()
	name_label.text = title
	name_label.custom_minimum_size.x = 68.0
	name_label.add_theme_font_size_override("font_size", 12)
	row.add_child(name_label)
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.value = initial
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	var value_label := Label.new()
	value_label.custom_minimum_size.x = 66.0
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)
	var refresh := func(value: float) -> void:
		value_label.text = (("%d" % int(round(value))) if step >= 1.0 else ("%.2f" % value)) + suffix
	refresh.call(initial)
	apply_value.call(initial)
	slider.value_changed.connect(func(value: float) -> void:
		refresh.call(value)
		apply_value.call(value)
	)

func _restart(mode: String) -> void:
	_mode = mode
	ArtV2.dash = not _clean_view
	MisprintDodgeProof.pushed_motion = _pushed_motion
	_hud.call("_launch", "tank", "", "mistral")
	if _clean_view:
		_apply_clean_view()
	var ctrl: CombatController = _hud.get("_ctrl")
	var state: CombatState = ctrl.state
	if mode == "high_flow":
		_apply_high_flow(state)
		_mode_label.text = "HIGH-FLOW · 6-beat / 0.26s weave"
	else:
		_mode_label.text = "NORMAL · live Mistral songbook"
	_policy = DuelistPolicy.new()
	_policy.latency_ticks = 0
	_policy.rng = DetRng.new(20260715 if mode == "normal" else 20260716)
	_last_policy_tick = -1

func _apply_high_flow(state: CombatState) -> void:
	# Test-only state mutation after RaidNet.build(): a repeatable fastest-cadence
	# phrase, never authored into RaidContent or serialized into a fight spec.
	state.encounter.melee["rhythm"] = 0.32
	state.encounter.melee["jig"] = 0.0
	state.encounter.melee["phrases"] = [{
		"name": "misprint_high_flow",
		"weight": 1.0,
		"rest": 0.32,
		"steps": [{"kind": "flurry", "n": 6, "gaps": [0.26, 0.26, 0.26, 0.26, 0.26]}],
	}]

func _toggle_auto() -> void:
	_auto = not _auto
	_auto_button.text = "AUTO: ON" if _auto else "AUTO: OFF"

func _toggle_view() -> void:
	_clean_view = not _clean_view
	_view_button.text = "VIEW: CLEAN" if _clean_view else "VIEW: FULL HUD"
	_restart(_mode)

func _toggle_motion() -> void:
	_pushed_motion = not _pushed_motion
	_motion_button.text = "MOTION: PUSHED" if _pushed_motion else "MOTION: BASELINE"
	_restart(_mode)

func _apply_clean_view() -> void:
	var ui: Control = _hud.get("_ui") as Control
	var stage: RaidStage2D = _hud.get("_stage2d") as RaidStage2D
	if ui == null:
		return
	# The proof is for the actor silhouette, so CLEAN means exactly that: retain
	# the live combat stage and suppress every HUD child, including the central
	# judgment channel, class band, raid frames, dev controls, and verdicts.
	for child in ui.get_children():
		if child is CanvasItem and child != stage:
			(child as CanvasItem).visible = false

func _process(_delta: float) -> void:
	if not _auto or _hud == null:
		return
	var ctrl: CombatController = _hud.get("_ctrl")
	if ctrl == null or ctrl.state == null or ctrl.state.over:
		return
	if ctrl.state.tick == _last_policy_tick:
		return
	_last_policy_tick = ctrl.state.tick
	var seat := ctrl.player()
	if seat == null or not seat.alive():
		return
	var action: Dictionary = _policy.act(CombatCore.observe(ctrl.state, seat))
	if not action.is_empty():
		ctrl.human(action)
