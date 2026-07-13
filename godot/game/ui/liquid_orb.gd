## A living liquid resource orb (health / rage / mana / sap / focus). The glass,
## the per-pixel liquid (depth shading, waved surface + meniscus, rising bubbles),
## the damage-CHIP ghost, the gain FLASH and the low-health BOIL all live in one
## shader pass (ui_orb_liquid.gdshader); this Control eases the fill, drives the
## chip/flash timers, and draws the gilded claw mount, the numeral and the
## caption plaque on top. Public surface unchanged: fill / caption / set_values.
class_name LiquidOrb
extends Control

var value: float = 100.0
var max_value: float = 100.0
var fill: Color = Color("9a2b28")
var caption: String = "HP"
# --- ART V2 / C6B (set ONLY by the dash host; default off ⇒ legacy orb byte-identical):
# the same live feed presented as a painted HORIZONTAL safety bar (§2.3.1 E — HP left,
# Flow/Aggro right). Fills, numerals, captions, warnings stay code-drawn; the I3-B
# resource shell supplies only the housing.
var v2_bar: DashSkin = null
var v2_pct: bool = false          ## print the numeral as a percentage (the Flow/Aggro bar)
var v2_lock: float = -1.0         ## 0..1 threshold marker (the Duelist's 30% Flow lock);
                                  ## < 0 = none. Always code-drawn — never baked (README law).

var _phase: float = 0.0
var _disp: float = 1.0            # eased displayed fraction (the liquid moves like liquid)
var _chip: float = 1.0            # trails _disp downward after damage
var _flash: float = 0.0           # gain pulse, decays
var _prev_frac: float = -1.0
var _glow: GlowCore
var _liq: ColorRect
var _mat: ShaderMaterial

func _ready() -> void:
	# lit-from-within halo, brighter as it fills
	_glow = GlowCore.new()
	_glow.setup(18.0, fill.lightened(0.12), 0.0, 0.5, 0.12)
	add_child(_glow)
	# the liquid glass sphere — one shader pass, behind this control's own draw
	_liq = ColorRect.new()
	_liq.set_anchors_preset(Control.PRESET_FULL_RECT)
	_liq.show_behind_parent = true
	_liq.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat = ShaderMaterial.new()
	_mat.shader = preload("res://game/ui/ui_orb_liquid.gdshader")
	_mat.set_shader_parameter("liquid", fill)
	_liq.material = _mat
	add_child(_liq)

func set_values(v: float, m: float) -> void:
	value = v
	max_value = m

func _frac() -> float:
	return clampf(value / max_value, 0.0, 1.0) if max_value > 0.0 else 0.0

func _process(delta: float) -> void:
	_phase += delta * 2.4
	var frac := _frac()
	if _prev_frac < 0.0:
		_prev_frac = frac
		_disp = frac
		_chip = frac
	# a real gain flashes the liquid (heals, resource bursts — not the idle trickle)
	if frac > _prev_frac + 0.015:
		_flash = 1.0
	_prev_frac = frac
	_flash = maxf(0.0, _flash - delta * 2.6)
	# the liquid eases to the true level; the pale chip band drains after it
	_disp = lerpf(_disp, frac, minf(1.0, delta * 7.0))
	if _disp >= _chip:
		_chip = _disp
	else:
		_chip = maxf(_disp, _chip - delta * 0.45)
	var throb := UiKit.crit_throb(frac, _phase) if caption == "HEALTH" else 0.0
	if v2_bar != null:                # C6B bar mode: the orb shader/halo stay dark
		if _liq != null and _liq.visible:
			_liq.visible = false
		if _glow != null and _glow.visible:
			_glow.visible = false
		queue_redraw()
		return
	if _glow != null:
		_glow.set_base(0.18 + 0.55 * frac + 0.25 * _flash)
	if _mat != null:
		_mat.set_shader_parameter("frac", _disp)
		_mat.set_shader_parameter("chip", _chip)
		_mat.set_shader_parameter("flash", _flash)
		_mat.set_shader_parameter("throb", throb)
	queue_redraw()

## C6B: the painted horizontal safety bar — shell = I3-B resource frame (end caps at
## uniform scale), well/fill/chip/numeral/caption all code-drawn from the SAME eased
## feed the orb uses. The host draws the 30% Flow lock on top (code-owned by law).
func _draw_v2_bar() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	v2_bar.hshell(self, "shell_resource", rect, DashSkin.CAPS_RESOURCE)
	var well := v2_bar.sliced_opening("shell_resource", rect, DashSkin.CAPS_RESOURCE, DashSkin.OPEN_RESOURCE)
	draw_rect(well, Palette.BG0)
	draw_rect(Rect2(well.position, Vector2(well.size.x, well.size.y * 0.45)), Color(0, 0, 0, 0.35))
	var frac := clampf(_disp, 0.0, 1.0)
	var throb := UiKit.crit_throb(_frac(), _phase) if caption == "HEALTH" else 0.0
	# pale chip ghost trails the fill down after damage (the orb's read, flattened)
	if _chip > frac + 0.003:
		draw_rect(Rect2(well.position.x + well.size.x * frac, well.position.y + 1.0,
			well.size.x * (_chip - frac), well.size.y - 2.0), Color(0.95, 0.85, 0.8, 0.30))
	var fw := well.size.x * frac
	if fw > 1.0:
		var fc := fill.lerp(Palette.CRIMSON, 0.5 * throb)
		if _flash > 0.0:
			fc = fc.lightened(0.30 * _flash)
		UiKit.grad_rect(self, Rect2(well.position, Vector2(fw, well.size.y)),
			fc.lightened(0.22), fc.darkened(0.22))
		draw_rect(Rect2(well.position + Vector2(0, 1.0), Vector2(fw, well.size.y * 0.34)),
			Color(1, 1, 1, 0.10))
		if frac < 0.995:
			draw_rect(Rect2(well.position.x + fw - 1.5, well.position.y, 1.5, well.size.y),
				fc.lightened(0.5))
	if v2_lock >= 0.0:                # the lock line rides ABOVE the fill, code-owned
		var lx := well.position.x + well.size.x * v2_lock
		var lc := Color(1.0, 0.62, 0.30, 0.9)
		draw_line(Vector2(lx, well.position.y - 3.0), Vector2(lx, well.end.y + 3.0), lc, 2.0, true)
		UiKit.text_shadowed(self, UiKit.display(700), Vector2(lx - 20.0, well.end.y + 12.0),
			"%d%% LOCK" % int(round(v2_lock * 100.0)), HORIZONTAL_ALIGNMENT_LEFT, 70.0,
			UiKit.SIZE["MICRO"], lc)
	var numc := Palette.GOLD_BRIGHT.lerp(Palette.CRIMSON.lightened(0.25), throb)
	var vtxt := (str(int(round(value))) + "%") if v2_pct else str(int(round(value)))
	UiKit.text_shadowed(self, UiKit.display(700), Vector2(well.position.x, well.get_center().y + 5.0),
		vtxt, HORIZONTAL_ALIGNMENT_RIGHT, well.size.x - 8.0, UiKit.SIZE["LABEL"], numc)
	UiKit.text_shadowed(self, UiKit.display(600, 2), Vector2(well.position.x + 8.0, well.get_center().y + 4.5),
		caption.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, well.size.x - 60.0,
		UiKit.SIZE["MICRO"], Palette.GOLD_DIM.lightened(0.25))

func _draw() -> void:
	if v2_bar != null:
		_draw_v2_bar()
		return
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - 3.0
	var frac := _frac()

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

	# value inside (bleeds crimson as a HEALTH orb empties); caption plaque below
	var throb := UiKit.crit_throb(frac, _phase) if caption == "HEALTH" else 0.0
	var numc := Palette.GOLD_BRIGHT.lerp(Palette.CRIMSON.lightened(0.25), throb)
	UiKit.text_shadowed(self, UiKit.display(700), Vector2(c.x - r, c.y + 8.0), str(int(round(value))),
		HORIZONTAL_ALIGNMENT_CENTER, 2.0 * r, UiKit.SIZE["TITLE"], numc)
	var cap := caption.to_upper()
	var cw := maxf(44.0, 9.4 * float(cap.length()) + 14.0)
	var crect := Rect2(c.x - cw * 0.5, c.y + r + 6.0, cw, 16.0)
	var chip_sb := StyleBoxFlat.new()
	chip_sb.bg_color = Color(Palette.BG0.r, Palette.BG0.g, Palette.BG0.b, 0.85)
	chip_sb.border_color = Palette.GOLD_DIM
	chip_sb.set_border_width_all(1)
	chip_sb.set_corner_radius_all(5)
	draw_style_box(chip_sb, crect)
	UiKit.text_shadowed(self, UiKit.display(600, 2), Vector2(crect.position.x, crect.position.y + 12.0),
		cap, HORIZONTAL_ALIGNMENT_CENTER, cw, UiKit.SIZE["MICRO"], Palette.GOLD_DIM.lightened(0.25))
