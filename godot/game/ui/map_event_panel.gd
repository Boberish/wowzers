## MapEventPanel — the "you stopped at a node" dialog for the Topology map. Renders a
## title, flavor body, and 2–4 typed choices, then emits finished(fx) with the resolved
## effect. Handles the Inference Check grammar:
##   free   — {label, kind:"free", fx:{…,result}}                     (also the legacy shape)
##   check  — {label, kind:"check", verb, chance:int, breakdown:[[lbl,Δ]], …}
##            → on press the panel calls `resolver.call(orig_index)` which rolls the die
##              and returns {success, roll, p, result, fx}; the panel shows the ✓/✗
##              verdict, then finished(fx) on CONTINUE.
##   gated  — same as its underlying kind + {gated:true, locked_reason}; a locked choice
##            renders greyed with the printed reason and can't be pressed.
## Single-choice stops (cooling / cache / key pickup) pass one legacy {label, fx} choice.
##
## `orig_index` on each descriptor is its position in the event's choices array (so the
## die keys off the right choice_i). The HUD owns the resolver + effect application.
class_name MapEventPanel
extends Control

signal finished(fx: Dictionary)

var title_text := "NODE"
var body_text := ""
var choices: Array = []            ## [descriptor]
var accent: Color = Palette.GOLD
var resolver: Callable = Callable()   ## check resolver: (orig_index:int, nudge:int) -> Dictionary

var _box: VBoxContainer
var _nudge := {}                      ## orig_index -> ⚡ points fed (0..min(3,have))
var _desc := {}                       ## orig_index -> descriptor (for live % recompute)
var _main_btn := {}                   ## orig_index -> the commit Button (live % text)
var _nudge_lbl := {}                  ## orig_index -> the "⚡N → P%" label

func _ready() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := GlassPanel.new("PANEL", accent)
	panel.custom_minimum_size = Vector2(720, 630)   # tall enough for a 3-choice event w/ two checks + ⚡ steppers
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
	_show_prompt()

func _show_prompt() -> void:
	_clear()
	_title(title_text)
	_body(body_text)
	_box.add_child(_gap(4))
	var idx := 0
	for c in choices:
		_add_choice_button(c, idx)
		idx += 1

func _add_choice_button(c: Dictionary, i: int) -> void:
	var kind := String(c.get("kind", "free"))
	var gated := bool(c.get("gated", false))
	var orig: int = int(c.get("orig_index", i))
	_desc[orig] = c
	_nudge[orig] = 0

	var b := Button.new()
	b.custom_minimum_size = Vector2(560, 46)
	b.add_theme_font_size_override("font_size", 16)
	b.text = String(c["label"])
	# a check choice shows its % right on the button
	if kind == "check" and not gated:
		b.text = "%s          %d%%" % [String(c["label"]), int(c.get("chance", 0))]
		_main_btn[orig] = b
	if gated:
		b.disabled = true
		b.text = "🔒  " + String(c["label"])
	b.pressed.connect(_on_press.bind(c, orig))
	_box.add_child(b)

	# sub-line: locked reason, the check verb + itemized breakdown, or the free fx hint
	if gated:
		_sub("🔒 " + String(c.get("locked_reason", "locked")), Palette.VOID)
	elif kind == "check":
		var verb := String(c.get("verb", "CHECK"))
		var parts := ""
		for row in c.get("breakdown", []):
			var d := int((row as Array)[1])
			parts += "  %s %s%d" % [String((row as Array)[0]), ("+" if d >= 0 else ""), d]
		_sub("%s —%s" % [verb, parts], Palette.TEXT_DIM)
		_add_nudge_row(c, orig)
	else:
		var hint := _fx_hint(c.get("fx", {}))
		if hint != "":
			_sub(hint, Palette.TEXT_DIM)

## ⚡ NUDGE stepper: feed Entropy to raise this check's % before you commit. Shows the
## live ladder ("⚡2 → 84%"); the die is unchanged, you're just topping the sampler.
func _add_nudge_row(c: Dictionary, orig: int) -> void:
	var ladder: Array = c.get("nudge_ladder", [])
	if int(c.get("entropy_have", 0)) <= 0 or ladder.is_empty():
		return
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	var minus := _mini_btn("⚡ −")
	minus.pressed.connect(_adjust_nudge.bind(orig, -1))
	row.add_child(minus)
	var lbl := Label.new()
	lbl.text = "feed ⚡ to bias  (hold %d)" % int(c.get("entropy_have", 0))
	lbl.custom_minimum_size = Vector2(300, 0)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.add_theme_color_override("font_color", Palette.VOID)
	row.add_child(lbl)
	_nudge_lbl[orig] = lbl
	var plus := _mini_btn("⚡ +")
	plus.pressed.connect(_adjust_nudge.bind(orig, 1))
	row.add_child(plus)
	_box.add_child(row)

func _mini_btn(t: String) -> Button:
	var b := Button.new()
	b.text = t
	b.custom_minimum_size = Vector2(64, 34)
	b.add_theme_font_size_override("font_size", 14)
	return b

func _adjust_nudge(orig: int, delta: int) -> void:
	var c: Dictionary = _desc.get(orig, {})
	var ladder: Array = c.get("nudge_ladder", [])
	var cur := int(_nudge.get(orig, 0)) + delta
	cur = clampi(cur, 0, ladder.size())
	_nudge[orig] = cur
	var p := int(c.get("chance", 0)) if cur == 0 else int(ladder[cur - 1])
	if _main_btn.has(orig):
		(_main_btn[orig] as Button).text = "%s          %d%%" % [String(c["label"]), p]
	if _nudge_lbl.has(orig):
		var l := _nudge_lbl[orig] as Label
		if cur == 0:
			l.text = "feed ⚡ to bias  (hold %d)" % int(c.get("entropy_have", 0))
			l.add_theme_color_override("font_color", Palette.VOID)
		else:
			l.text = "⚡ %d fed  →  %d%%" % [cur, p]
			l.add_theme_color_override("font_color", Palette.GOLD_BRIGHT)

func _on_press(c: Dictionary, orig: int) -> void:
	if String(c.get("kind", "free")) == "check" and resolver.is_valid():
		var res: Dictionary = resolver.call(orig, int(_nudge.get(orig, 0)))
		_show_result(res.get("fx", {}), String(res.get("result", "")),
			bool(res.get("success", false)), int(res.get("roll", -1)), int(res.get("p", 0)), true)
	else:
		var fx: Dictionary = c.get("fx", {})
		_show_result(fx, String(fx.get("result", "It is done.")), true, -1, 0, false)

func _show_result(fx: Dictionary, text: String, success: bool, roll: int, p: int, was_check: bool) -> void:
	_clear()
	_title(title_text)
	if was_check:
		var col := Palette.WIN if success else Palette.LOSE
		var verdict := ("✓  MODEL CONFIDENCE %d%%  —  PASS" % p) if success else ("✗  ROLLED %d vs %d%%  —  FAIL" % [roll, p])
		_label(verdict, 15, col)
	_body(text)
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

## The reward/penalty preview line — themed for the whole Inference-Check vocab.
func _fx_hint(fx: Dictionary) -> String:
	var bits: Array = []
	if float(fx.get("heal", 0.0)) > 0.0:
		bits.append("+%d%% integrity" % int(round(float(fx["heal"]) * 100.0)))
	if float(fx.get("hurt", 0.0)) > 0.0:
		bits.append("−%d%% integrity" % int(round(float(fx["hurt"]) * 100.0)))
	if float(fx.get("wound", 0.0)) > 0.0:
		bits.append("corrupted sector")
	if bool(fx.get("repair", false)):
		bits.append("DEFRAG")
	if bool(fx.get("patch", false)) or bool(fx.get("draft", false)):
		bits.append("emergency patch")
	if int(fx.get("tokens", 0)) != 0:
		bits.append("%s⏣%d" % [("+" if int(fx["tokens"]) > 0 else "−"), abs(int(fx["tokens"]))])
	if int(fx.get("entropy", 0)) != 0 or int(fx.get("refund_entropy", 0)) != 0:
		var e := int(fx.get("entropy", 0)) + int(fx.get("refund_entropy", 0))
		bits.append("%s⚡%d" % [("+" if e > 0 else "−"), abs(e)])
	if int(fx.get("prior", 0)) != 0:
		bits.append("+📁%d" % int(fx["prior"]))
	if bool(fx.get("key", false)):
		bits.append("+ %s" % MapContent.KEY_NAME)
	if bool(fx.get("shard", false)):
		bits.append("+ credential shard")
	if fx.has("flag"):
		bits.append("a mark on your file")
	return "    ".join(bits)

# ---- little builders
func _clear() -> void:
	for c in _box.get_children():
		c.queue_free()

func _sub(t: String, col: Color) -> void:
	var l := _label(t, 11, col)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(560, 0)

func _title(t: String) -> void:
	var l := _label(t, 26, accent)
	l.add_theme_font_override("font", UiKit.title(800))

func _body(t: String) -> void:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.text = "[center]%s[/center]" % t
	r.fit_content = true
	r.custom_minimum_size = Vector2(580, 0)
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
