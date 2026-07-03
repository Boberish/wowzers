## Headless smoke for the Topology map flow (MASTER-PLAN §MAPS MAP-1): boots the
## Bulwark HUD, starts a map run on a FIXED seed, then drives node → panel → draft →
## fight → map transitions until the Seal falls — so every screen and routing lambda
## executes without a GUI. Multi-frame driver (one action per _process) so queue_free
## resolves between steps, matching real screen churn.
## Run: godot --headless --path godot --script res://sim/ui_smoke_map.gd
extends SceneTree

const MAP_SEED := 424242

var hud: Control
var step := 0
var fails := 0
var boon_i := 0

func _initialize() -> void:
	hud = load("res://game/bulwark_main.tscn").instantiate()
	root.add_child(hud)

func _process(_delta: float) -> bool:
	step += 1
	if step == 1:
		hud._start_map_run("warden")
		# re-deal onto a fixed seed so the smoke is reproducible
		hud._run.map = RunMap.generate(MAP_SEED, hud._run.encounters.size(), MapContent.event_ids())
		hud._run.map_node = -1
		hud._show_map()
		_check(hud._screen == "map", "map screen up")
		return false
	if step > 120:
		print("MAP UI SMOKE: FAIL (no end after %d steps)" % step)
		quit(1)
		return true

	match String(hud._screen):
		"map":
			var opts: Array = hud._run.map.reachable(hud._run.map_node, hud._run.inventory)
			_check(not opts.is_empty(), "reachable nodes exist")
			# prefer utility nodes so panels/drafts get exercised; combat otherwise
			var pick: int = opts[0]
			for id in opts:
				var k := String(hud._run.map.node(id)["kind"])
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
			var fx: Dictionary = panel.choices[0].get("fx", {})
			panel._on_press(panel.choices[0], 0)   # builds the result view (real UI path)
			panel.finished.emit(fx)                # simulate CONTINUE: apply fx → map / draft
			_check(hud._run.hp_frac >= 0.05 and hud._run.hp_frac <= 1.0, "hp_frac bounded")
		"draft":
			# take any not-yet-owned boon; the empty-pool path routes back to the map itself
			var pools: Array = BulwarkBoons.SHARED + BulwarkBoons.WARDEN
			while boon_i < pools.size() and hud._run.boons.has(pools[boon_i]["id"]):
				boon_i += 1
			if boon_i < pools.size():
				hud._on_card_taken(pools[boon_i])
			else:
				hud._draft_to_map = false
				hud._show_map()
			_check(hud._screen == "map" or hud._screen == "combat", "draft routed onward")
		"combat":
			var s0: Seat = hud._ctrl.state.seats[0]
			_check(s0.hp > 0.0 and s0.hp <= s0.hp_max, "fight hp scaled to integrity")
			hud._on_end(true)             # declare victory, exercise the map end-routing
		"end":
			print("run reached the Seal and ended: ok (visited=%d, hp_frac=%.2f, keys=%s)" %
				[_visited(), hud._run.hp_frac, str(hud._run.inventory)])
			print("MAP UI SMOKE: %s" % ("ALL PASS" if fails == 0 else "%d FAILURES" % fails))
			quit(0 if fails == 0 else 1)
			return true
	return false

func _visited() -> int:
	var v := 0
	for n in hud._run.map.nodes:
		if bool(n.get("visited", false)):
			v += 1
	return v

func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("  CHECK FAIL: ", what)
