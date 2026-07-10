## screenshot_event.gd — visual probe of the Inference Check event panel (prompt with
## the % + itemized breakdown + ⚡ nudge stepper, then the ✓/✗ result). WSLg (NOT --headless):
##   godot --path godot --script res://sim/screenshot_event.gd --resolution 1920x1080 -- --out=/abs/dir
extends SceneTree

var out_dir := "user://shots"
var idx := -1
var frames := 0
var panel: MapEventPanel

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr("--out=".length())
	DirAccess.make_dir_recursive_absolute(out_dir)

func _process(_d: float) -> bool:
	if frames > 0:
		frames -= 1
		if frames == 0:
			var img := root.get_texture().get_image()
			var name := "event_prompt" if idx == 0 else "event_result"
			var path := out_dir.path_join(name + ".png")
			img.save_png(path)
			print("  shot: ", path)
		return false
	idx += 1
	if idx == 0:
		_bg()
		_build_panel()
		frames = 20
		return false
	if idx == 1:
		# feed 2 ⚡ to the HACK check, then commit → the ✓/✗ result view
		panel._adjust_nudge(1, 2)
		panel._on_press(panel.choices[1], 1)
		frames = 16
		return false
	print("EVENT SHOTS DONE -> ", out_dir)
	return true

func _bg() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.06)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

func _build_panel() -> void:
	# a caster with two interrupt boons, holding ⚡4 — the HACK check reads high + nudgeable
	var ctx := MapCheck.build_ctx([["interrupt"], ["interrupt"]], [], "disruptor", "caster",
		1.0, 4, 0, {}, {}, 0)
	var ev := MapContent.event("helpdesk")
	var raw: Array = ev["choices"]
	var descs: Array = []
	for i in raw.size():
		var c: Dictionary = raw[i]
		var d := {"label": String(c["label"]), "kind": String(c.get("kind", "free")),
			"orig_index": i, "fx": c.get("fx", {})}
		if String(c.get("kind", "")) == "check":
			var chk: Dictionary = c["check"]
			var info := MapCheck.chance(chk, ctx)
			d["chance"] = int(info["p"])
			d["breakdown"] = info["parts"]
			d["verb"] = String(chk.get("verb", "CHECK"))
			d["entropy_have"] = int(ctx["entropy"])
			d["nudge_ladder"] = MapCheck.nudge_ladder(chk, ctx)
		descs.append(d)
	panel = MapEventPanel.new()
	panel.title_text = String(ev["title"])
	panel.body_text = String(ev["body"])
	panel.choices = descs
	panel.accent = Palette.VOID
	panel.resolver = func(orig: int, nudge: int, attempt: int) -> Dictionary:
		return MapCheck.resolve(raw[orig], ctx, 999, 3, orig, attempt, {"nudge": nudge})
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(panel)
