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
## Multi-stage branch (OFFLINE only): a chosen leg leads to a follow-up stage. The HUD
## applies `fx` and renders `page`; the panel is rebuilt per stage. Online stages are
## server-driven (each stage is a fresh mapstop), so `client_stages` stays false there.
signal staged(fx: Dictionary, page: String)
var client_stages := false

var title_text := "NODE"
var body_text := ""
var choices: Array = []            ## [descriptor]
var accent: Color = Palette.GOLD
var resolver: Callable = Callable()   ## check resolver: (orig_index:int, nudge:int) -> Dictionary

var committed_index := -1             ## the orig_index the player pressed (online: sent to server)
var committed_nudge := 0              ## ⚡ fed on that press (online: sent to server)
var committed_seat := ""              ## the specialist that stepped up (online seat-picker)
var committed_attempt := 0            ## post-fail rerolls taken (online: sent so the server resolves the SAME die)
var committed_is_check := false       ## the committed choice was a check/wager (drives ⚡-spend + pity)
var committed_success := false        ## the committed roll's outcome (drives comeback pity)
var _cur_orig := -1                   ## the check being resolved/mulligan'd right now
var _cur_desc := {}
var _attempt := 0

## SEAT-PICKER (online co-op): the party chooses WHICH seat attempts a check — its
## build drives the %. `seats` = candidate seat keys (empty = no picker, e.g. offline);
## each choice descriptor carries `by_seat` = {seat -> {chance,breakdown,ladder,gated,…}}.
var seats: Array = []
var suggested := ""
var _acting := ""

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
	if not seats.is_empty():                     # default to the suggested specialist
		_acting = suggested if String(suggested) in seats else String(seats[0])
	_show_prompt()

func _show_prompt() -> void:
	_clear()
	_desc.clear()
	_main_btn.clear()
	_nudge_lbl.clear()
	_title(title_text)
	_body(body_text)
	if not seats.is_empty():
		_render_selector()
	_box.add_child(_gap(4))
	for c in choices:
		_add_choice_button(_effective(c), int((c as Dictionary).get("orig_index", 0)))

## Merge a choice's seat-independent fields (label/kind/verb/fx) with the ACTING seat's
## by_seat metadata (chance/breakdown/ladder/gate). Offline (no by_seat) reads flat fields.
func _effective(c: Dictionary) -> Dictionary:
	var m := {"label": String(c.get("label", "")), "kind": String(c.get("kind", "free")),
		"orig_index": int(c.get("orig_index", 0)), "fx": c.get("fx", {}),
		"verb": String(c.get("verb", "CHECK")), "entropy_have": int(c.get("entropy_have", 0)),
		"win_fx": c.get("win_fx", {}), "lose_fx": c.get("lose_fx", {})}   # both legs, printed pre-commit (§9.2)
	var v: Dictionary = c
	if c.has("by_seat") and _acting != "":
		v = (c["by_seat"] as Dictionary).get(_acting, {})
	if bool(v.get("gated", false)):
		m["gated"] = true
		m["locked_reason"] = String(v.get("locked_reason", "locked"))
	elif _check_like(String(m["kind"])):
		m["chance"] = int(v.get("chance", c.get("chance", 0)))
		m["breakdown"] = v.get("breakdown", c.get("breakdown", []))
		m["nudge_ladder"] = v.get("ladder", c.get("nudge_ladder", []))
	return m

## "WHO STEPS UP" — a row of seat buttons; the current one is lit, ★ marks the best fit.
func _render_selector() -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 8)
	var lead := Label.new()
	lead.text = "WHO STEPS UP:"
	lead.add_theme_font_size_override("font_size", 12)
	lead.add_theme_color_override("font_color", Palette.TEXT_DIM)
	row.add_child(lead)
	for st in seats:
		var b := Button.new()
		b.text = _seat_name(String(st)) + ("  ★" if String(st) == suggested else "")
		b.custom_minimum_size = Vector2(120, 34)
		b.add_theme_font_size_override("font_size", 13)
		if String(st) == _acting:
			b.disabled = true                    # the current specialist reads as selected
			b.add_theme_color_override("font_color_disabled", Palette.GOLD_BRIGHT)
		b.pressed.connect(_select_seat.bind(String(st)))
		row.add_child(b)
	_box.add_child(row)
	_sub("the specialist's build drives the check  ·  ★ = best fit", Palette.TEXT_DIM)

func _select_seat(st: String) -> void:
	if st == _acting:
		return
	_acting = st
	_show_prompt()

func _seat_name(st: String) -> String:
	match st:
		"tank": return "TANK"
		"blade": return "BLADE"
		"caster": return "CASTER"
		"healer": return "HEALER"
	return st.to_upper()

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
	# a check / wager choice shows its % right on the button
	if _check_like(kind) and not gated:
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
	elif _check_like(kind):
		if kind == "wager":
			_sub("⚠ WAGER — stakes %s on the roll, win or lose" % String(c.get("stake_label", "")), Palette.CRUSH)
		var verb := String(c.get("verb", "CHECK"))
		var parts := ""
		for row in c.get("breakdown", []):
			var d := int((row as Array)[1])
			parts += "  %s %s%d" % [String((row as Array)[0]), ("+" if d >= 0 else ""), d]
		_sub("%s —%s" % [verb, parts], Palette.TEXT_DIM)
		# BOTH LEGS, printed pre-commit (§9.2): what winning pays AND what losing costs —
		# so a check reads like "72% · on ✓ +2⏣ · on ✗ nothing lost" (fails are soft, free).
		var win := _fx_hint(c.get("win_fx", {}))
		var lose := _fx_hint(c.get("lose_fx", {}))
		if win != "" or lose != "":
			_sub("on ✓  %s      ·      on ✗  %s" % [
				(win if win != "" else "nothing gained"),
				(lose if lose != "" else "nothing lost")], accent)
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
	lbl.text = "spend ⚡ LUCK to raise the odds  (hold %d)" % int(c.get("entropy_have", 0))
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
			l.text = "spend ⚡ LUCK to raise the odds  (hold %d)" % int(c.get("entropy_have", 0))
			l.add_theme_color_override("font_color", Palette.VOID)
		else:
			l.text = "⚡ %d fed  →  %d%%" % [cur, p]
			l.add_theme_color_override("font_color", Palette.GOLD_BRIGHT)

func _check_like(kind: String) -> bool:
	return kind == "check" or kind == "wager"

func _on_press(c: Dictionary, orig: int) -> void:
	committed_index = orig
	committed_nudge = int(_nudge.get(orig, 0))
	committed_seat = _acting                     # the specialist that stepped up (online)
	_cur_orig = orig
	_cur_desc = c
	_attempt = 0
	_resolve_and_show()

## Resolve the current choice at the current attempt (a mulligan bumps _attempt). Records
## committed_* so the HUD can spend ⚡ (nudge + rerolls) and update comeback pity on commit.
func _resolve_and_show() -> void:
	var c: Dictionary = _cur_desc
	if _check_like(String(c.get("kind", "free"))) and resolver.is_valid():
		var res: Dictionary = resolver.call(_cur_orig, committed_nudge, _attempt)
		committed_attempt = _attempt
		committed_is_check = true
		committed_success = bool(res.get("success", false))
		_show_result(res.get("fx", {}), String(res.get("result", "")),
			bool(res.get("success", false)), int(res.get("roll", -1)), int(res.get("p", 0)), true,
			String(res.get("goto", "")))
	else:
		committed_is_check = false
		committed_success = true
		var fx: Dictionary = c.get("fx", {})
		_show_result(fx, String(fx.get("result", "It is done.")), true, -1, 0, false,
			String(c.get("next_page", "")))

func _show_result(fx: Dictionary, text: String, success: bool, roll: int, p: int, was_check: bool,
		next_page := "") -> void:
	_clear()
	_title(title_text)
	if was_check:
		var col := Palette.WIN if success else Palette.LOSE
		var verdict := ("✓  MODEL CONFIDENCE %d%%  —  PASS" % p) if success else ("✗  ROLLED %d vs %d%%  —  FAIL" % [roll, p])
		if _attempt > 0:
			verdict += "   (reroll %d)" % _attempt
		_label(verdict, 15, col)
	_body(text)
	var outcome := _fx_hint(fx)
	if outcome != "":
		_label(outcome, 14, accent)
	_box.add_child(_gap(6))
	# POST-FAIL MULLIGAN: spend ⚡ to reroll the die (attempt+1 = a genuinely different roll)
	if was_check and not success and _can_mulligan():
		var mb := Button.new()
		mb.text = "⚡ MULLIGAN  —  reroll  (−%d⚡)" % MapCheck.MULLIGAN_COST
		mb.custom_minimum_size = Vector2(320, 44)
		mb.add_theme_font_size_override("font_size", 15)
		mb.add_theme_color_override("font_color", Palette.VOID)
		mb.pressed.connect(func():
			_attempt += 1
			_resolve_and_show())
		_box.add_child(mb)
	var b := Button.new()
	# OFFLINE multi-stage: if this leg leads to a follow-up stage, advance instead of ending
	var stages := client_stages and next_page != ""
	b.text = "PROCEED  →" if stages else "CONTINUE"
	b.custom_minimum_size = Vector2(240, 46)
	b.add_theme_font_size_override("font_size", 16)
	b.pressed.connect(func():
		if stages:
			staged.emit(fx, next_page)
		else:
			finished.emit(fx))
	_box.add_child(b)

## Can the party still reroll? Needs ⚡ left after the nudge + prior rerolls, and a cap.
func _can_mulligan() -> bool:
	var have := int((_cur_desc as Dictionary).get("entropy_have", 0))
	var spent := committed_nudge + _attempt * MapCheck.MULLIGAN_COST
	return _attempt < MapCheck.MULLIGAN_MAX and (have - spent) >= MapCheck.MULLIGAN_COST

## The reward/penalty preview line — themed for the whole Inference-Check vocab.
func _fx_hint(fx: Dictionary) -> String:
	var bits: Array = []
	if float(fx.get("heal", 0.0)) > 0.0:
		bits.append("+%d%% party HP" % int(round(float(fx["heal"]) * 100.0)))
	if float(fx.get("hurt", 0.0)) > 0.0:
		bits.append("−%d%% party HP" % int(round(float(fx["hurt"]) * 100.0)))
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
