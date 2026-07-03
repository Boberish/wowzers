## screenshot_pause.gd — visual probe of the in-combat PAUSE menu + Class Codex.
## WSLg (NOT --headless):
##   godot --path godot --script res://sim/screenshot_pause.gd --resolution 1920x1080 -- --out=/absolute/dir
## Boots the game HUD, launches a fight per (seat,aspect), lets it warm up, opens the
## pause overlay, waits for the fade, and screenshots the frozen codex.
extends SceneTree

var out_dir := "user://shots"
var hud: Control
var combos := [
	{"name": "pause_tank_warden", "seat": "tank", "aspect": "warden"},
	{"name": "pause_blade_tempo", "seat": "blade", "aspect": "tempo"},
	{"name": "pause_caster_silencer", "seat": "caster", "aspect": "silencer"},
	{"name": "pause_healer_brinkwarden", "seat": "healer", "aspect": "brinkwarden"},
]
var idx := -1
var phase := "next"
var wait := 0

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr("--out=".length())
	DirAccess.make_dir_recursive_absolute(out_dir)
	hud = load("res://game/raid_main.tscn").instantiate()
	root.add_child(hud)

func _process(_d: float) -> bool:
	match phase:
		"next":
			idx += 1
			if idx >= combos.size():
				print("PAUSE CODEX TOUR DONE -> ", out_dir)
				return true
			hud._launch(String(combos[idx]["seat"]), String(combos[idx]["aspect"]))
			phase = "warm"; wait = 22          # let combat + boss intro settle
		"warm":
			wait -= 1
			if wait <= 0:
				hud._toggle_pause()
				phase = "fade"; wait = 16       # overlay entrance fade
		"fade":
			wait -= 1
			if wait <= 0:
				var img := root.get_texture().get_image()
				var p := out_dir.path_join(String(combos[idx]["name"]) + ".png")
				img.save_png(p)
				print("  shot: ", p)
				hud._resume_pause()
				phase = "next"
	return false
