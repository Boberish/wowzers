## artv2_vfx_tour.gd — the C7 visual gate. Two modes:
##
## FIGHT TOUR (default): boots THE RIFT into a live raid:tank fight and drives a
## SCRIPTED event timeline through the real HUD/stage feed — every I4 family at its
## graded intensities, the En Garde activation→hold→break chain, overlapping
## high-Flow actions over a live AnswerChannel + forced boss cast + low HP, an
## interrupt-scrub proof, and a teardown/re-entry proof (stale _post/pool law).
## Assertions print VFX TOUR CHECK lines; any FAIL flips the exit code.
##   godot --path godot --rendering-driver opengl3 --resolution 1920x1080 \
##     --script res://sim/artv2_vfx_tour.gd -- --out=/abs/dir [--profile=stack_atrium]
##     [--dash] [--actors] [--novfx] [--label=x]
## --novfx = the legacy/default-off A/B leg (same timeline, ArtV2.vfx stays false).
##
## SHEET MODE (--sheet): no fight — renders every family's frames side by side with
## a crosshair at each frame's REGISTERED PIVOT (the README's mandatory visual
## registration record for contact/release/body/ground anchors).
extends SceneTree

var out_dir := "user://shots_vfx"
var profile := ""
var label := ""
var novfx := false
var sheet := false
var hud: Node = null
var frame := -1
var fails := 0
var _sheet_fams: Array = []
var _sheet_i := 0

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr("--out=".length())
		elif a.begins_with("--profile="):
			profile = a.substr("--profile=".length())
		elif a.begins_with("--label="):
			label = a.substr("--label=".length())
		elif a == "--dash":
			ArtV2.dash = true
		elif a == "--actors":
			ArtV2.actors = true
		elif a == "--novfx":
			novfx = true
		elif a == "--sheet":
			sheet = true
	DirAccess.make_dir_recursive_absolute(out_dir)
	if sheet:
		_build_sheet()
		return
	ArtV2.scene = profile
	ArtV2.vfx = not novfx
	hud = (load("res://game/raid_main.tscn") as PackedScene).instantiate()
	root.add_child(hud)

func _shot(name: String) -> void:
	var img := root.get_texture().get_image()
	var p := out_dir.path_join("%s%s.png" % [label, name])
	img.save_png(p)
	print("  shot: ", p)

func _chk(name: String, ok: bool) -> void:
	if not ok:
		fails += 1
	print("  VFX TOUR CHECK %s: %s" % ["OK" if ok else "FAIL", name])

## one synthetic event through the REAL drain order (stage first, HUD second)
func _ev(ev: Dictionary) -> void:
	if hud._stage2d != null:
		hud._stage2d.on_event(ev)
	hud._handle_event(ev)

func _seat(i: int) -> Seat:
	return hud._ctrl.state.seats[i]

func _pool() -> VfxPool:
	return hud._stage2d._vfx if hud._stage2d != null else null

func _process(_delta: float) -> bool:
	frame += 1
	if sheet:
		return _process_sheet()
	if frame == 1:
		hud._launch("tank", "")
		# hand the local seat to AI (raid_stage_tour idiom): an idle human tank
		# wipes the party mid-timeline and tears the combat screen down under us
		hud._ctrl.state.seats[0].policy = RaidNet.make_policy("tank", 20260702)
	if hud == null or hud._ctrl == null or hud._ctrl.state == null:
		return false
	match frame:
		30:
			_shot("00_baseline")
			_chk("pool exists iff vfx on", (_pool() != null) == (not novfx))
			# capture insurance: software GL (llvmpipe) can render <15 fps, so a
			# fixed +N-frame snap would outrun a 110–260 ms flipbook. Slow every
			# playback through the pool's dev knob; bindings stay untouched.
			if _pool() != null:
				_pool().slowmo = 0.4
		35:
			_ev({"t": "duel_answer", "player": true, "seat": _seat(0), "kind": "parry",
				"grade": StrikeRes.Grade.PERFECT, "size": 2, "off_ms": 21, "id": 3})
		40:
			_shot("01_parry_great")
		70:
			_ev({"t": "duel_answer", "player": true, "seat": _seat(0), "kind": "parry",
				"grade": StrikeRes.Grade.BULLSEYE, "size": 3, "off_ms": 2, "id": 4})
		75:
			_shot("02_parry_perfect")
		110:
			for i in 4:
				_ev({"t": "duel_answer", "player": i == 0, "seat": _seat(i), "kind": "dodge",
					"grade": [StrikeRes.Grade.GRAZE, StrikeRes.Grade.GOOD,
						StrikeRes.Grade.PERFECT, StrikeRes.Grade.BULLSEYE][i],
					"size": 1, "off_ms": 40, "id": 9 + i})
		115:
			_shot("03_dodge_grades")
		150:
			_ev({"t": "duel_dump", "player": true, "seat": _seat(0), "amt": 64})
		155:
			_shot("04_dump_peak")
		163:
			_shot("04b_dump_travel")
		200:
			_ev({"t": "duel_engarde", "player": true, "seat": _seat(0)})
		212:
			_shot("05_engarde_activate")
		272:
			_shot("06_engarde_hold")
			if not novfx and _pool() != null:
				var live_eg := false
				for v in _pool()._voices:
					if (v as VfxPlayer).slot == "s0:eg" and (v as VfxPlayer).family == "engarde_hold":
						live_eg = true
				_chk("hold loop live on s0:eg", live_eg)
		280:
			_ev({"t": "duel_engarde_break", "player": true, "seat": _seat(0)})
		295:
			_shot("07_engarde_break_clean")
			if not novfx and _pool() != null:
				var eg_gone := true
				for v in _pool()._voices:
					if (v as VfxPlayer).slot == "s0:eg":
						eg_gone = false
				_chk("break stops the hold (no stale tail)", eg_gone)
		320:
			_ev({"t": "hurt", "player": true, "seat": _seat(0), "amt": 14.0, "size": 1})
		323:
			_shot("08_impact_light")
		350:
			_ev({"t": "hurt", "player": false, "seat": _seat(1), "amt": 34.0, "size": 2})
		355:
			_shot("09_impact_heavy")
		390:
			_ev({"t": "hurt", "player": true, "seat": _seat(0), "amt": 80.0, "size": 3})
		396:
			_shot("10_impact_crush")
		430:
			# THE OVERLAP — high Flow: everything at once over a live channel + a
			# forced boss cast + death's-door HP. Nothing may cover the instrument.
			_ev({"t": "duel_engarde", "player": true, "seat": _seat(0)})
			_ev({"t": "duel_answer", "player": true, "seat": _seat(0), "kind": "parry",
				"grade": StrikeRes.Grade.BULLSEYE, "size": 3, "off_ms": 1, "id": 21})
			_ev({"t": "duel_dump", "player": true, "seat": _seat(0), "amt": 90})
			_ev({"t": "hurt", "player": false, "seat": _seat(1), "amt": 30.0, "size": 1})
			_ev({"t": "hurt", "player": false, "seat": _seat(2), "amt": 45.0, "size": 2})
			_ev({"t": "hurt", "player": false, "seat": _seat(3), "amt": 70.0, "size": 3})
			_ev({"t": "coup", "player": true, "seat": _seat(0)})
			var st: CombatState = hud._ctrl.state
			_seat(0).hp = _seat(0).hp_max * 0.18   # low-HP vignette read (dev tour only)
			if hud._castbar != null:
				hud._castbar.active = true
				hud._castbar.boss_name = st.encounter.name
				hud._castbar.cast_name = "VERSE OF RUIN"
				hud._castbar.frac = 0.55
				hud._castbar.remaining = 1.4
				hud._castbar.kind = "kick"
		436:
			_shot("11_overlap_peak")
			if not novfx and _pool() != null:
				_chk("pool bounded under overlap", _pool().live_count() <= VfxPool.MAX_VOICES)
		449:
			_shot("12_overlap_settle")
		470:
			_ev({"t": "duel_answer", "player": true, "seat": _seat(0), "kind": "parry",
				"grade": StrikeRes.Grade.PERFECT, "size": 2, "off_ms": 30, "id": 33})
		478:
			# the interrupt law: a new committed answer SCRUBS the parry tail instantly
			_ev({"t": "duel_answer", "player": true, "seat": _seat(0), "kind": "dodge",
				"grade": StrikeRes.Grade.BULLSEYE, "size": 1, "off_ms": 5, "id": 34})
			if not novfx and _pool() != null:
				var fam := ""
				for v in _pool()._voices:
					if (v as VfxPlayer).slot == "s0:act":
						fam = (v as VfxPlayer).family
				_chk("new answer replaces the stale tail (dodge owns :act)", fam == "dodge")
		481:
			_shot("13_interrupt_scrub")
		510:
			# TEARDOWN + RE-ENTRY, the real idiom (clear→build in ONE stack — every
			# raid_hud caller does exactly this; _process never sees the gap):
			# _clear must null _post and drop the stage/pool refs (the H5 dangle fix).
			hud._clear()
			_chk("teardown nulls _post", hud._post == null)
			_chk("teardown nulls the stage", hud._stage2d == null)
			hud._build_combat(hud._ctrl.state)
			_chk("re-entry rebuilds _post iff vfx on", (hud._post != null) == (not novfx))
			_chk("re-entry rebuilds the pool iff vfx on", (_pool() != null) == (not novfx))
		515:
			_ev({"t": "duel_answer", "player": true, "seat": _seat(0), "kind": "parry",
				"grade": StrikeRes.Grade.BULLSEYE, "size": 2, "off_ms": 4, "id": 40})
		520:
			_shot("14_reentry")
		540:
			_chk("combat alive for the whole tour", hud._screen == "combat")
			print("VFX TOUR: %s (%s%s)" % ["ALL OK" if fails == 0 else "FAIL — %d checks" % fails,
				"novfx/" if novfx else "", profile if profile != "" else "legacy-scene"])
			quit(0 if fails == 0 else 1)
	return false

# ============================================================ SHEET MODE
## Every family's frames in a row, pivot crosshair on each — the registration record.
func _build_sheet() -> void:
	var book := VfxBook.make()
	if book == null:
		print("VFX TOUR: FAIL — sheet mode needs the delivered book")
		quit(1)
		return
	_sheet_fams = VfxBook.FAMILIES.duplicate()
	var bg := ColorRect.new()
	bg.color = Color(0.13, 0.14, 0.18)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

func _process_sheet() -> bool:
	# one family per ~12 frames: build, wait 2 frames to render, snap, tear down
	var phase := frame % 12
	if _sheet_i >= _sheet_fams.size():
		print("VFX TOUR: ALL OK (sheet — %d families)" % _sheet_fams.size())
		quit(0)
		return false
	var fam := String(_sheet_fams[_sheet_i])
	if phase == 2:
		var book := VfxBook.make()
		var host := Node2D.new()
		host.name = "sheet_host"
		root.add_child(host)
		var n := book.frame_count(fam)
		var step := 1830.0 / float(n)
		var sc := minf(0.42, step / 460.0)
		for i in n:
			var f := book.frame(fam, i)
			var at := Vector2(60.0 + step * (float(i) + 0.5), 560.0)
			var spr := Sprite2D.new()
			spr.texture = book.tex[fam]
			spr.region_enabled = true
			spr.region_rect = f["region"]
			spr.centered = false
			spr.offset = f["offset"]
			spr.position = at
			spr.scale = Vector2.ONE * sc
			host.add_child(spr)
			var cross := Node2D.new()
			cross.position = at
			cross.draw.connect(func():
				cross.draw_line(Vector2(-14, 0), Vector2(14, 0), Color(1, 0.3, 0.4, 0.9), 2.0)
				cross.draw_line(Vector2(0, -14), Vector2(0, 14), Color(1, 0.3, 0.4, 0.9), 2.0))
			host.add_child(cross)
		var lbl := Label.new()
		lbl.text = "%s · %d frames · pivot = crosshair (registration record)" % [fam, n]
		lbl.position = Vector2(60, 120)
		lbl.add_theme_font_size_override("font_size", 28)
		host.add_child(lbl)
	elif phase == 6:
		_shot("sheet_%s" % fam)
	elif phase == 8:
		var host := root.get_node_or_null("sheet_host")
		if host != null:
			host.name = "dying"
			host.queue_free()
		_sheet_i += 1
	return false
