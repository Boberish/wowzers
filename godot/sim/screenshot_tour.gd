## screenshot_tour.gd — boots every screen of every class HUD in a real window and
## saves PNGs, so UI work can be verified visually without a human at the keyboard.
## Run (needs a display, e.g. WSLg — NOT --headless):
##   godot --path godot --script res://sim/screenshot_tour.gd --resolution 1920x1080
## Optionally pass an output dir:  -- --out=/absolute/dir
extends SceneTree

var out_dir := "user://shots"
var steps: Array = []
var idx := -1
var frames_left := 0
var phase := 0            # 0 = spawn scene, 1 = run setup call, 2 = waiting, 3 = capture
var cur: Node = null

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr("--out=".length())
	DirAccess.make_dir_recursive_absolute(out_dir)

	steps = [
		{"name": "01_menu", "scene": "res://game/main.tscn", "wait": 12},
		{"name": "02_bulwark_select", "scene": "res://game/bulwark_main.tscn", "wait": 12},
		{"name": "03_bulwark_combat", "scene": "res://game/bulwark_main.tscn",
			"setup": func(h): h._start_run("warden"), "wait": 170},
		{"name": "04_bulwark_draft", "scene": "res://game/bulwark_main.tscn",
			"setup": func(h): h._start_run("warden"); h._show_draft(), "wait": 15},
		{"name": "05_bulwark_book", "scene": "res://game/bulwark_main.tscn",
			"setup": func(h): h._start_run("warden"); h._toggle_book(), "wait": 15},
		{"name": "06_bulwark_end", "scene": "res://game/bulwark_main.tscn",
			"setup": func(h): h._start_run("warden"); h._show_end(true), "wait": 15},
		{"name": "07_mender_select", "scene": "res://game/mender_main.tscn", "wait": 12},
		{"name": "08_mender_combat", "scene": "res://game/mender_main.tscn",
			"setup": func(h): h._start_run("tidecaller"), "wait": 170},
		{"name": "09_mender_draft", "scene": "res://game/mender_main.tscn",
			"setup": func(h): h._start_run("tidecaller"); h._show_draft(), "wait": 15},
		{"name": "10_mender_binds", "scene": "res://game/mender_main.tscn",
			"setup": func(h): h._start_run("tidecaller"); h._show_binds(), "wait": 15},
		{"name": "11a_twinfang_select", "scene": "res://game/twinfang_main.tscn", "wait": 12},
		{"name": "11_twinfang_combat", "scene": "res://game/twinfang_main.tscn",
			"setup": func(h): h._start_run("tempo"), "wait": 170},
		{"name": "12a_voidcaller_select", "scene": "res://game/voidcaller_main.tscn", "wait": 12},
		{"name": "12_voidcaller_combat", "scene": "res://game/voidcaller_main.tscn",
			"setup": func(h): h._start_run("disruptor"), "wait": 170},
		{"name": "13_bloomweaver_select", "scene": "res://game/bloomweaver_main.tscn", "wait": 12},
		{"name": "14_bloomweaver_combat", "scene": "res://game/bloomweaver_main.tscn",
			"setup": func(h): h._start_run("wildgrove"), "wait": 170},
	]

func _process(_delta: float) -> bool:
	match phase:
		0:
			idx += 1
			if idx >= steps.size():
				print("TOUR DONE -> ", out_dir)
				return true
			if cur != null:
				cur.queue_free()
				cur = null
			var st: Dictionary = steps[idx]
			cur = (load(String(st["scene"])) as PackedScene).instantiate()
			root.add_child(cur)
			phase = 1
		1:
			var st: Dictionary = steps[idx]
			if st.has("setup"):
				(st["setup"] as Callable).call(cur)
			frames_left = int(st["wait"])
			phase = 2
		2:
			frames_left -= 1
			if frames_left <= 0:
				phase = 3
		3:
			var st: Dictionary = steps[idx]
			var img := root.get_texture().get_image()
			var path := out_dir.path_join(String(st["name"]) + ".png")
			img.save_png(path)
			print("  shot: ", path)
			phase = 0
	return false
