## artv2_dash_prep.gd — C6B non-image production: deterministically crop/trim the
## Bill-approved I3-B dashboard alpha sheets (art-source/graphics-v2/p5-dashboard/alpha/,
## README = the contract) into the runtime pieces DashSkin consumes. CROP · TRIM ·
## SCALE only — never generates, repaints, redesigns, or substitutes an image (the
## image stop). The wide sheet's baked utility sample is deliberately NOT cut — the
## dedicated utility-tab source supersedes it (README law).
##   godot --headless --path godot --script res://sim/artv2_dash_prep.gd
## Outputs res://game/art_v2/dash/*.png + manifest.json (source sha256 + crop rects +
## interior-opening fractions — the provenance record DashSkin's constants cite).
extends SceneTree

const SRC := "art-source/graphics-v2/p5-dashboard/alpha"
const DST := "res://game/art_v2/dash"
const A_MIN := 9          ## alpha above this counts as painted (soft-matte tolerant)

## piece -> [sheet, box fractions (x0,y0,x1,y1), target width px (0 = keep)]
## Boxes bound each piece on its sheet; the cut then TRIMS to the painted bbox
## inside the box, so sheet re-exports with the same composition keep working.
const PLAN := {
	"frame_answer.png": ["wide-components-alpha-v1.png", [0.00, 0.00, 1.00, 0.28], 1300],
	"shell_boss.png": ["wide-components-alpha-v1.png", [0.00, 0.28, 1.00, 0.585], 720],
	"shell_resource.png": ["wide-components-alpha-v1.png", [0.00, 0.585, 1.00, 0.79], 800],
	"party_row.png": ["compact-components-alpha-v1.png", [0.00, 0.00, 1.00, 0.50], 640],
	"slot_ability.png": ["compact-components-alpha-v1.png", [0.05, 0.50, 0.40, 1.00], 160],
	"socket_combo.png": ["compact-components-alpha-v1.png", [0.42, 0.50, 0.66, 1.00], 72],
	"socket_debuff.png": ["compact-components-alpha-v1.png", [0.70, 0.50, 0.90, 1.00], 56],
	"utility_tab.png": ["utility-tab-alpha-v1.png", [0.00, 0.00, 1.00, 1.00], 620],
}
## The seven answer icons: 7 equal columns, left→right per the README contents line.
## Each is trimmed, then the white TIMING NAIL above the body is cut off — the nail
## is the board's visual guide only; runtime alignment is the live AnswerChannel
## geometry (code-owned, README law).
const ICONS := ["icon_diamond", "icon_hexagon", "icon_octagon", "icon_brace",
	"icon_feint_diamond", "icon_feint_hexagon", "icon_feint_octagon"]
const ICON_SHEET := "answer-icons-alpha-v1.png"
const ICON_W := 96

func _initialize() -> void:
	var repo_root := ProjectSettings.globalize_path("res://").path_join("..")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DST))
	var fails := 0
	var manifest := {"sources": {}, "pieces": {}}
	var sheets := {}
	var names := [ICON_SHEET, "compact-components-alpha-v1.png",
		"utility-tab-alpha-v1.png", "wide-components-alpha-v1.png"]
	for n in names:
		var p := repo_root.path_join(SRC).path_join(n)
		var img := Image.load_from_file(p)
		if img == null:
			print("  DASH PREP FAIL: cannot load %s" % p)
			fails += 1
			continue
		img.convert(Image.FORMAT_RGBA8)
		sheets[n] = img
		manifest["sources"][n] = FileAccess.get_sha256(p)
	for piece in PLAN:
		var spec: Array = PLAN[piece]
		if not sheets.has(String(spec[0])):
			fails += 1
			continue
		var rec := _cut(sheets[String(spec[0])], spec[1], int(spec[2]), String(piece))
		if rec.is_empty():
			fails += 1
		else:
			manifest["pieces"][piece] = rec
	# --- the seven icons: the octagons' spikes cross the sheet's 7-column grid, so a
	# straight column cut beheads a spike AND leaves it as a stray in the neighbor.
	# Connected components instead: every painted component belongs to the column of
	# its centroid; an icon's crop = the union bbox of its own components. ---
	if sheets.has(ICON_SHEET):
		var boxes := _icon_boxes(sheets[ICON_SHEET], ICONS.size())
		for i in ICONS.size():
			var rec := _cut_px(sheets[ICON_SHEET], boxes[i], ICON_W, ICONS[i] + ".png", true)
			if rec.is_empty():
				fails += 1
			else:
				manifest["pieces"][ICONS[i] + ".png"] = rec
	else:
		fails += ICONS.size()
	var mf := FileAccess.open(ProjectSettings.globalize_path(DST + "/manifest.json"), FileAccess.WRITE)
	mf.store_string(JSON.stringify(manifest, "\t", true) + "\n")
	mf.close()
	print("DASH PREP: %s (%d pieces + manifest)" % ["ALL OK" if fails == 0 else "FAIL", manifest["pieces"].size()])
	quit(0 if fails == 0 else 1)

## Cut one piece: box → trim to painted bbox (+2px pad) → optional nail-cut →
## Lanczos to target width → save. Returns the manifest record (crop rect px on the
## source sheet · output size · interior transparent openings as fractions of the
## crop — the numbers DashSkin's opening constants are derived from).
func _cut(sheet: Image, boxf: Array, target_w: int, out_name: String, nail_cut := false) -> Dictionary:
	var sw := sheet.get_width()
	var sh := sheet.get_height()
	var box := Rect2i(int(float(boxf[0]) * sw), int(float(boxf[1]) * sh),
		int((float(boxf[2]) - float(boxf[0])) * sw), int((float(boxf[3]) - float(boxf[1])) * sh))
	return _cut_px(sheet, box, target_w, out_name, nail_cut)

func _cut_px(sheet: Image, box: Rect2i, target_w: int, out_name: String, nail_cut := false) -> Dictionary:
	var region := sheet.get_region(box)
	var used := _painted_bbox(region)
	if used.size.x <= 4 or used.size.y <= 4:
		print("  DASH PREP FAIL: %s — nothing painted in box %s (STOP: unusable source, ask Bill)" % [out_name, box])
		return {}
	used = used.grow(2).intersection(Rect2i(0, 0, region.get_width(), region.get_height()))
	var img := region.get_region(used)
	if nail_cut:
		var top := _nail_body_top(img)
		if top > 0:
			img = img.get_region(Rect2i(0, top, img.get_width(), img.get_height() - top))
	var holes := _openings(img)
	if target_w > 0 and img.get_width() > target_w:
		var scl := float(target_w) / float(img.get_width())
		img.resize(target_w, maxi(1, int(round(img.get_height() * scl))), Image.INTERPOLATE_LANCZOS)
	img.save_png(ProjectSettings.globalize_path(DST + "/" + out_name))
	print("  dash prep: %-24s crop %s -> %dx%d, %d opening(s)" % [out_name,
		Rect2i(box.position + used.position, used.size), img.get_width(), img.get_height(), holes.size()])
	return {"crop": [box.position.x + used.position.x, box.position.y + used.position.y,
		used.size.x, used.size.y], "out": [img.get_width(), img.get_height()], "openings": holes}

## The painted bounding box (alpha > A_MIN) — get_used_rect() counts alpha>0, which
## soft chroma mattes defeat; this threshold matches the README's matte contract.
func _painted_bbox(img: Image) -> Rect2i:
	var w := img.get_width()
	var h := img.get_height()
	var x0 := w
	var y0 := h
	var x1 := -1
	var y1 := -1
	for y in h:
		for x in w:
			if img.get_pixel(x, y).a8 > A_MIN:
				x0 = mini(x0, x)
				y0 = mini(y0, y)
				x1 = maxi(x1, x)
				y1 = maxi(y1, y)
	if x1 < 0:
		return Rect2i(0, 0, 0, 0)
	return Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1)

## Cut the timing NAIL off an icon. The nail touches the shape apex (no transparent
## gap — probed 2026-07-13), so a plain span threshold decapitates pointed tops.
## Instead: the nail's own width = the median span of the first 20 painted rows; the
## body starts at the first row wider than nail+4px (loses only the apex sliver the
## nail overlaps). An icon with NO nail (BRACE) opens wide immediately → no cut.
func _nail_body_top(img: Image) -> int:
	var w := img.get_width()
	var spans: Array = []
	var first_y := -1
	for y in img.get_height():
		var n := 0
		for x in w:
			if img.get_pixel(x, y).a8 > A_MIN:
				n += 1
		if n == 0 and first_y < 0:
			continue
		if first_y < 0:
			first_y = y
		spans.append(n)
		if spans.size() >= 120:
			break
	if spans.size() < 20:
		return 0
	var head: Array = spans.slice(0, 20)
	head.sort()
	var nail_w: int = head[10]
	if nail_w > int(0.08 * float(w)):
		return 0                      # no nail (BRACE) — the body opens wide at once
	for i in spans.size():
		if int(spans[i]) > nail_w + 4:
			return first_y + i
	return 0

## Per-icon crop boxes for an N-across icon sheet: BFS painted components on a 2×
## downsampled grid; each component joins the column of its centroid; an icon's box
## = the union bbox of its components (+2px slack for the downsample).
func _icon_boxes(sheet: Image, n: int) -> Array:
	var ds := 2
	var gw := sheet.get_width() / ds
	var gh := sheet.get_height() / ds
	var solid := PackedByteArray()
	solid.resize(gw * gh)
	for gy in gh:
		for gx in gw:
			solid[gy * gw + gx] = 1 if sheet.get_pixel(gx * ds, gy * ds).a8 > A_MIN else 0
	var seen := PackedByteArray()
	seen.resize(gw * gh)
	var boxes: Array = []
	for i in n:
		boxes.append(Rect2i(0, 0, 0, 0))
	for gy in gh:
		for gx in gw:
			var idx := gy * gw + gx
			if solid[idx] == 0 or seen[idx] == 1:
				continue
			var stack := [idx]
			seen[idx] = 1
			var bx0 := gx
			var by0 := gy
			var bx1 := gx
			var by1 := gy
			var cxs := 0
			var cnt := 0
			while not stack.is_empty():
				var c: int = stack.pop_back()
				var cx := c % gw
				var cy := c / gw
				bx0 = mini(bx0, cx)
				bx1 = maxi(bx1, cx)
				by0 = mini(by0, cy)
				by1 = maxi(by1, cy)
				cxs += cx
				cnt += 1
				for d in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
					var nx: int = cx + d[0]
					var ny: int = cy + d[1]
					if nx < 0 or ny < 0 or nx >= gw or ny >= gh:
						continue
					var ni := ny * gw + nx
					if solid[ni] == 1 and seen[ni] == 0:
						seen[ni] = 1
						stack.append(ni)
			if cnt < 4:
				continue                               # matte speck — drop
			var col := clampi(int(float(cxs) / float(cnt) * float(ds) * float(n) / float(sheet.get_width())), 0, n - 1)
			var r := Rect2i(bx0 * ds - 2, by0 * ds - 2, (bx1 - bx0 + 1) * ds + 4, (by1 - by0 + 1) * ds + 4) \
				.intersection(Rect2i(0, 0, sheet.get_width(), sheet.get_height()))
			boxes[col] = r if boxes[col].size == Vector2i.ZERO else boxes[col].merge(r)
	return boxes

## Interior transparent openings (the code-data windows): BFS on a 4× downsampled
## alpha grid; a transparent component that never touches the crop border is an
## opening. Reported as [x0,y0,x1,y1] fractions of the crop, largest first.
func _openings(img: Image) -> Array:
	var ds := 4
	var gw := maxi(1, img.get_width() / ds)
	var gh := maxi(1, img.get_height() / ds)
	var solid := PackedByteArray()
	solid.resize(gw * gh)
	for gy in gh:
		for gx in gw:
			solid[gy * gw + gx] = 1 if img.get_pixel(gx * ds, gy * ds).a8 > A_MIN else 0
	var seen := PackedByteArray()
	seen.resize(gw * gh)
	var out: Array = []
	for gy in gh:
		for gx in gw:
			var idx := gy * gw + gx
			if solid[idx] == 1 or seen[idx] == 1:
				continue
			var stack := [idx]
			seen[idx] = 1
			var cells: Array = []
			var border := false
			while not stack.is_empty():
				var c: int = stack.pop_back()
				cells.append(c)
				var cx := c % gw
				var cy := c / gw
				if cx == 0 or cy == 0 or cx == gw - 1 or cy == gh - 1:
					border = true
				for d in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
					var nx: int = cx + d[0]
					var ny: int = cy + d[1]
					if nx < 0 or ny < 0 or nx >= gw or ny >= gh:
						continue
					var ni := ny * gw + nx
					if solid[ni] == 0 and seen[ni] == 0:
						seen[ni] = 1
						stack.append(ni)
			if border or cells.size() < 12:
				continue
			var bx0 := gw
			var by0 := gh
			var bx1 := 0
			var by1 := 0
			for c in cells:
				bx0 = mini(bx0, int(c) % gw)
				bx1 = maxi(bx1, int(c) % gw)
				by0 = mini(by0, int(c) / gw)
				by1 = maxi(by1, int(c) / gw)
			out.append({"cells": cells.size(), "frac": [
				snappedf(float(bx0 * ds) / float(img.get_width()), 0.001),
				snappedf(float(by0 * ds) / float(img.get_height()), 0.001),
				snappedf(float((bx1 + 1) * ds) / float(img.get_width()), 0.001),
				snappedf(float((by1 + 1) * ds) / float(img.get_height()), 0.001)]})
	out.sort_custom(func(a, b): return int(a["cells"]) > int(b["cells"]))
	var fr: Array = []
	for o in out:
		fr.append(o["frac"])
	return fr
