## screenshot_world — visual probe of THE WORLD (W1). WSLg (NOT --headless):
##   godot --path godot --script res://sim/screenshot_world.gd -- --out=/absolute/dir
## Tours: the Atlas (fresh) → the Bastion → Zone 1 fresh → mid-conquest (sluice flag
## live, acre flooded) → conquered (crest + flight path) → Atlas with the beacon lit.
extends SceneTree

var out_dir := "user://shots"
var hud: Node = null
var idx := -1
var frames := 0
var steps := ["atlas_fresh", "bastion", "zone_fresh", "zone_mid", "zone_cleared", "atlas_lit"]

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
			img.save_png(out_dir.path_join("world_" + String(steps[idx]) + ".png"))
			print("  shot: world_", steps[idx])
		return false
	idx += 1
	if idx >= steps.size():
		print("WORLD TOUR DONE -> ", out_dir)
		quit(0)
		return true
	match String(steps[idx]):
		"atlas_fresh":
			hud._world = WorldSave.new()   # a fresh world, disk untouched
			hud._show_atlas()
		"bastion":
			hud._show_bastion()
		"zone_fresh":
			hud._zone_id = WorldContent.ZONE1
			hud._show_zone()
		"zone_mid":
			# mid-conquest: spine to the sluice taken, gate open, acre flooded
			for nid in [0, 1, 2, 3, 17]:
				hud._world.mark_cleared(WorldContent.ZONE1, nid)
			hud._world.set_flag(WorldContent.ZONE1, "sluice", "opened")
			hud._world.set_at(WorldContent.ZONE1, 3)
			hud._zone_toast = "⚑  THE SLUICE — YOURS, forever"
			hud._show_zone()
		"zone_cleared":
			var z := WorldContent.zone(WorldContent.ZONE1)
			for n in (z["nodes"] as Array):
				hud._world.mark_cleared(WorldContent.ZONE1, int(n["id"]))
			hud._world.unlock_waystation(WorldContent.ZONE1)
			hud._world.set_at(WorldContent.ZONE1, 8)
			hud._zone_toast = "★  THE OLD MILL FALLS — ZONE CLEARED. The Gildfields are yours."
			hud._show_zone()
		"atlas_lit":
			hud._show_atlas()
	frames = 14
	return false
