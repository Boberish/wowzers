## Headless functional probe for the Inference Check event flow (offline path):
## instantiates the real MapEventPanel with prepared descriptors + a MapCheck resolver,
## builds it in a tree, presses the check choice, and drives the ✓/✗ result → finished(fx).
## Proves the whole present→roll→resolve→apply chain runs without a GUI.
##   godot --headless --path godot --script res://sim/map_event_probe.gd
extends SceneTree

var _panel: MapEventPanel
var _stage := 0
var _got_fx: Variant = null
var _built := 0
var _fails := 0
var _spent_nudge := -1

func _process(_d: float) -> bool:
	match _stage:
		0:
			_setup()
			_stage = 1
			return false
		1:
			# _ready has run → the prompt is built (choice buttons + ⚡ steppers).
			_built = _count_buttons(_panel)
			_ok("panel built choice + nudge buttons (%d ≥ 3)" % _built, _built >= 3)
			# ⚡ NUDGE: feed 1 Entropy to the HACK check (orig 1) — its % must rise
			var base_p := int((_panel.choices[1] as Dictionary)["chance"])
			_panel._adjust_nudge(1, 1)
			var nudged_p := int((_panel._main_btn[1] as Button).text.split("%")[0].split(" ")[-1])
			_ok("⚡ nudge raised %d%% → %d%% (+8)" % [base_p, nudged_p], nudged_p == base_p + 8)
			_ok("panel tracked ⚡ spend = 1", int(_panel._nudge.get(1, 0)) == 1)
			# commit the HACK check WITH the nudge; resolver must receive it
			_panel._on_press(_panel.choices[1], 1)
			_ok("resolver received the ⚡ spend (1)", _spent_nudge == 1)
			_stage = 2
			return false
		2:
			var cont := _find_button(_panel, "CONTINUE")
			_ok("check resolved → result screen with CONTINUE", cont != null)
			if cont != null:
				cont.pressed.emit()
			_ok("finished(fx) fired with a real leg", _got_fx is Dictionary and not (_got_fx as Dictionary).is_empty())
			_test_gate()
			print("MAP EVENT PROBE: %s" % ("ALL OK" if _fails == 0 else "%d FAIL" % _fails))
			quit(0 if _fails == 0 else 1)
			return true
	return false

func _setup() -> void:
	# a caster with two interrupt boons at the terminal — the HACK check should read high
	var ctx := MapCheck.build_ctx([["interrupt"], ["interrupt"]], [], "disruptor", "caster",
		1.0, 0, 2, 0, {}, {}, 0)
	var ev := MapContent.event("helpdesk")
	var raw: Array = ev["choices"]
	var descs: Array = []
	for i in raw.size():
		var c: Dictionary = raw[i]
		var d := {"label": String(c["label"]), "kind": String(c.get("kind", "free")),
			"orig_index": i, "fx": c.get("fx", {})}
		if String(c.get("kind", "")) == "check":
			var chk: Dictionary = c["check"]
			var info := MapCheck.chance(chk, ctx)
			d["chance"] = int(info["p"])
			d["breakdown"] = info["parts"]
			d["verb"] = String(chk.get("verb", "CHECK"))
			d["entropy_have"] = int(ctx["entropy"])
			d["nudge_ladder"] = MapCheck.nudge_ladder(chk, ctx)
			print("  prepped %s check '%s' → %d%%  (⚡ladder %s)" % [d["verb"], d["label"], int(info["p"]), str(d["nudge_ladder"])])
		descs.append(d)
	_panel = MapEventPanel.new()
	_panel.title_text = String(ev["title"])
	_panel.body_text = String(ev["body"])
	_panel.choices = descs
	_spent_nudge = -1
	_panel.resolver = func(orig: int, nudge: int, attempt: int) -> Dictionary:
		_spent_nudge = nudge
		return MapCheck.resolve(raw[orig], ctx, 1234, 5, orig, attempt, {"nudge": nudge})
	_panel.finished.connect(func(fx: Dictionary): _got_fx = fx)
	root.add_child(_panel)

## The prompt_injection badge choice is gated on the API KEY — without it, greyed.
func _test_gate() -> void:
	var no_key := MapCheck.build_ctx([], [], "warden", "tank", 1.0, 0, 0, 0, {}, {}, 0)
	var have := MapCheck.build_ctx([], [], "warden", "tank", 1.0, 0, 0, 0, {"api_key": true}, {}, 0)
	var badge: Dictionary = (MapContent.event("prompt_injection")["choices"] as Array)[0]
	var gate: Dictionary = badge["gate"]
	_ok("prompt_injection badge gated without API KEY", not MapCheck.gate_ok(gate, no_key))
	_ok("… and unlocks with the API KEY", MapCheck.gate_ok(gate, have))

# ---- helpers
func _count_buttons(node: Node) -> int:
	var n := 0
	for c in node.get_children():
		if c is Button:
			n += 1
		n += _count_buttons(c)
	return n

func _find_button(node: Node, text: String) -> Button:
	for c in node.get_children():
		if c is Button and String((c as Button).text) == text:
			return c
		var r := _find_button(c, text)
		if r != null:
			return r
	return null

func _ok(msg: String, cond: bool) -> void:
	print("  [%s] %s" % [("PASS" if cond else "FAIL"), msg])
	if not cond:
		_fails += 1
