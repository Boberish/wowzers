## Repro probe: OFFLINE Topology descent — beat the Ring-3 Seal through the REAL
## raid_hud path and drive the FULL post-fight chain (drop card -> continue ->
## floor-cleared -> DESCEND) for every seat. Catches "beat the boss and it ended,
## no next level".
##   godot --headless --path godot --script res://sim/map_advance_probe.gd
extends SceneTree

var hud: Control
var seats := ["tank", "blade", "caster", "healer"]
var aspects := {"tank": "warden", "blade": "venomancer", "caster": "disruptor", "healer": "tidecaller"}
var si := 0
var step := 0
var fails := 0

func _find_buttons(node: Node, out: Array) -> void:
	if node is Button:
		out.append(node)
	for c in node.get_children():
		_find_buttons(c, out)

func _press(prefix: String) -> bool:
	var btns: Array = []
	_find_buttons(hud._ui, btns)
	for b in btns:
		if String((b as Button).text).begins_with(prefix):
			(b as Button).emit_signal("pressed")
			return true
	return false

func _find_draft(node: Node):
	# skip screens _clear() has already queue-freed (still in-tree this frame) —
	# the COMMANDER draft chain builds the next screen in the same frame
	if node is DraftScreen and not node.is_queued_for_deletion():
		return node
	for c in node.get_children():
		var r = _find_draft(c)
		if r != null:
			return r
	return null

## take the first boon offer to advance past the REFORGE draft
func _take_draft() -> bool:
	var ds = _find_draft(hud._ui)
	if ds != null and not (ds._offers as Array).is_empty():
		ds.emit_signal("boon_taken", ds._offers[0])
		return true
	return false

func _process(_delta: float) -> bool:
	if hud == null:
		hud = load("res://game/raid_main.tscn").instantiate()
		root.add_child(hud)
		return false
	if si >= seats.size():
		print("PROBE DONE — fails=%d" % fails)
		quit(1 if fails > 0 else 0)
		return true
	var seat: String = seats[si]
	step += 1
	if step == 1:
		hud._seat_key = seat
		hud._aspect = String(aspects[seat])
		hud._start_map_run()
		hud._enter_node(hud._map.seal_id)          # jump to the Seal fight
		return false
	if step == 2 and String(hud._screen) == "ledger":
		# GEAR-2: the boss's Ledger page interposes before a Seal pull — swear the
		# first oath (or take the plain pull button) and re-run this step with the
		# fight live. (The probe predated the Ledger and crashed here — stale probe
		# fixed with REFIT P3.1; ui_smoke_map presses through the same way.)
		if not _press("SWEAR"):
			_press("")
		step = 1
		return false
	if step == 2:
		var s: CombatState = hud._ctrl.state
		CombatCore.damage_boss(s, s.seats[0], s.boss.hp)
		for i in 60:
			if s.over:
				break
			hud._ctrl._process(1.0 / 30.0)
			hud._process(1.0 / 30.0)
		# Drive the WHOLE post-win chain in whatever order it interposes (the probe
		# predated THE RECKONING recap + the framework's rig-wire ceremony — stale-probe
		# fix, P3.1): recap CONTINUE → drop EQUIP/SCRAP → REFORGE draft chain (one per
		# seat, COMMANDER) → the blade's rig board (ui_smoke_raid's drive, same ids).
		var dropped := false
		var drafted := false
		var guard := 0
		while guard < 16 and String(hud._screen) in ["recap", "drop", "draft", "rig"]:
			match String(hud._screen):
				"recap":
					_press("")
				"drop":
					dropped = true
					if not (_press("EQUIP") or _press("SCRAP") or _press("REPLACE")):
						print("[%s] FAIL: drop card had no continue button" % seat)
						fails += 1
						break
				"draft":
					if not _take_draft():
						break
					drafted = true
				"rig":
					hud._rig_on_when(true, "coup")
					hud._rig_on_then(true, "overcharge")
					if hud._rig_confirm != null and not hud._rig_confirm.disabled:
						hud._rig_confirm.emit_signal("pressed")
					else:
						print("[%s] FAIL: rig board would not confirm" % seat)
						fails += 1
						break
			guard += 1
		var after_scr := String(hud._screen)
		var has_descend := _press("DESCEND")       # press it if present (advances the floor)
		# framework seats (blade/TEMPO): the floor-1 elevation interposes the MODULE
		# install before the next map — drive it like ui_smoke_raid does.
		if String(hud._screen) == "module":
			hud._pick_module("edge", hud._build_floor)
		var floor_after := int(hud._floor)
		var ok := has_descend and floor_after == 1 and String(hud._screen) == "map"
		if not ok:
			fails += 1
		print("[%-6s] seal WON -> drop=%s draft=%s (%s) DESCEND=%s -> floor=%d screen=%s  %s" % [
			seat, str(dropped), str(drafted), after_scr, str(has_descend), floor_after, hud._screen,
			("OK" if ok else "FAIL <<<")])
		si += 1
		step = 0
		return false
	return false
