## screenshot_seatpick.gd — visual probe of the ONLINE seat-picker (v7): the "WHO STEPS
## UP" selector + per-seat check %s. Shot 1 = the suggested CASTER (HACK reads high);
## shot 2 = switch to TANK (the same check reads base). WSLg (NOT --headless):
##   godot --path godot --script res://sim/screenshot_seatpick.gd --resolution 1920x1080 -- --out=/abs/dir
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
			var name := "seatpick_caster" if idx == 0 else "seatpick_tank"
			img.save_png(out_dir.path_join(name + ".png"))
			print("  shot: ", name)
		return false
	idx += 1
	if idx == 0:
		_bg()
		_build_panel()
		frames = 20
		return false
	if idx == 1:
		panel._select_seat("tank")            # send a NON-specialist — the %s drop
		frames = 16
		return false
	print("SEATPICK SHOTS DONE -> ", out_dir)
	return true

func _bg() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.05, 0.06)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

func _build_panel() -> void:
	# four seat builds; the caster carries the interrupt kit (best on a HACK check)
	var ctxs := {
		"tank": MapCheck.build_ctx([["guard"], ["guard"]], [], "warden", "tank", 0.85, 4, 0, {}, {}, 0),
		"blade": MapCheck.build_ctx([["rage"]], [], "tempo", "blade", 0.85, 4, 0, {}, {}, 0),
		"caster": MapCheck.build_ctx([["interrupt"], ["interrupt"], ["counter"]], [], "disruptor", "caster", 0.85, 4, 0, {}, {}, 0),
		"healer": MapCheck.build_ctx([], [], "tidecaller", "healer", 0.85, 4, 0, {}, {}, 0),
	}
	var seats := ["tank", "blade", "caster", "healer"]
	var ev := MapContent.event("helpdesk")
	var raw: Array = ev["choices"]
	var descs: Array = []
	for i in raw.size():
		var c: Dictionary = raw[i]
		var by_seat := {}
		for st in seats:
			var m := {}
			if String(c.get("kind", "")) == "check":
				var chk: Dictionary = c["check"]
				m["chance"] = int(MapCheck.chance(chk, ctxs[st])["p"])
				m["breakdown"] = MapCheck.chance(chk, ctxs[st])["parts"]
				m["ladder"] = MapCheck.nudge_ladder(chk, ctxs[st])
			by_seat[st] = m
		descs.append({"label": String(c["label"]), "kind": String(c.get("kind", "free")),
			"orig_index": i, "fx": c.get("fx", {}),
			"verb": String((c.get("check", {}) as Dictionary).get("verb", "CHECK")),
			"entropy_have": 4, "by_seat": by_seat})
	panel = MapEventPanel.new()
	panel.title_text = String(ev["title"])
	panel.body_text = String(ev["body"])
	panel.choices = descs
	panel.seats = seats
	panel.suggested = "caster"
	panel.accent = Palette.VOID
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(panel)
