## PaintedActor2D — the C4 PAINTED ACTOR ADAPTER (GRAPHICS-PLAN §5·C4, §2.1).
## A class-agnostic, native, reusable layered actor: it consumes the documented
## folder/metadata contract (`game/art_v2/ACTORS.md` — actor.json + parts/ +
## frames/) and satisfies the full Actor2D verb surface, so the stage never
## learns class-specific art details. Three part modes:
##   RIGID       — a Sprite2D layer (weapon, plate, head): offsets/rotations only
##   DEFORM      — a Polygon2D warp quad (cloth, cloak): hem sways at render rate
##   REPLACEMENT — whole-figure contact/extreme drawings swapped in for one beat
##     (windup_<kind> scrubbed by amt · swing_<kind> flashed at release)
## LAWS: zero combat/gameplay state (verbs in, pixels out — reads NOTHING) ·
## render-rate motion only (idle/breath/sway are cosmetic wall-clock; windup is
## SCRUBBED deterministically from the amt the engine feeds every frame) · all
## textures + metadata resolved AT CONSTRUCTION (SCENES.md §3½ — no I/O in any
## draw/process path) · missing or invalid folder/json/parts ⇒ try_make returns
## null and the caller falls back to the legacy actor (C1 fail-safe; the legacy
## factory and its post-purge fallthrough stay byte-untouched) · NO Spine —
## pure native nodes behind the Actor2D contract (the Spine door stays a door).
class_name PaintedActor2D
extends Actor2D

const ACTORS_DIR := "res://game/art_v2/actors"

## THE ONE DOOR (called from ArtV2.make_actor, flag-gated): resolve the id's
## folder (aspect variant `<id>_<aspect>/` wins over `<id>/`), parse + build.
## Any failure ⇒ null ⇒ the legacy puppet. Never throws, never half-builds.
static func try_make(id: String, aspect := "") -> PaintedActor2D:
	var candidates: Array[String] = []
	if aspect != "":
		candidates.append("%s/%s_%s" % [ACTORS_DIR, id, aspect])
	candidates.append("%s/%s" % [ACTORS_DIR, id])
	for dir in candidates:
		var meta := _load_meta(dir)
		if meta.is_empty():
			continue
		var a := PaintedActor2D.new()
		if a._build(dir, meta):
			return a
		a.free()   # metadata parsed but zero parts built — clean fallback
	return null

static func _load_meta(dir: String) -> Dictionary:
	var path := dir + "/actor.json"
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if parsed is Dictionary and (parsed as Dictionary).has("parts"):
		return parsed
	push_warning("PaintedActor2D: invalid actor.json at %s — legacy actor" % path)
	return {}

var _rig: Node2D                       ## the layered parts root (hidden while a replacement frame shows)
var _parts: Dictionary = {}            ## part name -> Node2D
var _deforms: Array[Polygon2D] = []    ## warp quads animated in _process
var _frames: Dictionary = {}           ## "windup_heavy" etc -> Texture2D (resolved at build)
var _swap: Sprite2D                    ## the replacement-frame display
var _gaze: Polygon2D                   ## the boss-gaze diamond (set_highlight)
var _glow_part: Node2D = null          ## optional part that reads power_glow
var _height := 300.0                   ## figure height (gaze placement, swap anchor)
var _poses: Dictionary = {}            ## C5: pose name -> {part: radians DELTA from base} ("root" = the rig)
var _base_rot: Dictionary = {}         ## part name -> authored base rotation (rad)
var _scale_base := 1.0
var _t := 0.0                          ## cosmetic clock (idle only — never gameplay)
var _scrub := 0.0                      ## windup amt, fed by the engine every frame
var _swing_t := 0.0                    ## replacement swing-frame time left
var _enraged := false

## Build the whole node tree + resolve every texture NOW (§3½: construction-
## time I/O only). json array order = paint order (first = deepest). Returns
## false when no part could be built — the caller frees us and falls back.
func _build(dir: String, meta: Dictionary) -> bool:
	_scale_base = float(meta.get("scale", 1.0))
	_height = float(meta.get("height", 300.0))
	_rig = Node2D.new()
	_rig.scale = Vector2.ONE * _scale_base
	add_child(_rig)
	var built := 0
	var parts: Array = meta.get("parts", [])
	for p_v in parts:
		if not (p_v is Dictionary):
			continue
		var p: Dictionary = p_v
		var tex_path := "%s/%s" % [dir, String(p.get("tex", ""))]
		if not ResourceLoader.exists(tex_path, "Texture2D"):
			push_warning("PaintedActor2D: part '%s' texture missing (%s) — part skipped" % [String(p.get("name", "?")), tex_path])
			continue
		var tex := load(tex_path) as Texture2D
		var node: Node2D
		if String(p.get("mode", "rigid")) == "deform":
			node = _make_deform(tex, p)
		else:
			node = _make_rigid(tex, p)
		var at: Array = p.get("at", [0, 0])
		node.position = Vector2(float(at[0]), float(at[1]))
		node.rotation = deg_to_rad(float(p.get("rot", 0.0)))
		node.scale = Vector2.ONE * float(p.get("scale", 1.0))   # C5.1: per-part registration scale
		var parent_node: Node2D = _parts.get(String(p.get("parent", "")), _rig)
		parent_node.add_child(node)
		var pname := String(p.get("name", "part%d" % built))
		_parts[pname] = node
		built += 1
	if built == 0:
		return false
	for pname in _parts:
		_base_rot[pname] = (_parts[pname] as Node2D).rotation
	var poses: Dictionary = meta.get("poses", {})
	for pose_name in poses:
		var src: Dictionary = poses[pose_name]
		var conv: Dictionary = {}
		for part in src:
			conv[String(part)] = deg_to_rad(float(src[part]))
		_poses[String(pose_name)] = conv
	if meta.has("glow_part"):
		_glow_part = _parts.get(String(meta["glow_part"]))
	var frames: Dictionary = meta.get("frames", {})
	for k in frames:
		var fp := "%s/%s" % [dir, String(frames[k])]
		if ResourceLoader.exists(fp, "Texture2D"):
			_frames[String(k)] = load(fp) as Texture2D
	_swap = Sprite2D.new()
	_swap.centered = false
	# C5.1: frames_scale matches the replacement drawings' apparent size to the
	# layered rig (both are authored figures; parity is a registration number)
	_swap.scale = Vector2.ONE * _scale_base * float(meta.get("frames_scale", 1.0))
	_swap.visible = false
	add_child(_swap)
	_gaze = Polygon2D.new()
	var g := 10.0
	_gaze.polygon = PackedVector2Array([Vector2(0, -g), Vector2(g, 0), Vector2(0, g), Vector2(-g, 0)])
	_gaze.color = Color(1.0, 0.85, 0.35, 0.9)
	_gaze.position = Vector2(0, -_height * _scale_base - 22.0)
	_gaze.visible = false
	add_child(_gaze)
	return true

func _make_rigid(tex: Texture2D, p: Dictionary) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	var anch: Array = p.get("anchor", [0.5, 0.5])
	s.offset = Vector2(-float(anch[0]) * tex.get_width(), -float(anch[1]) * tex.get_height())
	return s

## The warp quad: 6 verts (corners + side midpoints); the lower half sways.
func _make_deform(tex: Texture2D, p: Dictionary) -> Polygon2D:
	var w := float(tex.get_width())
	var h := float(tex.get_height())
	var poly := Polygon2D.new()
	poly.texture = tex
	var pts := PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h * 0.55),
		Vector2(w, h), Vector2(0, h), Vector2(0, h * 0.55)])
	poly.polygon = pts
	poly.uv = pts
	var anch: Array = p.get("anchor", [0.5, 0.0])
	poly.offset = Vector2(-float(anch[0]) * w, -float(anch[1]) * h)
	poly.set_meta("base", pts)
	poly.set_meta("sway", float(p.get("sway", 6.0)))
	_deforms.append(poly)
	return poly

# ---------------------------------------------------------------- render-rate
func _process(delta: float) -> void:
	_t += delta
	if _swing_t > 0.0:
		_swing_t -= delta
		if _swing_t <= 0.0 and _scrub <= 0.0:
			_hide_swap()
	# idle breath — suspended while a windup scrub owns the silhouette
	if _scrub <= 0.0 and _rig.visible:
		_rig.scale.y = _scale_base * (1.0 + 0.014 * sin(_t * 2.3))
	var k := 0
	for poly in _deforms:
		var base: PackedVector2Array = poly.get_meta("base")
		var sway := float(poly.get_meta("sway"))
		var pts := PackedVector2Array(base)
		for i in [2, 3, 4, 5]:   # lower-half verts: hem sways, shoulders pinned
			var depth := (base[i].y / base[3].y)
			pts[i].x = base[i].x + sin(_t * 1.9 + float(k) * 1.7 + base[i].x * 0.01) * sway * depth
		poly.polygon = pts
		k += 1

func _show_swap(tex: Texture2D) -> void:
	_swap.texture = tex
	_swap.offset = Vector2(-tex.get_width() * 0.5, -float(tex.get_height()))
	_swap.visible = true
	_rig.visible = false

func _hide_swap() -> void:
	_swap.visible = false
	_rig.visible = true

func _flash(col: Color) -> void:
	modulate = col
	var tw := create_tween()
	tw.tween_property(self, "modulate", (Color(1.0, 0.82, 0.82) if _enraged else Color.WHITE), 0.28)

# ------------------------------------------------- C5: the data-driven poses
## Apply a named pose at weight w (0..1): every listed part rotates base+delta*w;
## "root" tilts the whole rig. Returns false when the actor has no such pose —
## callers fall back to the C4 generic motion (class-agnostic law).
func _pose_lerp(pose_name: String, w: float) -> bool:
	if not _poses.has(pose_name):
		return false
	var pose: Dictionary = _poses[pose_name]
	for part in pose:
		var d := float(pose[part]) * w
		if String(part) == "root":
			_rig.rotation = d
		else:
			var n: Node2D = _parts.get(String(part))
			if n != null:
				n.rotation = float(_base_rot.get(String(part), 0.0)) + d
	return true

func _pose_reset() -> void:
	_rig.rotation = 0.0
	for part in _base_rot:
		var n: Node2D = _parts.get(String(part))
		if n != null:
			n.rotation = float(_base_rot[part])

## Snap a pose on, hold it a beat, then ease every affected part home.
func _pose_flash(pose_name: String, hold: float, back: float) -> bool:
	if not _pose_lerp(pose_name, 1.0):
		return false
	var pose: Dictionary = _poses[pose_name]
	var tw := create_tween()
	tw.tween_interval(hold)
	tw.tween_callback(func():
		var tb := create_tween()
		tb.set_parallel(true)
		for part in pose:
			if String(part) == "root":
				tb.tween_property(_rig, "rotation", 0.0, back)
			else:
				var n: Node2D = _parts.get(String(part))
				if n != null:
					tb.tween_property(n, "rotation", float(_base_rot.get(String(part), 0.0)), back))
	return true

# ============================================================ the Actor2D verbs
func act(_id: String, flourish := false) -> Dictionary:
	var tw := create_tween()
	tw.tween_property(_rig, "position:x", 18.0, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_rig, "position:x", 0.0, 0.15)
	return {"delay": 0.10, "kind": ("coup" if flourish else "slash")}

## SCRUBBED: called EVERY FRAME with amt 0..1 — the pose is a pure function of
## amt (same amt in ⇒ same silhouette out; timing truth stays the engine's).
func windup(kind: String, amt: float) -> void:
	_scrub = clampf(amt, 0.0, 1.0)
	var fk := "windup_" + kind
	if _frames.has(fk):
		_show_swap(_frames[fk])
		_swap.rotation = -0.10 * _scrub
		_swap.position = Vector2(-6.0 * _scrub, 5.0 * _scrub)
		return
	if _pose_lerp("windup", _scrub):        # C5 authored coil (torso chain — legs planted)
		_rig.position = Vector2(-8.0 * _scrub, 0.0)   # step-back slides ALONG the baseline
		return
	_rig.rotation = -0.30 * _scrub          # generic coil (no authored pose)
	_rig.position = Vector2(-8.0 * _scrub, 0.0)

func clear_windup() -> void:
	_scrub = 0.0
	if _swing_t <= 0.0:
		_hide_swap()
	_pose_reset()
	_rig.position = Vector2.ZERO

func swing(kind: String) -> void:
	_scrub = 0.0
	_pose_reset()
	_rig.position = Vector2.ZERO
	var fk := "swing_" + kind
	if _frames.has(fk):
		_show_swap(_frames[fk])
		_swing_t = 0.16
		_pose_flash("swing", 0.05, 0.18)   # the rig un-hides already easing home
		return
	_pose_flash("swing", 0.05, 0.20)       # authored thrust (falls through silently if absent)
	var tw := create_tween()
	tw.tween_property(_rig, "position:x", 26.0, 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_rig, "position:x", 0.0, 0.18)

func curse_release() -> void:
	_flash(Color(0.75, 0.45, 0.95))

# --- reacts ---
func evade_react() -> void:
	_pose_flash("parry", 0.06, 0.22)       # the deflection flick (blade up, weight back)
	var tw := create_tween()
	tw.tween_property(_rig, "position:x", -22.0, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_rig, "position:x", 0.0, 0.16)

func hop_react(clean: bool) -> void:
	var tw := create_tween()
	tw.tween_property(_rig, "position:y", -26.0 if clean else -16.0, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_rig, "position:y", 0.0, 0.14).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func graze_react() -> void:
	_flash(Color(0.85, 0.85, 0.9))

func stumble_react() -> void:
	var tw := create_tween()
	tw.tween_property(_rig, "rotation", 0.16, 0.10)
	tw.tween_property(_rig, "rotation", 0.0, 0.22)

func brace_react() -> void:
	var tw := create_tween()
	tw.tween_property(_rig, "scale:y", _scale_base * 0.93, 0.08)
	tw.tween_property(_rig, "scale:y", _scale_base, 0.16)

func hit_react(big: bool) -> void:
	_flash(Color(1.0, 0.35, 0.35) if big else Color(1.0, 0.6, 0.6))
	var tw := create_tween()
	tw.tween_property(_rig, "position:x", -14.0 if big else -8.0, 0.05)
	tw.tween_property(_rig, "position:x", 0.0, 0.14)

func slump_react() -> void:
	var tw := create_tween()
	tw.tween_property(_rig, "rotation", 0.10, 0.20)
	tw.tween_property(_rig, "rotation", 0.0, 0.30)

func cast_react(_id: String) -> void:
	_flash(Color(0.6, 0.85, 1.0))

func stagger_anim() -> void:
	var tw := create_tween()
	for i in 3:
		tw.tween_property(_rig, "position:x", 10.0 - 6.0 * float(i), 0.05)
		tw.tween_property(_rig, "position:x", -8.0 + 5.0 * float(i), 0.05)
	tw.tween_property(_rig, "position:x", 0.0, 0.06)

func heal_flash() -> void:
	_flash(Color(0.55, 1.0, 0.6))

# --- state-driven looks ---
func power_glow(frac: float) -> void:
	if _glow_part != null:
		_glow_part.modulate = Color.WHITE.lerp(Color(1.0, 0.85, 0.4), clampf(frac, 0.0, 1.0))

func set_highlight(on: bool) -> void:
	_gaze.visible = on

func set_enrage(on: bool) -> void:
	_enraged = on
	modulate = Color(1.0, 0.82, 0.82) if on else Color.WHITE

func variant(_id: String) -> void:
	pass   # per-encounter reskins are a C5+/Codex concern — ids resolve folders

func die() -> void:
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_rig, "rotation", -PI * 0.5, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "modulate:a", 0.45, 0.6)

func win() -> void:
	var tw := create_tween()
	for i in 2:
		tw.tween_property(_rig, "position:y", -20.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(_rig, "position:y", 0.0, 0.14)
