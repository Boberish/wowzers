## StageBackdrop — the Gilded Reliquary scene. The fight happens INSIDE a ruined
## gothic sanctum, not on a flat void: atmospheric shader ground, a colonnade of
## pointed arches, the Rift itself burning as a fissure behind the boss (additive),
## slow god-rays, a ritual ground ring, and drifting embers. Pure view: draws from
## local time only, never touches combat state. One node, first child of any screen.
class_name StageBackdrop
extends Control

var focus := Vector2(0.5, 0.38)      # where the boss / wordmark sits — rift + rays aim here
var combat := true                    # menu variant: taller rift, no ritual ground, calmer rays

var _arch: Control
var _glow: Control
var _embers: CPUParticles2D
var _t := 0.0
# fixed jag profile so the crack is stable frame-to-frame (no unseeded randomness)
const _JAGS := [0.0, 0.6, -0.45, 0.85, -0.75, 0.35, -0.6, 0.15, -0.25, 0.0]

func _init(is_combat := true) -> void:
	combat = is_combat
	if not combat:
		focus = Vector2(0.5, 0.30)
	# anchors must exist BEFORE tree entry: layout applies on enter, and a parent that
	# is already laid out will never resize us afterwards (codebase idiom: place, THEN add)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	UiKit.stage_background(self)

	_arch = Control.new()
	_arch.set_anchors_preset(Control.PRESET_FULL_RECT)
	_arch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_arch.draw.connect(_paint_arch)
	add_child(_arch)

	_glow = Control.new()
	_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = add
	_glow.draw.connect(_paint_glow)
	add_child(_glow)

	UiKit.gold_motes(self)
	_embers = _make_embers()
	add_child(_embers)
	resized.connect(_relayout)
	_relayout()

func _relayout() -> void:
	if _embers != null:
		_embers.position = Vector2(size.x * focus.x, size.y * (focus.y - 0.05))
		_embers.emission_rect_extents = Vector2(size.x * 0.012, size.y * 0.22)
	if _arch != null:
		_arch.queue_redraw()

func _make_embers() -> CPUParticles2D:
	# a thin column of crimson embers rising out of the fissure
	var p := CPUParticles2D.new()
	p.amount = 16
	p.lifetime = 7.0
	p.preprocess = 5.0
	p.direction = Vector2(0, -1)
	p.spread = 14.0
	p.gravity = Vector2(0, -14)
	p.initial_velocity_min = 6.0
	p.initial_velocity_max = 20.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	var g := Gradient.new()
	var ec := Palette.CRIMSON.lerp(Palette.GOLD, 0.35)
	g.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	g.colors = PackedColorArray([Color(ec.r, ec.g, ec.b, 0.0),
		Color(ec.r, ec.g, ec.b, 0.5), Color(ec.r, ec.g, ec.b, 0.0)])
	p.color_ramp = g
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = m
	return p

func _process(delta: float) -> void:
	_t += delta
	if _glow != null:
		_glow.queue_redraw()

# ---------------------------------------------------------------- architecture
func _qbez(a: Vector2, ctrl: Vector2, b: Vector2, t: float) -> Vector2:
	return a.lerp(ctrl, t).lerp(ctrl.lerp(b, t), t)

## outline of a pointed (gothic) arch opening, base -> apex -> base
func _arch_pts(x0: float, x1: float, y_base: float, y_apex: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var w := x1 - x0
	var y_spring := y_apex + (y_base - y_apex) * 0.45
	pts.append(Vector2(x0, y_base))
	var n := 7
	for i in range(n + 1):
		pts.append(_qbez(Vector2(x0, y_spring), Vector2(x0 + w * 0.10, y_apex),
			Vector2(x0 + w * 0.5, y_apex), float(i) / float(n)))
	for i in range(1, n + 1):
		pts.append(_qbez(Vector2(x0 + w * 0.5, y_apex), Vector2(x1 - w * 0.10, y_apex),
			Vector2(x1, y_spring), float(i) / float(n)))
	pts.append(Vector2(x1, y_base))
	return pts

func _paint_arch() -> void:
	var w := _arch.size.x
	var h := _arch.size.y
	if w <= 0.0 or h <= 0.0:
		return
	var ci := _arch
	var floor_y := h * 0.80
	var wall_top := h * 0.26
	var wall := Color(Palette.BG1.r, Palette.BG1.g, Palette.BG1.b, 0.62)
	var hole := Color(Palette.BG0.r, Palette.BG0.g, Palette.BG0.b, 0.85)

	# far wall + colonnade of arch openings
	ci.draw_rect(Rect2(0, wall_top, w, floor_y - wall_top), wall)
	var n_arch := 9
	var aw := w / float(n_arch)
	for i in n_arch:
		var cx := (float(i) + 0.5) * aw
		var half := aw * 0.30
		var apex := wall_top + (floor_y - wall_top) * 0.16
		ci.draw_colored_polygon(_arch_pts(cx - half, cx + half, floor_y, apex), hole)
		# column edge highlights (the one virtual light, from top-left)
		var lit := Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.16)
		var dim := Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.05)
		ci.draw_line(Vector2(cx - half, floor_y), Vector2(cx - half, apex + (floor_y - apex) * 0.45), lit, 1.2, true)
		ci.draw_line(Vector2(cx + half, floor_y), Vector2(cx + half, apex + (floor_y - apex) * 0.45), dim, 1.2, true)

	# wall cornice + floor line
	ci.draw_line(Vector2(0, wall_top), Vector2(w, wall_top), Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.10), 1.5, true)
	ci.draw_line(Vector2(0, floor_y), Vector2(w, floor_y), Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.22), 1.5, true)
	# the ground plane recedes into dark
	ci.draw_rect(Rect2(0, floor_y, w, h - floor_y), Color(0, 0, 0, 0.30))

	# two monumental foreground pillars framing the stage
	for side: float in [0.055, 0.945]:
		var px := w * side
		var pw := w * 0.030
		ci.draw_rect(Rect2(px - pw, h * 0.10, pw * 2.0, floor_y - h * 0.10 + h * 0.04), Color(0.045, 0.040, 0.068, 0.9))
		var lit2 := Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.20)
		ci.draw_line(Vector2(px - pw, h * 0.10), Vector2(px - pw, floor_y + h * 0.04), lit2, 1.5, true)
		ci.draw_line(Vector2(px + pw, h * 0.10), Vector2(px + pw, floor_y + h * 0.04),
			Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.07), 1.5, true)
		# capital
		ci.draw_rect(Rect2(px - pw * 1.30, h * 0.088, pw * 2.6, h * 0.014), Color(0.055, 0.048, 0.080, 0.95))
		ci.draw_line(Vector2(px - pw * 1.30, h * 0.088), Vector2(px + pw * 1.30, h * 0.088), lit2, 1.2, true)

	# ritual ground under the boss (combat only): engraved ellipse rings
	if combat:
		var gp := Vector2(w * focus.x, floor_y - h * 0.015)
		ci.draw_set_transform(gp, 0.0, Vector2(1.0, 0.30))
		var rr := w * 0.115
		ci.draw_arc(Vector2.ZERO, rr, 0.0, TAU, 64, Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.30), 2.0, true)
		ci.draw_arc(Vector2.ZERO, rr * 0.82, 0.0, TAU, 56, Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.14), 1.2, true)
		ci.draw_arc(Vector2.ZERO, rr * 0.55, 0.0, TAU, 48, Color(Palette.CRIMSON.r, Palette.CRIMSON.g, Palette.CRIMSON.b, 0.10), 1.2, true)
		for i in 24:
			var a := TAU * float(i) / 24.0
			var d := Vector2(cos(a), sin(a))
			ci.draw_line(d * rr * 0.94, d * rr, Color(Palette.GOLD_DIM.r, Palette.GOLD_DIM.g, Palette.GOLD_DIM.b, 0.25), 1.5, true)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## a crack polyline that thins + fades toward its lower end instead of cutting off
func _crack(ci: CanvasItem, pts: PackedVector2Array, col: Color, wdt: float) -> void:
	var n := pts.size() - 1
	for i in n:
		var t := float(i) / float(n)
		var c2 := col
		if t > 0.62:
			c2.a = col.a * (1.0 - (t - 0.62) / 0.38)
		ci.draw_line(pts[i], pts[i + 1], c2, maxf(1.0, wdt * (1.0 - 0.40 * t)), true)

# ---------------------------------------------------------------- rift + light
func _paint_glow() -> void:
	var w := _glow.size.x
	var h := _glow.size.y
	if w <= 0.0 or h <= 0.0:
		return
	var ci := _glow
	var fx := w * focus.x
	var pulse := 0.5 + 0.5 * sin(_t * 1.6)

	# the Rift: a jagged fissure burning behind the boss / wordmark
	var y0 := h * 0.03
	var y1 := h * (focus.y + (0.10 if combat else 0.16))
	var amp := w * (0.009 if combat else 0.013)
	var pts := PackedVector2Array()
	for i in _JAGS.size():
		var t := float(i) / float(_JAGS.size() - 1)
		pts.append(Vector2(fx + _JAGS[i] * amp, lerpf(y0, y1, t)))
	var deep := Palette.CRIMSON_DEEP
	_crack(ci, pts, Color(deep.r, deep.g, deep.b, 0.34), w * 0.016)
	_crack(ci, pts, Color(Palette.CRIMSON.r, Palette.CRIMSON.g, Palette.CRIMSON.b, 0.20 + 0.10 * pulse), w * 0.005)
	_crack(ci, pts, Color(Palette.GOLD_BRIGHT.r, Palette.GOLD_BRIGHT.g, Palette.GOLD_BRIGHT.b, 0.34 + 0.16 * pulse), w * 0.0016)
	# two small side branches
	var b1 := pts[3]
	var b2 := pts[6]
	ci.draw_polyline(PackedVector2Array([b1, b1 + Vector2(-w * 0.012, h * 0.03), b1 + Vector2(-w * 0.016, h * 0.055)]),
		Color(Palette.CRIMSON.r, Palette.CRIMSON.g, Palette.CRIMSON.b, 0.14 + 0.06 * pulse), w * 0.0022, true)
	ci.draw_polyline(PackedVector2Array([b2, b2 + Vector2(w * 0.014, h * 0.025), b2 + Vector2(w * 0.019, h * 0.05)]),
		Color(Palette.CRIMSON.r, Palette.CRIMSON.g, Palette.CRIMSON.b, 0.14 + 0.06 * pulse), w * 0.0022, true)

	# god-rays fanning down from above the rift
	var apex := Vector2(fx, -h * 0.06)
	for i in 3:
		var base_a := PI * 0.5 + (float(i) - 1.0) * 0.16
		var sway := sin(_t * 0.10 + float(i) * 2.1) * 0.05
		var a1 := base_a + sway - 0.035
		var a2 := base_a + sway + 0.035
		var ln := h * 1.25
		var alpha := (0.030 if combat else 0.022) + 0.012 * sin(_t * 0.21 + float(i) * 1.7)
		ci.draw_colored_polygon(PackedVector2Array([apex,
			apex + Vector2(cos(a1), sin(a1)) * ln, apex + Vector2(cos(a2), sin(a2)) * ln]),
			Color(Palette.GOLD.r, Palette.GOLD.g, Palette.GOLD.b, maxf(alpha, 0.0)))

	# warm pool of light on the ritual ground
	if combat:
		var gp := Vector2(fx, h * 0.785)
		ci.draw_set_transform(gp, 0.0, Vector2(1.0, 0.30))
		ci.draw_circle(Vector2.ZERO, w * 0.115, Color(Palette.GOLD.r, Palette.GOLD.g, Palette.GOLD.b, 0.030 + 0.012 * pulse))
		ci.draw_circle(Vector2.ZERO, w * 0.065, Color(Palette.CRIMSON.r, Palette.CRIMSON.g, Palette.CRIMSON.b, 0.035))
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
