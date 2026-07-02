## A liquid-fill resource orb (health / rage / mana). The fill sloshes (sine surface);
## over it sits the glass-gem overlay (rim-light bevel + specular + crescent shadow) and
## a lit-from-within glow. Health orbs pulse crimson when low.
class_name LiquidOrb
extends Control

var value: float = 100.0
var max_value: float = 100.0
var fill: Color = Color("9a2b28")
var caption: String = "HP"
var _phase: float = 0.0
var _glow: GlowCore
var _gem: ColorRect

func _ready() -> void:
	# lit-from-within halo, brighter as it fills
	_glow = GlowCore.new()
	_glow.setup(18.0, fill.lightened(0.12), 0.0, 0.5, 0.12)
	add_child(_glow)
	# glass-gem surface: gold rim-light bevel + wet specular + bottom crescent shadow
	_gem = UiKit.orb_overlay(self)

func set_values(v: float, m: float) -> void:
	value = v
	max_value = m

func _process(delta: float) -> void:
	_phase += delta * 2.4
	var frac := 0.0
	if max_value > 0.0:
		frac = clampf(value / max_value, 0.0, 1.0)
	if _glow != null:
		_glow.set_base(0.18 + 0.55 * frac)
	if _gem != null:
		var throb := UiKit.crit_throb(frac, _phase) if caption == "HEALTH" else 0.0
		(_gem.material as ShaderMaterial).set_shader_parameter("throb", throb)
	queue_redraw()

func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - 3.0
	var frac := 0.0
	if max_value > 0.0:
		frac = clampf(value / max_value, 0.0, 1.0)

	# recessed well, then a full fill we mask down to the sloshing surface line
	draw_circle(c, r, Palette.BG0)
	draw_circle(c, r, fill.darkened(0.20))

	var surface_y := c.y + r - 2.0 * r * frac
	var amp := 2.0 + 4.0 * frac * (1.0 - frac)
	var k := TAU * 1.5 / (2.0 * r)
	var mask := PackedVector2Array()
	mask.append(Vector2(c.x - r - 4.0, c.y - r - 4.0))
	mask.append(Vector2(c.x + r + 4.0, c.y - r - 4.0))
	var steps := 24
	for i in range(steps + 1):
		var x := c.x + r + 4.0 - (2.0 * r + 8.0) * float(i) / float(steps)
		var y := surface_y + amp * sin((x - c.x) * k + _phase)
		mask.append(Vector2(x, y))
	draw_colored_polygon(mask, Palette.BG0)

	# bright meniscus band at the surface
	if frac > 0.02 and frac < 0.99:
		var band := PackedVector2Array()
		for i in range(steps + 1):
			var x := c.x - r + (2.0 * r) * float(i) / float(steps)
			band.append(Vector2(x, surface_y + amp * sin((x - c.x) * k + _phase)))
		draw_polyline(band, fill.lightened(0.4), 1.5, true)

	# gilded claw mount: a cradle arc under the orb + three tapered prongs gripping the rim
	var cr := r + 3.0
	draw_arc(c + Vector2(0, r * 0.10), cr + 2.0, TAU * 0.14, TAU * 0.36, 28,
		Palette.GOLD_DIM, 3.0, true)
	draw_arc(c + Vector2(0, r * 0.10), cr + 2.0, TAU * 0.17, TAU * 0.27, 20,
		Palette.GOLD, 1.6, true)
	for ang: float in [TAU * 0.14, TAU * 0.25, TAU * 0.36]:
		var d := Vector2(cos(ang), sin(ang))
		var side := Vector2(-d.y, d.x) * 3.4
		var tip := c + d * (r * 0.80)
		var b1 := c + d * (cr + 4.0) + side
		var b2 := c + d * (cr + 4.0) - side
		draw_colored_polygon(PackedVector2Array([tip, b1, b2]), Palette.GOLD_DIM)
		draw_line(tip, b1, Palette.GOLD, 1.2, true)

	# value inside; caption on a small engraved plaque seated below the mount
	UiKit.text_shadowed(self, UiKit.display(700), Vector2(c.x - r, c.y + 8.0), str(int(round(value))),
		HORIZONTAL_ALIGNMENT_CENTER, 2.0 * r, UiKit.SIZE["TITLE"], Palette.GOLD_BRIGHT)
	var cap := caption.to_upper()
	var cw := maxf(44.0, 9.4 * float(cap.length()) + 14.0)
	var crect := Rect2(c.x - cw * 0.5, c.y + r + 6.0, cw, 16.0)
	var chip := StyleBoxFlat.new()
	chip.bg_color = Color(Palette.BG0.r, Palette.BG0.g, Palette.BG0.b, 0.85)
	chip.border_color = Palette.GOLD_DIM
	chip.set_border_width_all(1)
	chip.set_corner_radius_all(5)
	draw_style_box(chip, crect)
	UiKit.text_shadowed(self, UiKit.display(600, 2), Vector2(crect.position.x, crect.position.y + 12.0),
		cap, HORIZONTAL_ALIGNMENT_CENTER, cw, UiKit.SIZE["MICRO"], Palette.GOLD_DIM.lightened(0.25))
