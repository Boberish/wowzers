## Headless smoke for the RAID Topology descent (THE map flow — REFIT-PLAN P1 re-host;
## the old solo/bulwark_main version is retired with the solo scenes): boots THE HUD
## (raid_main), starts a commanded descent as the tank, re-deals Floor 1 onto a FIXED
## seed, then walks the floor screen by screen — map → stops/events → ledger oaths →
## arming → burst-won fights → drops → boon-draft chains — until the floor Seal falls
## (PRIVILEGE ELEVATED). Multi-frame driver (one action per _process) so queue_free
## resolves between steps, matching real screen churn. Flow smoke: asserts routing
## invariants, NOT checksums (fight seeds are wall-clock by design here).
## Run: godot --headless --path godot --script res://sim/ui_smoke_map.gd
extends SceneTree

const MAP_SEED := 424242

var hud: Control
var step := 0
var fails := 0
var takes := 0            # boon-draft picks taken (human + commanded AI raiders)
var fights := 0           # burst-won pulls (combat + the Seal)
var stops := 0            # mapstop panels driven
var stall := 0            # steps since the screen last changed
var last_screen := ""

func _initialize() -> void:
	hud = load("res://game/raid_main.tscn").instantiate()
	root.add_child(hud)

func _process(_delta: float) -> bool:
	step += 1
	if step == 1:
		hud._seat_key = "tank"
		hud._aspect = "warden"
		hud._start_map_run()          # tank: creed pick skips straight to the floor
		# re-deal Floor 1 onto a fixed seed so the smoke's walk is reproducible
		var fl: Dictionary = RaidContent.FLOORS[0]
		hud._d.map = RunMap.generate(MAP_SEED, hud._d.fights.size(),
			MapContent.raid_event_ids(),
			{RunMap.KIND_COOLING: 1, RunMap.KIND_CACHE: 1},
			int(fl["shard_req"]), int(fl.get("tickets", 0)), int(fl.get("rows", 8)))
		hud._d.node = -1
		hud._show_map()
		_check(hud._screen == "map", "raid map screen up")
		last_screen = "map"
		return false
	if step > 900:
		print("MAP UI SMOKE: FAIL (no floor clear after %d steps, screen=%s)" % [step, hud._screen])
		quit(1)
		return true

	var scr := String(hud._screen)
	stall = 0 if scr != last_screen else stall + 1
	last_screen = scr
	if stall > 90:
		print("MAP UI SMOKE: FAIL (stalled %d steps on screen=%s)" % [stall, scr])
		quit(1)
		return true

	match scr:
		"map":
			var opts: Array = hud._d.map.reachable(hud._d.node, hud._d.inv)
			_check(not opts.is_empty(), "reachable nodes exist")
			if opts.is_empty():
				quit(1)
				return true
			# prefer utility nodes so panels/events/tickets get exercised; combat otherwise
			var pick: int = opts[0]
			for id in opts:
				var k := String(hud._d.map.node(id)["kind"])
				if k != RunMap.KIND_COMBAT and k != RunMap.KIND_SEAL:
					pick = id
					break
			hud._enter_node(pick)
		"mapstop":
			var panel: MapEventPanel = null
			for c in hud._ui.get_children():
				if c is MapEventPanel and not c.is_queued_for_deletion():
					panel = c
			_check(panel != null, "stop panel present")
			if panel == null:
				quit(1)
				return true
			stops += 1
			var fx: Dictionary = panel.choices[0].get("fx", {})
			panel._on_press(panel.choices[0], 0)   # builds the result view (real UI path)
			panel.finished.emit(fx)                # CONTINUE: apply fx → route onward
			for f in hud._d.fracs:
				_check(float(f) >= 0.0 and float(f) <= 1.0, "integrity frac bounded")
		"ledger":
			# the boss's Ledger page: swear the first oath if one's offered, else pull
			if not _press("SWEAR"):
				_check(_press(""), "ledger page has a button")
		"arming":
			var ap: ArmingPanel = null
			for c in hud._ui.get_children():
				if c is ArmingPanel and not c.is_queued_for_deletion():
					ap = c
			_check(ap != null, "arming panel present")
			if ap != null:
				ap.banked.emit()               # bank the charge, proceed to the pull
		"combat":
			var s: CombatState = hud._ctrl.state if hud._ctrl != null else null
			_check(s != null, "combat has a live state")
			if s == null:
				quit(1)
				return true
			if not s.over:
				fights += 1
				CombatCore.damage_boss(s, s.seats[0], s.boss.hp)   # burst-win the pull
			for i in 8:                        # let the end-routing run
				hud._ctrl._process(1.0 / 30.0)
				hud._process(1.0 / 30.0)
				if hud._screen != "combat":
					break
		"drop":
			if not _press("EQUIP") and not _press("SCRAP"):
				_check(_press(""), "drop ceremony has a button")
		"draft":
			var ds = _find_draft()
			if ds != null and takes < 60:
				takes += 1
				ds.emit_signal("boon_taken", ds._offers[0])
			else:
				_check(_press(""), "draft screen routed onward")
		"recap":
			# STATS PAGE v2 rides every recap as a "◆ FULL REPORT" button — press
			# CONTINUE by name so the walk routes onward instead of into the report
			_check(_press("CONTINUE"), "recap has a CONTINUE")
		"report":
			# if a walk ever lands on the stats page, BACK out and keep walking
			_check(_press("‹ BACK"), "stats page has a BACK")
		"end":
			print("floor cleared: ok (fights=%d stops=%d drafts=%d visited=%d steps=%d)" %
				[fights, stops, takes, _visited(), step])
			print("MAP UI SMOKE: %s" % ("ALL PASS" if fails == 0 else "%d FAILURES" % fails))
			quit(0 if fails == 0 else 1)
			return true
		_:
			# any interposed screen (module/rig fire only for conforming seats; unknown
			# ceremony pages): drive it by its first button, fail loudly if it has none
			_check(_press(""), "screen '%s' offers a button" % scr)
	return false

func _visited() -> int:
	var v := 0
	if hud._d.map == null:
		return v
	for n in hud._d.map.nodes:
		if bool(n.get("visited", false)):
			v += 1
	return v

## Find + press the first Button under the HUD whose text starts with `prefix`
## ("" = any button) — drives ceremony pages the way a click would.
func _press(prefix: String) -> bool:
	var stack: Array = [hud._ui]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Button and not n.is_queued_for_deletion() \
				and (prefix == "" or String((n as Button).text).begins_with(prefix)):
			(n as Button).pressed.emit()
			return true
		for c in n.get_children():
			stack.append(c)
	return false

## The one LIVE DraftScreen (skips screens _clear() queue-freed this frame — the
## COMMANDER chain builds the next seat's screen in the same frame).
func _find_draft():
	var stack: Array = [hud._ui]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is DraftScreen and not n.is_queued_for_deletion():
			return n
		for c in n.get_children():
			stack.append(c)
	return null

func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("  CHECK FAIL: ", what)
