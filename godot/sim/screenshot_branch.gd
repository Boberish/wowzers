## screenshot_branch.gd — visual probe of a MULTI-STAGE BRANCH (P3): the rollback_daemon
## ROOT (a "Hear the catch…" branch choice), then the "catch" SUB-PAGE it opens (a check
## that fail-forwards). WSLg (NOT --headless):
##   godot --path godot --script res://sim/screenshot_branch.gd --resolution 1920x1080 -- --out=/abs/dir
extends SceneTree

var out_dir := "user://shots"
var idx := -1
var frames := 0
var panel: MapEventPanel
var ctx: Dictionary

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr("--out=".length())
	DirAccess.make_dir_recursive_absolute(out_dir)
	ctx = MapCheck.build_ctx([["guard"], ["guard"]], [], "warden", "tank", 0.9, 3, 0, {}, {}, 0)

func _process(_d: float) -> bool:
	if frames > 0:
		frames -= 1
		if frames == 0:
			var img := root.get_texture().get_image()
			img.save_png(out_dir.path_join(("branch_root" if idx == 0 else "branch_catch") + ".png"))
			print("  shot")
		return false
	idx += 1
	var ev := MapContent.event("rollback_daemon")
	if idx == 0:
		_bg()
		_show_page(ev, "", ev.get("choices", []))
		frames = 20
		return false
	if idx == 1:
		var pg: Dictionary = ev["pages"]["catch"]
		_show_page(ev, "catch", pg["choices"])
		frames = 18
		return false
	print("BRANCH SHOTS DONE -> ", out_dir)
	return true

func _bg() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.06)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

func _show_page(ev: Dictionary, page: String, raw: Array) -> void:
	if panel != null:
		panel.queue_free()
	var src: Dictionary = ev if page == "" else (ev["pages"] as Dictionary)[page]
	var descs: Array = []
	for i in raw.size():
		var c: Dictionary = raw[i]
		var d := {"label": String(c["label"]), "kind": String(c.get("kind", "free")), "orig_index": i,
			"fx": c.get("fx", {}), "next_page": String(c.get("branch", String(c.get("goto", ""))))}
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
	panel.client_stages = true
	panel.title_text = String(src.get("title", ""))
	panel.body_text = String(src.get("body", ""))
	panel.choices = descs
	panel.accent = Palette.VOID
	panel.resolver = func(orig: int, nudge: int, attempt: int) -> Dictionary:
		return MapCheck.resolve(raw[orig], ctx, 777, 4, MapCheck.choice_slot(page, orig), attempt, {"nudge": nudge})
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(panel)
