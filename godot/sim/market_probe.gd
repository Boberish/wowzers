## Probe: THE PROMPT MARKET (DESCENT §6, slice 3) + per-seat wallets (V#11).
## Proves, by driving the real HUD:
##   A. the MARKET node opens a MarketScreen (not the CACHE stub) with MARKET_LIVE
##   B. a BUY spends YOUR wallet and grants the good (REGENERATE charge)
##   C. AUTO on LEAVE: each AI raider spends its OWN wallet (per-seat), not yours
##   D. per-seat mint would credit each seat (wallets are independent objects)
##   godot --headless --path godot --script res://sim/market_probe.gd
extends SceneTree

var hud: Control
var step := 0
var fails := 0
var _left := false   # set by the LEAVE callback (a member, not a captured local — GDScript
                     # lambdas capture locals by VALUE, so a `func(): local = true` can't be observed)

func _ck(cond: bool, label: String) -> void:
	if not cond:
		fails += 1
	print("  %s %s" % [("OK  " if cond else "FAIL"), label])

func _find(node: Node, cls: String):
	if node.get_class() == cls or (cls == "MarketScreen" and node is MarketScreen):
		if not node.is_queued_for_deletion():
			return node
	for c in node.get_children():
		var r = _find(c, cls)
		if r != null:
			return r
	return null

## First enabled Button whose text begins with `prefix`.
func _btn(node: Node, prefix: String) -> Button:
	if node is Button and not (node as Button).disabled \
			and String((node as Button).text).begins_with(prefix):
		return node
	for c in node.get_children():
		var r := _btn(c, prefix)
		if r != null:
			return r
	return null

func _process(_dt: float) -> bool:
	if hud == null:
		hud = load("res://game/raid_main.tscn").instantiate()
		root.add_child(hud)
		return false
	step += 1
	if step != 1:
		return false

	print("MARKET PROBE")
	hud._seat_key = "tank"
	hud._aspect = "warden"
	hud._d.party = {}
	hud._ensure_party()
	hud._start_map_run()
	# give every seat its own wallet — per-seat (V#11)
	hud._d.run.tokens = 20
	hud._d.run.regenerate = 0
	for k in hud._d.ai_runs:
		(hud._d.ai_runs[k] as RunState).tokens = 8
		(hud._d.ai_runs[k] as RunState).regenerate = 0
	hud._market_auto = true

	# ---- A. the node opens a shop, not a cache stub
	hud._show_market(0, func(): _left = true, false)
	var ms = _find(hud._ui, "MarketScreen")
	_ck(ms != null, "A: MARKET_LIVE opens a MarketScreen")

	# ---- B. a BUY spends YOUR wallet + grants the good (regenerate is the first BUY slot)
	var tok0: int = hud._d.run.tokens
	var reg0: int = hud._d.run.regenerate
	var buy := _btn(hud._ui, "BUY")
	_ck(buy != null, "B: a BUY button is offered and affordable")
	if buy != null:
		buy.pressed.emit()
	_ck(hud._d.run.tokens < tok0 and hud._d.run.regenerate == reg0 + 1,
		"B: BUY spent your ⏣ (%d->%d) and banked +1 REGENERATE" % [tok0, hud._d.run.tokens])

	# ---- C. AUTO on LEAVE: AI raiders spend their OWN wallets, yours is untouched by them
	var my_after_buy: int = hud._d.run.tokens
	var blade: RunState = hud._d.ai_runs["blade"]
	var blade_tok0: int = blade.tokens
	var leave := _btn(hud._ui, "LEAVE")
	_ck(leave != null, "C: LEAVE is offered")
	if leave != null:
		leave.pressed.emit()
	_ck(_left, "C: LEAVE returns to the caller")
	_ck(blade.tokens < blade_tok0 and blade.regenerate > 0,
		"C: AUTO — the blade AI spent ITS OWN ⏣ (%d->%d) on REGENERATE" % [blade_tok0, blade.tokens])
	_ck(hud._d.run.tokens == my_after_buy,
		"C: your wallet was NOT touched by the AI auto-spend (per-seat)")

	# ---- D. wallets are independent objects (no shared pot)
	_ck(hud._d.run != hud._d.ai_runs["blade"] and hud._d.run != hud._d.ai_runs["caster"],
		"D: every seat holds its own RunState wallet")

	print("MARKET PROBE: %s" % ("ALL OK" if fails == 0 else "%d FAIL" % fails))
	quit(1 if fails > 0 else 0)
	return true
