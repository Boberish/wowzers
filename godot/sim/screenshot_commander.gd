## screenshot_commander.gd — visual probe of COMMANDER mode. WSLg (NOT --headless):
##   godot --path godot --script res://sim/screenshot_commander.gd -- --out=/absolute/dir
## Shots: the PARTY setup screen (defaults), the party with commanded picks
## (tempo blade + Bloomweaver healer), and an AI raider's REFORGE draft screen.
extends SceneTree

var out_dir := "user://shots"
var hud: Node = null
var idx := -1
var frames := 0
var steps := ["party_default", "party_commanded", "ai_draft"]

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr("--out=".length())
	DirAccess.make_dir_recursive_absolute(out_dir)

func _process(_d: float) -> bool:
	if hud == null:
		hud = (load("res://game/raid_main.tscn") as PackedScene).instantiate()
		root.add_child(hud)
		return false
	if frames > 0:
		frames -= 1
		if frames == 0:
			var img := root.get_texture().get_image()
			img.save_png(out_dir.path_join("commander_" + String(steps[idx]) + ".png"))
			print("  shot: commander_", steps[idx])
		return false
	idx += 1
	if idx >= steps.size():
		print("COMMANDER TOUR DONE -> ", out_dir)
		return true
	match String(steps[idx]):
		"party_default":
			hud._seat_key = "tank"
			hud._aspect = "warden"
			hud._party = {}
			hud._show_party_setup()
		"party_commanded":
			hud._party["blade"]["aspect"] = "tempo"
			hud._party["healer"] = {"cls": "bloomweaver", "aspect": "thornveil"}
			hud._show_party_setup()
		"ai_draft":
			hud._start_map_run()
			# jump straight to the BLADE's draft (the AI-ally REFORGE framing)
			hud._show_seat_draft("blade", func(): pass)
	frames = 14
	return false
