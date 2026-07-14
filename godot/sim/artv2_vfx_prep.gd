## artv2_vfx_prep.gd — C7 non-image production: deterministically cut the Bill-approved
## I4 signature-VFX alpha sheets (art-source/graphics-v2/p6-vfx/alpha/, README +
## source-layout.json = the contract) into per-family flipbook atlases + manifest for
## the VfxBook/VfxPool runtime. CUT · TRIM · PACK only — never generates, repaints,
## redesigns, or substitutes an image (the image stop).
##   godot --headless --path godot --script res://sim/artv2_vfx_prep.gd
## Outputs res://game/art_v2/vfx/<family>.png + manifest.json (source sha256 + per-frame
## atlas rects + trim offsets + full registration-cell dims + registered pivots).
##
## THE CUT LAW (README): cells come from source-layout.json's EXPLICIT edges — the odd
## 941 source height is intentional (rows are 470/471 px); never infer vframes=2.
## Every frame keeps its full registration canvas (cell dims + trim offset recorded),
## alpha-trim is recorded, and the pivot is registered per frame.
##
## THE PIVOT LAW (probed 2026-07-14): registration is consistent WITHIN a sheet row but
## drifts up to ~80 px BETWEEN rows (e.g. the En Garde floor ring rides higher in row 2).
## Pivots are therefore computed PER ROW and stamped per frame:
##   contact / release      -> the row-union alpha-weighted centroid (the burst/origin)
##   body_and_floor /
##   ground_contact         -> x = row centroid · y = the row floor line (max painted y
##                             − FLOOR_INSET: the ellipse/ring half-height)
## The vfx tour renders every frame with its pivot crosshair — the visual registration
## gate the README demands. A family that reads mis-anchored gets an explicit override
## in PIVOT_OVERRIDE (still deterministic; provenance says so).
extends SceneTree

const SRC := "art-source/graphics-v2/p6-vfx"
const DST := "res://game/art_v2/vfx"
const A_MIN := 9              ## alpha above this counts as painted (soft-matte tolerant)
const PAD := 2                ## trim slack, px
const GUTTER := 2             ## atlas gutter, px
const ATLAS_MAX_W := 4096     ## WebGL2-safe atlas width
const FLOOR_INSET := 18.0     ## floor-ring half-height: pivot sits ON the ring, not under it

## family id -> [alpha sheet, runtime defaults]. ms/base_scale/loop are RUNTIME TUNING
## seeds (the manifest carries them; the tour is where they get eyeballed), from the
## README's suggested totals: light ~110 · parry/dodge ~190–220 · heavy ~190 ·
## crush/dump ~230–260 · engarde activation ~300–360 · hold loop ~1.6–2.4 s low-rate.
const FAMILIES := {
	"parry": {"sheet": "parry-alpha-v1.png", "ms": 26, "scale": 0.62, "loop": false,
		"travel_deg": 0.0},
	"dodge": {"sheet": "dodge-alpha-v1.png", "ms": 26, "scale": 0.62, "loop": false,
		"travel_deg": 0.0},
	"dump": {"sheet": "dump-alpha-v1.png", "ms": 30, "scale": 0.72, "loop": false,
		"travel_deg": -38.0},   ## authored premium wave travels up-right (tour-checked)
	"engarde_activate": {"sheet": "engarde-activate-alpha-v1.png", "ms": 42, "scale": 0.60,
		"loop": false, "travel_deg": 0.0},
	"engarde_hold": {"sheet": "engarde-hold-alpha-v1.png", "ms": 500, "scale": 0.60,
		"loop": true, "travel_deg": 0.0},
	"impact_light": {"sheet": "impact-light-alpha-v1.png", "ms": 18, "scale": 0.45,
		"loop": false, "travel_deg": 0.0},
	"impact_heavy": {"sheet": "impact-heavy-alpha-v1.png", "ms": 24, "scale": 0.62,
		"travel_deg": 0.0, "loop": false},
	"impact_crush": {"sheet": "impact-crush-alpha-v1.png", "ms": 32, "scale": 0.78,
		"travel_deg": 0.0, "loop": false},
}

## Explicit per-family pivot override, CELL coords (the registration escape hatch —
## empty today; fill only after the tour proves a computed rule mis-anchors).
const PIVOT_OVERRIDE := {}

func _initialize() -> void:
	var repo_root := ProjectSettings.globalize_path("res://").path_join("..")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DST))
	var layout_path := repo_root.path_join(SRC).path_join("source-layout.json")
	var layout_txt := FileAccess.get_file_as_string(layout_path)
	if layout_txt == "":
		print("VFX PREP FAIL: cannot read %s" % layout_path)
		quit(1)
		return
	var layout: Dictionary = JSON.parse_string(layout_txt)
	var sheets_meta: Dictionary = layout.get("sheets", {})
	var fails := 0
	var manifest := {"sources": {}, "families": {},
		"provenance": "I4 alpha sheets (2baf3fe) cut per source-layout.json by artv2_vfx_prep.gd — C7"}
	for fam in FAMILIES:
		var spec: Dictionary = FAMILIES[fam]
		var sheet_name := String(spec["sheet"])
		var meta: Dictionary = sheets_meta.get(sheet_name, {})
		if meta.is_empty():
			print("  VFX PREP FAIL: %s missing from source-layout.json (STOP: contract mismatch, ask Bill)" % sheet_name)
			fails += 1
			continue
		var src_path := repo_root.path_join(SRC).path_join("alpha").path_join(sheet_name)
		var img := Image.load_from_file(src_path)
		if img == null:
			print("  VFX PREP FAIL: cannot load %s" % src_path)
			fails += 1
			continue
		img.convert(Image.FORMAT_RGBA8)
		manifest["sources"][sheet_name] = FileAccess.get_sha256(src_path)
		var grid: Dictionary = layout.get(String(meta["layout"]), {})
		var rec := _family(img, fam, spec, meta, grid)
		if rec.is_empty():
			fails += 1
		else:
			manifest["families"][fam] = rec
	var mf := FileAccess.open(ProjectSettings.globalize_path(DST + "/manifest.json"), FileAccess.WRITE)
	mf.store_string(JSON.stringify(manifest, "\t", true) + "\n")
	mf.close()
	print("VFX PREP: %s (%d families + manifest)" % ["ALL OK" if fails == 0 else "FAIL",
		(manifest["families"] as Dictionary).size()])
	quit(0 if fails == 0 else 1)

## One family: explicit-edge cells -> per-frame trim -> per-row pivots -> packed atlas.
func _family(sheet: Image, fam: String, spec: Dictionary, meta: Dictionary, grid: Dictionary) -> Dictionary:
	var xe: Array = grid.get("x_edges", [])
	var ye: Array = grid.get("y_edges", [])
	var want := int(meta.get("frames", 0))
	if xe.size() < 2 or ye.size() < 2 or want <= 0:
		print("  VFX PREP FAIL: %s bad layout grid" % fam)
		return {}
	# --- cells row-major off the EXPLICIT edges (never infer equal rows) ---
	var cells: Array = []            # [{box: Rect2i, row: int}]
	for r in ye.size() - 1:
		for c in xe.size() - 1:
			if cells.size() >= want:
				break
			cells.append({"box": Rect2i(int(xe[c]), int(ye[r]),
				int(xe[c + 1]) - int(xe[c]), int(ye[r + 1]) - int(ye[r])), "row": r})
	if cells.size() < want:
		print("  VFX PREP FAIL: %s grid yields %d cells < %d frames" % [fam, cells.size(), want])
		return {}
	# --- per-frame painted bbox + per-row union stats (centroid / floor line) ---
	var frames: Array = []           # [{img, trim: Rect2i (cell coords), cell: Rect2i, row}]
	var row_wx := {}                 # row -> [Σa·x, Σa·y, Σa, max_painted_y]
	for i in want:
		var box: Rect2i = (cells[i] as Dictionary)["box"]
		var row := int((cells[i] as Dictionary)["row"])
		var region := sheet.get_region(box)
		var used := _painted_bbox(region)
		if used.size.x <= 2 or used.size.y <= 2:
			print("  VFX PREP FAIL: %s frame %d empty in box %s (STOP: unusable source, ask Bill)" % [fam, i, box])
			return {}
		used = used.grow(PAD).intersection(Rect2i(0, 0, region.get_width(), region.get_height()))
		if not row_wx.has(row):
			row_wx[row] = [0.0, 0.0, 0.0, 0.0]
		var acc: Array = row_wx[row]
		for y in range(used.position.y, used.end.y):
			for x in range(used.position.x, used.end.x):
				var a := float(region.get_pixel(x, y).a8)
				if a > float(A_MIN):
					acc[0] += a * float(x)
					acc[1] += a * float(y)
					acc[2] += a
					acc[3] = maxf(acc[3], float(y))
		frames.append({"img": region.get_region(used), "trim": used, "cell": box, "row": row})
	# --- per-row pivot by anchor rule (cell coords) ---
	var anchor := String(meta.get("anchor_rule", "contact"))
	var row_pivot := {}
	for row in row_wx:
		var acc: Array = row_wx[row]
		if acc[2] <= 0.0:
			print("  VFX PREP FAIL: %s row %d has no paint" % [fam, row])
			return {}
		var cx := float(acc[0]) / float(acc[2])
		var cy := float(acc[1]) / float(acc[2])
		if anchor == "body_and_floor" or anchor == "ground_contact":
			cy = float(acc[3]) - FLOOR_INSET
		row_pivot[row] = Vector2(snappedf(cx, 0.1), snappedf(cy, 0.1))
	if PIVOT_OVERRIDE.has(fam):
		for row in row_pivot:
			row_pivot[row] = PIVOT_OVERRIDE[fam]
	# --- pack the atlas: frames left->right, wrap at ATLAS_MAX_W ---
	var rects: Array = []
	var pen := Vector2i.ZERO
	var shelf_h := 0
	var atlas_w := 0
	for f in frames:
		var sz: Vector2i = ((f as Dictionary)["trim"] as Rect2i).size
		if pen.x > 0 and pen.x + sz.x > ATLAS_MAX_W:
			pen = Vector2i(0, pen.y + shelf_h + GUTTER)
			shelf_h = 0
		rects.append(Rect2i(pen, sz))
		atlas_w = maxi(atlas_w, pen.x + sz.x)
		shelf_h = maxi(shelf_h, sz.y)
		pen.x += sz.x + GUTTER
	var atlas_h := pen.y + shelf_h
	var atlas := Image.create(atlas_w, atlas_h, false, Image.FORMAT_RGBA8)
	for i in frames.size():
		atlas.blit_rect((frames[i] as Dictionary)["img"], Rect2i(Vector2i.ZERO,
			(rects[i] as Rect2i).size), (rects[i] as Rect2i).position)
	atlas.save_png(ProjectSettings.globalize_path("%s/%s.png" % [DST, fam]))
	# --- manifest record ---
	var out_frames: Array = []
	for i in frames.size():
		var f: Dictionary = frames[i]
		var trim: Rect2i = f["trim"]
		var cell: Rect2i = f["cell"]
		var pv: Vector2 = row_pivot[int(f["row"])]
		out_frames.append({
			"rect": [(rects[i] as Rect2i).position.x, (rects[i] as Rect2i).position.y,
				(rects[i] as Rect2i).size.x, (rects[i] as Rect2i).size.y],
			"trim": [trim.position.x, trim.position.y],
			"cell": [cell.size.x, cell.size.y],
			"pivot": [pv.x, pv.y],
		})
	print("  vfx prep: %-17s %d frames -> %dx%d atlas · pivot rule %s%s" % [fam,
		frames.size(), atlas_w, atlas_h, anchor, " (OVERRIDE)" if PIVOT_OVERRIDE.has(fam) else ""])
	return {
		"sheet": String(spec["sheet"]),
		"anchor": anchor,
		"pivot_rule": "override" if PIVOT_OVERRIDE.has(fam) else "computed_per_row",
		"frames": out_frames,
		"ms_per_frame": int(spec["ms"]),
		"base_scale": float(spec["scale"]),
		"loop": bool(spec["loop"]),
		"travel_deg": float(spec.get("travel_deg", 0.0)),
		"blend": "normal",          ## authored color layer; additive dupes are RUNTIME layers
		"additive_dup": true,
	}

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
