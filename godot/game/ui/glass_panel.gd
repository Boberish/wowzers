## GlassPanel — a frosted-glass gilded surface (ui_glass.gdshader) that drops in wherever
## a flat StyleBoxFlat Panel was. Add content as children; they draw on top of the glass.
## Variants: PANEL / CARD / FRAME / TOOLTIP / WELL. set_active() brightens the edge glow.
class_name GlassPanel
extends Control

const SHADER := preload("res://game/ui/ui_glass.gdshader")
const PAD := 24.0

var _rect: ColorRect
var _mat := ShaderMaterial.new()
var _glow_base: float = 0.14

func _init(variant: String = "PANEL", accent: Color = Palette.GOLD_DIM) -> void:
	var alpha := 0.90
	var radius := 12.0
	var glow := 0.14
	var top := Palette.FILL_TOP
	match variant:
		"CARD":
			alpha = 0.96; radius = 12.0; glow = 0.16
		"FRAME":
			alpha = 0.86; radius = 8.0; glow = 0.10
		"TOOLTIP":
			alpha = 0.90; radius = 8.0; glow = 0.10
		"WELL":
			alpha = 0.94; radius = 6.0; glow = 0.0; top = Palette.WELL_TOP
	_glow_base = glow
	_mat.shader = SHADER
	_mat.set_shader_parameter("shape", 0)
	_mat.set_shader_parameter("shadow_pad", PAD)
	_mat.set_shader_parameter("corner_radius", radius)
	_mat.set_shader_parameter("fill_alpha", alpha)
	_mat.set_shader_parameter("glow_boost", glow)
	_mat.set_shader_parameter("accent_color", accent)
	_mat.set_shader_parameter("fill_top", top)
	_mat.set_shader_parameter("fill_bot", Palette.FILL_BOT)

func _ready() -> void:
	_rect = ColorRect.new()
	_rect.show_behind_parent = true              # always draws behind the content children
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.material = _mat
	add_child(_rect)
	resized.connect(_layout)
	_layout()

func _layout() -> void:
	if _rect == null:
		return
	_rect.position = Vector2(-PAD, -PAD)          # grow beyond the panel so the shadow has room
	_rect.size = size + Vector2(PAD * 2.0, PAD * 2.0)
	_mat.set_shader_parameter("rect_px", _rect.size)

func set_active(on: bool) -> void:
	_mat.set_shader_parameter("glow_boost", _glow_base * (2.2 if on else 1.0))
