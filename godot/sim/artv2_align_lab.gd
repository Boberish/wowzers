## artv2_align_lab.gd — THE DUELIST ALIGNMENT LAB (C5.1, dev-only; WSLg/desktop,
## NOT headless). Shows the layered PaintedActor2D at large zoom with part
## bounding boxes + pivot markers, the approved anchor as an optional ghost, and
## the core pose set; every part's at/anchor/rot/scale is editable live and can
## be saved straight back into actor.json. Registration numbers ONLY — this tool
## never touches a bitmap (the C5.1 image stop lives outside it).
##
## INTERACTIVE:
##   1..6 poses (idle · windup .5 · windup 1.0 · parry · hit · die)  ·  R reload
##   TAB select part · ARROWS nudge at (SHIFT ×0.2 fine) · Q/E rot ∓1° (SHIFT ¼°)
##   [ ] part scale ∓2% · G ghost · B boxes · PgUp/PgDn zoom · S SAVE actor.json
## CLI (my loop / screenshots):
##   godot --path godot --rendering-driver opengl3 --resolution 1920x1080 \
##     --script res://sim/artv2_align_lab.gd -- --pose=windup10 --zoom=3 \
##     --ghost --shot=/abs/out.png [--focus=arm]   (--focus centers that part)
extends SceneTree

const AJSON := "res://game/art_v2/actors/duelist/actor.json"
const GHOST := "art-source/graphics-v2/p4-duelist/anchors/duelist-dodge-tank-anchor-v1.png"
const POSES := ["idle", "windup05", "windup10", "parry", "hit", "die"]

var actor: PaintedActor2D = null
var overlay: Control
var hud: Label
var ghost: Sprite2D = null
var pose := "idle"
var zoom := 2.4
var boxes := true
var show_ghost := false
var sel := 0                 ## selected part index (part names order)
var part_names: Array = []
var shot_path := ""
var focus_part := ""
var frame := -1
var meta: Dictionary = {}    ## the live actor.json dict (edited + saved)
var _baseline: Line2D

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--pose="):
			pose = a.substr("--pose=".length())
		elif a.begins_with("--zoom="):
			zoom = float(a.substr("--zoom=".length()))
		elif a.begins_with("--shot="):
			shot_path = a.substr("--shot=".length())
		elif a.begins_with("--focus="):
			focus_part = a.substr("--focus=".length())
		elif a == "--ghost":
			show_ghost = true
	var bg := ColorRect.new()
	bg.color = Color(0.13, 0.14, 0.17)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	_baseline = Line2D.new()   # the stage baseline the feet must ride
	_baseline.add_point(Vector2(0, 0))
	_baseline.add_point(Vector2(4000, 0))
	_baseline.default_color = Color(0.9, 0.8, 0.3, 0.5)
	_baseline.width = 2.0
	root.add_child(_baseline)
	overlay = Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.draw.connect(_paint_overlay)
	hud = Label.new()
	hud.position = Vector2(14, 10)
	hud.add_theme_font_size_override("font_size", 15)
	_load_actor()
	root.add_child(overlay)
	root.add_child(hud)
	# a SceneTree script has no Node input virtuals — keys arrive via the window
	root.window_input.connect(_on_input)

func _floor_y() -> float:
	return root.get_visible_rect().size.y * 0.86

func _anchor_pos() -> Vector2:
	return Vector2(root.get_visible_rect().size.x * 0.42, _floor_y())

## (Re)build the actor from actor.json on disk — R / after S; ghost rebuilt too.
func _load_actor() -> void:
	if actor != null:
		actor.queue_free()
	if ghost != null:
		ghost.queue_free()
		ghost = null
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(AJSON))
	meta = parsed if parsed is Dictionary else {}
	actor = PaintedActor2D.try_make("duelist")
	if actor == null:
		print("ALIGN LAB: adapter did not build — fix actor.json")
		quit(1)
		return
	actor.position = _anchor_pos()
	actor.scale = Vector2.ONE * zoom
	root.add_child(actor)
	root.move_child(actor, 2)   # above bg+baseline, below overlay/hud
	part_names = []
	for p_v in (meta.get("parts", []) as Array):
		part_names.append(String((p_v as Dictionary).get("name", "?")))
	if show_ghost:
		var img := Image.load_from_file(ProjectSettings.globalize_path("res://").path_join("..").path_join(GHOST))
		if img != null:
			# the approved anchor is a MODEL SHEET — shown as a side reference
			# panel at comparable figure height, never composited under the rig
			ghost = Sprite2D.new()
			ghost.texture = ImageTexture.create_from_image(img)
			ghost.centered = false
			ghost.modulate = Color(1, 1, 1, 0.92)
			root.add_child(ghost)
			root.move_child(ghost, 1)
	_apply_pose()
	_layout_screen()

func _apply_pose() -> void:
	actor.clear_windup()
	match pose:
		"windup05":
			actor.windup("light", 0.5)
		"windup10":
			actor.windup("light", 1.0)
		"parry":
			actor.evade_react()
		"hit":
			actor.hit_react(true)
		"die":
			actor.die()
	_hud_text()

func _part_dict(i: int) -> Dictionary:
	var parts: Array = meta.get("parts", [])
	if i >= 0 and i < parts.size():
		return parts[i]
	return {}

func _hud_text() -> void:
	var pd := _part_dict(sel)
	hud.text = "ALIGN LAB · pose %s · zoom %.1f · part [%s]  at=%s rot=%s° scale=%s anchor=%s\n1-6 pose · TAB part · ARROWS at · Q/E rot · [ ] scale · G ghost · B boxes · R reload · S SAVE" % [
		pose, zoom, String(pd.get("name", "?")), str(pd.get("at", [0, 0])),
		str(pd.get("rot", 0)), str(pd.get("scale", 1.0)), str(pd.get("anchor", []))]

## Overlay: bounding box + pivot cross + name for every part, in GLOBAL space.
func _paint_overlay() -> void:
	if not boxes or actor == null:
		return
	var ci := overlay
	var i := 0
	for pname in part_names:
		var n: Node2D = actor._parts.get(String(pname))
		if n == null:
			i += 1
			continue
		var tex: Texture2D = null
		var off := Vector2.ZERO
		if n is Sprite2D:
			tex = (n as Sprite2D).texture
			off = (n as Sprite2D).offset
		elif n is Polygon2D:
			tex = (n as Polygon2D).texture
			off = (n as Polygon2D).offset
		if tex == null:
			i += 1
			continue
		var xf := n.get_global_transform()
		var col := Color.from_hsv(float(i) / maxf(1.0, float(part_names.size())), 0.75, 1.0, 0.9)
		var sz := Vector2(tex.get_width(), tex.get_height())
		var pts := PackedVector2Array([xf * (off), xf * (off + Vector2(sz.x, 0)),
			xf * (off + sz), xf * (off + Vector2(0, sz.y)), xf * (off)])
		ci.draw_polyline(pts, col, 1.5, true)
		var piv := xf * Vector2.ZERO
		ci.draw_line(piv + Vector2(-7, 0), piv + Vector2(7, 0), col, 2.0)
		ci.draw_line(piv + Vector2(0, -7), piv + Vector2(0, 7), col, 2.0)
		ci.draw_circle(piv, 3.0, col)
		ci.draw_string(ThemeDB.fallback_font, pts[0] + Vector2(2, -4),
			"%s%s" % ["> " if i == sel else "", pname], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, col)
		i += 1

func _layout_screen() -> void:
	var vp := root.get_visible_rect().size
	_baseline.position = Vector2(0, _floor_y())
	actor.position = _anchor_pos()
	if ghost != null and ghost.texture != null:
		var gh := float(ghost.texture.get_height())
		var gs := (vp.y * 0.55) / gh
		ghost.scale = Vector2.ONE * gs
		ghost.position = Vector2(vp.x - ghost.texture.get_width() * gs - 12.0, vp.y * 0.06)

func _process(_delta: float) -> bool:
	frame += 1
	overlay.queue_redraw()
	if frame == 1:
		_layout_screen()
	if pose == "windup05":
		actor.windup("light", 0.5)   # fed per-frame, like the stage
	elif pose == "windup10":
		actor.windup("light", 1.0)
	if focus_part != "" and frame == 2:
		var n: Node2D = actor._parts.get(focus_part)
		if n != null:
			var center := root.get_visible_rect().size * 0.5
			actor.position += center - n.global_position
			if ghost != null:
				ghost.position = actor.position
	if shot_path != "" and frame == (55 if pose == "die" else 20):
		var img := root.get_texture().get_image()
		img.save_png(shot_path)
		print("  shot: ", shot_path)
		quit(0)
	return false

func _on_input(ev: InputEvent) -> void:
	if not (ev is InputEventKey) or not ev.is_pressed():
		return
	var k := (ev as InputEventKey).keycode
	var fine: bool = (ev as InputEventKey).shift_pressed
	var pd := _part_dict(sel)
	var step := 0.2 if fine else 1.0
	match k:
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6:
			pose = POSES[k - KEY_1]
			_load_actor()
		KEY_TAB:
			sel = (sel + 1) % maxi(1, part_names.size())
			_hud_text()
		KEY_RIGHT, KEY_LEFT, KEY_UP, KEY_DOWN:
			var at: Array = pd.get("at", [0, 0])
			var d := {KEY_RIGHT: Vector2(step, 0), KEY_LEFT: Vector2(-step, 0),
				KEY_UP: Vector2(0, -step), KEY_DOWN: Vector2(0, step)}[k] as Vector2
			pd["at"] = [snappedf(float(at[0]) + d.x, 0.1), snappedf(float(at[1]) + d.y, 0.1)]
			_write_tmp_and_reload()
		KEY_Q, KEY_E:
			var r := float(pd.get("rot", 0.0)) + (0.25 if fine else 1.0) * (1.0 if k == KEY_E else -1.0)
			pd["rot"] = snappedf(r, 0.05)
			_write_tmp_and_reload()
		KEY_BRACKETLEFT, KEY_BRACKETRIGHT:
			var sc := float(pd.get("scale", 1.0)) * (0.98 if k == KEY_BRACKETLEFT else 1.02)
			pd["scale"] = snappedf(sc, 0.001)
			_write_tmp_and_reload()
		KEY_G:
			show_ghost = not show_ghost
			_load_actor()
		KEY_B:
			boxes = not boxes
		KEY_PAGEUP, KEY_PAGEDOWN:
			zoom = clampf(zoom * (1.2 if k == KEY_PAGEUP else 1.0 / 1.2), 0.5, 8.0)
			_load_actor()
		KEY_R:
			_load_actor()
		KEY_S:
			_save()

## Every edit round-trips through the REAL file so the adapter path is always
## the thing being proven (edit → write → rebuild from disk).
func _write_tmp_and_reload() -> void:
	_save()
	_load_actor()

func _save() -> void:
	var f := FileAccess.open(AJSON, FileAccess.WRITE)
	f.store_string(JSON.stringify(meta, "\t") + "\n")
	f.close()
	print("saved -> ", AJSON)
