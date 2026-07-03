## Probe: the refreshed front-of-house flow (ONE GAME · ONE HUD). Boots the game HUD
## and walks HOME -> CLASS -> SUB-CLASS -> RAID -> the descent, asserting each screen
## builds and the flow reaches a live map run.
##   godot --headless --path godot --script res://sim/menu_probe.gd
extends SceneTree

var hud: Control
var step := 0
var fails := 0

func _ck(cond: bool, label: String) -> void:
	if not cond:
		fails += 1
	print("  %s %s" % [("OK  " if cond else "FAIL"), label])

func _process(_d: float) -> bool:
	if hud == null:
		hud = load("res://game/raid_main.tscn").instantiate()
		root.add_child(hud)
		return false
	step += 1
	if step == 1:
		_ck(String(hud._screen) == "home", "boots into HOME (screen=%s)" % hud._screen)
		hud._show_class_select()
		_ck(String(hud._screen) == "class", "PLAY -> class select (screen=%s)" % hud._screen)
		hud._show_aspect_pick("healer")
		_ck(String(hud._screen) == "aspect", "class -> aspect (screen=%s)" % hud._screen)
		hud._show_raid_select("healer", "brinkwarden")
		_ck(String(hud._screen) == "raidpick" and hud._seat_key == "healer" and hud._aspect == "brinkwarden",
			"aspect -> raid pick (seat=%s aspect=%s)" % [hud._seat_key, hud._aspect])
		hud._start_map_run()
		_ck(String(hud._screen) == "map" and hud._map != null and hud._run != null,
			"raid -> live descent (screen=%s run=%s)" % [hud._screen, str(hud._run != null)])
		hud._show_home()
		_ck(String(hud._screen) == "home", "return to HOME (screen=%s)" % hud._screen)
		print("MENU PROBE: %s (fails=%d)" % [("ALL OK" if fails == 0 else "FAIL"), fails])
		quit(1 if fails > 0 else 0)
	return false
