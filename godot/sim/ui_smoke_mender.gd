## Headless smoke test for the Mender HUD: instantiate the scene, drive every screen
## and a full run, and exercise the tooltip / cast / event-juice paths so construction
## errors surface without a GUI. Driving happens in _process (after _ready).
extends SceneTree

var hud: Control
var done := false

func _initialize() -> void:
	hud = load("res://game/mender_main.tscn").instantiate()
	root.add_child(hud)

func _process(_delta: float) -> bool:
	if done:
		return true
	done = true
	print("select screen: ok (ui=", hud._ui != null, " ctrl=", hud._ctrl != null, ")")

	hud._start_run("tidecaller")
	print("combat (tidecaller): ok, loadout=", hud._run.loadout, " frames=", hud._frames.size())

	# exercise a render frame's worth of updates + juice handlers
	hud._process(0.016)
	hud._show_tip("flash", hud._runes[0]["rune"])
	hud._show_tip("surge", hud._runes[hud._runes.size() - 1]["rune"])
	hud._hide_tip()
	var party_seat = hud._frames[0]["seat"]
	hud._handle_event({"t": "hurt", "seat": party_seat, "amt": 40})
	hud._handle_event({"t": "heal", "seat": party_seat, "amt": 60})
	hud._handle_event({"t": "debuff", "seat": party_seat})
	print("render + juice + tooltips: ok")

	# mouseover click-cast: hover a frame, a bound mouse chord casts on it
	hud._hover_seat = hud._frames[0]["seat"]
	hud._cast_on(hud._hover_seat, "flash")
	hud._cast_on(hud._frames[1]["seat"], "renew")
	var mev := InputEventMouseButton.new()
	mev.button_index = MOUSE_BUTTON_RIGHT
	mev.shift_pressed = true
	var pv: float = hud._predict(hud._mcfg.spells["flash"], party_seat)
	print("mouseover cast + chord(", hud._mouse_chord(mev), ") + prediction: ok (flash frac=", "%.2f" % pv, ")")

	hud._show_binds()
	hud._on_bind_changed(1, "left")     # rebind left -> flash
	hud._reset_binds()
	print("bindings screen: ok, hint=", hud._hint_text())

	# draft + end screens
	hud._show_draft()
	print("draft screen: ok, boons available")
	hud._show_end(true)
	hud._show_end(false)
	print("end screens: ok")

	# brinkwarden path
	hud._start_run("brinkwarden")
	hud._process(0.016)
	print("brinkwarden path: ok, spec strip=", hud._spec != null)

	print("MENDER UI SMOKE PASSED")
	return true
