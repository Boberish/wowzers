## Class-select menu — the game's entry point. The wordmark burns in front of the Rift;
## below it, one emblem card per class (glyph medallion, name, verb, description) with
## hover ignite. Clicking a card enters that class's scene; every HUD returns here on Esc.
extends Control

static var CLASSES := [
	{"scene": "res://game/bulwark_main.tscn", "name": "THE BULWARK", "role": "TANK — MITIGATE",
		"desc": "Read the swing, parry it, punish the opening.", "accent": Palette.STEEL, "icon": "guard"},
	{"scene": "res://game/mender_main.tscn", "name": "THE MENDER", "role": "HEALER — KEEP-ALIVE",
		"desc": "Triage the raid, time the beat, catch the spike.", "accent": Palette.WIN, "icon": "well"},
	{"scene": "res://game/bloomweaver_main.tscn", "name": "THE BLOOMWEAVER", "role": "HEALER — ANTICIPATE",
		"desc": "Plant the garden, time the ward, bloom the save.", "accent": Palette.VERDANCE, "icon": "growth"},
	{"scene": "res://game/twinfang_main.tscn", "name": "THE TWINFANG", "role": "MELEE — DRIVE THE RHYTHM",
		"desc": "Chain Perfect Strikes, build Flow, out-pace the boss.", "accent": Palette.FLOW, "icon": "strike"},
	{"scene": "res://game/voidcaller_main.tscn", "name": "THE VOIDCALLER", "role": "CASTER — INTERRUPT",
		"desc": "Read the cast bar, kick the heals, silence the choir.", "accent": Palette.KICK, "icon": "bolt"},
	{"scene": "res://game/raid_main.tscn", "name": "THE RIFT", "role": "RAID — FOUR AS ONE",
		"desc": "Tank a raid Seal live, with three AI raiders at your side.", "accent": Palette.RELIC, "icon": "shockwave"},
]

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	# route debug autostart straight to the right class scene
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--autostart="):
			var asp := a.substr("--autostart=".length())
			if asp.begins_with("raid") or asp.begins_with("world") or asp.begins_with("atlas") \
					or asp.begins_with("zone") or asp.begins_with("gate"):
				get_tree().change_scene_to_file.call_deferred("res://game/raid_main.tscn")
				return
			if asp.begins_with("warden") or asp.begins_with("juggernaut"):
				get_tree().change_scene_to_file.call_deferred("res://game/bulwark_main.tscn")
				return
			if asp.begins_with("tidecaller") or asp.begins_with("brinkwarden"):
				get_tree().change_scene_to_file.call_deferred("res://game/mender_main.tscn")
				return
			if asp.begins_with("wildgrove") or asp.begins_with("thornveil"):
				get_tree().change_scene_to_file.call_deferred("res://game/bloomweaver_main.tscn")
				return
			if asp.begins_with("tempo") or asp.begins_with("venomancer"):
				get_tree().change_scene_to_file.call_deferred("res://game/twinfang_main.tscn")
				return
			if asp.begins_with("disruptor") or asp.begins_with("silencer"):
				get_tree().change_scene_to_file.call_deferred("res://game/voidcaller_main.tscn")
				return
	_build()

func _build() -> void:
	theme = UiKit.build_theme()
	add_child(StageBackdrop.new(false))     # calm sanctum variant — the Rift looms behind the wordmark

	var wm := Label.new()
	wm.text = "PROJECT RIFT"
	wm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wm.add_theme_font_override("font", UiKit.title(900))
	wm.add_theme_font_size_override("font_size", UiKit.SIZE["HERO"])
	wm.add_theme_color_override("font_color", Palette.GOLD)
	wm.add_theme_color_override("font_shadow_color", UiKit.TEXT_SHADOW)
	wm.add_theme_constant_override("shadow_offset_y", 4)
	_pin(wm, 0.5, 0.0, 0, 150, 1400, 90)
	add_child(wm)

	var sub := Label.new()
	sub.text = "C H O O S E   Y O U R   C L A S S"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_override("font", UiKit.display(500, 3))
	sub.add_theme_font_size_override("font_size", UiKit.SIZE["SUBHEAD"])
	sub.add_theme_color_override("font_color", Palette.TEXT_DIM)
	_pin(sub, 0.5, 0.0, 0, 258, 900, 30)
	add_child(sub)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	row.anchor_left = 0.5
	row.anchor_right = 0.5
	row.anchor_top = 0.0
	row.anchor_bottom = 0.0
	row.offset_left = -955.0
	row.offset_right = 955.0
	row.offset_top = 330.0
	row.offset_bottom = 740.0
	add_child(row)
	for i in CLASSES.size():
		var card := ClassCard.new(CLASSES[i])
		row.add_child(card)
		# emblem cards take the stage one at a time
		card.modulate.a = 0.0
		var tw := card.create_tween()
		tw.tween_interval(0.08 + 0.07 * float(i))
		tw.tween_property(card, "modulate:a", 1.0, 0.26)

	var foot := Label.new()
	foot.text = "All five roles online — mitigate · keep-alive · anticipate · drive · interrupt — and the Rift is open."
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.add_theme_font_size_override("font_size", UiKit.SIZE["CAPTION"])
	foot.add_theme_color_override("font_color", Palette.TEXT_DIM)
	_pin(foot, 0.5, 0.0, 0, 790, 900, 24)
	add_child(foot)

## anchor a control's centre-x to a screen fraction with a fixed width
func _pin(n: Control, ax: float, ay: float, ox: float, oy: float, w: float, h: float) -> void:
	n.anchor_left = ax
	n.anchor_right = ax
	n.anchor_top = ay
	n.anchor_bottom = ay
	n.offset_left = ox - w * 0.5
	n.offset_right = ox + w * 0.5
	n.offset_top = oy
	n.offset_bottom = oy + h

# ============================================================ the emblem card
class ClassCard extends GlassPanel:
	var data: Dictionary
	var _accent: Color
	var _tex: Texture2D
	var _hovered := false
	var _hover := 0.0
	var _pulse := 0.0

	func _init(c: Dictionary) -> void:
		data = c
		_accent = c["accent"]
		super._init("CARD", _accent)
		custom_minimum_size = Vector2(296, 410)
		mouse_filter = Control.MOUSE_FILTER_STOP
		_tex = RuneIcons.tex(String(c["icon"]))

	func _notification(what: int) -> void:
		if what == NOTIFICATION_MOUSE_ENTER:
			_hovered = true
			set_active(true)
		elif what == NOTIFICATION_MOUSE_EXIT:
			_hovered = false
			set_active(false)

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			get_tree().change_scene_to_file(String(data["scene"]))

	func _process(delta: float) -> void:
		_pulse += delta * 2.6
		var target := 1.0 if _hovered else 0.0
		if absf(target - _hover) > 0.002:
			_hover += (target - _hover) * clampf(delta * 12.0, 0.0, 1.0)
			pivot_offset = size * 0.5
			scale = Vector2.ONE * (1.0 + 0.035 * _hover)
		queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		# engraved border + filigree
		var inset := 7.0
		var bcol := Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.5 + 0.4 * _hover)
		draw_rect(Rect2(inset, inset, w - inset * 2.0, h - inset * 2.0), bcol, false, 1.2)
		UiKit.filigree_corner(self, Vector2(inset, inset), Vector2(1, 1), 10.0)
		UiKit.filigree_corner(self, Vector2(w - inset, inset), Vector2(-1, 1), 10.0)
		UiKit.filigree_corner(self, Vector2(inset, h - inset), Vector2(1, -1), 10.0)
		UiKit.filigree_corner(self, Vector2(w - inset, h - inset), Vector2(-1, -1), 10.0)

		# glyph medallion: accent-lit disc + gilded ring + the class rune
		var mc := Vector2(w * 0.5, 96.0)
		var mr := 46.0 + 2.5 * _hover
		draw_circle(mc, mr, Palette.FILL_BOT)
		var halo := _accent
		halo.a = 0.12 + 0.10 * _hover + 0.04 * sin(_pulse)
		draw_circle(mc, mr * 1.25, halo)
		UiKit.gilded_ring(self, mc, mr, 2.5, 40)
		if _tex != null:
			var isz := mr * 1.1
			var irect := Rect2(mc - Vector2(isz, isz) * 0.5, Vector2(isz, isz))
			draw_texture_rect(_tex, Rect2(irect.position + Vector2(0, 2), irect.size), false, UiKit.TEXT_SHADOW)
			draw_texture_rect(_tex, irect, false, _accent.lightened(0.15 + 0.2 * _hover))

		# name / role / description
		UiKit.text_shadowed(self, UiKit.display(750, 1), Vector2(8, 188.0), String(data["name"]),
			HORIZONTAL_ALIGNMENT_CENTER, w - 16, UiKit.SIZE["HEADER"], Palette.GOLD.lerp(Palette.GOLD_BRIGHT, 0.4))
		UiKit.text_shadowed(self, UiKit.display(600, 2), Vector2(8, 214.0), String(data["role"]),
			HORIZONTAL_ALIGNMENT_CENTER, w - 16, UiKit.SIZE["CAPTION"], _accent.lightened(0.1))
		# description, wrapped by hand across two centred lines if needed
		var body := UiKit.body(400)
		var words := String(data["desc"]).split(" ")
		var lines: Array[String] = [""]
		for wd in words:
			var probe := (lines[-1] + " " + wd).strip_edges()
			if body.get_string_size(probe, HORIZONTAL_ALIGNMENT_LEFT, -1, UiKit.SIZE["BODY"]).x > w - 44.0:
				lines.append(wd)
			else:
				lines[-1] = probe
		for i in lines.size():
			UiKit.text_shadowed(self, body, Vector2(8, 258.0 + 22.0 * float(i)), lines[i],
				HORIZONTAL_ALIGNMENT_CENTER, w - 16, UiKit.SIZE["BODY"], Palette.TEXT)

		# ENTER ribbon
		var ry := h - 32.0
		draw_line(Vector2(w * 0.24, ry - 6.0), Vector2(w * 0.76, ry - 6.0),
			Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.5), 1.0, true)
		UiKit.text_shadowed(self, UiKit.display(650, 2), Vector2(0, ry + 12.0),
			"◆  ENTER  ◆" if _hovered else "enter",
			HORIZONTAL_ALIGNMENT_CENTER, w, UiKit.SIZE["CAPTION"],
			Palette.GOLD_BRIGHT if _hovered else Palette.TEXT_DIM)
