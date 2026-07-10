## Focused probe for the WAGER kind + post-fail MULLIGAN.
##  - a wager folds its fixed stake into the result fx (paid win or lose)
##  - online ⚡ accounting: server spends nudge + attempt×MULLIGAN_COST, die honours attempt
##  - the panel offers a MULLIGAN on a fail (⚡ affordable) and rerolls at attempt+1
##   godot --headless --path godot --script res://sim/map_wager_probe.gd
extends SceneTree

var _fails := 0
var _stage := 0
var _panel: MapEventPanel
var _fail_seed := 0

func _process(_d: float) -> bool:
	match _stage:
		0:
			_test_wager_fold()
			_test_online_mulligan()
			_build_fail_panel()
			_stage = 1
			return false
		1:
			# press the (failing) check → MULLIGAN offered → press it → attempt bumps + rerolls
			_panel._on_press(_panel.choices[0], 0)
			_ok("check failed at attempt 0 (setup)", not _panel.committed_success)
			var mull := _find_button(_panel, "⚡ MULLIGAN  —  reroll  (−%d⚡)" % MapCheck.MULLIGAN_COST)
			_ok("MULLIGAN offered on a fail with ⚡ in hand", mull != null)
			if mull != null:
				mull.pressed.emit()
			_ok("mulligan bumped the committed attempt to 1", _panel.committed_attempt == 1)
			print("MAP WAGER PROBE: %s" % ("ALL OK" if _fails == 0 else "%d FAIL" % _fails))
			quit(0 if _fails == 0 else 1)
			return true
	return false

func _test_wager_fold() -> void:
	var ctx := MapCheck.build_ctx([], [], "warden", "tank", 1.0, 4, 0, {}, {}, 0)
	# SYNTHETIC wager — decoupled from content. The integrity kill (DESCENT §11 #2)
	# re-priced the only in-content wager (overtime_daemon) off the retired "integrity"
	# stake, so this guards the SURVIVING wager-fold path (MapCheck.resolve, §12 keeps
	# wagers) directly: a 2 ⏣ stake folded into the leg fx, paid WIN OR LOSE.
	var wager := {"kind": "wager", "wager": {"stake": "tokens", "amount": 2},
		"check": {"verb": "OUTBID", "tags": ["rage"], "base": 40, "per": 9},
		"success": {"fx": {"tokens": 4, "entropy": 1}}, "fail": {"fx": {"refund_entropy": 1}}}
	_ok("synthetic 'Bill it' is a WAGER staking tokens",
		String(wager.get("kind", "")) == "wager" and String(wager["wager"]["stake"]) == "tokens")
	# resolve at several seeds — the 2 ⏣ stake is folded WIN OR LOSE (success 4−2=+2, fail 0−2=−2)
	var always := true
	for seed in [1, 2, 7, 99, 4242]:
		var res := MapCheck.resolve(wager, ctx, seed, 3, 1, 0, {})
		var base_tokens := 4 if bool(res["success"]) else 0
		if int((res["fx"] as Dictionary).get("tokens", 0)) != base_tokens - 2:
			always = false
	_ok("the wager stake (2 ⏣) is folded into fx, win or lose", always)

func _test_online_mulligan() -> void:
	var ctx := MapCheck.build_ctx([], [], "warden", "tank", 1.0, 6, 0, {}, {}, 0)
	var chk_choice := {"kind": "check", "check": {"verb": "T", "tags": ["x"], "base": 20},
		"success": {"fx": {"heal": 0.1}}, "fail": {"fx": {"hurt": 0.05}}}
	# server resolves at attempt 2 with 1 nudge: spend = 1 + 2×2 = 5 → entropy_after = 6-5 = 1
	var srv := CampaignCore.resolve_event_choice(chk_choice, ctx, 4242, 5, 1, 1, 6, 2)
	var cli := MapCheck.resolve(chk_choice, ctx, 4242, 5, 1, 2, {"nudge": 1})
	_ok("online mulligan ⚡ accounting: 6 − (nudge 1 + 2×%d) = %d" % [MapCheck.MULLIGAN_COST, int(srv["entropy_after"])],
		int(srv["entropy_after"]) == 6 - (1 + 2 * MapCheck.MULLIGAN_COST))
	_ok("online mulligan die: server(attempt 2) == client(attempt 2)",
		int(srv["p"]) == int(cli["p"]) and bool(srv["success"]) == bool(cli["success"]))
	# a fresh die per attempt (attempt 0 vs 2 differ, in general)
	_ok("attempt bumps the die", not is_equal_approx(MapCheck.roll(4242, 5, 1, 0), MapCheck.roll(4242, 5, 1, 2)))

func _build_fail_panel() -> void:
	# a base-20 check + ⚡6 in hand; find a seed where attempt 0 FAILS (roll ≥ 20)
	var ctx := MapCheck.build_ctx([], [], "warden", "tank", 1.0, 6, 0, {}, {}, 0)
	var chk := {"verb": "PROVE", "tags": ["x"], "base": 20}
	var choice := {"kind": "check", "check": chk, "success": {"fx": {"heal": 0.1}},
		"fail": {"fx": {"hurt": 0.05}, "result": "it fails"}}
	_fail_seed = 0
	for seed in range(1, 200):
		if MapCheck.roll(seed, 0, 0, 0) >= 20.0:
			_fail_seed = seed
			break
	_panel = MapEventPanel.new()
	_panel.title_text = "A PROVING"
	_panel.body_text = "…"
	_panel.choices = [{"label": "Prove it", "kind": "check", "orig_index": 0, "fx": {},
		"chance": 20, "breakdown": [["base", 20]], "verb": "PROVE", "entropy_have": 6, "nudge_ladder": [28, 36, 44]}]
	_panel.resolver = func(orig: int, nudge: int, attempt: int) -> Dictionary:
		return MapCheck.resolve(choice, ctx, _fail_seed, 0, 0, attempt, {"nudge": nudge})
	root.add_child(_panel)

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
