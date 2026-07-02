## UiKit — the Gilded Arcane Glass shared toolkit. One virtual light (top-left), one
## gold gradient, shared shader PROGRAMS (each compiles once; every widget makes
## its own ShaderMaterial but points at the shared Shader). Tokens + draw helpers live
## here so the whole UI reads as one intentional system, not per-widget one-offs.
class_name UiKit
extends RefCounted

# --- shared shader programs (compile once — kind to the WebGL2 warm-up budget) ---
const BAR_SHADER := preload("res://game/ui/ui_bar.gdshader")
const BG_SHADER := preload("res://game/ui/background.gdshader")

# --- the one virtual light + gold ramp ---
const LIGHT_DIR := Vector2(-0.6, -0.8)          # top-left (screen y is down)
const TEXT_SHADOW := Color(0.027, 0.027, 0.047, 0.72)

# --- the Gilded Reliquary type system (all OFL, bundled with licenses) ---
# Cinzel Decorative = wordmark/banners · Cinzel (variable) = display/numerals ·
# Spectral = body. Get them via title()/display()/body(), never preload elsewhere.
const _F_CINZEL := preload("res://game/ui/fonts/cinzel/Cinzel.ttf")
const _F_TITLE_REG := preload("res://game/ui/fonts/cinzel_decorative/CinzelDecorative-Regular.ttf")
const _F_TITLE_BOLD := preload("res://game/ui/fonts/cinzel_decorative/CinzelDecorative-Bold.ttf")
const _F_TITLE_BLACK := preload("res://game/ui/fonts/cinzel_decorative/CinzelDecorative-Black.ttf")
const _F_BODY_REG := preload("res://game/ui/fonts/spectral/Spectral-Regular.ttf")
const _F_BODY_MED := preload("res://game/ui/fonts/spectral/Spectral-Medium.ttf")
const _F_BODY_SEMI := preload("res://game/ui/fonts/spectral/Spectral-SemiBold.ttf")

# --- type scale (px, in the 1920x1080 design space) ---
const SIZE := {"HERO": 72, "DISPLAY": 40, "GAUGE": 30, "TITLE": 24, "HEADER": 19,
	"SUBHEAD": 16, "BODY": 15, "LABEL": 13, "CAPTION": 11, "MICRO": 10}

static var _display_cache: Dictionary = {}

## Display face (Cinzel): boss names, headers, class names, big numerals.
## weight 400..900; tracking = extra px between glyphs (headers read best at 1-3).
static func display(weight: int = 600, tracking: int = 0) -> Font:
	var key := weight * 100 + tracking
	if not _display_cache.has(key):
		var fv := FontVariation.new()
		fv.base_font = _F_CINZEL
		fv.variation_opentype = {"wght": weight}
		if tracking != 0:
			fv.spacing_glyph = tracking
		_display_cache[key] = fv
	return _display_cache[key]

## Wordmark face (Cinzel Decorative): game title, VICTORY/DEFEAT banners only.
static func title(weight: int = 700) -> Font:
	if weight >= 900:
		return _F_TITLE_BLACK
	if weight >= 700:
		return _F_TITLE_BOLD
	return _F_TITLE_REG

## Body face (Spectral): descriptions, tooltips, hints, stat lines.
static func body(weight: int = 500) -> Font:
	if weight >= 600:
		return _F_BODY_SEMI
	if weight >= 500:
		return _F_BODY_MED
	return _F_BODY_REG

static var _noise: NoiseTexture2D

# ---------------------------------------------------------------- shared assets
static func noise() -> NoiseTexture2D:
	if _noise == null:
		var fn := FastNoiseLite.new()
		fn.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		fn.frequency = 0.012
		_noise = NoiseTexture2D.new()
		_noise.width = 256
		_noise.height = 256
		_noise.seamless = true
		_noise.noise = fn
	return _noise

# ---------------------------------------------------------------- background stage
## Full-rect atmospheric ground (BG_SHADER) replacing a flat BG0 ColorRect.
static func stage_background(parent: Control) -> ColorRect:
	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = BG_SHADER
	m.set_shader_parameter("noise_tex", noise())
	bg.material = m
	bg.resized.connect(func() -> void:
		if bg.size.y > 0.0:
			m.set_shader_parameter("aspect", Vector2(bg.size.x / bg.size.y, 1.0)))
	parent.add_child(bg)
	if bg.size.y > 0.0:
		m.set_shader_parameter("aspect", Vector2(bg.size.x / bg.size.y, 1.0))
	return bg

## Ambient drifting gold motes (CPUParticles2D — web-reliable). Add above the stage.
static func gold_motes(parent: Control) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.amount = 40
	p.lifetime = 9.0
	p.preprocess = 6.0
	p.position = Vector2.ZERO
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(640, 380)
	p.direction = Vector2(0, -1)
	p.spread = 40.0
	p.gravity = Vector2(0, -6)
	p.initial_velocity_min = 3.0
	p.initial_velocity_max = 12.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.4
	p.color = Palette.GOLD_BRIGHT
	var gm := Palette.GOLD_BRIGHT
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	g.colors = PackedColorArray([
		Color(gm.r, gm.g, gm.b, 0.0), Color(gm.r, gm.g, gm.b, 0.45), Color(gm.r, gm.g, gm.b, 0.0)])
	p.color_ramp = g
	var cm := CanvasItemMaterial.new()
	cm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	p.material = cm
	parent.add_child(p)
	# re-centre the emitter over the viewport
	if parent is Control:
		p.position = (parent as Control).size * 0.5
		(parent as Control).resized.connect(func() -> void: p.position = (parent as Control).size * 0.5)
	return p

# ---------------------------------------------------------------- bars
## A glossy glass bar (BAR_SHADER) tinted from `accent`. Position + size it, then call
## set_bar() each frame. deep->bright fill, gloss sheen, leading edge, gold frame.
static func make_bar(parent: CanvasItem, accent: Color) -> ColorRect:
	var r := ColorRect.new()
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = BAR_SHADER
	m.set_shader_parameter("col_deep", accent.darkened(0.55))
	m.set_shader_parameter("col_mid", accent)
	m.set_shader_parameter("col_bright", accent.lightened(0.24))
	m.set_shader_parameter("col_leading", accent.lightened(0.5))
	m.set_shader_parameter("col_chip", accent.lightened(0.35))
	r.material = m
	parent.add_child(r)
	return r

static func set_bar(bar: ColorRect, frac: float, chip: float = -1.0) -> void:
	var m: ShaderMaterial = bar.material
	m.set_shader_parameter("rect_size", bar.size)
	m.set_shader_parameter("fill_frac", clampf(frac, 0.0, 1.0))
	m.set_shader_parameter("chip_frac", clampf(maxf(chip, frac), 0.0, 1.0))

# ---------------------------------------------------------------- _draw helpers
## Shadowed text: a BG0 drop pass then the fill. Every string in the game goes through
## this so nothing sits flat on the glass.
static func text_shadowed(ci: CanvasItem, font: Font, pos: Vector2, s: String,
		halign: int, width: float, size: int, color: Color) -> void:
	ci.draw_string(font, pos + Vector2(0, 1), s, halign, width, size, TEXT_SHADOW)
	ci.draw_string(font, pos, s, halign, width, size, color)

## Segmented 2-tone lit-metal bevel ring (gold, one virtual light) with dark depth lines.
static func gilded_ring(ci: CanvasItem, center: Vector2, radius: float,
		thickness: float, segments: int = 48) -> void:
	var nl := LIGHT_DIR.normalized()
	for i in segments:
		var a0 := TAU * float(i) / float(segments)
		var a1 := TAU * float(i + 1) / float(segments)
		var mid := (a0 + a1) * 0.5
		var lit := clampf(Vector2(cos(mid), sin(mid)).dot(nl) * 0.5 + 0.5, 0.0, 1.0)
		var col := Palette.GOLD_DIM.lerp(Palette.GOLD, smoothstep(0.0, 0.6, lit))
		col = col.lerp(Palette.GOLD_BRIGHT, smoothstep(0.6, 1.0, lit))
		ci.draw_arc(center, radius, a0, a1, 3, col, thickness, true)
	ci.draw_arc(center, radius - thickness * 0.5, 0.0, TAU, segments, Palette.EDGE, 1.0, true)
	ci.draw_arc(center, radius + thickness * 0.5, 0.0, TAU, segments, Color(0, 0, 0, 0.5), 1.0, true)

## Feathered gradient arc (tail->head) for telegraph sweeps / resource arcs.
static func gradient_arc(ci: CanvasItem, center: Vector2, radius: float, from: float,
		to: float, width: float, col_tail: Color, col_head: Color, segments: int = 40) -> void:
	for i in segments:
		var t0 := float(i) / float(segments)
		var t1 := float(i + 1) / float(segments)
		var a0 := lerpf(from, to, t0)
		var a1 := lerpf(from, to, t1)
		ci.draw_arc(center, radius, a0, a1, 2, col_tail.lerp(col_head, (t0 + t1) * 0.5), width, true)

## Incised radial ticks (dark groove + lit gold lip) — chiseled into a glass dial/gauge.
static func engraved_ticks(ci: CanvasItem, center: Vector2, r_in: float, r_out: float,
		count: int, col: Color = Palette.GOLD_DIM) -> void:
	for i in count:
		var a := TAU * float(i) / float(count) - PI / 2.0
		var dir := Vector2(cos(a), sin(a))
		ci.draw_line(center + dir * r_in, center + dir * r_out, Palette.BG0, 2.5, true)
		ci.draw_line(center + dir * r_in + Vector2(0.6, 0.6), center + dir * r_out + Vector2(0.6, 0.6),
			col, 1.0, true)

## Gold L-bracket + gem flourish at a rect corner. dir components are ±1 (into the rect).
static func filigree_corner(ci: CanvasItem, corner: Vector2, dir: Vector2, arm: float = 12.0) -> void:
	var p := corner + Vector2(dir.x * 6.0, dir.y * 6.0)
	ci.draw_line(p, p + Vector2(dir.x * arm, 0), Palette.GOLD, 2.0, true)
	ci.draw_line(p, p + Vector2(0, dir.y * arm), Palette.GOLD, 2.0, true)
	ci.draw_circle(p, 2.0, Palette.GOLD_BRIGHT)

# ---------------------------------------------------------------- utilities
static func crit_throb(frac: float, phase: float, threshold: float = 0.25) -> float:
	if frac >= threshold:
		return 0.0
	return (1.0 - frac / threshold) * (0.5 + 0.5 * sin(phase * 4.0))

## Ornamental wing flourish for medallion gauges: three tapering, fading gold strokes
## sweeping out from a core, with a gem at the leading tip. s = -1 (left) / +1 (right).
static func wing_flourish(ci: CanvasItem, c: Vector2, s: float, span: float,
		accent: Color, lit := false) -> void:
	for k in 3:
		var p0 := c + Vector2(s * 48.0, -16.0 + float(k) * 9.0)
		var ctrl := c + Vector2(s * (48.0 + span * 0.5), -34.0 + float(k) * 8.0)
		var p2 := c + Vector2(s * (48.0 + span), -18.0 + float(k) * 13.0)
		var prev := p0
		var n := 14
		for i in range(1, n + 1):
			var t := float(i) / float(n)
			var pt := p0.lerp(ctrl, t).lerp(ctrl.lerp(p2, t), t)
			var col := Palette.GOLD if k == 0 else Palette.GOLD_DIM
			if lit:
				col = col.lerp(accent, 0.4)
			col.a = (0.5 if k == 0 else 0.28) * (1.0 - t * 0.75)
			ci.draw_line(prev, pt, col, maxf(0.8, 2.2 - t * 1.6 - float(k) * 0.3), true)
			prev = pt
		if k == 0:
			ci.draw_circle(p2, 2.2, Palette.GOLD if lit else Palette.GOLD_DIM)

## A small engraved caption plaque (dark chip + gold border + tracked Cinzel smallcaps)
## centred at `at`. Lit plaques brighten. The gauge family's shared label treatment.
static func engraved_plaque(ci: CanvasItem, at: Vector2, text: String, lit := false,
		size_px: int = 10) -> Rect2:
	var cap := text.to_upper()
	var f := display(600, 2)
	var tw := f.get_string_size(cap, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px).x
	var w := tw + 18.0
	var r := Rect2(at.x - w * 0.5, at.y - 9.0, w, 18.0)
	var chip := StyleBoxFlat.new()
	chip.bg_color = Color(Palette.BG0.r, Palette.BG0.g, Palette.BG0.b, 0.88)
	chip.border_color = Palette.GOLD if lit else Palette.GOLD_DIM
	chip.set_border_width_all(1)
	chip.set_corner_radius_all(5)
	ci.draw_style_box(chip, r)
	text_shadowed(ci, f, Vector2(r.position.x, at.y + 4.0), cap, HORIZONTAL_ALIGNMENT_CENTER,
		w, size_px, Palette.GOLD if lit else Palette.GOLD_DIM.lightened(0.25))
	return r

## A circular gilded gem-pip (backlash / combo / bloodied counters): lit = accent fill
## + gold bevel + specular; unlit = dark + dim rim.
static func gilded_pip(ci: CanvasItem, c: Vector2, r: float, on: bool, accent: Color) -> void:
	ci.draw_circle(c, r, accent if on else Color(0.09, 0.10, 0.14))
	gilded_ring(ci, c, r, 2.0, 18)
	if on:
		ci.draw_circle(c - Vector2(r * 0.30, r * 0.34), r * 0.28, Color(1, 1, 1, 0.7))

## The global gilded theme — set on a HUD root so bare Buttons/Labels inherit it.
## Buttons speak Cinzel smallcaps; everything else defaults to Spectral body.
static func build_theme() -> Theme:
	var t := Theme.new()
	t.default_font = body(500)
	t.default_font_size = SIZE["BODY"]
	t.set_stylebox("normal", "Button", _btn_sb(Color(Palette.FILL_TOP.r, Palette.FILL_TOP.g, Palette.FILL_TOP.b, 0.92), Palette.GOLD_DIM, 1))
	t.set_stylebox("hover", "Button", _btn_sb(Palette.PANEL.lightened(0.05), Palette.GOLD, 2))
	t.set_stylebox("pressed", "Button", _btn_sb(Palette.BG1, Palette.GOLD_BRIGHT, 2))
	t.set_stylebox("disabled", "Button", _btn_sb(Color(Palette.BG1.r, Palette.BG1.g, Palette.BG1.b, 0.5), Palette.EDGE, 1))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", Palette.TEXT)
	t.set_color("font_hover_color", "Button", Palette.GOLD_BRIGHT)
	t.set_color("font_pressed_color", "Button", Palette.GOLD_BRIGHT)
	t.set_font("font", "Button", display(600, 1))
	t.set_font_size("font_size", "Button", SIZE["SUBHEAD"])
	t.set_color("font_color", "Label", Palette.TEXT)
	return t

static func _btn_sb(bg: Color, border: Color, bw: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 14.0
	sb.content_margin_right = 14.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 5
	sb.shadow_offset = Vector2(0, 3)
	return sb

## A gilded bar drawn IMMEDIATELY in _draw (no shader child) — for the small inline
## gauges: recessed well, deep->bright accent fill, top gloss, bright leading edge, and a
## 2-tone gold bevel frame (one virtual light). Cheap; matches the shader bars visually.
static func glass_bar_draw(ci: CanvasItem, rect: Rect2, frac: float, accent: Color) -> void:
	frac = clampf(frac, 0.0, 1.0)
	ci.draw_rect(rect, Color(0.03, 0.025, 0.05))                                   # recessed well
	ci.draw_rect(Rect2(rect.position, Vector2(rect.size.x, rect.size.y * 0.5)), Color(0, 0, 0, 0.35))
	if frac > 0.001:
		var fw := rect.size.x * frac
		ci.draw_rect(Rect2(rect.position, Vector2(fw, rect.size.y)), accent.darkened(0.14))
		ci.draw_rect(Rect2(rect.position + Vector2(0, rect.size.y * 0.6), Vector2(fw, rect.size.y * 0.4)),
			accent.darkened(0.4))                                                 # bottom shade
		ci.draw_rect(Rect2(rect.position + Vector2(1, 1), Vector2(maxf(0.0, fw - 2.0), rect.size.y * 0.34)),
			Color(1, 1, 1, 0.13))                                                 # top gloss
		ci.draw_rect(Rect2(rect.position + Vector2(fw - 2.0, 0), Vector2(2.0, rect.size.y)),
			accent.lightened(0.5))                                               # bright leading edge
	var p := rect.position
	var s := rect.size
	ci.draw_line(p, Vector2(p.x + s.x, p.y), Palette.GOLD_BRIGHT, 1.5, true)       # 2-tone gold bevel
	ci.draw_line(p, Vector2(p.x, p.y + s.y), Palette.GOLD, 1.5, true)
	ci.draw_line(Vector2(p.x, p.y + s.y), p + s, Palette.GOLD_DIM, 1.5, true)
	ci.draw_line(Vector2(p.x + s.x, p.y), p + s, Palette.GOLD_DIM, 1.5, true)
