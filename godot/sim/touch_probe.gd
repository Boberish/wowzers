## touch_probe.gd — the MOBILE whole-screen touch contract (consolidation, 2026-07-14):
## LEFT half = dodge · RIGHT half = parry (hold→release) · DUELIST ONLY · and the grammar
## must NOT intercept UI — menus (non-combat screens), the pause overlay, the PAUSE button
## rect, or the party column. Drives raid_hud._input directly with crafted
## InputEventScreenTouch events and asserts consumption + the _touch_side ledger.
##   godot --headless --path godot --script res://sim/touch_probe.gd
extends SceneTree

var hud: Node = null
var frame := -1
var fails := 0

func _chk(name: String, ok: bool) -> void:
	if not ok:
		fails += 1
	print("  TOUCH CHECK %s: %s" % ["OK" if ok else "FAIL", name])

func _initialize() -> void:
	hud = (load("res://game/raid_main.tscn") as PackedScene).instantiate()
	root.add_child(hud)

func _process(_d: float) -> bool:
	frame += 1
	if frame == 1:
		hud._launch("tank", "")
	if frame != 10:
		return frame > 10
	var vp := root.get_visible_rect().size

	# [1] combat + duelist: LEFT press = dodge side, RIGHT press+hold = parry side
	var evl := InputEventScreenTouch.new()
	evl.position = Vector2(vp.x * 0.25, vp.y * 0.5)
	evl.pressed = true
	evl.index = 0
	hud._input(evl)
	_chk("left press enters the ledger as dodge-side", hud._touch_side.get(0, true) == false)
	var evlr := InputEventScreenTouch.new()
	evlr.position = evl.position
	evlr.pressed = false
	evlr.index = 0
	hud._input(evlr)
	_chk("left release clears the ledger", not hud._touch_side.has(0))
	var evr := InputEventScreenTouch.new()
	evr.position = Vector2(vp.x * 0.75, vp.y * 0.5)
	evr.pressed = true
	evr.index = 1
	hud._input(evr)
	_chk("right press enters the ledger as parry-side", hud._touch_side.get(1, false) == true)
	var evrr := InputEventScreenTouch.new()
	evrr.position = evr.position
	evrr.pressed = false
	evrr.index = 1
	hud._input(evrr)
	_chk("right release clears the ledger (defense_release path)", not hud._touch_side.has(1))

	# [2] the PAUSE-button carve-out: a touch on its rect is UI, never footwork
	# (headless skips _add_pause_button — stand a fake one at a known rect)
	var pb := Button.new()
	hud._ui.add_child(pb)
	pb.position = Vector2(vp.x - 150.0, 14.0)
	pb.size = Vector2(130.0, 32.0)
	hud._pause_btn = pb
	var evp := InputEventScreenTouch.new()
	evp.position = pb.get_global_rect().get_center()
	evp.pressed = true
	evp.index = 2
	hud._input(evp)
	_chk("pause-rect press stays a CLICK (no footwork, no ledger)", not hud._touch_side.has(2))

	# [3] the party-column carve-out
	if hud._raid_col != null:
		var evc := InputEventScreenTouch.new()
		evc.position = hud._raid_col.get_global_rect().get_center()
		evc.pressed = true
		evc.index = 3
		hud._input(evc)
		_chk("party-column press stays a CLICK", not hud._touch_side.has(3))

	# [4] paused: the overlay owns every touch (grammar gated by _pause == null)
	hud._toggle_pause()
	var evz := InputEventScreenTouch.new()
	evz.position = Vector2(vp.x * 0.25, vp.y * 0.5)
	evz.pressed = true
	evz.index = 4
	hud._input(evz)
	_chk("paused: no footwork", not hud._touch_side.has(4))
	hud._toggle_pause()

	# [5] a NON-duelist seat never gets the grammar (twinfang rebuild)
	hud._clear()
	_chk("teardown clears the touch ledger", hud._touch_side.is_empty())
	hud._launch("blade", "")
	var evb := InputEventScreenTouch.new()
	evb.position = Vector2(vp.x * 0.25, vp.y * 0.5)
	evb.pressed = true
	evb.index = 5
	hud._input(evb)
	_chk("non-Duelist seat: touch is not footwork", not hud._touch_side.has(5))

	print("TOUCH PROBE: %s" % ("ALL OK" if fails == 0 else "FAIL — %d" % fails))
	quit(0 if fails == 0 else 1)
	return false
