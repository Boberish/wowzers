## Probe: the BOON draft in the raid Topology descent. Proves (A) the human gets a
## run + drafted boons ride into the pull via _inject_boons, and (B) winning a fight
## reaches the REFORGE (draft) screen after the gear drop.
##   godot --headless --path godot --script res://sim/raid_boon_probe.gd
extends SceneTree

var hud: Control
var step := 0
var fails := 0

func _find_buttons(node: Node, out: Array) -> void:
	if node is Button:
		out.append(node)
	for c in node.get_children():
		_find_buttons(c, out)

func _press(prefix: String) -> bool:
	var b: Array = []
	_find_buttons(hud._ui, b)
	for x in b:
		if String((x as Button).text).begins_with(prefix):
			(x as Button).emit_signal("pressed")
			return true
	return false

func _process(_d: float) -> bool:
	if hud == null:
		hud = load("res://game/raid_main.tscn").instantiate()
		root.add_child(hud)
		return false
	step += 1
	if step == 1:
		hud._seat_key = "tank"
		hud._aspect = "warden"
		hud._start_map_run()
		# TEST A — wiring: a run exists, a boon can be drafted, and it injects into the kit
		var run_ok := hud._run != null and String(hud._run.char_class) == "bulwark"
		var picks: Array = Draft.roll_offers(hud._run)
		var pre := (hud._run.boons as Dictionary).size()
		if not picks.is_empty():
			Draft.take(hud._run, picks[0])
		var grew := (hud._run.boons as Dictionary).size() > pre
		hud._enter_node(hud._map.entry_id)                 # launch the entry fight
		if String(hud._screen) == "ledger":               # GEAR-2: the oath offer interposes
			_press("FIGHT UNSWORN")
		var kit = hud._ctrl.state.seats[0].kit
		var injected: bool = kit != null and (kit.boons as Dictionary).size() > 0 \
			and (kit.boons as Dictionary).size() == (hud._run.boons as Dictionary).size()
		print("[A wiring] run=%s (class=%s) offers=%d boon_taken=%s kit_injected=%s (%d boons)" % [
			str(run_ok), String(hud._run.char_class), picks.size(), str(grew), str(injected),
			(kit.boons as Dictionary).size() if kit != null else -1])
		if not (run_ok and grew and injected):
			fails += 1
		return false
	if step == 2:
		# TEST B — flow: win the fight, clear the gear drop, land on the REFORGE draft
		var s: CombatState = hud._ctrl.state
		CombatCore.damage_boss(s, s.seats[0], s.boss.hp + s.boss.hp_max + 1.0)
		for i in 50:
			if s.over:
				break
			hud._ctrl._process(1.0 / 30.0)
			hud._process(1.0 / 30.0)
		var after_win := String(hud._screen)               # "drop" (gear card) expected
		var pressed := _press("EQUIP") or _press("SCRAP") or _press("REPLACE")
		var after_drop := String(hud._screen)              # "draft" (REFORGE) expected
		print("[B flow] after_win=%s drop_continue=%s after_drop=%s draft_shown=%s" % [
			after_win, str(pressed), after_drop, str(after_drop == "draft")])
		if after_drop != "draft":
			fails += 1
		print("RAID BOON PROBE: %s (fails=%d)" % [("ALL OK" if fails == 0 else "FAIL"), fails])
		quit(1 if fails > 0 else 0)
	return false
