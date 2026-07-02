## Headless smoke test for the HUD: instantiate the scene and drive every screen /
## the whole run loop directly, so construction/logic errors surface without a GUI.
## Driving happens in _process (not _initialize) so the HUD's _ready has run first.
## (Custom _draw is validated by actually running the game window.)
extends SceneTree

var hud: Control
var done := false

func _initialize() -> void:
	hud = load("res://game/bulwark_main.tscn").instantiate()
	root.add_child(hud)

func _process(_delta: float) -> bool:
	if done:
		return true
	done = true
	print("select screen: ok (ui=", hud._ui != null, " ctrl=", hud._ctrl != null, ")")

	hud._start_run("warden")
	print("combat screen (warden): ok, loadout=", hud._run.loadout)

	hud._show_ability_tip(0)
	hud._show_ability_tip(3)
	hud._show_spec_tip()
	hud._show_guard_tip()
	hud._hide_tip()
	hud._handle_event({"t": "negate", "player": true})
	hud._handle_event({"t": "hurt", "player": true, "amt": 112, "size": 2})
	hud._handle_event({"t": "boss_hit", "amt": 130})
	hud._handle_event({"t": "defend", "player": true})
	print("tooltips + juice handlers: ok")

	var steps := 0
	while not hud._run.is_last() and steps < 8:
		var picks: Array = BulwarkBoons.roll(hud._run)
		print("  draft roll ", hud._run.enc_index, " -> ", picks.map(func(b): return b["id"]))
		if not picks.is_empty():
			BulwarkBoons.apply(picks[0], hud._run)
		hud._run.enc_index += 1
		hud._begin_fight()
		steps += 1
	print("ran full loop: ok, final loadout=", hud._run.loadout, " boons=", hud._run.boons.keys())

	hud._show_draft()
	print("draft screen: ok")
	hud._toggle_book()
	print("spellbook: ok")
	hud._show_end(true)
	hud._show_end(false)
	print("end screens: ok")

	hud._start_run("juggernaut")
	hud._show_draft()
	print("juggernaut path: ok")

	hud._show_boss_select("warden")
	hud._show_boss_select("juggernaut")
	print("dev boss-select screen: ok")

	print("UI SMOKE PASSED")
	return true
