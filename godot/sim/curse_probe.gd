## Probe: THE JAILBREAK curse system (DESCENT §7, slice 4). Drives the real HUD to prove:
##   A. _add_curse enforces CAP 2 + the HARD RULE (no run-length TIMING curse)
##   B. ECONOMY TAX bites: a mint curse halves _mint_curse_mult; a price curse marks up _market_price
##   C. HP/TIMING TAX: _apply_curse_marks folds seat_hp_cut / window_tighten into the pending
##      fight mark AND decrements (bounded, "next N fights")
##   D. EXITS: the Cooling purge fork (purge_curse fx) and the Market DEPRECATE slot both clear a curse
##   E. TICKING: economy curses decrement per fight and expire
##   godot --headless --path godot --script res://sim/curse_probe.gd
extends SceneTree

var hud: Control
var step := 0
var fails := 0
var _left := false

func _find(node: Node, cls: String):
	if (cls == "MapEventPanel" and node is MapEventPanel) and not node.is_queued_for_deletion():
		return node
	for c in node.get_children():
		var r = _find(c, cls)
		if r != null:
			return r
	return null

func _ck(cond: bool, label: String) -> void:
	if not cond:
		fails += 1
	print("  %s %s" % [("OK  " if cond else "FAIL"), label])

func _c(kind: String, label: String, fights: int, mag: float) -> Dictionary:
	return {"kind": kind, "label": label, "fights": fights, "mag": mag}

func _process(_dt: float) -> bool:
	if hud == null:
		hud = load("res://game/raid_main.tscn").instantiate()
		root.add_child(hud)
		return false
	step += 1
	if step != 1:
		return false

	print("CURSE PROBE")
	hud._seat_key = "tank"
	hud._aspect = "warden"
	hud._d.party = {}
	hud._ensure_party()
	hud._start_map_run()
	hud._d.curses = []
	hud._d.marks = {}

	# ---- A. cap-2 + HARD RULE
	_ck(hud._add_curse(_c("hp", "HP — corrupted sector", 1, 0.2)), "A: 1st curse added")
	_ck(hud._add_curse(_c("timing", "TIMING — windows -10%", 1, 0.1)), "A: 2nd curse added")
	_ck(not hud._add_curse(_c("hp", "HP", 1, 0.2)), "A: 3rd curse REFUSED (cap 2)")
	hud._d.curses = []
	_ck(not hud._add_curse(_c("timing", "run-long timing", 0, 0.1)),
		"A: a run-length TIMING curse is REFUSED (HARD RULE)")

	# ---- B. ECONOMY bites
	hud._d.curses = [_c("economy_mint", "ECONOMY — mint halved", 2, 0.0)]
	_ck(is_equal_approx(hud._mint_curse_mult(), 0.5), "B: a mint curse halves the mint mult")
	hud._d.curses = [_c("economy_price", "ECONOMY — market +3", 2, 3.0)]
	var base_price: int = hud._market_price(5)
	hud._d.curses = []
	var no_curse_price: int = hud._market_price(5)
	_ck(base_price == no_curse_price + 3, "B: a price curse marks up _market_price (+3)")

	# ---- C. HP/TIMING fold into the pending mark + decrement
	hud._d.curses = [_c("hp", "HP", 1, 0.2), _c("timing", "TIMING", 2, 0.1)]
	hud._d.marks = {}
	hud._apply_curse_marks()
	_ck(is_equal_approx(float(hud._d.marks.get("seat_hp_cut", 0.0)), 0.2),
		"C: HP curse folded seat_hp_cut into the mark")
	_ck(is_equal_approx(float(hud._d.marks.get("window_tighten", 0.0)), 0.1),
		"C: TIMING curse folded window_tighten into the mark")
	# the 1-fight HP curse expired; the 2-fight timing curse ticked to 1 and stays
	var kinds: Array = []
	for c in hud._d.curses:
		kinds.append(String((c as Dictionary)["kind"]))
	_ck(kinds == ["timing"] and int((hud._d.curses[0] as Dictionary)["fights"]) == 1,
		"C: bounded bites decrement — HP(1) expired, TIMING(2->1) stays")

	# ---- D. exits: Cooling purge + Market DEPRECATE
	hud._d.curses = [_c("hp", "HP", 1, 0.2), _c("timing", "TIMING", 2, 0.1)]
	hud._apply_map_fx({"purge_curse": true})
	_ck(hud._d.curses.size() == 1, "D: the Cooling purge fork clears one curse (2->1)")
	hud._d.run.tokens = 99
	hud._d.deprecate_uses = 0
	var dep := {"kind": "deprecate", "price": hud._market_price(5)}
	var ok: bool = hud._market_buy([dep], 0)
	_ck(ok and hud._d.curses.is_empty() and hud._d.deprecate_uses == 1,
		"D: Market DEPRECATE purges the last curse + escalates uses")

	# ---- E. economy ticking
	hud._d.curses = [_c("economy_mint", "mint", 2, 0.0)]
	hud._tick_economy_curses()
	_ck(int((hud._d.curses[0] as Dictionary)["fights"]) == 1, "E: economy curse ticks 2->1")
	hud._tick_economy_curses()
	_ck(hud._d.curses.is_empty(), "E: economy curse expires at 0")

	# ---- F. the JAILBREAK node: a deal grants the good AND the bite; the node opens
	hud._d.curses = []
	hud._d.charge = 10
	var deal: Dictionary = hud.JAILBREAK_DEALS[0]        # OVERCLOCK: +45 ⏻ + a timing bite
	hud._apply_map_fx((deal["fx"] as Dictionary).duplicate(true))
	_ck(hud._d.charge == 55 and hud._d.curses.size() == 1,
		"F: a deal grants the good (+45⏻) AND applies the bite (both halves)")
	hud._d.curses = []
	hud._show_jailbreak(0, func(): _left = true)
	_ck(_find(hud._ui, "MapEventPanel") != null, "F: _show_jailbreak opens a two-deal panel")

	print("CURSE PROBE: %s" % ("ALL OK" if fails == 0 else "%d FAIL" % fails))
	quit(1 if fails > 0 else 0)
	return true
