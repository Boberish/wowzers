## ArmingPanel — THE KILL SWITCH cash-out, shown before a Seal when the party has ⏻.
## A LINEAR spend dial (Bill's call, not a 50/100 cliff): drag how much ⏻ to pour in,
## then pick which fight-shape it takes — SURGE (boss boots wounded + a free opening) or
## SHIELD PRIME (an absorb wall vs one-shots) — or BANK it toward the finale. Emits the
## resolved mark + the amount spent; the HUD applies it via RaidMarks on the pull.
class_name ArmingPanel
extends Control

signal armed(kind: String, spend: int)   ## a spend committed ("surge"/"shield") → the pull gets the mark
signal banked()                            ## keep climbing toward the live UNPLUG

var charge := 0
var boss_name := "THE SEAL"

var _box: VBoxContainer
var _slider: HSlider
var _surge_lbl: Label
var _shield_lbl: Label
var _surge_btn: Button
var _shield_btn: Button

func _ready() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := GlassPanel.new("PANEL", Palette.CHARGE)
	panel.custom_minimum_size = Vector2(700, 500)
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for m in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(m, 34)
	panel.add_child(margin)
	_box = VBoxContainer.new()
	_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_box.add_theme_constant_override("separation", 12)
	margin.add_child(_box)

	_title("⏻  KILL SWITCH ASSEMBLY — %d%% ARMED" % charge)
	_body("The Seal looms. The maintenance panel hums with everything you've scavenged. "
		+ "Overtorquing the coupling may void the warranty and, the card adds in smaller print, several of you.")
	_box.add_child(_gap(4))

	var srow := HBoxContainer.new()
	srow.alignment = BoxContainer.ALIGNMENT_CENTER
	srow.add_theme_constant_override("separation", 12)
	var slab := _mklabel("POUR IN:", 13, Palette.TEXT_DIM)
	srow.add_child(slab)
	_slider = HSlider.new()
	_slider.min_value = 0
	_slider.max_value = charge
	_slider.step = 5
	_slider.value = charge
	_slider.custom_minimum_size = Vector2(360, 28)
	_slider.value_changed.connect(func(_v): _refresh())
	srow.add_child(_slider)
	_box.add_child(srow)

	_surge_lbl = _mklabel("", 12, Palette.TEXT_DIM)
	_surge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(_surge_lbl)
	_surge_btn = _mkbtn("")
	_surge_btn.pressed.connect(_on_surge)
	_box.add_child(_surge_btn)

	_box.add_child(_gap(2))
	_shield_lbl = _mklabel("", 12, Palette.TEXT_DIM)
	_shield_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_box.add_child(_shield_lbl)
	_shield_btn = _mkbtn("")
	_shield_btn.pressed.connect(_on_shield)
	_box.add_child(_shield_btn)

	_box.add_child(_gap(6))
	var bank := _mkbtn("BANK IT  —  keep climbing toward the finale")
	bank.pressed.connect(func(): banked.emit())
	_box.add_child(bank)
	_refresh()

func _spend() -> int:
	return int(_slider.value)

func _refresh() -> void:
	var n := _spend()
	var surge: Dictionary = RaidMarks.overclock("surge", n)
	var cut := int(round(float(surge.get("boss_hp_cut", 0.0)) * 100.0))
	var freeze := snappedf(float(surge.get("boot_freeze", 0)) / 30.0, 0.1)
	var absorb := int(round(float((RaidMarks.overclock("shield", n) as Dictionary).get("party_absorb", 0.0))))
	_surge_lbl.text = "the boss boots at %d%% HP, its timers frozen ~%.1fs — a free opening" % [100 - cut, freeze]
	_shield_lbl.text = "each raider opens behind a %d-point absorb wall — eats a one-shot" % absorb
	_surge_btn.text = "⚡ SURGE   (spend %d ⏻)" % n
	_shield_btn.text = "🛡 SHIELD PRIME   (spend %d ⏻)" % n
	var can := n > 0
	_surge_btn.disabled = not can
	_shield_btn.disabled = not can

func _on_surge() -> void:
	armed.emit("surge", _spend())

func _on_shield() -> void:
	armed.emit("shield", _spend())

# ---- builders
func _title(t: String) -> void:
	var l := _mklabel(t, 24, Palette.CHARGE)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", UiKit.title(800))
	_box.add_child(l)

func _body(t: String) -> void:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.text = "[center]%s[/center]" % t
	r.fit_content = true
	r.custom_minimum_size = Vector2(560, 0)
	r.add_theme_font_override("normal_font", UiKit.body())
	r.add_theme_font_size_override("normal_font_size", 14)
	r.add_theme_color_override("default_color", Palette.TEXT)
	_box.add_child(r)

func _mklabel(t: String, fs: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	return l

func _mkbtn(t: String) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(480, 44)
	b.add_theme_font_size_override("font_size", 15)
	return b

func _gap(h: int) -> Control:
	var g := Control.new()
	g.custom_minimum_size = Vector2(0, h)
	return g
