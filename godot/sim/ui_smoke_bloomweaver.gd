## Headless smoke test for the Bloomweaver HUD: instantiate the scene, drive every
## screen and a full run, and exercise the tooltip / cast / event-juice paths so
## construction errors surface without a GUI. Driving happens in _process (after _ready).
extends SceneTree

var hud: Control
var done := false

func _initialize() -> void:
	hud = load("res://game/bloomweaver_main.tscn").instantiate()
	root.add_child(hud)

func _process(_delta: float) -> bool:
	if done:
		return true
	done = true
	print("select screen: ok (ui=", hud._ui != null, " ctrl=", hud._ctrl != null, ")")

	hud._start_run("wildgrove")
	print("combat (wildgrove): ok, loadout=", hud._run.loadout, " frames=", hud._frames.size())

	# exercise a render frame's worth of updates + juice handlers
	hud._process(0.016)
	hud._show_tip("growth", hud._runes[0]["rune"])
	hud._show_tip("wildbloom", hud._runes[hud._runes.size() - 1]["rune"])
	hud._hide_tip()
	var party_seat = hud._frames[0]["seat"]
	hud._handle_event({"t": "hurt", "seat": party_seat, "amt": 40})
	hud._handle_event({"t": "heal", "seat": party_seat, "amt": 60})
	hud._handle_event({"t": "debuff", "seat": party_seat})
	hud._handle_event({"t": "bloom", "seat": party_seat, "amt": 55})
	hud._handle_event({"t": "perfect_ward", "seat": party_seat})
	hud._handle_event({"t": "wilt", "seat": party_seat, "amt": 20})
	hud._handle_event({"t": "warded", "seat": party_seat})
	hud._handle_event({"t": "saprot", "seat": party_seat})
	hud._handle_event({"t": "lifesurge"})
	hud._handle_event({"t": "wildbloom", "n": 4})
	hud._handle_event({"t": "briarheart"})
	hud._handle_event({"t": "boss_hit", "amt": 26})
	print("render + juice + tooltips: ok")

	# mouseover click-cast: hover a frame, a bound mouse chord casts on it; the
	# double-tap (growth on a growth'd target) is the BLOOM path
	hud._hover_seat = hud._frames[0]["seat"]
	hud._cast_on(hud._hover_seat, "growth")
	hud._cast_on(hud._frames[1]["seat"], "bark")
	var mev := InputEventMouseButton.new()
	mev.button_index = MOUSE_BUTTON_RIGHT
	mev.shift_pressed = true
	var bf: float = hud._bloom_frac(party_seat)
	print("mouseover cast + chord(", hud._mouse_chord(mev), ") + bloom ghost: ok (frac=", "%.2f" % bf, ")")

	hud._show_binds()
	hud._on_bind_changed(1, "left")     # rebind left -> growth
	hud._reset_binds()
	print("bindings screen: ok, hint=", hud._hint_text())

	# draft + end screens
	hud._show_draft()
	print("draft screen: ok, boons available")
	hud._show_end(true)
	hud._show_end(false)
	print("end screens: ok")

	# thornveil path
	hud._start_run("thornveil")
	hud._process(0.016)
	print("thornveil path: ok, verdance gauge=", hud._verd != null)

	print("BLOOMWEAVER UI SMOKE PASSED")
	return true
