## artv2_dash_tour.gd — fast deterministic C6C dashboard visual/geometry gate.
##
## Boots the ACTUAL raid_main + DashHostC6A, lets the real HUD build and adopt its
## widgets, then freezes only the combat drivers. Child controls keep processing,
## so their normal easing/glow/flipbook presentation remains live. The tour stages
## view fields on those REAL controls; it never mutates CombatState, a Seat, a spec,
## an input queue, or protocol truth.
##
##   godot --path godot --rendering-driver opengl3 \
##     --resolution 1920x1080 --script res://sim/artv2_dash_tour.gd -- \
##     --out=/abs/shots [--profile=stack_atrium] \
##     [--states=overview,busy,claim,feint,gather,low_hp] [--vp=1920x1080]
extends SceneTree

const ALL_STATES := ["overview", "busy", "claim", "feint", "gather", "low_hp"]
const CONTRACT_RECTS := ["party", "boss_shell", "boss_cast", "utility", "meter",
	"answer", "health", "wind", "flow", "abilities"]
const SEPARATE_ISLANDS := ["party", "boss_shell", "utility", "answer", "health",
	"wind", "flow", "abilities"]

var out_dir := "user://shots_dash"
var profile := "stack_atrium"
var states: Array[String] = []
var logical_size := Vector2i(1920, 1080)
var _vp_requested := false

var hud: Control = null
var host: DashHostC6A = null
var _phase := 0
var _settle := 0
var _state_i := 0
var _wait_frames := 0
var _resolved := false
var _fails := 0
var _shot_size := Vector2i.ZERO
var _capture_retries := 0

const MAX_CAPTURE_RETRIES := 2
const BLACK_TILE_LIMIT := 0.08

func _initialize() -> void:
	_parse_args()
	if states.is_empty():
		states.assign(ALL_STATES)
	DirAccess.make_dir_recursive_absolute(out_dir)

	# Set the logical canvas BEFORE raid_main is instantiated. Mirror it to the
	# native window as well; explicit engine --resolution is still recommended and
	# the image-dimension assertion refuses a misleading filename if a platform
	# ignores runtime window resizing.
	root.content_scale_size = logical_size
	if _vp_requested:
		root.size = logical_size
		if DisplayServer.get_name() != "headless":
			DisplayServer.window_set_size(logical_size)

	ArtV2.actors = true
	ArtV2.dash = true
	ArtV2.scene = profile
	ArtV2.vfx = false
	ArtV2.dash_debug = false
	hud = (load("res://game/raid_main.tscn") as PackedScene).instantiate()
	root.add_child(hud)

func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.substr("--out=".length())
		elif arg.begins_with("--profile="):
			profile = arg.substr("--profile=".length()).strip_edges()
		elif arg.begins_with("--states="):
			for raw in arg.substr("--states=".length()).split(",", false):
				var state := raw.strip_edges().to_lower()
				if ALL_STATES.has(state) and not states.has(state):
					states.append(state)
				elif state != "":
					push_warning("DASH TOUR: unknown state '%s' ignored" % state)
		elif arg.begins_with("--vp="):
			var bits := arg.substr("--vp=".length()).to_lower().split("x", false)
			if bits.size() == 2 and bits[0].is_valid_int() and bits[1].is_valid_int():
				var parsed := Vector2i(int(bits[0]), int(bits[1]))
				if parsed.x >= 640 and parsed.y >= 360:
					logical_size = parsed
					_vp_requested = true
				else:
					push_warning("DASH TOUR: --vp must be at least 640x360; using 1920x1080")
			else:
				push_warning("DASH TOUR: malformed --vp (expected WxH); using 1920x1080")
	if profile == "":
		profile = "stack_atrium"

func _process(_delta: float) -> bool:
	match _phase:
		0:
			# The real tank/duelist entry path. No generated substitute scene and no
			# reconstructed dashboard are used anywhere in this tour.
			hud.call("_launch", "tank", "duelist", "mistral")
			_phase = 1
		1:
			host = _find_host()
			if host == null or not host._late_done or host._rows.size() != 4:
				_settle += 1
				if _settle > 120:
					_chk("deferred dashboard adoption completed", false)
					_finish()
				return false
			_settle += 1
			if _settle < 8: # several real HUD renders feed every widget once
				return false
			_freeze_drivers()
			_hide_intro()
			_stage_common()
			_check_contract()
			_phase = 2
		2:
			if _state_i >= states.size():
				_finish()
				return false
			_resolved = false
			_stage_state(states[_state_i])
			_wait_frames = 3 # settle real controls before arming a post-draw readback
			_phase = 3
		3:
			_wait_frames -= 1
			if _wait_frames > 0:
				return false
			var state := states[_state_i]
			if not _resolved and (state == "claim" or state == "feint"):
				_stage_resolution(state)
				_resolved = true
				_wait_frames = 3
				return false
			_capture_retries = 0
			_arm_capture(state)
		4:
			# `_after_frame_draw` owns save/advance. Keeping _process idle here avoids
			# reading a framebuffer while RenderingServer is still composing it.
			pass
	return false

func _find_host() -> DashHostC6A:
	if hud == null or hud.get("_shake_root") == null:
		return null
	for child in hud._shake_root.get_children():
		if child is DashHostC6A:
			return child as DashHostC6A
	return null

func _freeze_drivers() -> void:
	# Required tour idiom: stop RaidHud's own render/feed loop only after its
	# initial construction/adoption. Child widget processes remain enabled.
	hud.set_process(false)
	if hud._ctrl != null:
		hud._ctrl.set_process(false)

func _hide_intro() -> void:
	# The normal 2.4 s ceremony would cover the instrument in a fast tour. Removing
	# this view-only transient avoids a real-time wait and touches no fight state.
	for child in hud._ui.get_children():
		if child is BossIntro:
			child.visible = false

func _chk(label: String, ok: bool) -> void:
	if not ok:
		_fails += 1
	print("  DASH TOUR CHECK %s: %s" % ["OK" if ok else "FAIL", label])

func _inside(outer: Rect2, inner: Rect2, slop := 0.75) -> bool:
	return inner.position.x >= outer.position.x - slop \
		and inner.position.y >= outer.position.y - slop \
		and inner.end.x <= outer.end.x + slop \
		and inner.end.y <= outer.end.y + slop \
		and inner.size.x > 0.0 and inner.size.y > 0.0

func _overlap_area(a: Rect2, b: Rect2) -> float:
	var ov := a.intersection(b)
	return ov.size.x * ov.size.y if ov.size.x > 0.0 and ov.size.y > 0.0 else 0.0

func _check_contract() -> void:
	_chk("Art V2 actors + scene + dash selectors enabled",
		ArtV2.actors and ArtV2.dash and ArtV2.scene == profile)
	_chk("actual DashHostC6A exists", host != null)
	if host == null:
		return
	_chk("painted DashSkin resolved", host._skin != null)
	_chk("actual DuelistBand adopted", host.band is DuelistBand)
	_chk("exactly four real party rows", host._rows.size() == 4)
	if host.band is DuelistBand:
		_chk("Wind gauge contract exposes exactly five combo sockets",
			(host.band as DuelistBand).gauge.combo_max == 5)

	var bounds := Rect2(Vector2.ZERO, host.size)
	for key in CONTRACT_RECTS:
		_chk("%s rect contained in logical viewport" % key,
			host._r.has(key) and _inside(bounds, host._r[key]))
	for i in SEPARATE_ISLANDS.size():
		for j in range(i + 1, SEPARATE_ISLANDS.size()):
			var a: String = SEPARATE_ISLANDS[i]
			var b: String = SEPARATE_ISLANDS[j]
			_chk("%s / %s islands do not overlap" % [a, b],
				_overlap_area(host._r[a], host._r[b]) <= 0.5)

func _stage_common() -> void:
	var db := host.band as DuelistBand
	# Enemy island: retain the real widget, but hold a legible tour cast open.
	hud._bar.boss_name = "MISTRAL-7B"
	hud._bar.hp = 7420.0
	hud._bar.hp_max = 10000.0
	hud._bar.phase_num = 2
	hud._bar.phase_ats = [1.0, 0.68, 0.34]
	hud._bar.enrage_in = 47.0
	hud._bar._chip = 0.79
	hud._bar._last_frac = 0.742
	_set_cast("KERNEL PANIC", "kick", 0.58, 1.7)

	# Four distinct reads prove the painted rows are live repaintings of RaidFrame.
	_stage_frame(0, 0.86, true, false, 0.08)
	_stage_frame(1, 0.68, false, true, 0.00)
	_stage_frame(2, 0.52, false, false, 0.14)
	_stage_frame(3, 0.93, false, false, 0.00)

	_set_orb(db.hp_orb, 86.0, 100.0)
	_set_orb(db.res_orb, 64.0, 100.0)
	db.gauge.wind = 7.4
	db.gauge.wind_max = 10.0
	db.gauge.combo = 3
	db.gauge.combo_max = 5
	db.gauge.fumbling = false
	for rune in [db.dodge_rune, db.parry_rune, db.dump_rune, db.engarde_rune]:
		(rune as AbilityRune).usable = true
		(rune as AbilityRune).affordable = true
		(rune as AbilityRune).cd_frac = 0.0
	if host._tab != null:
		host._tab._samples = [22.0, 31.0, 28.0, 44.0, 39.0, 57.0, 48.0, 63.0]
	if hud._aggro_warn != null:
		hud._aggro_warn.visible = false
	_reset_channel()

func _stage_frame(i: int, frac: float, debuff: bool, target: bool, shield: float) -> void:
	if i < 0 or i >= host._rows.size():
		return
	var row: DashPartyRow = host._rows[i]
	var fr := row.fr
	fr.maxhp = 1000
	fr.hp = int(round(frac * 1000.0))
	fr.frac = frac
	fr._disp_frac = frac
	fr._lag_frac = minf(1.0, frac + 0.07)
	fr._disp_hp = float(fr.hp)
	fr.absorb_frac = shield
	fr.absorb_val = shield * 1000.0
	fr.ward_remain = 4.8 if shield > 0.0 else -1.0
	fr.has_debuff = debuff
	fr.debuff_remain = 3.4 if debuff else -1.0
	fr._deb_total = 6.0 if debuff else 0.0
	fr.hots_rich = ([{"icon": "surge", "remain": 4.2, "total": 8.0, "src": "well"}]
		if i == 2 or i == 3 else [])
	fr.is_target = target
	fr.bloodied = frac < 0.35
	fr.dead = false
	fr.queue_redraw()
	row.queue_redraw()

func _set_orb(orb: LiquidOrb, value: float, maximum: float) -> void:
	orb.set_values(value, maximum)
	var frac := clampf(value / maximum, 0.0, 1.0)
	orb._disp = frac
	orb._chip = frac
	orb._prev_frac = frac
	orb.queue_redraw()

func _set_cast(title: String, kind: String, frac: float, remaining: float) -> void:
	var cast := hud._castbar as BossCastBar
	cast.active = true
	cast.boss_name = "MISTRAL-7B"
	cast.cast_name = title
	cast.kind = kind
	cast.frac = frac
	cast.remaining = remaining
	cast.window = 0.45 if kind == "kick" else 0.0
	cast.in_zone = kind == "kick" and frac >= 0.72
	cast.kickable_seat = true
	cast._alpha = 1.0
	cast.modulate.a = 1.0
	cast.visible = true
	cast.queue_redraw()

func _reset_channel() -> void:
	var ch := (host.band as DuelistBand).channel
	ch.bars = []
	ch.tbars = []
	ch.tick_frac = 0.0
	ch.tempo = 1.0
	ch.flurry = false
	ch.aggro_lost = false
	ch.horizon = 3.0
	ch.charge_tid = 0
	ch.charging = false
	ch.charge_frac = 0.0
	ch._seen.clear()
	ch._last_x.clear()
	ch._missed.clear()
	ch._flashes.clear()
	ch._stamps.clear()
	ch._deaths.clear()
	ch._verdicts.clear()
	ch._rail.clear()
	ch._shards.clear()
	ch._gate_pulse = 0.0
	ch._gate_bloom = 0.0
	ch._edge_flash = 0.0
	ch._press_flash = 0.0
	ch._dud_t = 0.0
	ch.queue_redraw()

func _bar(id: int, kind: String, eta: float, size: int, purple := false,
		peeled := false, answered := false) -> Dictionary:
	return {"id": id, "kind": kind, "eta": eta, "size": size,
		"purple": purple, "peeled": peeled, "answered": answered}

func _stage_state(state: String) -> void:
	_stage_common()
	var db := host.band as DuelistBand
	var ch := db.channel
	match state:
		"overview":
			ch.bars = [
				_bar(101, "auto", 2.34, AbilityRes.Size.LIGHT),
				_bar(102, "global", 1.76, AbilityRes.Size.HEAVY),
				_bar(103, "heavy", 1.12, AbilityRes.Size.HEAVY),
				_bar(104, "auto", 0.54, AbilityRes.Size.LIGHT),
			]
		"busy":
			ch.flurry = true
			ch.tempo = 1.25
			ch.bars = [
				_bar(111, "auto", 2.62, AbilityRes.Size.LIGHT),
				_bar(112, "global", 2.20, AbilityRes.Size.HEAVY),
				_bar(113, "auto", 1.82, AbilityRes.Size.LIGHT),
				_bar(114, "heavy", 1.42, AbilityRes.Size.HEAVY),
				_bar(115, "global", 1.03, AbilityRes.Size.HEAVY),
				_bar(116, "auto", 0.64, AbilityRes.Size.LIGHT),
				_bar(117, "heavy", 0.28, AbilityRes.Size.CRUSH),
			]
			_set_orb(db.res_orb, 92.0, 100.0)
			db.gauge.combo = 5
		"claim":
			ch.bars = [
				_bar(201, "heavy", 0.08, AbilityRes.Size.HEAVY),
				_bar(202, "auto", 1.20, AbilityRes.Size.LIGHT),
				_bar(203, "global", 2.05, AbilityRes.Size.HEAVY),
			]
		"feint":
			# A fake can wear ANY actionable shape; all three remain purple.
			ch.bars = [
				_bar(301, "auto", 0.10, AbilityRes.Size.LIGHT, true),
				_bar(302, "global", 0.96, AbilityRes.Size.HEAVY, true),
				_bar(303, "heavy", 1.78, AbilityRes.Size.CRUSH, true),
				_bar(304, "auto", 2.42, AbilityRes.Size.LIGHT),
			]
		"gather":
			ch.bars = [
				_bar(401, "auto", 1.34, AbilityRes.Size.LIGHT),
				_bar(402, "global", 2.16, AbilityRes.Size.HEAVY),
			]
			ch.tbars = [_bar(-410, "buster", 0.72, AbilityRes.Size.CRUSH)]
			ch.charge_tid = -410
			ch.charging = true
			ch.charge_frac = 0.72
			ch.charge_min = 0.50
			ch.charge_full = 0.90
			db.parry_rune.kick()
		"low_hp":
			_set_orb(db.hp_orb, 18.0, 100.0)
			_stage_frame(0, 0.18, true, true, 0.04)
			_set_cast("TOTAL SYSTEM FAILURE", "brace", 0.82, 0.7)
			ch.bars = [
				_bar(501, "heavy", 0.42, AbilityRes.Size.CRUSH),
				_bar(502, "global", 1.08, AbilityRes.Size.HEAVY),
				_bar(503, "auto", 1.78, AbilityRes.Size.LIGHT, false, true),
			]
			db.gauge.wind = 2.1
			db.dodge_rune.affordable = false
	ch.queue_redraw()
	db.gauge.queue_redraw()

func _stage_resolution(state: String) -> void:
	var ch := (host.band as DuelistBand).channel
	if state == "claim":
		ch.press_tick("parry")
		ch.resolve(201, "bullseye", "PARRY!", "+2ms")
	else:
		ch.resolve(301, "read", "READ", "— fake")

func _safe_profile() -> String:
	var out := ""
	for c in profile.to_lower():
		out += c if (c >= "a" and c <= "z") or (c >= "0" and c <= "9") else "_"
	return out.trim_prefix("_").trim_suffix("_")

func _arm_capture(state: String) -> void:
	if DisplayServer.get_name() == "headless":
		_chk("%s capture needs a rendering display (do not pass --headless)" % state, false)
		_state_i += 1
		_phase = 2
		return
	RenderingServer.frame_post_draw.connect(_after_frame_draw.bind(state), CONNECT_ONE_SHOT)
	_phase = 4

func _opaque_black_ratio(img: Image) -> float:
	# Native OpenGL can occasionally return an opaque-black tile mosaic when
	# several capture processes contend. Legitimate UI blacks are near-black and
	# occupy little area; the corruption is exact black across large 8px samples.
	var black := 0
	var total := 0
	for y in range(0, img.get_height(), 8):
		for x in range(0, img.get_width(), 8):
			var c := img.get_pixel(x, y)
			total += 1
			if c.a >= 0.99 and maxf(c.r, maxf(c.g, c.b)) <= 0.002:
				black += 1
	return float(black) / float(maxi(1, total))

func _after_frame_draw(state: String) -> void:
	var img := root.get_texture().get_image()
	if img == null:
		_chk("%s viewport image is available" % state, false)
		_state_i += 1
		_phase = 2
		return
	var black_ratio := _opaque_black_ratio(img)
	if black_ratio >= BLACK_TILE_LIMIT and _capture_retries < MAX_CAPTURE_RETRIES:
		_capture_retries += 1
		print("  DASH TOUR RETRY: %s capture sampled %.1f%% opaque black (attempt %d/%d)" % [
			state, black_ratio * 100.0, _capture_retries, MAX_CAPTURE_RETRIES])
		call_deferred("_arm_capture", state)
		return
	var clean_pixels := black_ratio < BLACK_TILE_LIMIT
	_chk("%s capture has no opaque-black tile corruption" % state, clean_pixels)
	var actual := img.get_size()
	var nonzero := actual.x > 0 and actual.y > 0
	var stable := _shot_size == Vector2i.ZERO or actual == _shot_size
	var requested := not _vp_requested or actual == logical_size
	_chk("%s capture has stable non-zero dimensions" % state, nonzero and stable)
	_chk("%s capture matches requested logical dimensions" % state, requested)
	if clean_pixels and nonzero and stable and requested:
		if _shot_size == Vector2i.ZERO:
			_shot_size = actual
		_save(state, img)
	else:
		var stale := _shot_path(state)
		if FileAccess.file_exists(stale):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(stale))
		print("  shot skipped: invalid capture for ", state)
	_state_i += 1
	_phase = 2

func _shot_path(state: String) -> String:
	var name := "%s_%dx%d_%s.png" % [
		_safe_profile(), logical_size.x, logical_size.y, state]
	return out_dir.path_join(name)

func _save(state: String, img: Image) -> void:
	var actual := img.get_size()
	var path := _shot_path(state)
	var err := img.save_png(path)
	_chk("%s PNG saved" % state, err == OK and FileAccess.file_exists(path))
	var disk := Image.load_from_file(path)
	_chk("%s saved PNG dimensions verified" % state,
		disk != null and disk.get_size() == actual)
	print("  shot: ", path, "  (", actual.x, "x", actual.y, ")")

func _finish() -> void:
	print("DASH TOUR: %s — %d state(s), profile '%s', logical %dx%d" % [
		"ALL OK" if _fails == 0 else "FAIL (%d checks)" % _fails,
		_state_i, profile, logical_size.x, logical_size.y])
	quit(0 if _fails == 0 else 1)
