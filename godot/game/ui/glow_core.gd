## GlowCore — a soft additive glow you drop behind/over any Control (rune, orb,
## dial core). It's a ColorRect running glow.gdshader in additive blend; the host
## widget just calls set_base() each frame to say how lit it should be, and the
## core self-animates a gentle shimmer. All instances share one shader program.
class_name GlowCore
extends ColorRect

const SHADER := preload("res://game/ui/glow.gdshader")

var _mat := ShaderMaterial.new()
var _base: float = 0.0        # target intensity the host drives
var _shimmer: float = 0.0     # 0 = steady, 1 = full sine breathing
var _phase: float = 0.0

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mat.shader = SHADER
	material = _mat

## host: the widget to sit over. pad grows the glow beyond the widget on every side.
func setup(pad: float, glow_color: Color, peak: float, spread: float, shimmer: float = 0.0) -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_left = -pad
	offset_top = -pad
	offset_right = pad
	offset_bottom = pad
	_shimmer = shimmer
	_mat.set_shader_parameter("glow_color", glow_color)
	_mat.set_shader_parameter("peak", peak)
	_mat.set_shader_parameter("spread", spread)
	_mat.set_shader_parameter("intensity", 0.0)

func set_base(v: float) -> void:
	_base = maxf(0.0, v)

func set_glow_color(c: Color) -> void:
	_mat.set_shader_parameter("glow_color", c)

func _process(delta: float) -> void:
	_phase += delta * 5.0
	var mul := 1.0 - _shimmer + _shimmer * (0.6 + 0.4 * sin(_phase))
	_mat.set_shader_parameter("intensity", _base * mul)
