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
	if step == 2:
		var s: CombatState = hud._ctrl.state
		CombatCore.damage_boss(s, s.seats[0], s.boss.hp)
		for i in 60:
			if s.over:
				break
			hud._ctrl._process(1.0 / 30.0)
			hud._process(1.0 / 30.0)
		var scr := String(hud._screen)
		var dropped := scr == "drop"
		# advance through the drop card if one showed (press EQUIP or SCRAP)
		if dropped:
			if not (_press("EQUIP") or _press("SCRAP") or _press("REPLACE")):
				print("[%s] FAIL: drop card had no continue button" % seat)
				fails += 1
		var after_scr := String(hud._screen)
		var has_descend := _press("DESCEND")       # press it if present (advances the floor)
		var floor_after := int(hud._floor)
		var ok := has_descend and floor_after == 1 and String(hud._screen) == "map"
		if not ok:
			fails += 1
		print("[%-6s] seal WON -> drop=%s screen_after_drop=%s DESCEND_shown=%s -> floor=%d screen=%s  %s" % [
			seat, str(dropped), after_scr, str(has_descend), floor_after, hud._screen,
			("OK" if ok else "FAIL <<<")])
		si += 1
		step = 0
		return false
	return false
