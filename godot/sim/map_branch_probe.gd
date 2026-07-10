## Focused probe for MULTI-STAGE BRANCHES + cross-node FLAGS (P3):
##  - the rollback_daemon event's page structure (branch → catch → fail-forward → scrubbed)
##  - choice_slot gives sub-pages their OWN die (root unchanged)
##  - the panel's client-side staging: pressing a branch → `staged(fx, page)`
##  - flag gates: favor_returned's choices grey without the flag, unlock with it
##   godot --headless --path godot --script res://sim/map_branch_probe.gd
extends SceneTree

var _panel: MapEventPanel
var _staged_page := ""
var _staged := false
var _fails := 0
var _stage := 0

func _process(_d: float) -> bool:
	match _stage:
		0:
			_test_content()
			_test_slots()
			_test_flags()
			_test_online_branch()
			# build a panel with a BRANCH choice + client staging, then press it
			_panel = MapEventPanel.new()
			_panel.client_stages = true
			_panel.title_text = "THE ROLLBACK DAEMON"
			_panel.body_text = "…"
			_panel.choices = [
				{"label": "Decline", "kind": "free", "orig_index": 0, "fx": {"result": "ok"}, "next_page": ""},
				{"label": "Hear the catch…", "kind": "branch", "orig_index": 1,
					"fx": {"result": "it leans in"}, "next_page": "catch"}]
			_panel.staged.connect(func(_fx: Dictionary, page: String):
				_staged = true
				_staged_page = page)
			root.add_child(_panel)
			_stage = 1
			return false
		1:
			# press the branch choice → its result screen shows "PROCEED →"
			_panel._on_press(_panel.choices[1], 1)
			var proceed := _find_button(_panel, "PROCEED  →")
			_ok("branch choice → 'PROCEED →' (not CONTINUE)", proceed != null)
			if proceed != null:
				proceed.pressed.emit()
			_ok("staged(fx, 'catch') fired", _staged and _staged_page == "catch")
			print("MAP BRANCH PROBE: %s" % ("ALL OK" if _fails == 0 else "%d FAIL" % _fails))
			quit(0 if _fails == 0 else 1)
			return true
	return false

func _test_content() -> void:
	var ev := MapContent.event("rollback_daemon")
	var pages: Dictionary = ev.get("pages", {})
	_ok("rollback_daemon has a branch choice → 'catch'",
		String((ev["choices"] as Array)[1].get("branch", "")) == "catch")
	_ok("pages.catch and pages.scrubbed exist", pages.has("catch") and pages.has("scrubbed"))
	var catch_check: Dictionary = (pages["catch"]["choices"] as Array)[0]
	_ok("catch's check fail-forwards (goto='scrubbed')",
		String((catch_check.get("fail", {}) as Dictionary).get("goto", "")) == "scrubbed")

func _test_slots() -> void:
	# root ("",i) == i (byte-identical dice); a sub-page shifts to its own slot band
	var root0 := MapCheck.choice_slot("", 0)
	var root1 := MapCheck.choice_slot("", 1)
	var c0 := MapCheck.choice_slot("catch", 0)
	var s0 := MapCheck.choice_slot("scrubbed", 0)
	_ok("root slots unchanged (0,1)", root0 == 0 and root1 == 1)
	_ok("sub-page slots distinct from root and each other",
		c0 != 0 and c0 != s0 and c0 >= 1000)

func _test_flags() -> void:
	var none := MapCheck.build_ctx([], [], "warden", "tank", 1.0, 0, 0, {}, {}, 0)
	var covered := MapCheck.build_ctx([], [], "warden", "tank", 1.0, 0, 0, {}, {"covered_shift": true}, 0)
	var fr := MapContent.event("favor_returned")
	var g0: Dictionary = (fr["choices"] as Array)[0]["gate"]
	_ok("favor_returned repayment gated without the flag", not MapCheck.gate_ok(g0, none))
	_ok("… and unlocks once 'covered_shift' is set", MapCheck.gate_ok(g0, covered))

## The ONLINE branch glue (server-authoritative): a branch choice surfaces goto='catch';
## the catch sub-page's check resolves at its OWN slot, identical to the client-local
## resolve; a check leg's goto (fail-forward) surfaces from the resolved leg.
func _test_online_branch() -> void:
	var ctx := MapCheck.build_ctx([], [], "warden", "tank", 1.0, 4, 0, {}, {}, 0)
	var ev := MapContent.event("rollback_daemon")
	# the root "Hear the catch…" branch choice → goto 'catch'
	var branch: Dictionary = (ev["choices"] as Array)[1]
	var rb := CampaignCore.resolve_event_choice(branch, ctx, 1, 1, MapCheck.choice_slot("", 1), 0, 4)
	_ok("server: branch choice surfaces goto='catch'", String(rb.get("goto", "")) == "catch")
	# the catch page's SELF check, resolved server-side at the sub-page slot
	var catch_check: Dictionary = (ev["pages"]["catch"]["choices"] as Array)[0]
	var slot := MapCheck.choice_slot("catch", 0)
	var srv := CampaignCore.resolve_event_choice(catch_check, ctx, 4242, 5, slot, 0, 4)
	var cli := MapCheck.resolve(catch_check, ctx, 4242, 5, slot, 0, {"nudge": 0})
	_ok("catch check: server==client on the sub-page slot",
		int(srv["p"]) == int(cli["p"]) and bool(srv["success"]) == bool(cli["success"]))
	# the resolved leg's goto surfaces (success → "", fail → "scrubbed")
	var want := "scrubbed" if not bool(srv["success"]) else ""
	_ok("catch check goto matches the resolved leg", String(srv.get("goto", "")) == want)

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
