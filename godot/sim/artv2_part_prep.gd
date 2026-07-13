## artv2_part_prep.gd — C5 non-image production: crop approved alpha sources to
## their used rect and normalize them onto the 300px actor contract, writing the
## runtime PNGs the PaintedActor2D contract consumes (ACTORS.md). This tool
## CROPS and SCALES only — it never generates, redesigns, or repaints an image
## (the C5 image stop). Re-run whenever Codex re-delivers a source.
##   godot --headless --path godot --script res://sim/artv2_part_prep.gd
## Sources: art-source/graphics-v2/p4-duelist/alpha/  (outside res://)
## Targets: res://game/art_v2/actors/duelist/{parts,frames}/
extends SceneTree

const SRC := "art-source/graphics-v2/p4-duelist/alpha"
const DST := "res://game/art_v2/actors/duelist"

## part -> [source file, target key ("h"=height/"w"=width), target px]
## Sizes place the composed figure on the 300px contract (head ~80 incl. hair,
## wide stance ~170 tall, sword long + narrow per the approved anchor).
const PLAN := {
	"parts/legs.png": ["legs-alpha-v1.png", "h", 170],
	"parts/torso.png": ["torso-alpha-v1.png", "h", 135],
	"parts/head.png": ["head-alpha-v1.png", "h", 82],
	"parts/arm.png": ["arm-alpha-v1.png", "w", 105],
	"parts/blade.png": ["blade-alpha-v1.png", "w", 165],
	"parts/cloak.png": ["cloak-alpha-v1.png", "h", 125],
	"frames/windup_heavy.png": ["windup-heavy-alpha-v1.png", "h", 310],
	"frames/swing_heavy.png": ["swing-heavy-alpha-v1.png", "h", 300],
}

func _initialize() -> void:
	var repo_root := ProjectSettings.globalize_path("res://").path_join("..")
	var fails := 0
	for dst in PLAN:
		var spec: Array = PLAN[dst]
		var src_path := repo_root.path_join(SRC).path_join(String(spec[0]))
		var img := Image.load_from_file(src_path)
		if img == null:
			print("  PREP FAIL: cannot load %s" % src_path)
			fails += 1
			continue
		img.convert(Image.FORMAT_RGBA8)
		var used := img.get_used_rect()
		if used.size.x <= 0 or used.size.y <= 0 or used.size == Vector2i(img.get_width(), img.get_height()):
			# a fully-opaque "alpha" source means the chroma key was never cut —
			# that is an unusable source, not something to fix silently (image stop)
			print("  PREP FAIL: %s has no transparency to crop (used=%s) — STOP, ask Bill/Codex" % [String(spec[0]), used])
			fails += 1
			continue
		var cropped := img.get_region(used)
		var scl: float
		if String(spec[1]) == "h":
			scl = float(spec[2]) / float(cropped.get_height())
		else:
			scl = float(spec[2]) / float(cropped.get_width())
		var out_w := maxi(1, int(round(cropped.get_width() * scl)))
		var out_h := maxi(1, int(round(cropped.get_height() * scl)))
		cropped.resize(out_w, out_h, Image.INTERPOLATE_LANCZOS)
		var out_path := ProjectSettings.globalize_path(DST + "/" + dst)
		cropped.save_png(out_path)
		print("  prep: %-24s %s -> used %s -> %dx%d" % [dst, String(spec[0]), used, out_w, out_h])
	print("PART PREP: %s (%d files)" % ["ALL OK" if fails == 0 else "FAIL", PLAN.size()])
	quit(0 if fails == 0 else 1)
