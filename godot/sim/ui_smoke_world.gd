## Headless smoke for THE WORLD (W1): boots the raid HUD and drives the whole preview
## loop — home → THE WORLD → seat/aspect → ATLAS → BASTION (stations) → ZONE 1 —
## then CONQUERS the Gildfields the interesting way: spine fights, the sluice CHOICE
## (THE ZONE REMEMBERS: the flooded acre must resolve to a cache), the marsh RUSH to
## the door without the capstone, the personal gate, the Old Mill, the waystation.
## Asserts the OVERWORLD POWER RULE on every pull: bare kit (no boons, no gear, full HP).
## Headless = disk-inert (WorldSave never touches user://).
## Run: godot --headless --path godot --script res://sim/ui_smoke_world.gd
extends SceneTree

var hud: Control
var step := 0
var fails := 0
var plan_i := 0

## The drive plan: [zone node to enter, what we expect it to be]
const PLAN := [
	[0, "fight"],      # FIELDGATE
	[17, "camp"],      # OLD BOUNDARY STONE (dead-end lore)
	[1, "fight"],      # THE LONG FURROWS
	[2, "event"],      # HARROW CROSS
	[3, "choice"],     # THE SLUICE — we WRENCH IT OPEN (flag: sluice=opened)
	[13, "cache"],     # THE DROWNED ACRE — flooded ⇒ CACHE (THE ZONE REMEMBERS)
	[14, "event"],     # REEDMERE
	[15, "cache"],     # SALTWASH LANDING
	[19, "door"],      # UNDERMILL GATE — the RUSH: door before the capstone
	[6, "event"],      # MILLWATCH RISE
	[18, "gate"],      # THE THRESHOLD — the personal exam, alone
	[7, "fight"],      # THE OLD MILL — the capstone (boss kind launches like a fight)
	[8, "waystation"], # GILDWATCH BEACON — the flight path opens
]

func _initialize() -> void:
	hud = (load("res://game/raid_main.tscn") as PackedScene).instantiate()
	root.add_child(hud)

func _process(_d: float) -> bool:
	step += 1
	if step > 400:
		print("WORLD UI SMOKE: FAIL (no end after %d steps)" % step)
		quit(1)
		return true
	if step == 1:
		_check(hud._screen == "home", "home up")
		hud._start_world_pick()
		_check(hud._screen == "class", "world door → class select")
		return false
	if step == 2:
		hud._pick_class("tank", "bulwark")
		_check(hud._screen == "aspect", "class → aspect ceremony")
		return false
	if step == 3:
		hud._show_raid_select("tank", "warden")   # the ceremony's chosen route
		_check(hud._screen == "atlas", "world_pending: aspect → THE ATLAS")
		_check(hud._world != null, "world save loaded (in-memory, disk-inert)")
		return false
	if step == 4:
		hud._enter_atlas_pin("bastion")
		_check(hud._screen == "bastion", "atlas → the Bastion")
		return false
	if step == 5:
		hud._show_party_setup()
		_check(hud._screen == "party", "the Warband Camp opens the Commander tent")
		_check(hud._party_ctx == "bastion", "camp knows it's a place, not a descent")
		return false
	if step == 6:
		hud._show_bastion()
		hud._show_atlas()
		_check(hud._screen == "atlas", "muster returns → set out to the Atlas")
		return false
	if step == 7:
		hud._enter_atlas_pin(WorldContent.ZONE1)
		_check(hud._screen == "zone", "atlas → ZONE 1 (the Gildfields)")
		var front := WorldContent.frontier(WorldContent.zone(WorldContent.ZONE1), hud._world)
		_check(front == [0], "fresh zone: only the entry beckons")
		return false

	# ---- the conquest drive: one PLAN entry per screen-cycle
	match String(hud._screen):
		"zone":
			if plan_i >= PLAN.size():
				return _finish()
			var nid := int(PLAN[plan_i][0])
			var front := WorldContent.frontier(WorldContent.zone(WorldContent.ZONE1), hud._world)
			_check(front.has(nid), "plan node %d is on the frontier" % nid)
			hud._enter_zone_node(nid)
			_check(hud._screen == "zonestop", "node %d stops for its fiction beat" % nid)
		"zonestop":
			var panel: MapEventPanel = null
			for c in hud._ui.get_children():
				if c is MapEventPanel and not c.is_queued_for_deletion():
					panel = c
			_check(panel != null, "zone stop panel present")
			if panel == null:
				quit(1)
				return true
			# the sluice: take choice 0 (WRENCH IT OPEN) — every other stop takes 0 too
			var pick := 0
			var fx: Dictionary = (panel.choices[pick] as Dictionary).get("fx", {})
			panel._on_press(panel.choices[pick], pick)
			panel.finished.emit(fx)
			# a non-combat node resolves straight back to the zone → advance the plan
			if String(hud._screen) == "zone":
				_after_node(int(PLAN[plan_i][0]))
				plan_i += 1
		"combat":
			var s: CombatState = hud._ctrl.state
			_check(hud._zone_live, "combat is a ZONE pull")
			for u in s.seats:
				_check(u.kit == null or u.kit.boons.is_empty(), "bare kit: no boons on %s" % u.unit_name)
				_check(u.gear == null or (u.gear is Array and (u.gear as Array).is_empty()),
					"bare kit: no gear on %s" % u.unit_name)
				_check(absf(u.hp - u.hp_max) < 0.01, "full HP in: %s" % u.unit_name)
			if String(PLAN[plan_i][1]) == "gate":
				_check(hud._gate_live, "gate exam flagged (fought alone)")
			hud._on_end(true)
			_check(hud._screen == "recap", "won pull → the Reckoning")
		"recap":
			var btn := _find_button(hud._ui, "CONTINUE ▸")
			_check(btn != null, "recap continue present")
			if btn != null:
				btn.pressed.emit()
			_check(String(hud._screen) == "zone", "recap → back on the zone map")
			_after_node(int(PLAN[plan_i][0]))
			plan_i += 1
	return false

## Post-node assertions at the moments that matter.
func _after_node(nid: int) -> void:
	var w: WorldSave = hud._world
	_check(w.is_cleared(WorldContent.ZONE1, nid), "node %d conquered forever" % nid)
	match nid:
		3:
			_check(String(w.flags(WorldContent.ZONE1).get("sluice", "")) == "opened",
				"THE ZONE REMEMBERS: the sluice flag is permanent")
			var acre := WorldContent.resolved_node(WorldContent.zone(WorldContent.ZONE1), 13,
				w.flags(WorldContent.ZONE1))
			_check(String(acre["kind"]) == "cache", "the flooded acre resolves to a CACHE")
		19:
			_check(not w.is_cleared(WorldContent.ZONE1, 7), "the RUSH is real: door before capstone")
		7:
			_check(WorldContent.zone_conquered(WorldContent.zone(WorldContent.ZONE1), w),
				"the Old Mill falls ⇒ ZONE CLEARED")
		8:
			_check(w.has_waystation(WorldContent.ZONE1), "the beacon joins the sky roads")
	# the save round-trips byte-identically at every write point
	_check(WorldSave.from_json(w.canonical()).canonical() == w.canonical(),
		"save canonical round-trip at node %d" % nid)

func _finish() -> bool:
	hud._show_atlas()
	_check(hud._screen == "atlas", "conquest done → the Atlas")
	var w: WorldSave = hud._world
	print("conquered %d/20 nodes · sluice=%s · waystation=%s · zone_cleared=%s" % [
		w.cleared_count(WorldContent.ZONE1),
		String(w.flags(WorldContent.ZONE1).get("sluice", "?")),
		str(w.has_waystation(WorldContent.ZONE1)),
		str(WorldContent.zone_conquered(WorldContent.zone(WorldContent.ZONE1), w))])
	print("WORLD UI SMOKE: %s" % ("ALL PASS" if fails == 0 else "%d FAILURES" % fails))
	quit(0 if fails == 0 else 1)
	return true

func _find_button(node: Node, text: String) -> Button:
	if node is Button and (node as Button).text == text:
		return node
	for c in node.get_children():
		var hit := _find_button(c, text)
		if hit != null:
			return hit
	return null

func _check(ok: bool, what: String) -> void:
	if not ok:
		fails += 1
		print("  CHECK FAIL: ", what)
