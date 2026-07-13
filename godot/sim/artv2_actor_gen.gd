## artv2_actor_gen.gd — regenerate the FLAT-COLOR DEBUG parts for a painted
## actor (C4 proof art — deliberately placeholder: solid fills, hard borders,
## hazard stripes on replacement frames; NEVER final art, Codex owns that).
##   godot --headless --path godot --script res://sim/artv2_actor_gen.gd -- --id=duelist
## Writes into res://game/art_v2/actors/<id>/{parts,frames}/ next to actor.json.
extends SceneTree

func _initialize() -> void:
	var id := "duelist"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--id="):
			id = a.substr("--id=".length())
	var base := "res://game/art_v2/actors/%s" % id
	DirAccess.make_dir_recursive_absolute(base + "/parts")
	DirAccess.make_dir_recursive_absolute(base + "/frames")
	_part(base + "/parts/legs.png", 52, 120, Color("2c3444"))
	_part(base + "/parts/torso.png", 60, 112, Color("4a6a8a"))
	_part(base + "/parts/head.png", 42, 46, Color("d9c9a8"))
	_part(base + "/parts/arm.png", 20, 92, Color("3c5a76"))
	_part(base + "/parts/blade.png", 12, 124, Color("c8d4e0"))
	_part(base + "/parts/cloak.png", 74, 150, Color("7a2030"))
	_frame(base + "/frames/windup_heavy.png", 200, 320, Color("d07a20"))
	_frame(base + "/frames/swing_heavy.png", 240, 300, Color("30a8c0"))
	print("ACTOR GEN DONE -> %s (6 parts + 2 frames)" % base)
	quit(0)

## a solid part slab: fill + darker 2px border (reads as an obvious placeholder)
func _part(path: String, w: int, h: int, col: Color) -> void:
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	img.fill(col)
	var edge := col.darkened(0.45)
	for x in w:
		for t in 2:
			img.set_pixel(x, t, edge)
			img.set_pixel(x, h - 1 - t, edge)
	for y in h:
		for t in 2:
			img.set_pixel(t, y, edge)
			img.set_pixel(w - 1 - t, y, edge)
	img.save_png(ProjectSettings.globalize_path(path))

## a replacement/contact frame: translucent silhouette + hazard stripes — it
## must SCREAM debug on any screenshot
func _frame(path: String, w: int, h: int, col: Color) -> void:
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var on_stripe := int(floor((float(x) + float(y)) / 24.0)) % 2 == 0
			img.set_pixel(x, y, col if on_stripe else Color(col.darkened(0.5), 0.85))
	img.save_png(ProjectSettings.globalize_path(path))
