## screenshot_alch_bar.gd — visual probe for the Alchemist ability bar WITH a module +
## drafted spells: confirms the CATALYST (module) and SPITFIRE/DECANT/REDUCTION (spell)
## runes appear beside DODGE and the hint lists their keys.
## Needs a display (WSLg — NOT --headless):
##   godot --path godot --script res://sim/screenshot_alch_bar.gd -- --out=/absolute/dir
extends SceneTree

var out_dir := "user://shots"
var cur: Node = null
var phase := 0
var waited := 0

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr("--out=".length())
	DirAccess.make_dir_recursive_absolute(out_dir)

func _process(_d: float) -> bool:
	match phase:
		0:
			cur = (load("res://game/raid_main.tscn") as PackedScene).instantiate()
			root.add_child(cur)
			phase = 1
		1:
			# a campaign run with The Third Reagent module + all three spells drafted.
			var run := RunState.start_alchemist("brew", 7)
			run.modules["third_reagent"] = true
			for sp in ["spitfire", "decant", "reduction"]:
				run.loadout.append(sp)
				run.boons[sp] = true
			cur._run = run
			cur._launch("caster", "brew")
			waited = 0
			phase = 2
		2:
			waited += 1
			if waited > 10:
				var img := root.get_texture().get_image()
				var path := out_dir.path_join("alch_bar_full.png")
				img.save_png(path)
				print("  shot: ", path)
				return true
	return false
