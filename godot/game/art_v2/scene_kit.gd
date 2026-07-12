## SceneKit — the Scene Profile host (GRAPHICS-PLAN Packet C2, the §2.2 law).
## An encounter selects a PROFILE; a profile composes SIX independent layers,
## never a baked screenshot:
##   1 backdrop · 2 distant life · 3 midground · 4 combat floor ·
##   5 encounter dressing · 6 atmosphere + palette
## Profiles are PURE DATA (the PROFILES dict); the host reads layer specs and
## draws them — C3 teaches these layers to consume Codex-generated textures, the
## contract here does not change. The two v2_*_test profiles are TEMPORARY
## COLORED/DEBUG layers only (the §2.2 interior/exterior contrast-pair proof
## harness) — no art, deliberately placeholder-looking, watermarked on screen.
##
## LAWS (§2.2 + C2 constraints): profiles change art/palette/light/ambience but
## NEVER actor scale/feet (RaidStage2D.SLOTS is untouched — this node only sits
## behind the stage), combat geometry, input, or UI truth. Aspect-expand safe:
## wider aspects GROW design width, so every side layer repeats/extends from
## live `size` (never stretched key art). Profile "" / "legacy" / unknown ⇒ the
## existing StageBackdrop UNCHANGED — absence returns legacy, the C1 fail-safe.
## Placeholder dressing stays BEHIND the stage; true foreground occluders are a
## post-C3 problem (they need a second host slot in front of the actors).
class_name SceneKit
extends Control

## Matches the legacy StageBackdrop floor line (h*0.80); the raiders' feet ride
## RaidStage2D.SLOTS fractions (0.775–0.790) just above it. View-only echo.
const FLOOR_Y := 0.80
## Where the boss stands (echoes RaidStage2D.BOSS_AT.x) — pools/dressing aim here.
const FOCUS_X := 0.72

## THE PROFILES — pure data, six layer specs each. Debug palettes only:
## interior = the dark bound-chamber test, exterior = bright readable daylight
## (SUNPRINT CEL's default world is the bright one — the dark room is contrast).
const PROFILES := {
	"v2_interior_test": {
		"backdrop": {"top": Color(0.07, 0.08, 0.13), "bottom": Color(0.13, 0.13, 0.20)},
		"distant": {"kind": "machinery", "color": Color(0.16, 0.17, 0.26, 0.85), "count": 6},
		"midground": {"kind": "pipes", "color": Color(0.10, 0.10, 0.17, 0.92),
			"edge": Color(0.30, 0.42, 0.52, 0.35), "spacing": 0.16},
		"floor": {"color": Color(0.09, 0.09, 0.14), "line": Color(0.36, 0.50, 0.62, 0.45),
			"pool": Color(0.30, 0.55, 0.70, 0.05)},
		"dressing": {"kind": "blocks", "color": Color(0.05, 0.05, 0.09, 0.95),
			"edge": Color(0.30, 0.42, 0.52, 0.28)},
		"atmosphere": {"particles": Color(0.45, 0.75, 0.95), "rise": true,
			"tint": Color(0.30, 0.45, 0.80, 0.05)},
	},
	"v2_exterior_test": {
		"backdrop": {"top": Color(0.36, 0.62, 0.90), "bottom": Color(0.92, 0.88, 0.66)},
		"distant": {"kind": "clouds", "color": Color(1.0, 1.0, 1.0, 0.85), "count": 5},
		"midground": {"kind": "trees", "color": Color(0.28, 0.52, 0.30, 0.95),
			"edge": Color(0.16, 0.34, 0.20, 0.9), "spacing": 0.14},
		"floor": {"color": Color(0.55, 0.62, 0.34), "line": Color(0.35, 0.44, 0.22, 0.8),
			"pool": Color(1.0, 0.95, 0.60, 0.10)},
		"dressing": {"kind": "posts", "color": Color(0.42, 0.32, 0.22, 0.95),
			"edge": Color(0.85, 0.78, 0.60, 0.5)},
		"atmosphere": {"particles": Color(1.0, 0.95, 0.70), "rise": false,
			"tint": Color(1.0, 0.92, 0.55, 0.04)},
	},
}

## THE ONE DOOR (wired behind ArtV2.make_scene): known profile ⇒ a SceneKit
## host; "" / "legacy" / unknown ⇒ the legacy StageBackdrop, byte-for-byte.
static func make(profile_id: String, is_combat := true) -> Control:
	if profile_id != "" and profile_id != "legacy":
		if PROFILES.has(profile_id):
			return SceneKit.new(profile_id)
		push_warning("SceneKit: unknown scene profile '%s' — legacy backdrop" % profile_id)
	return StageBackdrop.new(is_combat)

var profile_id := ""
var spec: Dictionary = {}

var _distant_l: Control
var _atmos: CPUParticles2D
var _t := 0.0
# fixed offset tables so shapes are stable frame-to-frame (no unseeded randomness)
# typed: an untyped const Array indexes to Variant and breaks every `:=` inference
# downstream (the CLAUDE.md parse-cascade gotcha — this file killed boot on 2026-07-12)
const _DRIFT: Array[float] = [0.05, 0.38, 0.62, 0.20, 0.81, 0.50, 0.12, 0.70]
const _BOB: Array[float] = [0.0, 0.6, -0.4, 0.8, -0.7, 0.3, -0.5, 0.15]

func _init(p: String) -> void:
	profile_id = p
	spec = PROFILES.get(p, {})
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	# six layers, back to front — each a full-rect draw surface fed by its spec
	_layer(_paint_backdrop)
	_distant_l = _layer(_paint_distant)
	_layer(_paint_midground)
	_layer(_paint_floor)
	_layer(_paint_dressing)
	_atmos = _make_atmosphere()
	add_child(_atmos)
	var tint := _layer(_paint_tint)   # the palette half of layer 6
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	tint.material = add
	# C2 watermark: these are debug layers — say so on every screenshot
	var tag := Label.new()
	tag.text = "SCENEKIT · %s · C2 placeholder" % profile_id
	tag.add_theme_font_size_override("font_size", 11)
	tag.add_theme_color_override("font_color", Color(1, 1, 1, 0.30))
	tag.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	tag.position = Vector2(10, -24)
	add_child(tag)
	resized.connect(_relayout)
	_relayout()

func _layer(painter: Callable) -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(painter.bind(c))
	add_child(c)
	return c

func _relayout() -> void:
	if _atmos != null:
		_atmos.position = Vector2(size.x * 0.5, size.y * (FLOOR_Y - 0.05))
		_atmos.emission_rect_extents = Vector2(size.x * 0.45, size.y * 0.30)
	for c in get_children():
		if c is Control:
			(c as Control).queue_redraw()

func _process(delta: float) -> void:
	_t += delta
	if _distant_l != null:
		_distant_l.queue_redraw()   # the only animated draw layer (drift)

# ---------------------------------------------------------------- 1 · backdrop
func _paint_backdrop(ci: Control) -> void:
	var w := ci.size.x
	var h := ci.size.y
	if w <= 0.0 or h <= 0.0:
		return
	var d: Dictionary = spec.get("backdrop", {})
	var top: Color = d.get("top", Color.BLACK)
	var bot: Color = d.get("bottom", Color.BLACK)
	ci.draw_polygon(
		PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
		PackedColorArray([top, top, bot, bot]))

# ------------------------------------------------------------- 2 · distant life
func _paint_distant(ci: Control) -> void:
	var w := ci.size.x
	var h := ci.size.y
	if w <= 0.0 or h <= 0.0:
		return
	var d: Dictionary = spec.get("distant", {})
	var col: Color = d.get("color", Color.WHITE)
	var n := int(d.get("count", 5))
	for i in n:
		var f := _DRIFT[i % _DRIFT.size()]
		if String(d.get("kind", "")) == "clouds":
			# drifting ellipses; wrap across the LIVE width (aspect-expand safe)
			var cx := fposmod(f * w + _t * (6.0 + 3.0 * f), w + 240.0) - 120.0
			var cy := h * (0.10 + 0.16 * _BOB[i % _BOB.size()] * 0.5 + 0.10 * f)
			ci.draw_set_transform(Vector2(cx, cy), 0.0, Vector2(2.6, 1.0))
			ci.draw_circle(Vector2.ZERO, h * (0.028 + 0.02 * f), col)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			# hung machinery: slow-swaying chained blocks off the ceiling
			var cx2 := (f * 0.9 + 0.05) * w
			var sway := sin(_t * 0.5 + f * TAU) * w * 0.004
			var drop := h * (0.10 + 0.10 * _BOB[i % _BOB.size()] * 0.5 + 0.06)
			ci.draw_line(Vector2(cx2, 0), Vector2(cx2 + sway, drop), col, 2.0, true)
			ci.draw_rect(Rect2(cx2 + sway - h * 0.018, drop, h * 0.036, h * 0.05), col)

# --------------------------------------------------------------- 3 · midground
func _paint_midground(ci: Control) -> void:
	var w := ci.size.x
	var h := ci.size.y
	if w <= 0.0 or h <= 0.0:
		return
	var d: Dictionary = spec.get("midground", {})
	var col: Color = d.get("color", Color.DIM_GRAY)
	var edge: Color = d.get("edge", Color.GRAY)
	var floor_y := h * FLOOR_Y
	# REPEATABLE framing elements at fixed spacing across the LIVE width — a
	# 2560×1080 canvas simply gets more of them (§2.2: sides grow, never stretch)
	var spacing: float = maxf(80.0, h * float(d.get("spacing", 0.15)) * 1.9)
	var n := int(ceil(w / spacing)) + 1
	for i in n:
		var cx := (float(i) + 0.5) * spacing
		if String(d.get("kind", "")) == "trees":
			var trunk_w := h * 0.012
			ci.draw_rect(Rect2(cx - trunk_w, floor_y - h * 0.16, trunk_w * 2.0, h * 0.16), edge)
			ci.draw_circle(Vector2(cx, floor_y - h * 0.20), h * (0.055 + 0.015 * _BOB[i % _BOB.size()]), col)
		else:
			# industrial pipe columns with a lit edge (the interior framing)
			var pw := h * 0.020
			ci.draw_rect(Rect2(cx - pw, h * 0.18, pw * 2.0, floor_y - h * 0.18), col)
			ci.draw_line(Vector2(cx - pw, h * 0.18), Vector2(cx - pw, floor_y), edge, 1.5, true)
			ci.draw_rect(Rect2(cx - pw * 1.6, h * 0.30, pw * 3.2, h * 0.012), col)

# ------------------------------------------------------------- 4 · combat floor
func _paint_floor(ci: Control) -> void:
	var w := ci.size.x
	var h := ci.size.y
	if w <= 0.0 or h <= 0.0:
		return
	var d: Dictionary = spec.get("floor", {})
	var floor_y := h * FLOOR_Y
	ci.draw_rect(Rect2(0, floor_y, w, h - floor_y), d.get("color", Color.BLACK))
	ci.draw_line(Vector2(0, floor_y), Vector2(w, floor_y), d.get("line", Color.GRAY), 2.0, true)
	# perspective cue: a soft pool under the boss slot (contact shadows stay on
	# RaidStage2D — this is scenery, not the shadow contract)
	var pool: Color = d.get("pool", Color(1, 1, 1, 0.05))
	ci.draw_set_transform(Vector2(w * FOCUS_X, floor_y + h * 0.005), 0.0, Vector2(1.0, 0.30))
	ci.draw_circle(Vector2.ZERO, w * 0.11, pool)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# -------------------------------------------------------- 5 · encounter dressing
func _paint_dressing(ci: Control) -> void:
	var w := ci.size.x
	var h := ci.size.y
	if w <= 0.0 or h <= 0.0:
		return
	var d: Dictionary = spec.get("dressing", {})
	var col: Color = d.get("color", Color.BLACK)
	var edge: Color = d.get("edge", Color.GRAY)
	var floor_y := h * FLOOR_Y
	if String(d.get("kind", "")) == "posts":
		# a fence line receding along the floor edge on both flanks
		for fx: float in [0.04, 0.10, 0.90, 0.96]:
			var px := w * fx
			ci.draw_rect(Rect2(px - h * 0.006, floor_y - h * 0.05, h * 0.012, h * 0.06), col)
			ci.draw_line(Vector2(px - h * 0.006, floor_y - h * 0.05),
				Vector2(px - h * 0.006, floor_y + h * 0.01), edge, 1.2, true)
	else:
		# monumental side blocks framing the stage (the interior's pillar bases)
		for s: Array in [[0.05, 1.0], [0.95, -1.0]]:
			var px2 := w * float(s[0])
			ci.draw_rect(Rect2(px2 - h * 0.035, h * 0.12, h * 0.07, floor_y - h * 0.12 + h * 0.03), col)
			ci.draw_line(Vector2(px2 - h * 0.035 * float(s[1]), h * 0.12),
				Vector2(px2 - h * 0.035 * float(s[1]), floor_y + h * 0.03), edge, 1.5, true)

# ---------------------------------------------------- 6 · atmosphere + palette
func _make_atmosphere() -> CPUParticles2D:
	var d: Dictionary = spec.get("atmosphere", {})
	var pc: Color = d.get("particles", Color.WHITE)
	var p := CPUParticles2D.new()
	p.amount = 20
	p.lifetime = 8.0
	p.preprocess = 6.0
	p.direction = Vector2(0, -1) if bool(d.get("rise", true)) else Vector2(1, -0.15)
	p.spread = 18.0
	p.gravity = Vector2(0, -8) if bool(d.get("rise", true)) else Vector2(4, -2)
	p.initial_velocity_min = 4.0
	p.initial_velocity_max = 14.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.2
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	g.colors = PackedColorArray([Color(pc.r, pc.g, pc.b, 0.0),
		Color(pc.r, pc.g, pc.b, 0.4), Color(pc.r, pc.g, pc.b, 0.0)])
	p.color_ramp = g
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = m
	return p

func _paint_tint(ci: Control) -> void:
	var w := ci.size.x
	var h := ci.size.y
	if w <= 0.0 or h <= 0.0:
		return
	var d: Dictionary = spec.get("atmosphere", {})
	ci.draw_rect(Rect2(0, 0, w, h), d.get("tint", Color(0, 0, 0, 0)))
