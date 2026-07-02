## MapEventPanel — the "you stopped at a node" dialog for the Topology map:
## title, flavor body, choice buttons; picking a choice swaps in its result text
## + a CONTINUE button, then emits finished(fx). Also serves single-choice stops
## (cooling / cache / key pickup) — pass one choice labeled accordingly.
##
## fx (from MapContent): {heal: frac, hurt: frac, draft: bool, result: String}
## The HUD applies effects; this panel only presents them (shows a +/- preview line).
class_name MapEventPanel
extends Control

signal finished(fx: Dictionary)

var title_text := "NODE"
var body_text := ""
var choices: Array = []           ## [{label, fx}]
var accent: Color = Palette.GOLD

var _box: VBoxContainer

func _ready() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := GlassPanel.new("PANEL", accent)
	panel.custom_minimum_size = Vector2(660, 420)
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for m in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(m, 34)
	panel.add_child(margin)
	_box = VBoxContainer.new()
	_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_box.add_theme_constant_override("separation", 14)
	margin.add_child(_box)
	_show_prompt()

func _show_prompt() -> void:
	_clear()
	_title(title_text)
	_body(body_text)
	_box.add_child(_gap(6))
	for c in choices:
		var fx: Dictionary = c.get("fx", {})
		var b := Button.new()
		b.text = String(c["label"])
		b.custom_minimum_size = Vector2(420, 46)
		b.add_theme_font_size_override("font_size", 16)
		b.pressed.connect(_on_choice.bind(fx))
		_box.add_child(b)
		var hint := _fx_hint(fx)
		if hint != "":
			var l := _label(hint, 11, Palette.TEXT_DIM)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _on_choice(fx: Dictionary) -> void:
	_clear()
	_title(title_text)
	_body(String(fx.get("result", "It is done.")))
	var outcome := _fx_hint(fx)
	if outcome != "":
		_label(outcome, 14, accent)
	_box.add_child(_gap(6))
	var b := Button.new()
	b.text = "CONTINUE"
	b.custom_minimum_size = Vector2(240, 46)
	b.add_theme_font_size_override("font_size", 16)
	b.pressed.connect(func(): finished.emit(fx))
	_box.add_child(b)

func _fx_hint(fx: Dictionary) -> String:
	var bits: Array = []
	if float(fx.get("heal", 0.0)) > 0.0:
		bits.append("+%d%% integrity" % int(round(float(fx["heal"]) * 100.0)))
	if float(fx.get("hurt", 0.0)) > 0.0:
		bits.append("−%d%% integrity" % int(round(float(fx["hurt"]) * 100.0)))
	if bool(fx.get("draft", false)):
		bits.append("+ reforge draft")
	if bool(fx.get("key", false)):
		bits.append("+ %s" % MapContent.KEY_NAME)
	return "   ".join(bits)

# ---- little builders
func _clear() -> void:
	for c in _box.get_children():
		c.queue_free()

func _title(t: String) -> void:
	var l := _label(t, 26, accent)
	l.add_theme_font_override("font", UiKit.title(800))

func _body(t: String) -> void:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.text = "[center]%s[/center]" % t
	r.fit_content = true
	r.custom_minimum_size = Vector2(560, 0)
	r.add_theme_font_override("normal_font", UiKit.body())
	r.add_theme_font_size_override("normal_font_size", 15)
	r.add_theme_color_override("default_color", Palette.TEXT)
	_box.add_child(r)

func _label(t: String, fs: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	_box.add_child(l)
	return l

func _gap(h: int) -> Control:
	var g := Control.new()
	g.custom_minimum_size = Vector2(0, h)
	return g
